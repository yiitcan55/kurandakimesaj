import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kurandakimesaj/domain/models.dart';
import 'package:kurandakimesaj/features/ayah_finder/ayah_error_messages.dart';
import 'package:kurandakimesaj/features/ayah_finder/ayah_finder_controller.dart';
import 'package:kurandakimesaj/features/ayah_finder/ayah_finder_screen.dart';

/// Ekranı sabit sonuçla süren controller: build() hazır sonuç döndürür.
class _FixedController extends AyahFinderController {
  _FixedController(this.fixed);
  final AyahFinderResult fixed;
  @override
  Future<AyahFinderResult?> build() async => fixed;
}

Future<void> _pump(WidgetTester tester, {AyahFinderResult? fixed}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (fixed != null) ayahFinderProvider.overrideWith(() => _FixedController(fixed)),
      ],
      child: MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: '/ayah-finder',
          routes: [
            GoRoute(path: '/ayah-finder', builder: (_, _) => const AyahFinderScreen()),
            GoRoute(
              path: '/meal-edit',
              builder: (_, _) => const Placeholder(key: Key('stub_meal_edit')),
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 100));
}

/// Gecikmeli flutter_animate timer'larını boşalt, sonra ağacı sök (ders 18).
Future<void> _finish(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpWidget(const SizedBox());
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  // Kod -> mesajın ayırt edici parçası (tablo birim testi).
  final cases = <String, String>{
    'file_too_large': 'Görsel en fazla 10 MB, video en fazla 20 MB',
    'video_missing': 'Video okunamadı',
    'no_video': 'Video isteği eksik gönderildi',
    'no_image': 'Bu içerikte okunabilecek bir görsel bulunamadı',
    'upload_failed': 'Video yüklenemedi',
    'asr_failed': 'Videodaki ses çözümlenemedi',
    'rate_limited': 'Şu an çok fazla istek var',
    'forbidden_path': 'Bu videoya erişim yetkin yok',
    'auth_required': 'Bu özellik için giriş yapman gerekir',
    'no_api_key': 'Ayet bulma servisi şu an yapılandırılmamış',
    'network': 'İnternete ulaşılamadı',
    'server_error': 'Sunucuda beklenmedik bir sorun oluştu',
    'bad_response': 'Sunucudan anlaşılmayan bir yanıt geldi',
    'not_found': "Bu videoda Kur'an tilaveti bulunamadı. Ayet aralığını elle seçebilirsin.",
    'ambiguous': 'Ayetler kesin belirlenemedi. Ayet aralığını elle seçebilirsin.',
  };

  for (final entry in cases.entries) {
    test('kod "${entry.key}" kendi Türkçe mesajını verir', () {
      expect(ayahErrorMessage(entry.key)?.$2, contains(entry.value));
    });
  }

  test('bağlantı kodları ve bilinmeyen kod null döner', () {
    for (final c in ['link_unresolved', 'blocked_host', 'invalid_url', 'totally_unknown_code', null]) {
      expect(ayahErrorMessage(c), isNull, reason: '$c');
    }
  });

  testWidgets('file_too_large ekranda tam metinle görünür', (tester) async {
    await _pump(
      tester,
      fixed: const AyahFinderResult(status: AyahFinderStatus.error, errorCode: 'file_too_large'),
    );
    expect(
      find.text('Dosya çok büyük. Görsel en fazla 10 MB, video en fazla 20 MB olabilir.'),
      findsOneWidget,
    );
    await _finish(tester);
  });

  testWidgets(
    'bilinmeyen hata kodu jenerik mesaja düşer ve debugPrint ile loglanır',
    (tester) async {
      final logs = <String>[];
      final original = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) logs.add(message);
      };
      // addTearDown DEĞİL: flutter_test debug değişkenlerinin test bitiminde
      // varsayılana döndüğünü doğruluyor; geri alma gövde içinde yapılmalı.
      try {
        await _pump(
          tester,
          fixed: const AyahFinderResult(
            status: AyahFinderStatus.error,
            errorCode: 'totally_unknown_code',
          ),
        );
        expect(find.textContaining('Beklenmedik bir hata oluştu'), findsOneWidget);
        expect(logs, contains('AyahFinder hata: kod="totally_unknown_code" detay=-'));
        await _finish(tester);
      } finally {
        debugPrint = original;
      }
    },
  );

  testWidgets("Ayet Bul'da Bağlantı Yapıştır alanı yok", (tester) async {
    await _pump(tester);
    expect(find.byType(TextField), findsNothing);
    expect(find.textContaining('Bağlantı Yapıştır'), findsNothing);
    await _finish(tester);
  });

  testWidgets("Videodan Meal kutucuğu /meal-edit'e gider", (tester) async {
    await _pump(tester);
    expect(find.text('Videodan Meal'), findsOneWidget);
    expect(find.text('Tilavet videosundaki ayetleri Meal Düzenle ile bul'), findsOneWidget);

    await tester.tap(find.byKey(const Key('ayahVideoTile')));
    // go_router push rota çözümlemesi asenkron: önce bir kare, sonra geçiş.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byKey(const Key('stub_meal_edit')), findsOneWidget);
    await _finish(tester);
  });

  // `app.dart` hedef rota ZATEN açıksa yeni ekran push etmez ("açık ekran
  // provider'ı dinleyip tüketir"). Ayet Bul girdiyi yalnız initState'te
  // tüketirse, ekran açıkken paylaşılan görsel sessizce düşer (emülatör S10).
  Future<(_RecordingController, ProviderContainer)> pumpRecording(
    WidgetTester tester,
  ) async {
    final rec = _RecordingController();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [ayahFinderProvider.overrideWith(() => rec)],
        child: const MaterialApp(home: AyahFinderScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(AyahFinderScreen)),
    );
    return (rec, container);
  }

  testWidgets('ekran AÇIKKEN gelen görsel paylaşımı tüketilir', (tester) async {
    final (rec, container) = await pumpRecording(tester);
    expect(rec.shared, isEmpty);

    container.read(sharedAyahInputProvider.notifier).set((
      imagePath: '/cache/a.png',
      videoPath: null,
      url: null,
    ));
    await tester.pump();

    expect(rec.shared, ['/cache/a.png']);
    expect(container.read(sharedAyahInputProvider), isNull);
    await _finish(tester);
  });

  testWidgets('ekran açıkken gelen VİDEO girdisine dokunulmaz (Meal Düzenle '
      'tüketir)', (tester) async {
    final (rec, container) = await pumpRecording(tester);

    container.read(sharedAyahInputProvider.notifier).set((
      imagePath: null,
      videoPath: '/cache/v.mp4',
      url: null,
    ));
    await tester.pump();

    expect(rec.shared, isEmpty);
    expect(container.read(sharedAyahInputProvider)?.videoPath, '/cache/v.mp4');
    await _finish(tester);
  });
}

/// `fromSharedImage` çağrılarını kaydeder; dosya okumaz.
class _RecordingController extends AyahFinderController {
  final List<String> shared = [];
  @override
  Future<AyahFinderResult?> build() async => null;
  @override
  Future<void> fromSharedImage(String path) async => shared.add(path);
}
