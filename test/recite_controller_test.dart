import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kurandakimesaj/data/local/app_database.dart' show Surah;
import 'package:kurandakimesaj/domain/quran_matcher.dart';
import 'package:kurandakimesaj/features/ayah_finder/recite_controller.dart';
import 'package:kurandakimesaj/features/quran/quran_screens.dart';

/// Okuyarak Bul denetleyicisi: tanınan metin -> sure adlı ayet kartı verisi.
/// Ses tanıma platform kanalı sahtelenir; `onRecognized` doğrudan çağrılır.

const _surahs = [
  Surah(number: 1, nameTr: 'Fâtiha', nameArabic: 'الفاتحة', meaning: 'Açılış', ayahCount: 7, revelation: 'Mekki', juzStart: 1),
  Surah(number: 2, nameTr: 'Bakara', nameArabic: 'البقرة', meaning: 'İnek', ayahCount: 286, revelation: 'Medeni', juzStart: 1),
];

const _ar = {
  1: 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
  2: 'ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَٰلَمِينَ',
  3: 'ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
  4: 'مَٰلِكِ يَوْمِ ٱلدِّينِ',
  5: 'إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ',
};
const _meal = {
  1: 'Rahman ve Rahim olan Allah\'ın adıyla:',
  2: 'Hamd, Alemlerin Rabbi Allah\'a mahsustur.',
  3: 'O Rahman ve Rahim\'dir,',
  4: 'Din Gününün sahibidir.',
  5: 'Ancak sana kulluk eder, ancak senden yardım dileriz.',
};

