// Reels'te sol-alttaki altın künye chip'ine ("Müzzemmil, 7") dokununca sure
// okuyucusu açılmalı. Kullanıcı raporu (iPhone, 1.0.x): "sureye gitmiyor".
//
// Bu dosya gerçek `FeedScreen` -> `_ReelsPager` -> `_ReelPage` -> `_ReelOverlay`
// ağacını pompalar (üst GestureDetector: onTap + onDoubleTap, dikey PageView).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kurandakimesaj/data/backend_repositories.dart';
import 'package:kurandakimesaj/data/device_services.dart';
import 'package:kurandakimesaj/data/local/app_database.dart';
import 'package:kurandakimesaj/data/repositories.dart';
import 'package:kurandakimesaj/data/tafsir.dart';
import 'package:kurandakimesaj/features/community/community_screens.dart';
import 'package:kurandakimesaj/features/home/home_screens.dart' show HomeShell;
import 'package:kurandakimesaj/features/quran/quran_screens.dart';

import 'support/recording_social_repository.dart';

class _FakeAudio extends Fake implements AudioService {
  @override
  Future<void> playUrl(String url, {required String title}) async {}
  @override
  Future<void> pause() async {}
  @override
  void dispose() {}
}

class _IdlePlayer extends QuranPlayerController {
  @override
  QuranPlayback build() => const QuranPlayback();
  @override
  Future<void> stop() async {}
}

class _Unmuted extends ReelsMutedNotifier {
  @override
  bool build() => false;
}

class _FakeGateway extends SupabaseGateway {
  _FakeGateway() : super(null);
  // `isAvailable` false kalırsa FeedScreen'in "çevrimdışı" ikonu Stack'in tek
  // non-positioned çocuğu olur ve tüm Reels 38x34'e büzülür (test artefaktı).
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

const _muzzemmil = Surah(
  number: 73,
  nameTr: 'Müzzemmil',
  nameArabic: 'المزمل',
  meaning: 'Örtünen',
  ayahCount: 20,
  revelation: 'Mekke',
  juzStart: 29,
);

// 20 ayet: hedef (7) ilk ekranın dışında kalsın — gerçek sure da böyle.
final _ayahs = <Ayah>[
  for (var n = 1; n <= 20; n++)
    Ayah(
      id: n,
      surahNumber: 73,
      numberInSurah: n,
      arabic: 'يَا أَيُّهَا الْمُزَّمِّلُ',
      meal: 'Ey örtüsüne bürünen! (ayet $n)',
    ),
];

// Gerçek varlık (1,9 MB + Isolate) FakeAsync'te yüklenmez; okuyucudaki her
// ayetin altında katlı "Tefsir" başlığı gerçek uygulamadaki gibi yer kaplasın.
final _tafsir = Tafsir(
  byAyah: {
    for (final s in [66, 73])
      for (var n = 1; n <= 20; n++) '$s:$n': 'Muhtasar tefsir ($s:$n)',
  },
  title: "Muhtasar Kur'an-ı Kerim Tefsiri Türkçe Tercümesi",
  source: 'QuranEnc.com',
  fetched: '2026-11-09',
);

// Gerçek tohum adı (seed_data.dart:183). Sunucu ise "Tahrim" yazıyor.
const _tahrim = Surah(
  number: 66,
  nameTr: 'Tahrîm',
  nameArabic: 'التحريم',
  meaning: 'Yasaklama',
  ayahCount: 12,
  revelation: 'Medeni',
  juzStart: 28,
);

FeedPost _post(String reference) => FeedPost(
  id: 'r1',
  authorId: 'a1',
  authorName: 'Yazar',
  reference: reference,
  arabic: '',
  meal: 'Meal metni.',
  topic: '',
  likeCount: 0,
  likedByMe: false,
  status: 'approved',
);

/// Gerçek router'ın biçimi: `StatefulShellRoute.indexedStack` + `HomeShell`,
/// Reels `/feed` dalında (router.dart:110-121). `_openReference`'ın
/// `Navigator.of(context)`'i bu durumda kök değil DAL navigator'ıdır (H3).
Widget _shellHost() {
  final router = GoRouter(
    initialLocation: '/feed',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => HomeShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: '/home', builder: (_, _) => const SizedBox())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/feed', builder: (_, _) => const FeedScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/messages', builder: (_, _) => const SizedBox())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/profile', builder: (_, _) => const SizedBox())],
          ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);
  return MaterialApp.router(routerConfig: router);
}

