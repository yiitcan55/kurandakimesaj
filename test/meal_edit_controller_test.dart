import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kurandakimesaj/data/backend_repositories.dart';
import 'package:kurandakimesaj/data/local/app_database.dart' show Ayah, Surah;
import 'package:kurandakimesaj/data/meal_video_store.dart';
import 'package:kurandakimesaj/domain/meal_cues.dart';
import 'package:kurandakimesaj/domain/models.dart';
import 'package:kurandakimesaj/features/meal_edit/meal_edit_controller.dart';
import 'package:kurandakimesaj/features/quran/quran_screens.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_ayah_finder_repository.dart';
import 'support/recording_social_repository.dart';

final _ayahs = [
  for (var i = 1; i <= 4; i++)
    Ayah(
      id: i,
      surahNumber: 36,
      numberInSurah: 57 + i,
      arabic: 'أ' * (10 * i),
      meal: 'meal ${57 + i}',
    ),
];

AyahFinderResult _matched() => AyahFinderResult(
  status: AyahFinderStatus.matched,
  range: const AyahRange(surah: 36, fromAyah: 58, toAyah: 59, reference: 'Yasin, 58-59'),
  matches: [
    for (final a in _ayahs.take(2))
      AyahMatch(
        reference: 'Yasin, ${a.numberInSurah}',
        surah: 36,
        ayah: a.numberInSurah,
        arabic: a.arabic,
        meal: a.meal,
        confidence: 1,
      ),
  ],
  timeline: const [
    AyahTimelineEntry(startSec: 1, endSec: 5, surah: 36, ayah: 58, reference: 'Yasin, 58', confidence: 1),
    AyahTimelineEntry(startSec: 5, endSec: 9, surah: 36, ayah: 59, reference: 'Yasin, 59', confidence: 1),
  ],
);

