import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kurandakimesaj/data/seed/ayah_notes_seed.dart';
import 'package:kurandakimesaj/data/seed/topical_seed.dart';
import 'package:kurandakimesaj/ui/core/ayah_note.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('notu olan ayette "Kısa açıklama" katlanır, açılınca metin görünür', (
    tester,
  ) async {
    final note = kAyahNotes['2:153']!;
    await tester.pumpWidget(
      _host(
        const AyahNote(surah: 2, ayah: 153, fg: Colors.black, ink: Colors.green),
      ),
    );

    expect(find.text('Kısa açıklama'), findsOneWidget);
    expect(find.text(note), findsNothing, reason: 'katlı başlar');

    await tester.tap(find.text('Kısa açıklama'));
    await tester.pumpAndSettle();
    expect(find.text(note), findsOneWidget);
    expect(find.textContaining('tefsir yerine geçmez'), findsOneWidget);
  });

  testWidgets('notu olmayan ayette hiçbir şey çizilmez', (tester) async {
    await tester.pumpWidget(
      _host(
        const AyahNote(surah: 1, ayah: 1, fg: Colors.black, ink: Colors.green),
      ),
    );
    expect(find.text('Kısa açıklama'), findsNothing);
  });

  test('konuya göre ayetlerin tamamının açıklaması var ve künyeden çözülür', () {
    for (final t in kTopicalSeed) {
      expect(
        AyahNote.noteForReference(t.$2),
        isNotNull,
        reason: '${t.$2} için açıklama yok',
      );
    }
  });
}
