import 'package:adhan/adhan.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:just_audio/just_audio.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../domain/models.dart';

/// Konum servisi — geolocator sarmalayıcısı. İzin yoksa null döner;
/// çağıran taraf İstanbul gibi bir varsayılana düşebilir.
class LocationService {
  /// İstanbul (Sultanahmet) — konum alınamazsa kullanılan varsayılan.
  static const double defaultLat = 41.0055;
  static const double defaultLng = 28.9769;
  static const String defaultLabel = 'İstanbul (varsayılan)';

  Future<({double lat, double lng})?> current() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return null;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      return (lat: pos.latitude, lng: pos.longitude);
    } catch (_) {
      return null;
    }
  }
}

/// Namaz vakti hesaplama — adhan (Diyanet/Türkiye yöntemi, Şafiî asr).
/// Saf hesap; konum dışarıdan verilir (test edilebilir).
class PrayerService {
  PrayerDay compute({
    required double lat,
    required double lng,
    required String locationLabel,
    DateTime? date,
  }) {
    final coords = Coordinates(lat, lng);
    final params = CalculationMethod.turkey.getParameters()
      ..madhab = Madhab.shafi;
    final base = date ?? DateTime.now();
    final today = PrayerTimes(coords, DateComponents.from(base), params);
    final tomorrow = PrayerTimes(
      coords,
      DateComponents.from(base.add(const Duration(days: 1))),
      params,
    );

    return PrayerDay(
      date: DateTime(base.year, base.month, base.day),
      locationLabel: locationLabel,
      tomorrowFajr: tomorrow.fajr.toLocal(),
      slots: [
        PrayerSlot(name: 'İmsak', time: today.fajr.toLocal()),
        PrayerSlot(name: 'Güneş', time: today.sunrise.toLocal(), isPrayer: false),
        PrayerSlot(name: 'Öğle', time: today.dhuhr.toLocal()),
        PrayerSlot(name: 'İkindi', time: today.asr.toLocal()),
        PrayerSlot(name: 'Akşam', time: today.maghrib.toLocal()),
        PrayerSlot(name: 'Yatsı', time: today.isha.toLocal()),
      ],
    );
  }

  /// Kuzeyden Kâbe yönü (derece).
  double qiblaBearing(double lat, double lng) =>
      Qibla(Coordinates(lat, lng)).direction;
}

/// Kıble pusulası — cihaz yönü akışı (flutter_compass).
class QiblaService {
  /// Cihaz pusula yönü derece akışı; sensör yoksa null akabilir.
  Stream<double?> headingStream() {
    final events = FlutterCompass.events;
    if (events == null) return const Stream<double?>.empty();
    return events.map((e) => e.heading);
  }
}

/// Yerel bildirim servisi — ezan / günün ayeti / kandil zamanlaması.
/// Native yapılandırma (kanal, izin) cihazda gerekir; başlatma hataları
/// yutulur, böylece uygulama bildirimsiz de çalışır.
class NotificationService {
  NotificationService(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;

  static const _prayerChannel = 'prayer_times';
  static const _ayahChannel = 'daily_ayah';

  Future<void> init() async {
    try {
      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      await _plugin.initialize(
        settings: const InitializationSettings(android: android, iOS: ios),
      );
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  Future<bool> requestPermission() async {
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final a = await android?.requestNotificationsPermission() ?? true;
      final i = await ios?.requestPermissions(alert: true, sound: true) ?? true;
      return a || i;
    } catch (_) {
      return false;
    }
  }

  NotificationDetails _details(String channel, String name) => NotificationDetails(
        android: AndroidNotificationDetails(
          channel,
          name,
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      );

  Future<void> showNow(String title, String body) async {
    if (!_ready) return;
    try {
      await _plugin.show(
        id: 0,
        title: title,
        body: body,
        notificationDetails: _details(_ayahChannel, 'Günün Ayeti'),
      );
    } catch (_) {}
  }

  /// Bir namaz vakti için bildirimi zamanlar (geçmişse atlanır).
  Future<void> schedulePrayer(int id, String name, DateTime when) async {
    if (!_ready || when.isBefore(DateTime.now())) return;
    try {
      await _plugin.zonedSchedule(
        id: id,
        title: '$name vakti',
        body: '$name vakti girdi. Allah kabul etsin.',
        scheduledDate: tz.TZDateTime.from(when, tz.local),
        notificationDetails: _details(_prayerChannel, 'Namaz Vakitleri'),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (_) {}
  }

  /// Her gün belirli saatte tekrar eden bildirim (günün ayeti, kandil vb.).
  Future<void> scheduleDaily(
    int id,
    String title,
    String body,
    int hour,
    int minute,
  ) async {
    if (!_ready) return;
    try {
      final now = tz.TZDateTime.now(tz.local);
      var when = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
      if (when.isBefore(now)) when = when.add(const Duration(days: 1));
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: when,
        notificationDetails: _details(_ayahChannel, 'Günün Ayeti'),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {}
  }

  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }

  Future<void> cancel(int id) async {
    try {
      await _plugin.cancel(id: id);
    } catch (_) {}
  }

  /// Günlük tekrarlayan dua hatırlatıcısı.
  Future<void> scheduleDailyDua({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    if (!_ready) return;
    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: _nextInstance(hour, minute),
        notificationDetails: NotificationDetails(
          android: const AndroidNotificationDetails(
            'dua_channel',
            'Dua Hatırlatıcısı',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {}
  }

  /// Tek seferlik bildirim (İslami takvim günleri için).
  Future<void> scheduleOnce({
    required int id,
    required DateTime dateTime,
    required String title,
    required String body,
  }) async {
    if (!_ready) return;
    try {
      final scheduled = tz.TZDateTime.from(dateTime, tz.local);
      if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) return;
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduled,
        notificationDetails: NotificationDetails(
          android: const AndroidNotificationDetails(
            'islamic_channel',
            'İslami Takvim',
            importance: Importance.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (_) {}
  }

  tz.TZDateTime _nextInstance(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}

/// Sesli okuma (tilavet) — just_audio sarmalayıcısı. Tek bir oynatıcı örneği.
class AudioService {
  final AudioPlayer player = AudioPlayer();

  Future<void> playUrl(String url) async {
    try {
      if (player.audioSource == null ||
          (player.audioSource as UriAudioSource?)?.uri.toString() != url) {
        await player.setUrl(url);
      }
      await player.play();
    } catch (_) {}
  }

  Future<void> pause() => player.pause();
  Future<void> stop() => player.stop();
  void dispose() => player.dispose();
}

/// Paylaşım servisi — share_plus (günün ayeti, koleksiyon kartı vb.).
class ShareService {
  Future<void> shareText(String text, {String? subject}) async {
    try {
      await SharePlus.instance.share(ShareParams(text: text, subject: subject));
    } catch (_) {}
  }
}
