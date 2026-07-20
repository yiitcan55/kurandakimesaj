import 'package:flutter_test/flutter_test.dart';
import 'package:kurandakimesaj/data/device_services.dart';
import 'package:kurandakimesaj/domain/models.dart';

void main() {
  group('PrayerDay', () {
    final base = DateTime(2026, 6, 15);
    final day = PrayerDay(
      date: base,
      locationLabel: 'Test',
      tomorrowFajr: DateTime(2026, 6, 16, 3, 30),
      slots: [
        PrayerSlot(name: 'İmsak', time: DateTime(2026, 6, 15, 3, 30)),
        PrayerSlot(name: 'Güneş', time: DateTime(2026, 6, 15, 5, 30), isPrayer: false),
        PrayerSlot(name: 'Öğle', time: DateTime(2026, 6, 15, 13, 0)),
        PrayerSlot(name: 'İkindi', time: DateTime(2026, 6, 15, 17, 0)),
        PrayerSlot(name: 'Akşam', time: DateTime(2026, 6, 15, 20, 30)),
        PrayerSlot(name: 'Yatsı', time: DateTime(2026, 6, 15, 22, 15)),
      ],
    );

    test('nextAfter öğleden önce Öğle döner', () {
      final next = day.nextAfter(DateTime(2026, 6, 15, 12, 0));
      expect(next?.name, 'Öğle');
    });

    test('Güneş bir namaz vakti olarak sıradaki sayılmaz', () {
      final next = day.nextAfter(DateTime(2026, 6, 15, 4, 0));
      expect(next?.name, 'Öğle');
    });

    test('Yatsı sonrası yarınki İmsak döner', () {
      final next = day.nextAfter(DateTime(2026, 6, 15, 23, 0));
      expect(next?.name, 'İmsak');
      expect(next?.time, DateTime(2026, 6, 16, 3, 30));
    });

    test('currentAt en son geçmiş namaz vaktini verir', () {
      final current = day.currentAt(DateTime(2026, 6, 15, 18, 0));
      expect(current?.name, 'İkindi');
    });
  });

  group('QiblaInfo', () {
    test('angleToQibla farkı normalize eder', () {
      const info = QiblaInfo(qiblaBearing: 150, deviceHeading: 100);
      expect(info.angleToQibla, 50);
    });

    test('hizalama ±5° içinde true', () {
      const aligned = QiblaInfo(qiblaBearing: 150, deviceHeading: 148);
      const notAligned = QiblaInfo(qiblaBearing: 150, deviceHeading: 100);
      expect(aligned.aligned, isTrue);
      expect(notAligned.aligned, isFalse);
    });
  });

  group('PrayerService (adhan)', () {
    test('İstanbul için 6 vakit sıralı hesaplanır', () {
      final day = PrayerService().compute(
        lat: 41.0082,
        lng: 28.9784,
        locationLabel: 'İstanbul',
        date: DateTime(2026, 6, 15),
      );
      expect(day.slots.length, 6);
      final times = day.slots.map((s) => s.time).toList();
      for (var i = 1; i < times.length; i++) {
        expect(times[i].isAfter(times[i - 1]), isTrue,
            reason: '${day.slots[i].name} bir önceki vakitten sonra olmalı');
      }
    });

    test('Kâbe yönü kuzeyden makul bir açıdır (0-360)', () {
      final bearing = PrayerService().qiblaBearing(41.0082, 28.9784);
      expect(bearing, greaterThanOrEqualTo(0));
      expect(bearing, lessThan(360));
    });
  });
}
