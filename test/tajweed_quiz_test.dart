import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kurandakimesaj/data/local/app_database.dart';
import 'package:kurandakimesaj/features/learning/learning_screens.dart';

void main() {
  testWidgets('Tecvid quiz tüm derslerden en çok 6 tekrarsız soru sorar', (tester) async {
    final lessons = [
      for (var i = 1; i <= 24; i++)
        TajweedLesson(
            id: i, order: i, title: 'Ders $i', rule: 'Kural $i', example: 'مثال$i', body: 'Gövde $i'),
    ];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: TajweedQuizDialog(lessons: lessons, random: Random(7))),
    ));
    final seen = <String>{};
    for (var q = 1; q <= 6; q++) {
      expect(find.text('Soru $q / 6'), findsOneWidget);
      expect(find.textContaining('Kural'), findsNothing); // kural metni sızmaz
      final example = tester.widget<Text>(find.textContaining('مثال')).data!;
      expect(seen.add(example), isTrue); // tekrarsız
      final n = int.parse(example.substring(4));
      expect(find.text('Ders $n'), findsOneWidget);
      expect(find.textContaining('Ders '), findsNWidgets(4));
      await tester.tap(find.text('Ders $n'));
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(seen.length, 6);
  });
}
