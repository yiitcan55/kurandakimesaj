import 'package:flutter/material.dart';

import '../domain/models.dart';

/// Bir özellik ekranının tanımı — route, başlık, açıklama, ikon, kategori.
/// Tek kaynak: Tüm Özellikler kataloğunu, placeholder ekranları ve router'ı
/// besler. Uygulama Planı.html §05'teki 24 özelliğin tamamı burada.
@immutable
class FeatureDef {
  const FeatureDef({
    required this.route,
    required this.title,
    required this.description,
    required this.icon,
    required this.category,
  });

  final String route;
  final String title;
  final String description;
  final IconData icon;
  final FeatureCategory category;
}

/// 24 özellik / 31 ekranın tam kataloğu (HİÇBİRİ ATLANMADI).
const List<FeatureDef> kFeatures = [
  // ── İbadet & Günlük (8) ──
  FeatureDef(route: '/prayer', title: 'Namaz Vakitleri', description: 'Günlük vakitler, sıradaki vakte geri sayım, ezan bildirimi.', icon: Icons.access_time_filled_rounded, category: FeatureCategory.ibadet),
  FeatureDef(route: '/dhikr', title: 'Zikirmatik', description: 'Dijital tesbih, dairesel sayaç, günlük zikir hedefi.', icon: Icons.fingerprint_rounded, category: FeatureCategory.ibadet),
  FeatureDef(route: '/tasbihat', title: 'Tesbihat', description: 'Namaz sonrası 33-33-33 adımlı rehberli sayaç.', icon: Icons.repeat_rounded, category: FeatureCategory.ibadet),
  FeatureDef(route: '/dua', title: 'Dua Kitaplığı', description: 'Sebebine göre dualar: Şifa, Rızık, Yolculuk, Sınav, Koruma…', icon: Icons.volunteer_activism_rounded, category: FeatureCategory.ibadet),
  FeatureDef(route: '/esma', title: 'Esmaü\'l-Hüsna', description: 'Allah\'ın 99 ismi, anlam + okunuş + ezber kartı.', icon: Icons.auto_awesome_rounded, category: FeatureCategory.ibadet),
  FeatureDef(route: '/fasting', title: 'Oruç & İmsakiye', description: 'İftar/sahur geri sayımı, Ramazan takvimi, kaza takibi.', icon: Icons.nightlight_round, category: FeatureCategory.ibadet),
  FeatureDef(route: '/holy-days', title: 'Dini Günler', description: 'Hicri takvim, kandil geri sayımı, yaklaşan özel günler.', icon: Icons.calendar_month_rounded, category: FeatureCategory.ibadet),
  FeatureDef(route: '/qibla', title: 'Pusula (Kıble)', description: 'Sensörle Kâbe yönünü gösteren pusula.', icon: Icons.explore_rounded, category: FeatureCategory.ibadet),

  // ── Kur'an & Öğrenme (8) ──
  FeatureDef(route: '/quran', title: 'Kur\'an Okuma', description: 'Arapça hero tipografi, meal & tefsir, sesli okuma, sepya mod.', icon: Icons.menu_book_rounded, category: FeatureCategory.kuran),
  FeatureDef(route: '/daily-ayah', title: 'Günlük Ayet & Hadis', description: 'Her gün yeni ayet ve hadis, paylaşıma hazır.', icon: Icons.wb_sunny_rounded, category: FeatureCategory.kuran),
  FeatureDef(route: '/topical', title: 'Konuya Göre Ayet', description: 'Ruh haline göre (Sabır, Huzur, Umut…) ayet önerisi.', icon: Icons.psychology_rounded, category: FeatureCategory.kuran),
  FeatureDef(route: '/miracles', title: 'Kuran Mucizeleri', description: 'Bilimsel, astronomi, embriyoloji, tarihi, sayısal kategoriler.', icon: Icons.science_rounded, category: FeatureCategory.kuran),
  FeatureDef(route: '/memorize', title: 'Sure Ezberi', description: 'Hıfz takibi, ilerleme yüzdesi, tekrar planlayıcı.', icon: Icons.school_rounded, category: FeatureCategory.kuran),
  FeatureDef(route: '/juz-tracker', title: 'Cüz / Hizb Takip', description: 'Günlük okuma hedefi, 30 cüz haritası, okuma serisi.', icon: Icons.donut_large_rounded, category: FeatureCategory.kuran),
  FeatureDef(route: '/stories', title: 'Peygamber Kıssaları', description: 'Kategorili, kısa okuma süreli anlatımlar, sesli seçenek.', icon: Icons.history_edu_rounded, category: FeatureCategory.kuran),
  FeatureDef(route: '/tajweed', title: 'Tecvid Dersleri', description: 'Kurallar, Arapça örnek, sesli telaffuz, mini quiz.', icon: Icons.record_voice_over_rounded, category: FeatureCategory.kuran),
  FeatureDef(route: '/quiz', title: 'Sure Quiz', description: 'Sure adları, ayet sayıları, iniş yerleri ve anlamlarını test eden 10 soruluk quiz.', icon: Icons.quiz_rounded, category: FeatureCategory.kuran),

  // ── İçerik & Topluluk (3) ──
  FeatureDef(route: '/studio', title: 'Video Edit + Meal', description: 'Şablon + tilavet + çoklu meal katmanı ile reels/TikTok videosu.', icon: Icons.movie_creation_rounded, category: FeatureCategory.icerik),
  FeatureDef(route: '/khatm', title: 'Hatim Halkaları', description: 'Grupça hatim, cüz dağıtımı, ortak ilerleme.', icon: Icons.groups_rounded, category: FeatureCategory.icerik),
  FeatureDef(route: '/collections', title: 'Koleksiyonlar', description: 'Ayetleri kaydet, listele, not al.', icon: Icons.bookmark_rounded, category: FeatureCategory.icerik),
  FeatureDef(route: '/ayah-finder', title: 'Ayet Bul', description: 'Görselden/bağlantıdan hangi ayet olduğunu bul (AI).', icon: Icons.image_search_rounded, category: FeatureCategory.icerik),

  // ── İstatistikler (1) ──
  FeatureDef(route: '/progress', title: 'İstatistiklerim', description: 'Ömür boyu okuma istatistikleri, haftalık ayet grafiği.', icon: Icons.bar_chart_rounded, category: FeatureCategory.kuran),

  // ── Araçlar (4) ──
  FeatureDef(route: '/zakat', title: 'Zekât Hesaplama', description: 'Nisab eşiği, altın/gümüş/nakit girişleri, %2,5 sonucu (canlı).', icon: Icons.calculate_rounded, category: FeatureCategory.araclar),
  FeatureDef(route: '/mosque', title: 'Cami Bul', description: 'Haritada yakın camiler, vakitleri ve yol tarifi.', icon: Icons.mosque_rounded, category: FeatureCategory.araclar),
  FeatureDef(route: '/donate', title: 'Bağış & Sadaka', description: 'Güvenilir kampanyalar, hızlı bağış, sadaka hatırlatıcısı.', icon: Icons.favorite_rounded, category: FeatureCategory.araclar),
  FeatureDef(route: '/dream', title: 'Rüya Tabiri', description: 'Klasik kaynaklara dayalı, sözlük tabanlı sembol araması.', icon: Icons.bedtime_rounded, category: FeatureCategory.araclar),
];

