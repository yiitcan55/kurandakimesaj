import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kurandakimesaj/ui/core/widgets.dart';

void main() {
  // Regresyon: onSave (DB insert) throw ederse buton "Kaydediliyor…"da asılı
  // kalmamalı, not sessizce kaybolmamalı — hata görünür olmalı, sheet açık kalmalı.
  testWidgets('Düşün sheet: kayıt başarısızsa buton kilitlenmez ve hata gösterilir',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => showReflectionSheet(
                  context,
                  reference: 'Bakara, 286',
                  onSave: (_) async => throw Exception('db fail'),
                ),
                child: const Text('aç'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();
    expect(find.text('Koleksiyona kaydet'), findsOneWidget);

    await tester.tap(find.text('Koleksiyona kaydet'));
    await tester.pumpAndSettle();

    // Hata yüzeye çıktı ve buton yeniden aktif (sheet açık kaldı).
    expect(find.text('Kaydedilemedi, tekrar deneyin.'), findsOneWidget);
    expect(find.text('Koleksiyona kaydet'), findsOneWidget);
  });
}
