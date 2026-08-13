import 'package:flutter/material.dart';

import '../domain/models.dart';

/// Bir özellik ekranının tanımı — route, başlık, açıklama, ikon, kategori.
/// Tek kaynak: Tüm Özellikler kataloğunu, placeholder ekranları ve router'ı
/// besler.
///
/// [description] alanları YAZILI ama uzun süre hiçbir ekranda gösterilmiyordu;
/// ana sayfa metin öncelikli satırlara geçince kullanılmaya başlandı.
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

/// 26 özelliğin tam kataloğu. Bölüm başlıklarındaki sayılar kayıt sayısıyla
/// BİREBİR eşleşir — eşleşmezse ya sayı ya kayıt yanlıştır (eskiden başlık 24,
/// gerçek 26; Kur'an 8 yazıp 10 tutuyordu).
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

  // ── Kur'an & Öğrenme (10) ──
  FeatureDef(route: '/quran', title: 'Kur\'an Okuma', description: 'Arapça hero tipografi, meal & tefsir, sesli okuma, sepya mod.', icon: Icons.menu_book_rounded, category: FeatureCategory.kuran),
  FeatureDef(route: '/daily-ayah', title: 'Günlük Ayet & Hadis', description: 'Her gün yeni ayet ve hadis, paylaşıma hazır.', icon: Icons.wb_sunny_rounded, category: FeatureCategory.kuran),
  FeatureDef(route: '/topical', title: 'Konuya Göre Ayet', description: 'Ruh haline göre (Sabır, Huzur, Umut…) ayet önerisi.', icon: Icons.psychology_rounded, category: FeatureCategory.kuran),
  FeatureDef(route: '/miracles', title: 'Kuran Mucizeleri', description: 'Bilimsel, astronomi, embriyoloji, tarihi, sayısal kategoriler.', icon: Icons.science_rounded, category: FeatureCategory.kuran),
  FeatureDef(route: '/memorize', title: 'Sure Ezberi', description: 'Hıfz takibi, ilerleme yüzdesi, tekrar planlayıcı.', icon: Icons.school_rounded, category: FeatureCategory.kuran),
  FeatureDef(route: '/juz-tracker', title: 'Cüz / Hizb Takip', description: 'Günlük okuma hedefi, 30 cüz haritası, okuma serisi.', icon: Icons.donut_large_rounded, category: FeatureCategory.kuran),
  FeatureDef(route: '/stories', title: 'Peygamber Kıssaları', description: 'Kategorili, kısa okuma süreli anlatımlar, sesli seçenek.', icon: Icons.history_edu_rounded, category: FeatureCategory.kuran),
  FeatureDef(route: '/tajweed', title: 'Tecvid Dersleri', description: 'Kurallar, Arapça örnek, sesli telaffuz, mini quiz.', icon: Icons.record_voice_over_rounded, category: FeatureCategory.kuran),
  FeatureDef(route: '/quiz', title: 'Sure Quiz', description: 'Sure adları, ayet sayıları, iniş yerleri ve anlamlarını test eden 10 soruluk quiz.', icon: Icons.quiz_rounded, category: FeatureCategory.kuran),
  // Okuma istatistiği bir Kur'an ekranıdır — eskiden "İstatistikler (1)" diye
  // ayrı bir bölüm başlığı altındaydı ama böyle bir FeatureCategory yok;
  // hayalet başlık, kategori sayılarının tutmamasının sebebiydi.
  FeatureDef(route: '/progress', title: 'İstatistiklerim', description: 'Ömür boyu okuma istatistikleri, haftalık ayet grafiği.', icon: Icons.bar_chart_rounded, category: FeatureCategory.kuran),

  // ── İçerik & Topluluk (4) ──
  FeatureDef(route: '/studio', title: 'Ayet Kartı Stüdyosu', description: 'Şablon + arka plan + metin ile paylaşılabilir ayet kartı.', icon: Icons.photo_filter_rounded, category: FeatureCategory.icerik),
  FeatureDef(route: '/khatm', title: 'Hatim Halkaları', description: 'Grupça hatim, cüz dağıtımı, ortak ilerleme.', icon: Icons.groups_rounded, category: FeatureCategory.icerik),
  FeatureDef(route: '/collections', title: 'Koleksiyonlar', description: 'Ayetleri kaydet, listele, not al.', icon: Icons.bookmark_rounded, category: FeatureCategory.icerik),
  FeatureDef(route: '/ayah-finder', title: 'Ayet Bul', description: 'Görselden/bağlantıdan hangi ayet olduğunu bul (AI).', icon: Icons.image_search_rounded, category: FeatureCategory.icerik),

  // ── Araçlar (4) ──
  FeatureDef(route: '/zakat', title: 'Zekât Hesaplama', description: 'Nisab eşiği, altın/gümüş/nakit girişleri, %2,5 sonucu (canlı).', icon: Icons.calculate_rounded, category: FeatureCategory.araclar),
  FeatureDef(route: '/mosque', title: 'Cami Bul', description: 'Haritada yakın camiler, vakitleri ve yol tarifi.', icon: Icons.mosque_rounded, category: FeatureCategory.araclar),
  FeatureDef(route: '/donate', title: 'Bağış & Sadaka', description: 'Güvenilir kampanyalar, hızlı bağış, sadaka hatırlatıcısı.', icon: Icons.favorite_rounded, category: FeatureCategory.araclar),
  FeatureDef(route: '/dream', title: 'Rüya Tabiri', description: 'Klasik kaynaklara dayalı, sözlük tabanlı sembol araması.', icon: Icons.bedtime_rounded, category: FeatureCategory.araclar),
];

/// Ana sayfanın "Keşfet" bölümündeki metin öncelikli kısayol satırları.
///
/// Seçim ölçütü (26 özellikten neden bu 4'ü): **sayfanın üstüyle mükerrer
/// olmayanlar**. Eski 8'li ızgara `/prayer`, `/dhikr`, `/qibla`, `/daily-ayah`'ı
/// da içeriyordu; oysa aynı dört hedef sayfanın en üstünde zaten namaz şeridi,
/// istatistik kartı, Kıble/Cami satırı ve Günün Ayeti hero'su olarak duruyor —
/// kısayol onları keşfedilebilir yapmıyor, yalnızca tekrar ediyordu.
/// Kalan dört rota dört modülü de temsil eder ve ana sayfada başka hiçbir
/// yerden tek dokunuşla açılmaz:
///  • /quran        → "Anla" adımının ana girişi (Kur'an & Öğrenme)
///  • /esma, /dua   → kısa, sık açılan referans ekranları (İbadet & Günlük)
///  • /zakat        → tek "Araçlar" temsilcisi (yüksek niyet, mevsimsel)
/// Geri kalan 22 özelliğe "Tüm Özellikler" kataloğundan erişilir.
///
/// Sunum artık ikon-kutusu ızgarası DEĞİL, [FeatureDef.description] gösteren
/// metin öncelikli satırlardır (DESIGN.md: "ikon-daire ızgarası yok"). Sabit
/// hücre yüksekliği de kalmadı: satırlar içeriğe uyar, yazı ölçeği büyüyünce
/// taşmaz. Personalizasyon bilinçli ertelendi — sabit set kas hafızasını korur.
const List<String> kQuickActionRoutes = ['/quran', '/esma', '/dua', '/zakat'];
