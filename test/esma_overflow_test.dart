import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kurandakimesaj/data/local/app_database.dart';
import 'package:kurandakimesaj/features/esma/esma_screen.dart';

/// Regresyon: Esmaü'l-Hüsna grid kartları, 2 satıra sarılan anlam metninde
/// dikey olarak taşıyordu (RenderFlex "BOTTOM OVERFLOWED BY 12 PIXELS").
/// Kök neden: childAspectRatio 1.15 + Arapça height 1.9 birlikte hücre
/// yüksekliğini ~12px aştırıyordu. Dar ekranda taşma daha da büyük olur.
void main() {
  testWidgets('Esma kartları dar ekranda taşmaz (2 satırlık anlam)', (tester) async {
    // Dar telefon ekranı — fix öncesi taşmayı tetikleyen koşul.
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // 2 satıra sarılacak kadar uzun anlam metni olan örnekler.
    const sample = <EsmaName>[
      EsmaName(
        id: 1,
        order: 1,
        name: 'Er-Rahmân',
        arabic: 'الرَّحْمٰن',
        meaning: 'Dünyada bütün mahlukata sınırsız merhamet ve şefkat gösteren',
      ),
      EsmaName(
        id: 2,
        order: 2,
        name: 'Es-Selâm',
        arabic: 'السَّلَام',
        meaning: 'Her türlü tehlikeden selamete çıkaran, esenlik ve barış veren',
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          esmaProvider.overrideWith((ref) async => sample),
        ],
        child: const MaterialApp(home: EsmaScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Taşma olursa Flutter bir FlutterError fırlatır; test binding'i yakalar.
    expect(tester.takeException(), isNull);
  });
}
