import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kurandakimesaj/data/backend_repositories.dart';
import 'package:kurandakimesaj/features/studio/studio_screens.dart';

import 'support/recording_social_repository.dart';

/// Stüdyo render regresyonları — GERÇEK telefon yüzeyinde.
///
/// Kilitlenen kusur: önizleme `ListView`in ilk çocuğuydu, "Reels'e Yayınla"
/// ise çok altındaki bir çocuk. 9:16 önizleme ekran yüksekliğinin büyük
/// kısmını kapladığı için butona ulaşmak ZORUNLU kaydırma gerektiriyordu;
/// kaydırınca `RenderSliverMultiBoxAdaptor` önizlemeyi layout ediyor ama
/// BOYAMIYOR → `RepaintBoundary` `needsPaint` kalıyor ve `toImage()`
/// `'!debugNeedsPaint': is not true` ile patlıyordu. `_publish`/`_export`
/// hatayı yuttuğu için kullanıcı yalnız "Yayınlama hatası" görüyordu:
/// gönderi HİÇ yayınlanamıyordu.
///
/// Mevcut `studio_video_test.dart` bunu göremiyor çünkü 400×2600 yüzey
/// kullanıyor — o yükseklikte hiçbir şey kaydırılmıyor, önizleme daima
/// boyalı. **Bu dosyanın tek ayırt edici noktası gerçekçi yüzey + kaydırma.**
///
/// İkinci değişmez: çıktı çözünürlüğü CİHAZDAN BAĞIMSIZ. Tuval eskiden ekran
/// genişliğine göre büyüyordu (`pixelRatio: 3.0` ile aynı 22pt farklı
/// telefonda farklı boyutta PNG üretiyordu); artık sabit 360×640.

/// `isSignedInProvider` reaktivitesi için (moderation_queue_test kalıbı).
class _FakeGateway extends SupabaseGateway {
  _FakeGateway() : super(null);
  @override
  bool get isSignedIn => true;
}