void main() {
  late Directory root;
  late FakeAyahFinderRepository fake;
  late RecordingSocialRepository social;
  late ProviderContainer container;

  File video(String name, {int? bytes}) {
    final f = File('${root.path}/$name')..writeAsBytesSync([1, 2, 3]);
    if (bytes != null) {
      final raf = f.openSync(mode: FileMode.append)..truncateSync(bytes);
      raf.closeSync();
    }
    return f;
  }

  MealEditState read() => container.read(mealEditProvider);
  MealEditController ctl() => container.read(mealEditProvider.notifier);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    root = Directory.systemTemp.createTempSync('meal_edit_test');
    fake = FakeAyahFinderRepository(result: _matched());
    social = RecordingSocialRepository();
    container = ProviderContainer(
      overrides: [
        ayahFinderRepositoryProvider.overrideWithValue(fake),
        socialRepositoryProvider.overrideWithValue(social),
        mealVideoStoreProvider.overrideWithValue(
          MealVideoStore(prefs: prefs, roots: () async => [root.path]),
        ),
        surahsProvider.overrideWith(
          (ref) async => const [
            Surah(
              number: 36,
              nameTr: 'Yasin',
              nameArabic: 'يس',
              meaning: '',
              ayahCount: 83,
              revelation: '',
              juzStart: 22,
            ),
          ],
        ),
        surahAyahsProvider.overrideWith((ref, n) async => _ayahs),
        cloudReelsProvider.overrideWith((ref) async => const []),
      ],
    );
    container.listen(mealEditProvider, (_, _) {});
  });
  tearDown(() {
    container.dispose();
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  test('20 MB altı video analiz edilir, aralık ve cue dolar', () async {
    final f = video('a.mp4');
    await ctl().loadVideo(f.path);
    expect(fake.calls, ['video:${f.path}']);
    expect(read().phase, MealEditPhase.ready);
    expect(read().range!.reference, 'Yasin, 58-59');
    expect(read().cues.length, 2);
    expect(read().canPublish, isTrue);
  });

  test('20 MB üstü videoda repo çağrılmaz ve elle seçim istenir', () async {
    final f = video('big.mp4', bytes: kAyahVideoMaxBytes + 1);
    await ctl().loadVideo(f.path);
    expect(fake.calls, isEmpty);
    expect(read().tooLarge, isTrue);
    expect(read().phase, MealEditPhase.needsManual);
    expect(read().errorCode, 'file_too_large');
    expect(read().canPublish, isFalse);
  });

  test('bulunamadı / belirsiz / hata elle seçime düşer ve kod taşınır', () async {
    final f = video('a.mp4');
    fake.result = const AyahFinderResult(status: AyahFinderStatus.notFound);
    await ctl().loadVideo(f.path);
    expect((read().phase, read().errorCode), (MealEditPhase.needsManual, 'not_found'));

    final g = video('b.mp4');
    fake.result = const AyahFinderResult(status: AyahFinderStatus.ambiguous);
    await ctl().loadVideo(g.path);
    expect(read().errorCode, 'ambiguous');

    final h = video('c.mp4');
    fake.result = const AyahFinderResult(status: AyahFinderStatus.error, errorCode: 'quota');
    await ctl().loadVideo(h.path);
    expect((read().phase, read().errorCode), (MealEditPhase.needsManual, 'quota'));
  });

  test('elle aralık süreye oransal cue üretir', () async {
    final f = video('a.mp4');
    fake.result = const AyahFinderResult(status: AyahFinderStatus.notFound);
    await ctl().loadVideo(f.path);
    ctl().setDuration(90);
    await ctl().setManualRange(surah: 36, from: 58, to: 59);
    expect(read().range!.reference, 'Yasin, 58-59');
    expect(read().phase, MealEditPhase.ready);
    expect(read().errorCode, isNull);
    expect(read().cues.first.startSec, 0);
    expect(read().cues.last.endSec, 90);
    // ağırlık 10:20 → ilk cue 30 sn
    expect(read().cues.first.endSec, closeTo(30, 0.01));

    await ctl().setManualRange(surah: 36, from: 58, to: 58);
    expect(read().range!.reference, 'Yasin, 58');
  });

  test('geç gelen analiz elle seçimi ezmez', () async {
    final f = video('a.mp4');
    fake.gate = Completer();
    final loading = ctl().loadVideo(f.path);
    await ctl().setManualRange(surah: 36, from: 60, to: 61);
    fake.gate!.complete(_matched());
    await loading;
    expect(read().range!.reference, 'Yasin, 60-61');
  });

  test('provider kapanınca sahipli video silinir', () async {
    final f = video('a.mp4');
    await ctl().loadVideo(f.path);
    container.dispose();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(f.existsSync(), isFalse);
  });

  test('yayından sonra kapanınca silinmez', () async {
    final f = video('a.mp4');
    await ctl().loadVideo(f.path);
    await ctl().publish(caption: 'x');
    expect(read().published, isTrue);
    container.dispose();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(f.existsSync(), isTrue);
  });

  test('aynı yol yeniden yüklenince silinmez ve repo ikinci kez çağrılmaz', () async {
    final f = video('a.mp4');
    await ctl().loadVideo(f.path);
    await ctl().loadVideo(f.path);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(f.existsSync(), isTrue);
    expect(fake.calls.length, 1);
    expect(read().loadSeq, 1);
  });

  test('farklı yol yüklenince önceki sahipli video silinir', () async {
    final a = video('a.mp4');
    final b = video('b.mp4');
    await ctl().loadVideo(a.path);
    await ctl().loadVideo(b.path);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(a.existsSync(), isFalse);
    expect(b.existsSync(), isTrue);
    expect(read().loadSeq, 2);
  });

  test('yayın kind=video, cue, stil ve künye ile createPost çağırır', () async {
    final f = video('a.mp4');
    await ctl().loadVideo(f.path);
    ctl().setStyle(MealCueStyle.large);
    await ctl().publish(caption: 'selam');
    expect(social.uploads, [true]);
    expect(social.lastPost!['kind'], 'video');
    expect(social.lastPost!['reference'], 'Yasin, 58-59');
    expect(social.lastPost!['caption'], 'selam');
    expect(social.lastPost!['videoUrl'], isNotNull);
    expect(social.lastPost!['meal'], 'meal 58');
    expect(social.lastMealCues, read().cues);
    expect(social.lastMealCueStyle, MealCueStyle.large);
    expect(read().publishing, isFalse);
  });

  test('20 MB üstünde yayın yüklemeye ulaşmadan reddedilir', () async {
    final f = video('a.mp4');
    await ctl().loadVideo(f.path);
    final raf = f.openSync(mode: FileMode.append)..truncateSync(kAyahVideoMaxBytes + 1);
    raf.closeSync();
    await expectLater(ctl().publish(caption: ''), throwsA(isA<StateError>()));
    expect(social.uploads, isEmpty);
    expect(read().publishing, isFalse);
  });

  test('yayından sonra canPublish kapanır ve ikinci yayın reddedilir', () async {
    final f = video('a.mp4');
    await ctl().loadVideo(f.path);
    await ctl().publish(caption: 'x');
    expect(read().canPublish, isFalse);
    await expectLater(ctl().publish(caption: 'x'), throwsA(isA<StateError>()));
    expect(social.uploads.length, 1);
  });

  test('bağlantı hatası bağlantı mesajı, diğer hatalar genel mesaj verir', () async {
    final f = video('a.mp4');
    await ctl().loadVideo(f.path);
    social.createError = const SocketException('x');
    await expectLater(
      ctl().publish(caption: ''),
      throwsA(isA<StateError>().having((e) => e.message, 'message', contains('Bağlantını'))),
    );
    social.createError = const FormatException('23514');
    await expectLater(
      ctl().publish(caption: ''),
      throwsA(isA<StateError>().having((e) => e.message, 'message', isNot(contains('Bağlantını')))),
    );
    expect(read().publishing, isFalse);
    expect(read().published, isFalse);
  });

  test('süre aralıktan sonra gelirse cue üretilir', () async {
    await ctl().setManualRange(surah: 36, from: 58, to: 59);
    expect(read().cues, isEmpty);
    ctl().setDuration(90);
    expect(read().cues.length, 2);
    expect(read().cues.last.endSec, 90);
  });

  test('kapanmış provider a gelen sonuç hata fırlatmaz', () async {
    final f = video('a.mp4');
    fake.gate = Completer();
    final loading = ctl().loadVideo(f.path);
    container.dispose();
    fake.gate!.complete(_matched());
    await loading;
  });
}
