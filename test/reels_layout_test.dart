// Reels yerleşim kusurları (iPhone ekran görüntüsü, kullanıcı hata listesi):
//  2+6) sağ üstteki ses tuşu durum çubuğunun/pilin altında kalıyordu;
//  3a)  durağan (still) görsel uzun ekranda iki yandan kırpılıyordu;
//  3b)  video altyazısı ekrana sığmıyordu;
//  4)   künyedeki sure adı sunucu (ASCII) ile uygulama (Fâtiha, Tahrîm) arasında eşleşmiyordu.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kurandakimesaj/data/backend_repositories.dart';
import 'package:kurandakimesaj/data/device_services.dart';
import 'package:kurandakimesaj/data/local/app_database.dart';
import 'package:kurandakimesaj/data/repositories.dart';
import 'package:kurandakimesaj/data/seed/seed_data.dart' show kSurahSeed;
import 'package:kurandakimesaj/domain/meal_cues.dart';
import 'package:kurandakimesaj/features/community/community_screens.dart';
import 'package:kurandakimesaj/features/meal_edit/meal_subtitle_overlay.dart';
import 'package:kurandakimesaj/features/quran/quran_screens.dart';
import 'package:video_player/video_player.dart';
// Doğrudan bağımlılık değil (video_player'ın geçişli bağımlılığı); platform
// sahtesi kurmak için tek yol.
// ignore: depend_on_referenced_packages
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'support/recording_social_repository.dart';

class _FakeAudio extends Fake implements AudioService {
  @override
  Future<void> playUrl(String url, {required String title}) async {}
  @override
  Future<void> pause() async {}
  @override
  void dispose() {}
}

class _Unmuted extends ReelsMutedNotifier {
  @override
  bool build() => false;
}

/// `VideoPlayerController.initialize()` gerçek platform kanalı olmadan
/// tamamlansın: tek bir `initialized` olayı (20 sn, 720×1280).
class _FakeVideoPlatform extends VideoPlayerPlatform {
  @override
  Future<void> init() async {}
  @override
  Future<void> dispose(int playerId) async {}
  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async => 1;
  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => Stream.value(
    VideoEvent(
      eventType: VideoEventType.initialized,
      duration: const Duration(seconds: 20),
      size: const Size(720, 1280),
    ),
  );
  @override
  Future<void> setLooping(int playerId, bool looping) async {}
  @override
  Future<void> setVolume(int playerId, double volume) async {}
  @override
  Future<void> play(int playerId) async {}
  @override
  Future<void> pause(int playerId) async {}
  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}
  @override
  Future<void> seekTo(int playerId, Duration position) async {}
  @override
  Future<Duration> getPosition(int playerId) async => Duration.zero;
  @override
  Widget buildView(int playerId) => const SizedBox();
  @override
  Widget buildViewWithOptions(VideoViewOptions options) => const SizedBox();
}

/// Oturum açık + Supabase var: bulut reels yolu.
class _CloudGateway extends SupabaseGateway {
  _CloudGateway() : super(null);
  @override
  bool get isAvailable => true;
  @override
  bool get isSignedIn => true;
}

class _ReelsRepo extends RecordingSocialRepository {
  _ReelsRepo(this.reels);
  final List<FeedPost> reels;
  @override
  Future<List<FeedPost>> fetchReels() async => reels;
}

FeedPost _post({String? thumbnailUrl, String? videoUrl}) => FeedPost(
  id: 'r1',
  authorId: 'a1',
  authorName: 'Yazar',
  reference: 'Müzzemmil, 7',
  arabic: '',
  meal: 'Meal metni.',
  topic: '',
  likeCount: 0,
  likedByMe: false,
  status: 'approved',
  thumbnailUrl: thumbnailUrl,
  videoUrl: videoUrl,
);

List<Override> _cloudOverrides({String? thumbnailUrl, String? videoUrl}) => [
  supabaseGatewayProvider.overrideWithValue(_CloudGateway()),
  socialRepositoryProvider.overrideWithValue(
    _ReelsRepo([_post(thumbnailUrl: thumbnailUrl, videoUrl: videoUrl)]),
  ),
  reelAudioServiceProvider.overrideWithValue(_FakeAudio()),
  reelsMutedProvider.overrideWith(_Unmuted.new),
];