Future<void> _pumpStudio(
  WidgetTester tester,
  RecordingSocialRepository repo, {
  required Size surface,
}) async {
  await tester.binding.setSurfaceSize(surface);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        socialRepositoryProvider.overrideWithValue(repo),
        supabaseGatewayProvider.overrideWithValue(_FakeGateway()),
      ],
      child: const MaterialApp(
        home: StudioScreen(
          initialArabic: 'وَبَشِّرِ الصَّابِرِينَ',
          initialText: 'Sabredenleri müjdele',
          initialReference: 'Bakara, 155',
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Formu butonlar görünene kadar kaydır — kullanıcının gerçek telefonda
/// yapmak ZORUNDA olduğu hareket. Sabit `drag` yerine `scrollUntilVisible`:
/// tembel listede hedef henüz mount edilmemiş olabilir.
Future<void> _scrollTo(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(
    target,
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

/// Yayınlama gerçek async iş yapar (`endOfFrame`, `toByteData` PNG
/// kodlaması) — `testWidgets`in sahte zamanı bunları ilerletmez.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    await tester.pump();
  }
}

/// google_fonts fontu ne asset'ten ne ağdan çözebiliyor ve hatayı FIRE-AND-
/// FORGET bir future'da fırlatıyor; `runAsync` gerçek zamanı açtığı an bu
/// hata o sırada koşan teste yazılıyor (bkz. tasks/lessons.md, ders 11).
/// Testin konusu font değil, render'ın kendisi. Font hatasını kendi zone'unda
/// yutuyoruz — `expect` hataları `completeError` ile AYNEN yükseliyor, yani
/// yeşil bir test hâlâ gerçek kanıt.
Future<void> _fontSafe(Future<void> Function() body) {
  final done = Completer<void>();
  runZonedGuarded(
    () async {
      try {
        await body();
        if (!done.isCompleted) done.complete();
      } catch (e, s) {
        if (!done.isCompleted) done.completeError(e, s);
      }
    },
    (e, s) {
      if (!e.toString().contains('GoogleFonts') && !done.isCompleted) {
        done.completeError(e, s);
      }
    },
  );
  return done.future;
}

/// PNG IHDR genişliği: 8 baytlık imza + 4 uzunluk + 4 tip ('IHDR') sonrası
/// 16..19 arası big-endian genişlik.
int _pngWidth(Uint8List b) =>
    (b[16] << 24) | (b[17] << 16) | (b[18] << 8) | b[19];

Future<void> _publishStill(
  WidgetTester tester,
  RecordingSocialRepository repo, {
  required Size surface,
}) async {
  await _pumpStudio(tester, repo, surface: surface);
  await _scrollTo(tester, find.byKey(const Key('studio_rights_checkbox')));
  await tester.tap(find.byKey(const Key('studio_rights_checkbox')));
  await tester.pumpAndSettle();
  await _scrollTo(tester, find.text("Reels'e Yayınla"));
  await tester.tap(find.text("Reels'e Yayınla"));
  await _settle(tester);
}

void main() {
  // `runAsync` gerçek zamanı açtığı için google_fonts fontu AĞDAN çekmeye
  // kalkıyor ve YAKALANMAMIŞ async hata fırlatıyor (bkz. tasks/lessons.md,
  // ders 11). Ölçtüğümüz değişmezle ilgisi yok — ağ bacağını kapatıyoruz.
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets(
    'Gerçek telefon yüzeyinde (390×760) forma kaydırıp yayınlayınca önizleme '
    'PNG\'si GERÇEKTEN yüklenir — ekran dışına çıkan RepaintBoundary çökmez',
    (tester) async => _fontSafe(() async {
      final repo = RecordingSocialRepository();
      await _publishStill(tester, repo, surface: const Size(390, 760));

      expect(tester.takeException(), isNull);

      // Asıl kapı: `_publish` hatayı yuttuğu için çökme testte istisna olarak
      // görünmez — kanıt, yüklemenin GERÇEKLEŞMİŞ olmasıdır. Kusurlu kodda
      // `_renderPng` patlar/null döner ve `uploads` BOŞ kalır.
      expect(repo.uploads, [false]);
      expect(find.textContaining('Yayınlama hatası'), findsNothing);
      expect(find.textContaining('Önizleme hazırlanamadı'), findsNothing);

      final bytes = repo.lastBytes;
      expect(bytes, isNotNull, reason: 'PNG baytları yüklenmedi');
      expect(
        bytes!.sublist(0, 4),
        [0x89, 0x50, 0x4E, 0x47],
        reason: 'Yüklenen şey PNG değil',
      );
      // 360 px tuval × pixelRatio 3.0 → Story çıktısı tam 1080 px geniş.
      expect(_pngWidth(bytes), 1080);
    }),
  );

  // Kullanıcının bildirdiği SIRA budur ve mekanizması ötekinden farklıdır:
  // yalnız kaydırmak boundary'yi kirletmez — katman KOPARILIR ama bayat hâliyle
  // durur, `toImage()` çalışır (release'de sessizce ESKİ kareyi yayınlar).
  // Çökme, önizleme boyanmaz haldeyken KİRLENDİĞİNDE oluşur: `flushPaint`
  // kopmuş katmanlı düğümü `_skippedPaintingOnLayer` ile atlar ve `_needsPaint`
  // KALICI olarak `true` kalır — kaç kare geçerse geçsin temizlenmez.
  // (Bu yüzden `endOfFrame` tek başına hiçbir şeyi düzeltmezdi.)
  testWidgets(
    'Kullanıcının gerçek sırası: aşağı kaydır → metin yaz (önizleme ekran '
    'dışındayken kirlenir) → yayınla — gönderi yine de yayınlanır',
    (tester) async => _fontSafe(() async {
      final repo = RecordingSocialRepository();
      await _pumpStudio(tester, repo, surface: const Size(390, 760));

      // Metin alanına ulaşmak önizlemeyi zaten boyama alanının dışına atar.
      final field = find.byType(TextField).first;
      await _scrollTo(tester, field);
      await tester.enterText(field, 'Sabredenlerle beraberdir');
      await tester.pumpAndSettle();

      await _scrollTo(tester, find.byKey(const Key('studio_rights_checkbox')));
      await tester.tap(find.byKey(const Key('studio_rights_checkbox')));
      await tester.pumpAndSettle();
      await _scrollTo(tester, find.text("Reels'e Yayınla"));
      await tester.tap(find.text("Reels'e Yayınla"));
      await _settle(tester);

      expect(repo.uploads, [false]);
      expect(repo.lastBytes, isNotNull, reason: 'Yayın hiç gerçekleşmedi');
      expect(_pngWidth(repo.lastBytes!), 1080);
    }),
  );

  testWidgets(
    'Çıktı çözünürlüğü CİHAZDAN BAĞIMSIZ: daha geniş yüzeyde (430×930) de '
    'PNG genişliği tam 1080 kalır',
    (tester) async => _fontSafe(() async {
      final repo = RecordingSocialRepository();
      await _publishStill(tester, repo, surface: const Size(430, 930));

      expect(repo.uploads, [false]);
      // Eskiden tuval `ekran genişliği - 40` idi → 430'luk cihazda 1170,
      // 390'lık cihazda 1050 px üretiyordu. Sabit tuval bunu kilitler.
      expect(_pngWidth(repo.lastBytes!), 1080);
    }),
  );

  // `_export` ("PNG Kaydet") ile `_publish` AYNI `_renderPng()`'den besleniyor,
  // ama `_export` hatayı yutup sessizce dönüyor: davranışsal bir assert
  // bulunamıyor (paylaşım kanalı testte yok, çıktı dosyası gözlenebilir değil).
  // Bunun yerine iki yolun da dayandığı YAPISAL değişmezi kilitliyoruz:
  // önizleme, kaydırılan listenin İÇİNDE olmamalı. Listeye geri taşınırsa bu
  // test düşer — `_export` yolunu koruyan gerçek kapı budur.
  testWidgets(
    'Önizleme tuvali kaydırılan listenin DIŞINDA durur — "PNG Kaydet" ve '
    'yayınlama aynı kökten beslendiği için ikisini birden korur',
    (tester) async => _fontSafe(() async {
      final repo = RecordingSocialRepository();
      await _pumpStudio(tester, repo, surface: const Size(390, 760));
      await _scrollTo(tester, find.byKey(const Key('studio_export_png')));

      const canvas = Key('studio_preview_canvas');
      expect(
        find.byKey(canvas),
        findsOneWidget,
        reason: 'Önizleme tuvali ağaçtan kayboldu',
      );
      expect(
        find.descendant(
          of: find.byType(Scrollable).first,
          matching: find.byKey(canvas),
        ),
        findsNothing,
        reason:
            'Önizleme tembel ListView içine geri taşınmış: kaydırılınca '
            'layout edilir ama BOYANMAZ, toImage() patlar',
      );
    }),
  );
}
