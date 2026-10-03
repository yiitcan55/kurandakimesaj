import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kurandakimesaj/data/local/app_database.dart';
import 'package:kurandakimesaj/features/esma/esma_screen.dart';

/// Regresyon: `showModalBottomSheet` alt güvenli alanı uygulamaz; Esmaü'l-Hüsna
/// detay sayfasında anlam metni 3 tuşlu gezinme çubuğunun ALTINDA kalıyordu.
void main() {
  testWidgets('Esma detay sayfasının metni gezinme çubuğunun üstünde kalır', (
    tester,
  ) async {
    const navBar = 48.0;
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = const FakeViewPadding(bottom: navBar);
    tester.view.viewPadding = const FakeViewPadding(bottom: navBar);
    addTearDown(tester.view.reset);

    const meaning = 'Dünyada bütün mahlukata sınırsız merhamet gösteren';
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          esmaProvider.overrideWith(
            (ref) async => const [
              EsmaName(
                id: 1,
                order: 1,
                name: 'Er-Rahmân',
                arabic: 'الرَّحْمٰن',
                meaning: meaning,
              ),
            ],
          ),
        ],
        child: const MaterialApp(home: EsmaScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Er-Rahmân'));
    await tester.pumpAndSettle();

    // İlk eşleşme kart, sonuncusu alt sayfadaki metin.
    final bottom = tester.getBottomLeft(find.text(meaning).last).dy;
    expect(bottom, lessThanOrEqualTo(800 - navBar));
  });
}