const _channel = MethodChannel('plugin.csdcorp.com/speech_to_text');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late List<MethodCall> platformCalls;

  setUp(() {
    platformCalls = [];
    container = ProviderContainer(overrides: [
      quranMatcherProvider.overrideWith(
        (ref) async => QuranMatcher([
          for (final a in _ar.keys)
            QuranVerse(surah: 1, ayah: a, arabic: _ar[a]!, meal: _meal[a]!),
        ]),
      ),
      surahsProvider.overrideWith((ref) async => _surahs),
    ]);
    // Ters sırada çalışır: önce container kapanır (cancel çağrısı sahte kanala gider).
    addTearDown(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null));
    addTearDown(container.dispose);
  });

  void mockSpeech({required bool ready, List<String> locales = const []}) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
      platformCalls.add(call);
      return switch (call.method) {
        'initialize' => ready,
        'locales' => locales,
        'listen' => true,
        _ => null,
      };
    });
  }

  Future<ReciteController> open() async {
    container.listen(reciteControllerProvider, (_, _) {}); // autoDispose canlı kalsın
    await container.read(quranMatcherProvider.future);
    await container.read(surahsProvider.future);
    return container.read(reciteControllerProvider.notifier);
  }

  ReciteState read() => container.read(reciteControllerProvider);

  group('eşleştirme', () {
    test('tanınan metin -> sure adlı referans, Arapça ve meal', () async {
      final c = await open();

      c.onRecognized('الحمد لله رب العالمين', const []);
      await pumpEventQueue();

      final top = read().matches.first;
      expect(top.reference, 'Fâtiha, 2');
      expect(top.surah, 1);
      expect(top.ayah, 2);
      expect(top.arabic, _ar[2]);
      expect(top.meal, _meal[2]);
      expect(top.confidence, greaterThan(0.8));
      expect(read().heard, 'الحمد لله رب العالمين');
    });

    test('iki ayete taşan okuma -> "Fâtiha, 4-5"; Arapça ve meal birleşir', () async {
      final c = await open();

      c.onRecognized('مالك يوم الدين إياك نعبد', const []);
      await pumpEventQueue();

      final top = read().matches.first;
      expect(top.reference, 'Fâtiha, 4-5');
      expect(top.ayah, 4);
      expect(top.arabic, '${_ar[4]} ${_ar[5]}');
      expect(top.meal, '${_meal[4]} ${_meal[5]}');
    });

    test('alternatif tahmin isabeti kurtarır', () async {
      final c = await open();

      c.onRecognized('ذهبت إلى السوق', const ['مالك يوم الدين']);
      await pumpEventQueue();

      expect(read().matches.first.reference, 'Fâtiha, 4');
    });

    // Emülatörde Husarî Fatiha 2-4 ile görülen gerçek dizi: Google tanıyıcısı
    // vakıf duraklamasında bölüm açar, araya "" koyar, yeni bölüm baştaki
    // boşlukla sıfırdan başlar; son sonuç yalnız son bölümü taşır.
    test('bölümlere ayrılan okuma birikir; boş ara sonuç duyulanı silmez', () async {
      final c = await open();

      c.onRecognized('الحمد لله رب العالمين', const [], isFinal: false);
      c.onRecognized('', const [], isFinal: false);
      expect(read().heard, 'الحمد لله رب العالمين', reason: 'boş ara sonuç silmemeli');
      c.onRecognized(' الرحمن الرحيم', const [], isFinal: false);
      c.onRecognized('', const [], isFinal: false);
      c.onRecognized(' مالك يوم الدين', const [], isFinal: true);
      await pumpEventQueue();

      expect(read().heard, 'الحمد لله رب العالمين الرحمن الرحيم مالك يوم الدين');
      expect(read().matches.first.surah, 1);
      expect(read().matches.first.ayah, inInclusiveRange(2, 4));
    });

    test('alakasız metin: sonuç yok, duyulan metin korunur', () async {
      final c = await open();

      c.onRecognized('ذهبت إلى السوق لشراء الخبز والحليب', const []);
      await pumpEventQueue();

      expect(read().matches, isEmpty);
      expect(read().heard, 'ذهبت إلى السوق لشراء الخبز والحليب');
    });
  });

  group('debounce', () {
    test('kısmi sonuç 350 ms sonra eşleşir; son sonuç beklemez', () async {
      final c = await open();

      c.onRecognized('الحمد لله', const [], isFinal: false);
      await pumpEventQueue();
      expect(read().heard, 'الحمد لله');
      expect(read().matches, isEmpty, reason: 'debounce süresi dolmadı');

      await Future<void>.delayed(const Duration(milliseconds: 450));
      await pumpEventQueue();
      expect(read().matches.first.reference, 'Fâtiha, 2');

      c.onRecognized('مالك يوم الدين', const [], isFinal: true);
      await pumpEventQueue();
      expect(read().matches.first.reference, 'Fâtiha, 4');
    });

    test('denetleyici kapanınca bekleyen kısmi sonuç hata üretmez', () async {
      final c = await open();

      c.onRecognized('الحمد لله', const [], isFinal: false);
      container.dispose();

      await Future<void>.delayed(const Duration(milliseconds: 450));
    });
  });

  // `SpeechToText()` tekildir ve ilk başarılı initialize'ı hatırlar: bu grup
  // sırayla çalışmalı (başarısız initialize önce).
  group('ses tanıma hazırlığı (sahte platform kanalı)', () {
    test('tanıyıcı başlatılamazsa kullanılamaz + Türkçe mesaj', () async {
      mockSpeech(ready: false);
      final c = await open();

      await c.start();

      expect(read().status, ReciteStatus.unavailable);
      expect(read().error, contains('Ses tanıma kullanılamıyor'));
      expect(platformCalls.map((e) => e.method), isNot(contains('listen')));
    });

    // Android 13+: locales() yalnız cihaz üstü dilleri verir (emülatörde Arapça
    // yoktu) ama çevrimiçi tanıyıcı ar-SA'yı tanıyabilir — liste kilitlememeli.
    test('dil listesinde Arapça yoksa yine ar-SA ile dinler', () async {
      mockSpeech(ready: true, locales: const ['en_US:English (United States)']);
      final c = await open();

      await c.start();

      expect(read().status, ReciteStatus.listening);
      final listen = platformCalls.singleWhere((e) => e.method == 'listen');
      expect((listen.arguments as Map)['localeId'], 'ar-SA');
    });

    test('tanıyıcı Arapçayı desteklemezse kullanılamaz + ekleme yönergesi', () async {
      mockSpeech(ready: true, locales: const ['en_US:English (United States)']);
      final c = await open();
      await c.start();

      // Platformdan gelen hata geri çağrısı (eklentinin gerçek kanal biçimi).
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
        _channel.name,
        _channel.codec.encodeMethodCall(MethodCall(
          'notifyError',
          jsonEncode({'errorMsg': 'error_language_not_supported', 'permanent': true}),
        )),
        (_) {},
      );

      expect(read().status, ReciteStatus.unavailable);
      expect(read().error, contains('Google uygulaması › Ayarlar › Ses › Diller'));
    });

    test('Arapça (SA tercihli) ile dinler; durdurunca hazıra döner', () async {
      mockSpeech(ready: true, locales: const [
        'en_US:English (United States)',
        'ar_EG:Arabic (Egypt)',
        'ar_SA:Arabic (Saudi Arabia)',
        'arn_CL:Mapudungun',
      ]);
      final c = await open();

      await c.start();

      expect(read().status, ReciteStatus.listening);
      final listen = platformCalls.singleWhere((e) => e.method == 'listen');
      expect((listen.arguments as Map)['localeId'], 'ar_SA');
      expect((listen.arguments as Map)['partialResults'], isTrue);

      await c.stop();
      expect(read().status, ReciteStatus.ready);
      expect(platformCalls.map((e) => e.method), contains('stop'));
    });

    test('yeni dinleme önceki okumayı biriktirmez', () async {
      mockSpeech(ready: true, locales: const ['ar_SA:Arabic (Saudi Arabia)']);
      final c = await open();
      c.onRecognized('الحمد لله رب العالمين', const [], isFinal: true);
      c.onRecognized('', const [], isFinal: false);

      await c.start();
      c.onRecognized('مالك يوم الدين', const [], isFinal: true);
      await pumpEventQueue();

      expect(read().heard, 'مالك يوم الدين');
      expect(read().matches.first.reference, 'Fâtiha, 4');
    });
  });
}
