# Kalıcılık Politikası (Persistence Decision Matrix)

Bu uygulamada durum 3 mekanizmaya yayılır. "X nerede yaşamalı?" sorusunun tek
cevabı olsun diye karar matrisi:

| Veri türü | Mekanizma | Neden | Örnek |
|---|---|---|---|
| **Salt-okunur dini içerik** (seed) | **drift** (seed tabloları) | Offline-first, sorgulanabilir, uygulamayla paketli; şema yükseltmede güvenle sıfırlanıp yeniden seed edilir | Surahs, Ayahs, Esma, Duas, TopicalAyahs, Stories, Miracles, Tajweed, DreamSymbols |
| **Kullanıcı üretimi kalıcı veri** | **drift** (kullanıcı tabloları) | Yapısal, sorgulanabilir, çevrimdışı yazılır, online iken Supabase'e senkron; **şema yükseltmede KORUNUR** (`_userTables`, `app_database.dart`) | Collections, Memorizations, JuzProgress, DhikrCounters |
| **Tekil ayar / bayrak / küçük liste** | **SharedPreferences** | Şema/migration yok; tek anahtar yeterli | AppSettings (meal/ilgi/bildirim), PRO bayrağı, render işleri (`render_jobs`) |
| **Kaynağı sunucu olan veri** | **Supabase** (cache yereli) | Çok-cihaz, gerçek zamanlı; istemci null-guard'lı (`SupabaseGateway`) | feed_posts, mesajlar, profil, hatim halkaları, render durumu |
| **Geçici / oturum-içi** | **in-memory** (Notifier/State) | Restart'ta kaybı kabul edilebilir | Aktif sohbet taslağı, AI mesaj geçmişi (henüz) |

## Kurallar
1. **Seed ≠ kullanıcı verisi.** drift'te ikisi `_userTables` ile ayrılır; içerik
   güncellemesi (seed yükseltme) **asla** ezber/koleksiyon ilerlemesini silmez.
2. **Kullanıcı tablosuna sütun eklersen** `app_database.dart` `onUpgrade`'inde
   açık `m.addColumn(...)` ile migrate et — IF NOT EXISTS eski tabloyu olduğu
   gibi bırakır.
3. **Supabase'e dokunan her erişim** `SupabaseGateway` üzerinden gider; ham
   `Supabase.instance` çağrısı yapma (guard'ı unutma riski).
4. **in-memory durum**, restart'ta kaybı gerçekten kabul edilebilirse kullanılır;
   "ertesi gün geri dön" davranışı gereken hiçbir şey in-memory olamaz.
