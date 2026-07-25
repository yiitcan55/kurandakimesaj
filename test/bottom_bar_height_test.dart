// REGRESYON KİLİDİ (1.0.1 build 3): alt menü çubuğu ekranı kaplamamalı.
//
// Olan: `SizedBox(height: 64)` → `ConstrainedBox(minHeight: 64)` değişimi
// (etiket iki satıra kayarsa bar büyüsün diye) yüksekliği serbest bıraktı.
// Serbest kalınca `_fab()` içindeki `Center`, heightFactor verilmediği için
// gelen maxHeight'a kadar büyüdü — Scaffold'un bottomNavigationBar yuvasında
// maxHeight EKRAN YÜKSEKLİĞİ. Bar tüm ekranı kapladı, ikonlar dikeyde
// ortalandı ve gövdeye sıfır yer kaldı: ana ekran bomboş göründü.
//
// `flutter analyze` ve mevcut testlerin hiçbiri bunu yakalamadı; sadece
// cihazda görülebiliyordu. Bu test o boşluğu kapatır.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kurandakimesaj/features/home/home_screens.dart';

void main() {
  testWidgets('alt menü çubuğu ekran yüksekliğini kaplamaz (min 64 civarı kalır)',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: const SizedBox.expand(child: Text('gövde')),
          bottomNavigationBar: BottomBar(
            currentIndex: 0,
            onTap: (_) {},
            onCreate: () {},
          ),
        ),
      ),
    );
    // pumpAndSettle: flutter_animate'in scale animasyonu bitmeden test biterse
    // "A Timer is still pending" ile düşer (ölçümle ilgisiz gürültü).
    await tester.pumpAndSettle();

    final screenHeight = tester.view.physicalSize.height / tester.view.devicePixelRatio;
    final barHeight = tester.getSize(find.byType(BottomBar)).height;

    // Regresyonda barHeight == ekran yüksekliği idi (800). Sağlıklı değer
    // ~64 (SafeArea eklerse biraz üstü). 120 sınırı, etiketler iki satıra
    // kaysa bile geçerli kalacak kadar geniş ama ekranı kaplamayı yakalar.
    expect(barHeight, lessThan(120),
        reason: 'bar $barHeight px — ekran $screenHeight px; Center büyümüş olabilir');
    expect(barHeight, greaterThanOrEqualTo(64));

    // Gövde gerçekten yer bulmuş olmalı (regresyonda sıfırdı).
    expect(tester.getSize(find.text('gövde')).height, greaterThan(screenHeight / 2));
  });
}
