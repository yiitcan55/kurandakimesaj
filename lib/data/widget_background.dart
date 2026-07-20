import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import 'device_services.dart';
import 'widget_sync_service.dart';

/// Uygulama ezan vakitlerini hesaplarken son konumu buraya yazar; background
/// isolate geolocator çağırmadan (arka plan konum izni gerektirmeden) okur.
const String kLastLatKey = 'widget_last_lat';
const String kLastLngKey = 'widget_last_lng';
const String kLastLocLabelKey = 'widget_last_loc_label';

const String _kPrayerTask = 'prayerWidgetRefresh';

/// Background isolate giriş noktası — uygulama kapalıyken ezan widget'ındaki
/// "sıradaki vakit" bilgisini günceller. Ayet günde bir değiştiği için burada
/// yenilenmez (uygulama açılış senkronu yeterli).
@pragma('vm:entry-point')
void widgetCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lat = prefs.getDouble(kLastLatKey) ?? LocationService.defaultLat;
      final lng = prefs.getDouble(kLastLngKey) ?? LocationService.defaultLng;
      final label =
          prefs.getString(kLastLocLabelKey) ?? LocationService.defaultLabel;
      final day = PrayerService()
          .compute(lat: lat, lng: lng, locationLabel: label);
      await WidgetSyncService().syncPrayer(day);
      return true;
    } catch (_) {
      return false;
    }
  });
}

/// Periyodik ezan widget'ı yenilemesi.
/// Android: ~15 dk (WorkManager alt sınırı). iOS: en iyi çaba (BGAppRefresh);
/// iOS'ta WidgetKit'in kendi 30 dk'lık timeline'ı da devrede. Kayıt hataları
/// yutulur — desteklenmeyen platform uygulamayı bozmamalı.
class WidgetBackground {
  static Future<void> init() async {
    try {
      await Workmanager().initialize(widgetCallbackDispatcher);
      await Workmanager().registerPeriodicTask(
        _kPrayerTask,
        _kPrayerTask,
        frequency: const Duration(minutes: 15),
      );
    } catch (_) {}
  }
}
