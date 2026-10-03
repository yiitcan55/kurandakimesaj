import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kurandakimesaj/features/meal_edit/meal_publish_sheet.dart';

/// MealPublishSheet "aptal" bir widget: provider'a bağlı değil, yalnız
/// `onPublish` geri çağrısını kullanır — bu yüzden ProviderScope gerekmez.
Future<void> _open(
  WidgetTester tester, {
  required Future<void> Function(String caption) onPublish,
  String? disabledReason,
}) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  await tester.binding.setSurfaceSize(const Size(400, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            key: const Key('open'),
            onPressed: () => showMealPublishSheet(
              context,
              onPublish: onPublish,
              disabledReason: disabledReason,
            ),
            child: const Text('aç'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.byKey(const Key('open')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> _acceptRights(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('meal_rights_checkbox')));
  await tester.pump(const Duration(milliseconds: 300));
}

FilledButton _publishButton(WidgetTester tester) => tester.widget<FilledButton>(
  find.byKey(const Key('meal_publish_button')),
);

void main() {
  testWidgets('açıklama onPublish\'e (kırpılmış olarak) ulaşır', (tester) async {
    String? got;
    await _open(tester, onPublish: (c) async => got = c);
    await tester.enterText(find.byType(TextField), '  Güzel bir ayet  ');
    await _acceptRights(tester);
    await tester.tap(find.byKey(const Key('meal_publish_button')));
    await tester.pump(const Duration(milliseconds: 500));
    expect(got, 'Güzel bir ayet');
  });

  testWidgets('başarıda inceleme bildirimi görünür ve sheet kapanır', (tester) async {
    await _open(tester, onPublish: (_) async {});
    await _acceptRights(tester);
    await tester.tap(find.byKey(const Key('meal_publish_button')));
    await tester.pump(); // onPublish tamamlanır, pop başlar
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byKey(const Key('meal_publish_button')), findsNothing);
    expect(find.textContaining('incelemeye alındı'), findsOneWidget);
  });

  testWidgets('hata mesajı gösterilir ve düğme yeniden açılır', (tester) async {
    var calls = 0;
    await _open(
      tester,
      onPublish: (_) async {
        calls++;
        throw calls == 1 ? StateError('Önce giriş yap.') : Exception('x');
      },
    );
    await _acceptRights(tester);
    await tester.tap(find.byKey(const Key('meal_publish_button')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('meal_publish_error')), findsOneWidget);
    expect(find.text('Önce giriş yap.'), findsOneWidget);
    expect(_publishButton(tester).onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('meal_publish_button')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.text('Yayınlanamadı. Bağlantını kontrol edip tekrar dene.'),
      findsOneWidget,
    );
  });

  testWidgets('meşgulken çift gönderim olmaz', (tester) async {
    final gate = Completer<void>();
    var calls = 0;
    await _open(tester, onPublish: (_) { calls++; return gate.future; });
    await _acceptRights(tester);
    await tester.tap(find.byKey(const Key('meal_publish_button')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(_publishButton(tester).onPressed, isNull);
    gate.complete();
    await tester.pump(const Duration(milliseconds: 600));
    expect(calls, 1);
  });

  testWidgets('disabledReason varken yayın kapalı ve neden görünür', (tester) async {
    await _open(
      tester,
      onPublish: (_) async {},
      disabledReason: 'Video 20 MB üstü olduğu için yayınlanamaz.',
    );
    await _acceptRights(tester);
    expect(_publishButton(tester).onPressed, isNull);
    expect(find.byKey(const Key('meal_publish_disabled_reason')), findsOneWidget);
    expect(find.text('Video 20 MB üstü olduğu için yayınlanamaz.'), findsOneWidget);
  });
}
