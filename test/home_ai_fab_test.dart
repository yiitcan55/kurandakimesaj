// Regresyon kilidi: Ana Sayfa'nın KENDİ Scaffold'undaki "Ayet Bul" FAB'ı.
//
// Üç şeyi kilitler:
//  1. `Key('home_ai_fab')` bulunur ve dokununca `/ayah-finder`'a gider.
//  2. `heroTag` AÇIKÇA verilmiş. `FeedScreen`in FAB'ı (`feed_create_fab`,
//     bkz. `community_screens.dart`) tag'siz ve router
//     `StatefulShellRoute.indexedStack` kullandığı için her iki dal aynı anda
//     ağaçta canlı kalabiliyor — iki tag'siz FAB "multiple heroes that share
//     the same tag" assertion'ıyla uygulamayı düşürür. Bu test o regresyonun
//     kapısıdır.
//  3. `Scaffold.floatingActionButtonLocation` `startFloat` (kullanıcı
//     "sol-alt" istedi).
//
// Gerçek uygulama router'ı yerine 2 rotalı minimal bir `GoRouter` kuruyoruz —
// testin konusu yönlendirme, ekranların gerçek içeriği değil (bkz.
// `test/share_cold_start_test.dart`'taki aynı kalıp).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kurandakimesaj/data/local/app_database.dart';
import 'package:kurandakimesaj/data/repositories.dart';
import 'package:kurandakimesaj/data/widget_sync_service.dart';
import 'package:kurandakimesaj/domain/models.dart';
import 'package:kurandakimesaj/features/daily_ayah/daily_ayah_screen.dart';
import 'package:kurandakimesaj/features/dhikr/dhikr_screens.dart';
import 'package:kurandakimesaj/features/home/home_screens.dart';
import 'package:kurandakimesaj/features/prayer/prayer_screen.dart';
import 'package:kurandakimesaj/features/progress/progress_screens.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// `home_widget` platform kanalına dokunmaz. Gerçek [WidgetSyncService]
/// test ortamında handler'sız `MethodChannel` çağırır ve yakalanmamış bir
/// `MissingPluginException` fırlatır (çağrı `HomeScreen._syncHomeWidgets`
/// içinde `await` edilmeden ateşlenir) — testin konusuyla ilgisiz bir async
/// hata testi kırardı.
class _NoopWidgetSyncService extends WidgetSyncService {
  @override
  Future<void> syncAyah(Ayah ayah, Surah? surah) async {}
  @override
  Future<void> syncPrayer(PrayerDay day) async {}
}

/// Gerçek [PrayerController] konum izni + adhan hesabı için gerçek servislere
/// bağımlı; testin konusuyla ilgisiz o zinciri atlamak için sabit bir gün
/// döner.
class _FakePrayerController extends PrayerController {
  @override
  Future<PrayerDay> build() async =>
      PrayerDay(date: DateTime.now(), slots: const [], locationLabel: 'Test');
}

GoRouter _routerKur() => GoRouter(
  initialLocation: '/home',
  routes: [
    GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
    GoRoute(
      path: '/ayah-finder',
      builder: (_, _) => const Placeholder(key: Key('stub_ayah_finder')),
    ),
  ],
);

/// `HomeScreen`i gerçek widget ağacıyla kurar; yalnızca ekranın dokunduğu
/// async provider'ları (drift/ağ/konum zincirlerini atlamak için) sahteyle
/// değiştirir — koda bakılarak çözüldü (`home_screens.dart` + `repositories.dart`).
Future<void> _anaSayfayiKur(WidgetTester tester) async {
  // Gerçek telefon boyu (bkz. görev notu) — dar varsayılan test yüzeyinde
  // `_HomeStats`/Kıble-Cami satırları yatayda taşardı.
  tester.view.physicalSize = const Size(390, 840);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: [
      dailyAyahProvider.overrideWith((ref) async => null),
      prayerControllerProvider.overrideWith(_FakePrayerController.new),
      dhikrDayTotalProvider.overrideWith((ref, dateIso) => Stream.value(0)),
      juzListProvider.overrideWith((ref) => Stream.value(<JuzProgressData>[])),
      widgetSyncServiceProvider.overrideWithValue(_NoopWidgetSyncService()),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: _routerKur()),
    ),
  );
  await tester.pump();
}

