import 'package:flutter_test/flutter_test.dart';
import 'package:kurandakimesaj/domain/models.dart';

void main() {
  group('AppSettings', () {
    test('varsayılan değerler doğru', () {
      const s = AppSettings();
      expect(s.onboardingComplete, false);
      expect(s.mealOption, MealOption.diyanet);
      expect(s.interests, isEmpty);
      expect(s.notificationsGranted, false);
    });

    test('copyWith yalnızca verilen alanı değiştirir', () {
      const s = AppSettings();
      final next = s.copyWith(
        onboardingComplete: true,
        mealOption: MealOption.elmalili,
      );
      expect(next.onboardingComplete, true);
      expect(next.mealOption, MealOption.elmalili);
      expect(next.notificationsGranted, s.notificationsGranted);
    });

    test('ilgi alanı kopyası orijinali değiştirmez', () {
      const s = AppSettings();
      final next = s.copyWith(interests: {AppInterest.okuma, AppInterest.ibadet});
      expect(next.interests.length, 2);
      expect(s.interests, isEmpty);
    });
  });
}
