import 'package:flutter_test/flutter_test.dart';
import 'package:kurandakimesaj/data/backend_repositories.dart';
import 'package:kurandakimesaj/domain/meal_cues.dart';

void main() {
  const base = {'id': 'p1'};

  test('kolon yokken boş liste ve standard stil', () {
    final p = FeedPost.fromMap({...base}, myId: null);
    expect(p.mealCues, isEmpty);
    expect(p.mealCueStyle, MealCueStyle.standard);
  });

  test("bozuk meal_cues FeedPost.fromMap'i düşürmez", () {
    final p = FeedPost.fromMap({
      ...base,
      'meal_cues': [
        {'s': 'x'},
      ],
      'meal_cue_style': 42,
    }, myId: null);
    expect(p.mealCues, isEmpty);
    expect(p.mealCueStyle, MealCueStyle.standard);
  });

  test('geçerli cue ve stil okunur', () {
    final p = FeedPost.fromMap({
      ...base,
      'meal_cues': [
        {'s': 0.5, 'e': 3, 'su': 1, 'a': 2},
      ],
      'meal_cue_style': 'arabic',
    }, myId: null);
    expect(p.mealCues, [
      const MealCue(startSec: 0.5, endSec: 3, surah: 1, ayah: 2),
    ]);
    expect(p.mealCueStyle, MealCueStyle.arabic);
  });
}