Future<void> _pumpReels(
  WidgetTester tester,
  String reference, {
  bool inShell = false,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        supabaseGatewayProvider.overrideWithValue(_FakeGateway()),
        socialRepositoryProvider.overrideWithValue(
          _ReelsRepo([_post(reference)]),
        ),
        reelAudioServiceProvider.overrideWithValue(_FakeAudio()),
        reelsMutedProvider.overrideWith(_Unmuted.new),
        surahsProvider.overrideWith((ref) async => [_tahrim, _muzzemmil]),
        surahAyahsProvider(66).overrideWith((ref) async => _ayahs),
        surahAyahsProvider(73).overrideWith((ref) async => _ayahs),
        tafsirProvider.overrideWith((ref) async => _tafsir),
        quranPlayerProvider.overrideWith(_IdlePlayer.new),
        ttsServiceProvider.overrideWithValue(TtsService()),
      ],
      child: inShell ? _shellHost() : const MaterialApp(home: FeedScreen()),
    ),
  );
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _teardown(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 3));
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('künye chip\'ine dokununca SurahReaderScreen açılır', (
    tester,
  ) async {
    await _pumpReels(tester, 'Müzzemmil, 7');
    final chip = find.byKey(const Key('reel_reference_chip'));
    expect(chip, findsOneWidget, reason: 'chip çizilmedi');

    await tester.tap(chip);
    // Üst GestureDetector.onDoubleTap, tek dokunuşu 300 ms bekletir.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 600));

    expect(
      find.byType(SurahReaderScreen),
      findsOneWidget,
      reason: 'dokunma sonrası okuyucu açılmadı',
    );
    await _teardown(tester);
  });

  testWidgets('StatefulShellRoute dalında da (gerçek router biçimi) açılır', (
    tester,
  ) async {
    await _pumpReels(tester, 'Müzzemmil, 7', inShell: true);
    final chip = find.byKey(const Key('reel_reference_chip'));
    expect(chip, findsOneWidget, reason: 'chip çizilmedi');

    await tester.tap(chip);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 600));

    expect(
      find.byType(SurahReaderScreen),
      findsOneWidget,
      reason: 'shell dalında okuyucu açılmadı',
    );
    await _teardown(tester);
  });

  // ── Aşağıdaki iki test, düzeltilmiş iki ayrı kusurun regresyon kilididir
  // (BUG-A: sunucu künyesi eşleşmesi, BUG-B: hedef ayete kaydırma). Düzeltme
  // geri alınırsa kırmızıya döner.

  testWidgets('[BUG-A] sunucu adıyla yazılmış künye ("Tahrim, 8" — gerçek üretim '
      'verisi) okuyucuyu açar', (tester) async {
    // feed_posts.reference "Tahrim, 8" (sunucu SURAH_NAMES, matcher.ts), uygulama
    // tohumu "Tahrîm": `_fold` yalnız İ/I + küçük harf — â/î/û'yu katlamaz.
    await _pumpReels(tester, 'Tahrim, 8');
    await tester.tap(find.byKey(const Key('reel_reference_chip')));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 600));

    expect(
      find.text('Bu sûre okuyucuda bulunamadı.'),
      findsNothing,
      reason: 'künye ayrıştı ama sure adı eşleşmedi → SnackBar, gezinme yok',
    );
    expect(find.byType(SurahReaderScreen), findsOneWidget);
    await _teardown(tester);
  });

  testWidgets('[BUG-B] okuyucu hedef ayete (7) kaydırır', (tester) async {
    await _pumpReels(tester, 'Müzzemmil, 7');
    await tester.tap(find.byKey(const Key('reel_reference_chip')));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(SurahReaderScreen), findsOneWidget);
    // Kaydırma (450 ms) + vurgu için bol süre.
    await tester.pump(const Duration(seconds: 2));

    final scrollable = tester.state<ScrollableState>(
      find
          .descendant(
            of: find.byType(SurahReaderScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(
      scrollable.position.pixels,
      greaterThan(0),
      reason: '`ListView(children:)` tembel: hedef ayetin `_targetKey.currentContext`i '
          'null → `_scrollToInitial` sessizce çıkıyor, bir daha denenmiyor',
    );
    await _teardown(tester);
  });
}
