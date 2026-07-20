import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kurandakimesaj/ui/core/widgets.dart';

/// GlassSegmentedToggle sözleşmesi: her segmente dokunmak doğru index'i bildirir,
/// iki segment de görünür.
void main() {
  testWidgets('segmente dokunmak doğru index ile onChanged tetikler', (tester) async {
    final tapped = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: GlassSegmentedToggle(
              segments: const ['Gönderiler', 'Reels'],
              index: 0,
              onChanged: tapped.add,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Gönderiler'), findsOneWidget);
    expect(find.text('Reels'), findsOneWidget);

    await tester.tap(find.text('Reels'));
    await tester.pump();
    expect(tapped, [1]);

    await tester.tap(find.text('Gönderiler'));
    await tester.pump();
    expect(tapped, [1, 0]);
  });
}
