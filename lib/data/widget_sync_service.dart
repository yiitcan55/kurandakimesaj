import 'package:home_widget/home_widget.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';

import '../domain/models.dart';
import 'local/app_database.dart';

/// Telefon ana ekran widget'larına veri köprüsü (home_widget).
///
/// Flutter tarafı veriyi paylaşılan depoya yazar; native AppWidget/WidgetKit
/// bu anahtarları okuyup render eder. RemoteViews canlı sayaç çalıştıramadığı
/// için widget "sıradaki vakit + saat" gösterir (geri sayım değil).
class WidgetSyncService {
  // iOS App Group — WidgetKit ile paylaşılan UserDefaults (Faz 3'te kurulur).
  static const String iOSAppGroup = 'group.com.kurandakimesaj.app';

  // Native AppWidgetProvider sınıf adları (qualified isim updateWidget'te şart).
  static const String _prayerAndroid = 'com.kurandakimesaj.app.PrayerWidgetProvider';
  static const String _ayahAndroid = 'com.kurandakimesaj.app.AyahWidgetProvider';

  // ponytail: holy_days_screen ile aynı liste; 12 string, paylaşmaya değmez.
  static const List<String> _hijriMonths = [
    'Muharrem', 'Safer', 'Rebiülevvel', 'Rebiülahir', 'Cemaziyelevvel',
    'Cemaziyelahir', 'Recep', 'Şaban', 'Ramazan', 'Şevval', 'Zilkade', 'Zilhicce',
  ];

  Future<void> _ensureGroup() => HomeWidget.setAppGroupId(iOSAppGroup);

  static String hijriToday() {
    final c = HijriCalendar.now();
    return '${c.hDay} ${_hijriMonths[c.hMonth - 1]} ${c.hYear}';
  }

  /// Namaz vakti + hicri tarih widget'ını günceller.
  Future<void> syncPrayer(PrayerDay day) async {
    await _ensureGroup();
    final next = day.nextAfter(DateTime.now());
    final fmt = DateFormat('HH:mm');
    await HomeWidget.saveWidgetData<String>(
        'prayer_next_name', next?.name ?? '—');
    await HomeWidget.saveWidgetData<String>(
        'prayer_next_time', next != null ? fmt.format(next.time) : '--:--');
    await HomeWidget.saveWidgetData<String>('prayer_location', day.locationLabel);
    await HomeWidget.saveWidgetData<String>('hijri_date', hijriToday());
    await HomeWidget.updateWidget(
      qualifiedAndroidName: _prayerAndroid,
      iOSName: 'PrayerWidget',
    );
  }

  /// Günün ayeti widget'ını günceller.
  ///
  /// Arapça metin BİLİNÇLİ olarak gönderilmiyor: domain kuralı #2 gereği mushaf
  /// hattı yalnız Amiri Quran ile render edilir, o font da ne RemoteViews'a ne
  /// de WidgetKit extension'ına paketli. Eskiden yazılan `ayah_arabic` anahtarını
  /// hiçbir platform okumuyordu — kaldırıldı.
  Future<void> syncAyah(Ayah ayah, Surah? surah) async {
    await _ensureGroup();
    await HomeWidget.saveWidgetData<String>('ayah_meal', ayah.meal);
    await HomeWidget.saveWidgetData<String>(
        'ayah_ref', '${surah?.nameTr ?? 'Sure'}, ${ayah.numberInSurah}');
    await HomeWidget.updateWidget(
      qualifiedAndroidName: _ayahAndroid,
      iOSName: 'AyahWidget',
    );
  }
}