/// Testin SONUNDA çağrılır (her testte, kaydırma/gecikme gerekmese bile).
///
/// BİLİNÇLİ OLARAK `pumpAndSettle()` KULLANILMIYOR: `ShimmerSkeleton`
/// (yükleme sırasında `_DailyAyahHero`/`_ReadingGoalCard`'ta)
/// `.animate(onPlay: (c) => c.repeat())` ile SONSUZ döner; pumpAndSettle
/// "artık zamanlanmış kare yok" bekler ve asla dönmez.
///
/// Yine de ağacı sabit süreli `pump`larla söküyoruz, çünkü:
///  - `flutter_animate`'in `initState`'te kurduğu sıfır-süreli `Timer`lar
///    fake-async saatini SÜRELİ bir `pump` ilerletmeden hiç ateşlenmez ve
///    testin sonunda "A Timer is still pending" ile düşer. Async veri
///    (`dailyAyahProvider` vb.) çözüldükçe yeni `.animate()` widget'ları
///    monte olup KADEMELİ olarak yeni sıfır-süreli `Timer`lar kurabiliyor;
///    3 saniyelik pump bu kademeleri kapatmaya yeter (bkz.
///    `test/text_scale_overflow_test.dart`'ın aynı ekran için kullandığı
///    ölçek).
///  - `_PrayerStrip` saniyelik bir `Timer.periodic` çalıştırıyor; yalnız
///    `dispose()` onu iptal eder — bu yüzden ağacı gerçekten BOŞALTMAK
///    gerekiyor, yalnızca pump'lamak yetmez.
Future<void> _soek(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

void main() {
  setUp(() async {
    // google_fonts test ortamında fontu çözemeyip yakalanmamış async hata
    // fırlatabiliyor (bkz. tasks/lessons.md ders 11).
    GoogleFonts.config.allowRuntimeFetching = false;
    // `_ReadingGoalCardState._load()` `ReadingGoalService` üzerinden gerçek
    // `SharedPreferences`i okuyor.
    SharedPreferences.setMockInitialValues({});
    // `HomeScreen.build` `DateFormat('d MMMM yyyy', 'tr')` çağırıyor; 'tr'
    // locale verisi önceden yüklenmezse `LocaleDataException` fırlatır
    // (bkz. `app.dart`'taki bootstrap çağrısı, testte tekrar edilmeli).
    await initializeDateFormatting('tr');
  });

  testWidgets(
    'Ana Sayfa\'da "Ayet Bul" FAB\'ı bulunur ve dokununca /ayah-finder açılır',
    (tester) async {
      await _anaSayfayiKur(tester);

      final fabFinder = find.byKey(const Key('home_ai_fab'));
      expect(fabFinder, findsOneWidget);
      expect(find.byKey(const Key('stub_ayah_finder')), findsNothing);

      await tester.tap(fabFinder);
      await tester.pump();
      // go_router push geçiş animasyonunun süresi kadar ilerlet (pumpAndSettle
      // yerine sabit süre — yukarıdaki gerekçe).
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byKey(const Key('stub_ayah_finder')), findsOneWidget);
      await _soek(tester);
    },
  );

  testWidgets(
    'Ana Sayfa FAB\'ının heroTag\'i AÇIKÇA verilmiş (Reels FAB\'ıyla çakışma regresyonu)',
    (tester) async {
      await _anaSayfayiKur(tester);

      final fab = tester.widget<FloatingActionButton>(
        find.byKey(const Key('home_ai_fab')),
      );
      // Gerekçe: `FeedScreen`in FAB'ı (`community_screens.dart`,
      // `key: feed_create_fab`) heroTag'siz ve router
      // `StatefulShellRoute.indexedStack` kullandığı için iki dal da aynı anda
      // ağaçta canlı kalabiliyor → iki tag'siz FAB "multiple heroes that
      // share the same tag" assertion'ıyla uygulamayı düşürür.
      expect(fab.heroTag, isNotNull);
      await _soek(tester);
    },
  );

  testWidgets(
    'Ana Sayfa FAB\'ı sol-altta durur (floatingActionButtonLocation: startFloat)',
    (tester) async {
      await _anaSayfayiKur(tester);

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(
        scaffold.floatingActionButtonLocation,
        FloatingActionButtonLocation.startFloat,
      );
      await _soek(tester);
    },
  );
}
