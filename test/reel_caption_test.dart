import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kurandakimesaj/data/backend_repositories.dart';
import 'package:kurandakimesaj/features/community/community_screens.dart';

/// `FeedPost.caption` daha önce veritabanına yazılıyor ama `fromMap` hiç
/// okumuyordu — ekranda görünen aslında `meal` idi. Bu testler hem o kök
/// nedeni (fromMap eksik alan okuması) hem de `ReelCaption` widget'ının
/// "kısa açıklamada sahte genişlet affordance'ı gösterme" dürüstlük
/// kuralını kilitler.
void main() {
  // google_fonts test ortamında fontu ne asset'ten ne ağdan çözebiliyor;
  // `allowRuntimeFetching = false` olmazsa testler ağ isteği denemesinden
  // dolayı yavaşlar/patlar (bkz. share_cold_start_test.dart, aynı kalıp).
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('FeedPost.fromMap caption okuması', () {
    test('caption kolonu doluysa okunur', () {
      final post = FeedPost.fromMap({'id': '1', 'caption': 'Elhamdülillah'}, myId: null);
      expect(post.caption, 'Elhamdülillah');
    });

    test('caption kolonu SELECT sonucunda yoksa boş string döner (çökme yok)', () {
      final post = FeedPost.fromMap({'id': '1'}, myId: null);
      expect(post.caption, '');
    });
  });

  group('ReelCaption', () {
    const uzunMetin =
        'Bu açıklama kasıtlı olarak çok uzun yazıldı ki dar bir kutuya '
        'sığmasın ve iki satırı kesin taşsın, böylece genişlet/daralt '
        'davranışı gerçekten test edilebilsin. Rabbimiz bize dünyada da '
        'ahirette de iyilik ver ve bizi ateşin azabından koru.';
    const kisaMetin = 'Kısa bir açıklama.';

    Widget dolgula(String text) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(width: 200, child: ReelCaption(text: text)),
        ),
      ),
    );

    testWidgets('uzun açıklama taşıyorsa 2 satır gösterir, dokunca 8 satıra genişler, tekrar dokunca 2ye döner', (
      tester,
    ) async {
      await tester.pumpWidget(dolgula(uzunMetin));
      await tester.pumpAndSettle();

      final metinKey = find.byKey(const Key('reel_caption_text'));
      final butonKey = find.byKey(const Key('reel_caption_toggle'));

      expect(tester.widget<Text>(metinKey).maxLines, ReelCaption.collapsedLines);

      await tester.tap(butonKey);
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(metinKey).maxLines, ReelCaption.expandedLines);

      await tester.tap(butonKey);
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(metinKey).maxLines, ReelCaption.collapsedLines);
    });

    testWidgets(
      'kısa açıklamada taşma olmadığı için sahte genişlet affordance\'ı gösterilmez',
      (tester) async {
        await tester.pumpWidget(dolgula(kisaMetin));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('reel_caption_toggle')), findsNothing);
        expect(find.text('…devamı'), findsNothing);
        // Metin yine de gösterilmeli, sadece dokunma affordance'ı olmadan.
        expect(find.byKey(const Key('reel_caption_text')), findsOneWidget);
      },
    );

    testWidgets('etiket metni kapalıyken …devamı, açıkken daha az olur', (tester) async {
      await tester.pumpWidget(dolgula(uzunMetin));
      await tester.pumpAndSettle();

      expect(find.text('…devamı'), findsOneWidget);
      expect(find.text('daha az'), findsNothing);

      await tester.tap(find.byKey(const Key('reel_caption_toggle')));
      await tester.pumpAndSettle();

      expect(find.text('daha az'), findsOneWidget);
      expect(find.text('…devamı'), findsNothing);
    });
  });
}
