// REGRESYON KİLİDİ (1.0.1 build 4): büyük sistem yazı ölçeğinde taşma.
//
// Kök neden: projede HİÇBİR yerde `textScaler` / `MediaQuery.withClampedTextScaling`
// yoktu. Android "Yazı tipi boyutu" 1.0→2.0×, iOS Dynamic Type AX5 ≈3.1× çıkıyor
// ve her sabit-piksel kabı zorluyor.
//
// İki katmanlı düzeltme yapıldı:
//   1. `app.dart` builder'ında ölçek 1.0–1.3 arasına kelepçelendi.
//   2. YAPISAL düzeltmeler: zikirmatik / tesbihat / kıble ekranları
//      `Expanded > Column(center)` idi, `SingleChildScrollView` yoktu; sabit
//      280/200/300px daireler + metin 640dp'de zaten sınırdaydı.
//
// Bu test 2. katmanı kilitler: `app.dart`'ı BYPASS eder ve ölçeği doğrudan
// 1.3'e sabitler. Kelepçe tek başına yeterli olsaydı bu test gereksiz olurdu —
// değil, 1.3'te de taşan yerler vardı. `CenteredScrollBody` geri alınırsa düşer.
//
// Mevcut boyut testleri (`bottom_bar_height_test`, `esma_overflow_test`) hiçbiri
// textScale > 1.0 ile çalışmıyor; bu boşluğu kapatır.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kurandakimesaj/features/dhikr/dhikr_screens.dart';
import 'package:kurandakimesaj/features/home/home_screens.dart';
import 'package:kurandakimesaj/features/qibla/qibla_screen.dart';
import 'package:kurandakimesaj/ui/core/widgets.dart';

/// Dar telefon + en büyük kelepçeli yazı ölçeği (1.3×).
/// `app.dart`'ın kelepçesi devrede DEĞİL — yapısal düzeltmeyi ölçüyoruz.
Widget _harness(Widget screen, {Size size = const Size(360, 640)}) =>
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: const TextScaler.linear(1.3),
        ),
        child: screen,
      ),
    );

/// Gerçek düzen kısıtı MediaQuery'den değil VIEW'dan gelir — ikisini birlikte
/// ayarlamazsak ekran gerçekte 800px yüksekliğinde kalır ve hiçbir şey taşmaz.
void _useViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {

  testWidgets('Zikirmatik 360×640 @1.3× taşmaz', (tester) async {
    _useViewport(tester, const Size(360, 640));
    await tester.pumpWidget(
      ProviderScope(child: _harness(const DhikrScreen())),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // Yapısal düzeltmenin GERÇEKTEN orada olduğunu doğrula: yalnız
    // "taşma yok" demek, ekran boş kalsa da geçerdi.
    expect(find.byType(CenteredScrollBody), findsOneWidget);
  });

  testWidgets('Tesbihat 360×640 @1.3× taşmaz', (tester) async {
    _useViewport(tester, const Size(360, 640));
    await tester.pumpWidget(
      ProviderScope(child: _harness(const TasbihatScreen())),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(CenteredScrollBody), findsOneWidget);
  });

  // Kıble 360×640'ta kaydırma OLMADAN da sığıyor — o boyutta test boş kalırdı.
  // 360×560 (bölünmüş ekran / küçük telefon) sabit 300px kadranın gerçekten
  // taştığı ilk boyut; düzeltme geri alınınca burada düşer.
  testWidgets('Kıble 360×560 @1.3× taşmaz (sensör var)', (tester) async {
    _useViewport(tester, const Size(360, 560));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          qiblaBearingProvider.overrideWith((ref) async => 151.4),
          headingProvider.overrideWith((ref) => Stream.value(148.0)),
        ],
        child: _harness(const QiblaScreen(), size: const Size(360, 560)),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(CenteredScrollBody), findsOneWidget);
  });

  testWidgets('Kıble 360×560 @1.3× taşmaz (sensör YOK — uyarı metni eklenir)',
      (tester) async {
    // Sensörsüz dal en uzun içerik: kadran + 2-3 satırlık uyarı paragrafı.
    _useViewport(tester, const Size(360, 560));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          qiblaBearingProvider.overrideWith((ref) async => 151.4),
          headingProvider.overrideWith((ref) => const Stream<double>.empty()),
        ],
        child: _harness(const QiblaScreen(), size: const Size(360, 560)),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('pusula sensörü algılanamadı'), findsOneWidget);
  });

  // Ana sayfada 8 hücreli bir `GridView.count(mainAxisExtent: 120)` vardı:
  // içerik 1.0×'te 116px'e sığıyordu (4px pay), 1.15×'te 360dp ekranda 8
  // başlığın 7'si iki satıra sarıyor ve 7 hücre AYNI ANDA taşıyordu. Izgara
  // kaldırıldı; yerine sabit yüksekliği OLMAYAN, içeriğe uyan metin öncelikli
  // satırlar geldi. Aynı taramada `_ReadingGoalCard`'ın "streak / sayfa"
  // satırı da yakalandı (Text'ler esnek değildi, 288px kartı 135px aşıyordu).
  //
  // `pumpAndSettle` KULLANILAMAZ: yükleme iskeletleri (`ShimmerSkeleton`)
  // sonsuz tekrarlı animasyondur, settle asla dönmez.
  testWidgets('Ana sayfa 360×640 @1.3× taşmaz (sabit hücre yüksekliği yok)',
      (tester) async {
    await initializeDateFormatting('tr');
    SharedPreferences.setMockInitialValues({});
    _useViewport(tester, const Size(360, 640));
    await tester.pumpWidget(
      ProviderScope(child: _harness(const HomeScreen())),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull, reason: 'ilk kare');

    // Sayfanın tamamı en az bir kez layout edilsin — taşma yalnızca görünür
    // olan alt ağaçta raporlanır.
    final list = find.byType(Scrollable).first;
    for (var i = 0; i < 10; i++) {
      await tester.drag(list, const Offset(0, -260));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull, reason: 'kaydırma adımı $i');
    }
    // "Taşma yok" tek başına ızgara geri gelirse de geçebilirdi (yalnız 1.0×
    // ölçekte). Deseni adıyla kilitle.
    expect(find.byType(GridView), findsNothing);
  });

  testWidgets('GoldChip şeridi büyük yazı ölçeğinde sabit yüksekliğe sıkışmaz',
      (tester) async {
    _useViewport(tester, const Size(360, 640));
    // Şeritler `SizedBox(height: 48)` ile dıştan sabitlenmişti; chip doğal
    // yüksekliği 40.3px ve ölçek ~1.4'te 48'i aşıyordu. Artık dokunma hedefini
    // (≥44px) chip'in KENDİSİ garanti ediyor, şerit içeriğe göre yükseliyor.
    await tester.pumpWidget(
      _harness(
        Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final l in ['Sübhânallâh', 'Elhamdülillâh', 'Allâhü Ekber'])
                    GoldChip(label: l, onTap: () {}),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    for (final size in tester.widgetList<GoldChip>(find.byType(GoldChip)).map(
        (w) => tester.getSize(find.byWidget(w)))) {
      expect(size.height, greaterThanOrEqualTo(44.0),
          reason: 'dokunma hedefi ≥44px olmalı (DESIGN.md)');
    }
  });
}