/// iPhone 14 Pro boyutu: 390×844 mantıksal. [topInset] durum çubuğu/çentik payı.
Future<void> _pumpFeed(
  WidgetTester tester, {
  required List<Override> overrides,
  double topInset = 0,
}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        builder: (context, child) {
          final mq = MediaQuery.of(context);
          final inset = EdgeInsets.only(top: topInset);
          return MediaQuery(
            data: mq.copyWith(padding: inset, viewPadding: inset),
            child: child!,
          );
        },
        home: const FeedScreen(),
      ),
    ),
  );
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Sonsuz animasyonlu ekranda `pumpAndSettle` yok (ders 18): ağacı açıkça sök.
Future<void> _teardown(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 3));
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('[2+6] ses tuşu durum çubuğunun (üst güvenli alan) altında durur', (
    tester,
  ) async {
    await _pumpFeed(tester, overrides: _cloudOverrides(), topInset: 59);

    final icon = find.byIcon(Icons.volume_up_rounded);
    expect(icon, findsOneWidget, reason: 'ses tuşu çizilmedi');
    final button = find.ancestor(of: icon, matching: find.byType(InkWell));
    expect(
      tester.getTopLeft(button.first).dy,
      greaterThanOrEqualTo(59),
      reason: 'ses tuşu durum çubuğu/pil bölgesine taşıyor',
    );
    await _teardown(tester);
  });

  testWidgets('[2] Supabase yokken (bulut ikonu görünür) Reels ekranı kaplar', (
    tester,
  ) async {
    await _pumpFeed(
      tester,
      overrides: [
        supabaseGatewayProvider.overrideWithValue(const SupabaseGateway(null)),
        feedProvider.overrideWith(
          (ref) async => [
            const TopicalAyah(
              id: 1,
              topic: 'Sabır',
              reference: 'Bakara, 153',
              arabic: '',
              meal: 'Ey iman edenler! Sabır ve namazla yardım dileyin.',
            ),
          ],
        ),
        reelAudioServiceProvider.overrideWithValue(_FakeAudio()),
        reelsMutedProvider.overrideWith(_Unmuted.new),
      ],
    );

    expect(
      find.byIcon(Icons.cloud_off_rounded),
      findsOneWidget,
      reason: 'çevrimdışı durum kurulamadı (test anlamsız)',
    );
    expect(
      tester.getSize(find.byType(PageView)),
      const Size(390, 844),
      reason: 'bulut ikonu Stack\'in tek konumsuz çocuğu olup Reels\'i büzdü',
    );
    await _teardown(tester);
  });

  testWidgets('[3a] durağan görsel kırpılmaz: BoxFit.contain', (tester) async {
    await _pumpFeed(
      tester,
      overrides: _cloudOverrides(thumbnailUrl: 'https://example.com/still.png'),
    );

    final image = find.descendant(
      of: find.byType(FeedScreen),
      matching: find.byType(Image),
    );
    expect(image, findsOneWidget, reason: 'durağan arka plan görseli çizilmedi');
    expect(tester.widget<Image>(image).fit, BoxFit.contain);
    await _teardown(tester);
  });

  testWidgets('[3b] uzun altyazı ekran yüksekliğinin %30\'unu aşmaz', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    const screenHeight = 844.0;

    // Arapça + meal stili ve uzun metin: 22 pt Arapça + 16 pt meal sayfası
    // tavansız ekran yüksekliğinin %30'unu rahatça aşar.
    final position = ValueNotifier(
      const VideoPlayerValue(
        duration: Duration(seconds: 20),
        position: Duration(seconds: 1),
      ),
    );
    addTearDown(position.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          surahAyahsProvider(1).overrideWith(
            (ref) async => [
              Ayah(
                id: 1,
                surahNumber: 1,
                numberInSurah: 1,
                arabic: List.filled(30, 'الحمد').join(' '),
                meal: List.filled(40, 'sabır').join(' '),
              ),
            ],
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            // Üretimdeki yerleşim: `_ReelOverlay` sol-alt sütunu.
            body: Stack(
              children: [
                Positioned(
                  left: 18,
                  right: 84,
                  bottom: 28,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ReelSubtitle(
                        position: position,
                        cues: const [
                          MealCue(startSec: 0, endSec: 10, surah: 1, ayah: 1),
                        ],
                        style: MealCueStyle.arabic,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('1. ayet'), findsOneWidget, reason: 'altyazı çizilmedi');
    final box = tester.getRect(
      find.descendant(
        of: find.byType(ReelSubtitle),
        matching: find.byType(FittedBox),
      ),
    );
    expect(
      box.height,
      lessThanOrEqualTo(screenHeight * 0.3 + 0.01),
      reason: 'altyazı ekranın %30\'unu aştı',
    );
    expect(box.width, lessThanOrEqualTo(390 - 18 - 84 + 0.01));
  });

  testWidgets('[ikon] duraklatma ikonu üst güvenli alanda bile ekranın tam ortasında', (
    tester,
  ) async {
    final previous = VideoPlayerPlatform.instance;
    VideoPlayerPlatform.instance = _FakeVideoPlatform();
    addTearDown(() => VideoPlayerPlatform.instance = previous);
    await _pumpFeed(
      tester,
      overrides: _cloudOverrides(videoUrl: 'https://example.com/v.mp4'),
      topInset: 59,
    );

    // Video başlatma zinciri (initialize → setLooping → setVolume) bittikten sonra
    // `_initialized` yansısın.
    await tester.pump(const Duration(milliseconds: 100));

    // Dokunuş: video oynuyorken duraklatır. Üst GestureDetector.onDoubleTap
    // tek dokunuşu 300 ms bekletir.
    await tester.tapAt(const Offset(195, 300));
    await tester.pump(const Duration(milliseconds: 400));

    final icon = find.byIcon(Icons.play_arrow_rounded);
    expect(icon, findsOneWidget, reason: 'duraklatma ikonu çizilmedi (test anlamsız)');
    // Çift-dokun kalbi `_ReelPage` içinde SafeArea DIŞINDA, tam ortada çizilir;
    // ikon da onunla aynı noktada olmalı (390×844 → 195, 422).
    expect(
      tester.getCenter(icon),
      const Offset(195, 422),
      reason: 'ikon SafeArea içinde kaldı: üst inset/2 kadar aşağı kaydı',
    );
    await _teardown(tester);
  });

  group('ReelSubtitle yerleşimi', () {
    const subtitleKey = Key('altyazi');
    const markerKey = Key('chip');

    /// Üretimdeki sol-alt sütun: altyazı + 10 pt boşluk + 44 pt'lik künye chip'i.
    Future<void> pumpColumn(
      WidgetTester tester, {
      required double positionSec,
      required Ayah ayah,
    }) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final position = ValueNotifier(
        VideoPlayerValue(
          duration: const Duration(seconds: 20),
          position: Duration(milliseconds: (positionSec * 1000).round()),
        ),
      );
      addTearDown(position.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            surahAyahsProvider(1).overrideWith((ref) async => [ayah]),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  Positioned(
                    left: 18,
                    right: 84,
                    bottom: 28,
                    child: Column(
                      key: const Key('sutun'),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ReelSubtitle(
                          key: subtitleKey,
                          position: position,
                          cues: const [
                            MealCue(startSec: 0, endSec: 10, surah: 1, ayah: 1),
                          ],
                          style: MealCueStyle.standard,
                        ),
                        const SizedBox(height: 10),
                        const SizedBox(key: markerKey, width: 100, height: 44),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
    }

    const shortAyah = Ayah(
      id: 1,
      surahNumber: 1,
      numberInSurah: 1,
      arabic: 'الحمد',
      meal: 'Hamd.',
    );

    testWidgets('aktif cue yokken (cue aralığı dışı) yükseklik 0, chip yerinde', (
      tester,
    ) async {
      // 15. sn: tek cue 0-10 sn → görünür altyazı yok.
      await pumpColumn(tester, positionSec: 15, ayah: shortAyah);

      expect(find.text('1. ayet'), findsNothing, reason: 'cue aralığı dışında altyazı çizildi');
      expect(
        tester.getSize(find.byKey(subtitleKey)).height,
        0,
        reason: 'aktif cue yokken görünmez bir blok yer ayırıyor',
      );
      // Altyazısız sütunla aynı: 10 pt boşluk + 44 pt chip.
      expect(tester.getSize(find.byKey(const Key('sutun'))).height, 54);
      expect(
        tester.getBottomLeft(find.byKey(markerKey)).dy,
        844 - 28,
        reason: 'künye chip\'i alttan 28 pt',
      );
      await _teardown(tester);
    });

    testWidgets('kısa cue sol kenara hizalı (ortalanmaz) ve içerik kadar yer kaplar', (
      tester,
    ) async {
      await pumpColumn(tester, positionSec: 1, ayah: shortAyah);

      final overlay = find.byType(MealSubtitleOverlay);
      expect(overlay, findsOneWidget, reason: 'altyazı çizilmedi');
      expect(
        tester.getTopLeft(overlay).dx,
        18,
        reason: 'altyazı sütunun sol kenarına değil ortaya hizalanıyor',
      );
      expect(tester.getSize(find.byKey(subtitleKey)).height, lessThan(100));
      await _teardown(tester);
    });
  });

  group('[4] sure adı anahtarı (künye → sure çözümü)', () {
    // Sunucu künyeyi `supabase/functions/_shared/quran/matcher.ts` SURAH_NAMES
    // ile yazar (ASCII); uygulama tohumu şapkalıdır. Dosya YALNIZ okunur.
    List<String> serverNames() {
      final src = File(
        'supabase/functions/_shared/quran/matcher.ts',
      ).readAsStringSync();
      final block = RegExp(
        r'const SURAH_NAMES = \[(.*?)\];',
        dotAll: true,
      ).firstMatch(src)!.group(1)!;
      return [for (final m in RegExp(r'"([^"]+)"').allMatches(block)) m.group(1)!];
    }

    test('sunucunun 114 adının her biri aynı sıradaki uygulama adına çözülür', () {
      final server = serverNames();
      expect(server, hasLength(114));
      expect(kSurahSeed, hasLength(114));
      final mismatches = [
        for (var i = 0; i < 114; i++)
          if (surahNameKey(server[i]) != surahNameKey(kSurahSeed[i].$2))
            '${i + 1}: sunucu "${server[i]}" ≠ uygulama "${kSurahSeed[i].$2}"',
      ];
      expect(mismatches, isEmpty);
    });

    test('114 uygulama anahtarı benzersizdir (yanlış sureye gidilmez)', () {
      expect({for (final s in kSurahSeed) surahNameKey(s.$2)}, hasLength(114));
    });
  });
}