/// Ana sayfadaki 8'li hızlı işlem ızgarası için öne çıkan rotalar.
///
/// Seçim gerekçesi (24 özellikten neden bu 8'i): Faz 1 "günlük çekirdek"
/// döngüsü — kullanıcının HER GÜN birden çok kez döneceği eylemler önceliklidir.
///  • /prayer, /dhikr, /qibla → günde 5 vakit tekrarlanan ibadet (en yüksek sıklık)
///  • /quran, /daily-ayah     → "Anla" adımı: okuma + günlük tek-dokunuş ayet
///  • /esma, /dua             → kısa, sık açılan referans ekranları
///  • /zakat                  → tek "Araçlar" temsilcisi (yüksek niyet, mevsimsel)
/// Dışarıda bırakılanlar (stüdyo, akış, hatim, mucizeler…) ya alt-sekmeden ya da
/// "Tüm Özellikler" kataloğundan erişilir; ızgarayı 8 ile sınırlamak 4x2 dokunma
/// hedefini (≥44px) ve görsel sadeliği korur. Personalizasyon (ilgi alanına göre
/// sıralama) bilinçli ertelendi: sabit set keşfedilebilirliği ve kas hafızasını
/// korur — analytics olmadan dinamik sıralama "kayan ızgara" hissi yaratırdı.
const List<String> kQuickActionRoutes = [
  '/quran',
  '/prayer',
  '/dhikr',
  '/qibla',
  '/daily-ayah',
  '/esma',
  '/dua',
  '/zakat',
];
