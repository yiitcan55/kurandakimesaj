import 'package:flutter/material.dart' show Icons, IconData, ThemeMode;
import 'package:flutter/widgets.dart';

/// Onboarding'de seçilen meal tercihi (Uygulama Planı.html §06 A akışı).
enum MealOption {
  diyanet('Diyanet Meali'),
  elmalili('Elmalılı Hamdi Yazır'),
  tdv('TDV Meali');

  const MealOption(this.label);
  final String label;
}

/// Kişiselleştirme için ilgi alanları (onboarding kurulum 2. adım).
enum AppInterest {
  okuma('Kur\'an Okuma', Icons.menu_book_rounded),
  ibadet('Günlük İbadet', Icons.mosque_rounded),
  ezber('Ezber & Öğrenme', Icons.school_rounded),
  uretim('İçerik Üretimi', Icons.movie_creation_rounded),
  topluluk('Topluluk', Icons.groups_rounded);

  const AppInterest(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// Özellik kategorileri (Tüm Özellikler kataloğu + modül gruplaması).
enum FeatureCategory {
  ibadet('İbadet & Günlük'),
  kuran('Kur\'an & Öğrenme'),
  icerik('İçerik & Topluluk'),
  araclar('Araçlar');

  const FeatureCategory(this.label);
  final String label;
}

/// Uygulama tercihleri — shared_preferences ile kalıcı.
/// Saf, değişmez (immutable) domain modeli (Flutter'a bağımsız mantık).
@immutable
class AppSettings {
  const AppSettings({
    this.onboardingComplete = false,
    this.mealOption = MealOption.diyanet,
    this.interests = const {},
    this.notificationsGranted = false,
    this.themeMode = ThemeMode.system,
  });

  final bool onboardingComplete;
  final MealOption mealOption;
  final Set<AppInterest> interests;
  final bool notificationsGranted;
  final ThemeMode themeMode;

  AppSettings copyWith({
    bool? onboardingComplete,
    MealOption? mealOption,
    Set<AppInterest>? interests,
    bool? notificationsGranted,
    ThemeMode? themeMode,
  }) {
    return AppSettings(
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      mealOption: mealOption ?? this.mealOption,
      interests: interests ?? this.interests,
      notificationsGranted: notificationsGranted ?? this.notificationsGranted,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}

/// Tek bir vakit dilimi (İmsak, Güneş, Öğle, İkindi, Akşam, Yatsı).
@immutable
class PrayerSlot {
  const PrayerSlot({
    required this.name,
    required this.time,
    this.isPrayer = true,
  });

  final String name;
  final DateTime time;

  /// Güneş bir namaz vakti değildir (yalnızca gösterim).
  final bool isPrayer;
}

/// Bir günün hesaplanmış namaz vakitleri (adhan + konum).
@immutable
class PrayerDay {
  const PrayerDay({
    required this.date,
    required this.slots,
    required this.locationLabel,
    this.tomorrowFajr,
  });

  final DateTime date;
  final List<PrayerSlot> slots;
  final String locationLabel;
  final DateTime? tomorrowFajr;

  /// Verilen ana göre sıradaki namaz vakti (yatsı sonrası → yarınki imsak).
  PrayerSlot? nextAfter(DateTime now) {
    for (final s in slots.where((s) => s.isPrayer)) {
      if (s.time.isAfter(now)) return s;
    }
    if (tomorrowFajr != null) {
      return PrayerSlot(name: 'İmsak', time: tomorrowFajr!);
    }
    return null;
  }

  /// Şu an içinde bulunulan vakit (en son geçmiş namaz vakti).
  PrayerSlot? currentAt(DateTime now) {
    PrayerSlot? current;
    for (final s in slots.where((s) => s.isPrayer)) {
      if (!s.time.isAfter(now)) current = s;
    }
    return current;
  }
}

/// Ayet Bulucu sonucu — Edge Function `ayah-finder` sözleşmesi.
enum AyahFinderStatus { matched, ambiguous, notFound, error }

/// Görsel/bağlantıdan tanınan tek bir ayet adayı.
@immutable
class AyahMatch {
  const AyahMatch({
    required this.reference,
    required this.surah,
    required this.ayah,
    required this.arabic,
    required this.meal,
    required this.confidence,
  });

  final String reference; // "Bakara, 153"
  final int surah;
  final int ayah;
  final String arabic;
  final String meal;
  final double confidence; // 0..1

  factory AyahMatch.fromJson(Map<String, dynamic> j) => AyahMatch(
        reference: (j['reference'] ?? '').toString(),
        surah: (j['surah'] as num?)?.toInt() ?? 0,
        ayah: (j['ayah'] as num?)?.toInt() ?? 0,
        arabic: (j['arabic'] ?? '').toString(),
        meal: (j['meal'] ?? '').toString(),
        confidence: (j['confidence'] as num?)?.toDouble() ?? 0,
      );
}

/// Videodan tanınan ayet ARALIĞI (ör. Yasin 58-61) — `ayah-finder-audio`.
/// Görsel/OCR yolunda gelmez (tek ayet); o yüzden `AyahFinderResult.range` null olabilir.
@immutable
class AyahRange {
  const AyahRange({
    required this.surah,
    required this.fromAyah,
    required this.toAyah,
    required this.reference,
  });

  final int surah;
  final int fromAyah;
  final int toAyah;
  final String reference; // "Yasin, 58-61"

  bool get isSingle => fromAyah == toAyah;

  factory AyahRange.fromJson(Map<String, dynamic> j) => AyahRange(
        surah: (j['surah'] as num?)?.toInt() ?? 0,
        fromAyah: (j['fromAyah'] as num?)?.toInt() ?? 0,
        toAyah: (j['toAyah'] as num?)?.toInt() ?? 0,
        reference: (j['reference'] ?? '').toString(),
      );
}

/// "Videonun kaçıncı saniyesinde hangi ayet okunuyor" — `ayah-finder-audio`.
@immutable
class AyahTimelineEntry {
  const AyahTimelineEntry({
    required this.startSec,
    required this.endSec,
    required this.surah,
    required this.ayah,
    required this.reference,
    required this.confidence,
  });

  final double startSec;
  final double endSec;
  final int surah;
  final int ayah;
  final String reference;
  final double confidence;

  /// "01:05" — video konumu.
  String get startLabel {
    final total = startSec.floor();
    final m = (total ~/ 60).toString().padLeft(2, '0');
    final s = (total % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  factory AyahTimelineEntry.fromJson(Map<String, dynamic> j) => AyahTimelineEntry(
        startSec: (j['startSec'] as num?)?.toDouble() ?? 0,
        endSec: (j['endSec'] as num?)?.toDouble() ?? 0,
        surah: (j['surah'] as num?)?.toInt() ?? 0,
        ayah: (j['ayah'] as num?)?.toInt() ?? 0,
        reference: (j['reference'] ?? '').toString(),
        confidence: (j['confidence'] as num?)?.toDouble() ?? 0,
      );
}

/// `ayah-finder` (görsel/bağlantı) ve `ayah-finder-audio` (video) ortak sonucu.
///
/// `range` + `timeline` yalnızca ses hattında dolar. Görsel hattının yanıtında bu
/// alanlar hiç bulunmaz → `fromJson` savunmacı okur, sözleşme iki yönde uyumludur
/// (eski sunucu yanıtı yeni modele oturur; yeni alanlar eski istemciyi bozmaz).
@immutable
class AyahFinderResult {
  const AyahFinderResult({
    required this.status,
    this.matches = const [],
    this.extractedArabic = '',
    this.errorCode,
    this.range,
    this.timeline = const [],
  });

  final AyahFinderStatus status;
  final List<AyahMatch> matches;
  final String extractedArabic;
  final String? errorCode;

  /// Videodan bulunan ayet aralığı — görsel yolunda null.
  final AyahRange? range;

  /// Hangi saniyede hangi ayet — görsel yolunda boş.
  final List<AyahTimelineEntry> timeline;

  factory AyahFinderResult.fromJson(Map<String, dynamic> j) => AyahFinderResult(
        status: AyahFinderStatus.values.firstWhere(
          (s) => s.name == j['status'],
          orElse: () => AyahFinderStatus.error,
        ),
        matches: ((j['matches'] as List?) ?? const [])
            .map((e) => AyahMatch.fromJson((e as Map).cast<String, dynamic>()))
            .toList(growable: false),
        extractedArabic: (j['extractedArabic'] ?? '').toString(),
        errorCode: j['errorCode']?.toString(),
        range: j['range'] is Map
            ? AyahRange.fromJson((j['range'] as Map).cast<String, dynamic>())
            : null,
        timeline: ((j['timeline'] as List?) ?? const [])
            .map((e) =>
                AyahTimelineEntry.fromJson((e as Map).cast<String, dynamic>()))
            .toList(growable: false),
      );
}

/// Kıble yönü bilgisi — Kâbe açısı + cihaz pusula yönü.
@immutable
class QiblaInfo {
  const QiblaInfo({
    required this.qiblaBearing,
    required this.deviceHeading,
  });

  /// Kuzeyden Kâbe'ye derece (0..360).
  final double qiblaBearing;

  /// Cihazın baktığı yön (derece, 0..360).
  final double deviceHeading;

  /// Kıbleye göre cihazın dönmesi gereken açı (derece).
  double get angleToQibla => (qiblaBearing - deviceHeading) % 360;

  /// Kıbleye hizalı mı (±5°)?
  bool get aligned {
    final d = angleToQibla;
    return d <= 5 || d >= 355;
  }
}
