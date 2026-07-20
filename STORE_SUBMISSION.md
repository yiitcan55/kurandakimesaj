# App Store gönderim dosyası

> Uygulama: **Kur'an'da ki Mesaj**  
> Bundle ID: `com.kurandakimesaj.app`  
> SKU: `KDM-IOS-001`  
> Sürüm: `1.0.0`  
> Son doğrulama: **21 Temmuz 2026**

Bu belge, kod tabanının mevcut davranışıyla eşleşen App Store Connect alanlarını ve yayın durumunu kaydeder. Mağaza metninde henüz çalışmayan video üretimi, sesli tefsir, sesli asistan, iOS widget veya paylaşım uzantısı vaat edilmemelidir.

## 1. Güncel yayın durumu

### Tamamlananlar

- [x] Bundle ID ve App Store Connect uygulama kaydı oluşturuldu.
- [x] iPhone-only hedefi ayarlandı.
- [x] `Info.plist` yalnız gerçekten kullanılan konum ve fotoğraf kitaplığı izinlerini açıklıyor.
- [x] iOS'ta Google giriş seçeneği gizlendi; böylece Sign in with Apple zorunluluğu bu sürümde tetiklenmiyor.
- [x] Topluluk gönderisi/reel/yorum için bildir ve kullanıcı engelle akışları eklendi.
- [x] Engellenen kullanıcıların içerikleri akıştan filtreleniyor.
- [x] Hesap silme akışı uygulama içinde mevcut.
- [x] 1024×1024, alfasız App Store simgesi ve iOS simge boyutları üretildi.
- [x] Gizlilik ve destek sayfaları canlı:
  - Gizlilik: <https://yiitcan55.github.io/kurandakimesaj-legal/privacy.html>
  - Destek: <https://yiitcan55.github.io/kurandakimesaj-legal/support.html>
- [x] `codemagic.yaml` ile iOS App Store derleme iş akışı hazırlandı.
- [x] `flutter analyze`: 0 sorun.
- [x] `flutter test`: 33/33 geçti.

### Gönderimden önce zorunlu kalanlar

- [ ] iPhone 6.9 inç için 1–10 gerçek uygulama ekran görüntüsü yüklenmeli. Mevcut `screenshots/` dosyaları Android ölçüsünde; App Store seti değildir.
- [ ] App Review için çalışan bir demo hesap ve parola hazırlanmalı.
- [ ] App Review iletişim adı, telefonu ve e-postası doğrulanmalı.
- [ ] Diyanet meal/metin içeriği, İslam Ansiklopedisi içeriği ve EveryAyah sesleri için dağıtım/lisans kanıtları hazır tutulmalı.
- [ ] Codemagic'te App Store Connect API anahtarı ve imzalama değişkenleri girilmeli.
- [ ] İlk IPA oluşturulup TestFlight'a yüklenmeli ve gerçek iPhone'da smoke test yapılmalı.

İlk sürüm için `What's New` alanı boş bırakılır. App Store incelemesine gönderim, TestFlight smoke testi tamamlanmadan yapılmamalıdır.

## 2. Türkçe ASO metadata paketi

### Uygulama adı

```text
Kur'an'da ki Mesaj
```

### Alt başlık

```text
Meal, namaz vakti ve kıble
```

### Anahtar kelimeler

92 karakter / 94 UTF-8 bayt:

```text
ayet,sure,dua,zikir,tesbih,ezan,ibadet,hatim,cüz,hizb,tecvid,imsakiye,oruç,esma,hadis,mushaf
```

### Tanıtım metni

```text
Kur'an'ı çevrimdışı oku, ibadetini takip et. Görsel veya kısa tilavet videosundaki ayeti bul, ayet kartını PNG olarak paylaş. Ücretsiz ve reklamsız.
```

### Açıklama

```text
Kur'an'da ki Mesaj; Kur'an okumayı, günlük ibadet takibini ve paylaşımı tek bir uygulamada buluşturur.

KUR'AN VE ÖĞRENME
• 114 surenin tamamını ve Türkçe mealini çevrimdışı okuyun.
• Ayetleri tilavet ile dinleyin; konuya göre ayet, günlük ayet ve hadis içeriklerini keşfedin.
• Sure ezberi, cüz/hizb takibi, okuma hedefi ve sure quizleriyle ilerlemenizi takip edin.
• Tecvid dersleri, peygamber kıssaları ve Esmaü'l-Hüsna içeriklerinden yararlanın.

GÜNLÜK İBADET
• Konumunuza göre namaz vakitlerini cihazınızda hesaplayın ve isteğe bağlı bildirimler kurun.
• Kıble pusulası, zikirmatik, tesbihat ve dua kitaplığını kullanın.
• Oruç ve imsakiye, hicri takvim ve dini günleri takip edin.

AYET BUL VE PAYLAŞ
• Cihazınızdaki bir görselden, desteklenen bir gönderi bağlantısından veya kısa tilavet videosundan okunan ayeti bulun.
• Arapça metin model tarafından çıkarılır; sure, ayet numarası ve meal doğrulanmış Kur'an veri setinden eşleştirilir.
• Ayetinizi şablon ve arka planla düzenleyip PNG ayet kartı olarak paylaşın.

TOPLULUK
• Ayet gönderilerini keşfedin, beğenin ve yorumlayın.
• Kişisel koleksiyonlar oluşturun ve hatim halkalarına katılın.
• Topluluk özellikleri için ücretsiz bir hesap gerekir; Kur'an ve temel ibadet araçları giriş yapmadan kullanılabilir.

DİĞER ARAÇLAR
Zekât hesaplama, cami bulma, bağış bağlantıları, rüya tabiri ve kişisel istatistikler.

Rüya yorumları ve zekât hesaplamaları bilgilendirme amaçlıdır; kesin dini hüküm veya mali danışmanlık değildir.

Uygulama ücretsiz ve reklamsızdır.
```

### Kategori ve telif

- Birincil kategori: **Reference**
- İkincil kategori: **Lifestyle**
- Telif: `2026 [App Store Connect'teki yasal hak sahibi adı]`

Apple telif işaretini arayüzde eklediği için alana ayrıca `©` yazılmaz. Yasal hak sahibi adı App Store Connect hesabından aynen alınmalı; tahmin edilmemelidir.

## 3. App Store Connect URL alanları

- Privacy Policy URL: `https://yiitcan55.github.io/kurandakimesaj-legal/privacy.html`
- Support URL: `https://yiitcan55.github.io/kurandakimesaj-legal/support.html`
- Marketing URL: ilk sürümde boş bırakılabilir.

## 4. App Privacy beyanı

Tracking: **No**. Aşağıdaki verilerin amacı **App Functionality** olarak seçilir.

| Apple veri türü | Toplanıyor | Kullanıcıya bağlı |
|---|---:|---:|
| Name | Evet | Evet |
| Email Address | Evet | Evet |
| User ID | Evet | Evet |
| Photos or Videos | Evet | Evet |
| Audio Data | Evet | Evet |
| Emails or Text Messages | Evet | Evet |
| Other User Content | Evet | Evet |
| Sensitive Info (dini tercihler/içerik) | Evet | Evet |
| Product Interaction | Evet | Evet |
| Precise Location | Evet | Hayır |

Konum namaz vakti/kıble hesabı için cihazda kullanılır; yakın cami araması açılırsa harita sağlayıcısına sorgu olarak iletilebilir. Ayet bulma için seçilen görsel Google Gemini'a; kısa video/ses ise özel Supabase Storage üzerinden Groq Whisper'a işlenmek üzere gönderilebilir. Bu akışlar gizlilik politikasında açıklanmıştır.

## 5. Yaş derecelendirmesi

Beklenen sonuç: **13+** (App Store Connect'in güncel yaş derecelendirme sistemi).

- User-Generated Content: Yes
- Social Media: Yes
- Messaging and Chat: Yes
- Unrestricted Web Access: No
- Advertising: No
- Parental Controls: No
- Age Assurance: No
- Mature or Suggestive Themes: Infrequent
- Realistic Violence: Infrequent
- Gambling, sexual content, graphic violence, drugs: None

Formun ürettiği nihai derece App Store Connect'te ayrıca doğrulanmalıdır.

## 6. App Review notu taslağı

```text
Kur'an'da ki Mesaj; çevrimdışı Kur'an/meal okuma, namaz vakti, kıble, ibadet araçları ve isteğe bağlı topluluk özellikleri sunar.

Demo hesap:
E-posta: [DEMO_EMAIL]
Parola: [DEMO_PASSWORD]

Hesap silme: Ayarlar > Hesap > Hesabı sil.

Topluluk moderasyonu: Gönderi, reel ve yorumların menüsünde Bildir ve Kullanıcıyı engelle seçenekleri vardır. Engellenen kullanıcıların içerikleri akıştan kaldırılır. Bildirimler geliştirici tarafından incelenir.

Ayet Bul veri akışı: Kullanıcının seçtiği görsel metin çıkarımı için Google Gemini'a gönderilebilir. Kısa tilavet videosu/sesi özel Supabase Storage üzerinden Groq Whisper ile çözümlenir ve geçici dosyanın silinmesi denenir. Uygulama üçüncü taraf platformlardan video indirmez.

Rüya yorumu ve zekât hesaplama özellikleri yalnız bilgilendirme amaçlıdır; kesin dini hüküm veya mali danışmanlık değildir.

İçerik lisans/izin belgeleri gerektiğinde inceleme ekibine sunulacaktır.
```

`[DEMO_EMAIL]`, `[DEMO_PASSWORD]` ve inceleme iletişim bilgileri doldurulmadan sürüm gönderilmez.

## 7. Codemagic yayın yapılandırması

İş akışı: `ios-app-store`  
Dosya: `codemagic.yaml`

Codemagic'te şu environment group'lar oluşturulmalıdır:

### `appstore_credentials`

- `APP_STORE_CONNECT_PRIVATE_KEY` — `.p8` anahtarının içeriği, Secure
- `APP_STORE_CONNECT_KEY_IDENTIFIER` — Key ID, Secure
- `APP_STORE_CONNECT_ISSUER_ID` — Issuer ID, Secure
- `CERTIFICATE_PRIVATE_KEY` — imzalama sertifikası özel anahtarı, Secure

API anahtarında en az **App Manager** yetkisi bulunmalıdır.

### `kdm_runtime`

- `SUPABASE_URL` — canlı proje URL'si
- `SUPABASE_ANON_KEY` — canlı anon/publishable key, Secure

İş akışı sırasıyla paketleri alır, analiz ve testleri çalıştırır, App Store imzalama dosyalarını hazırlar, IPA üretir ve App Store Connect'e yükler. İlk güvenli koşuda `submit_to_testflight: false` ve `submit_to_app_store: false` bırakılmıştır; bu yalnızca imzalı binary yükler, otomatik inceleme başlatmaz.

## 8. Son kontrol listesi

- [ ] Canlı gizlilik ve destek URL'leri App Store Connect'e kaydedildi.
- [ ] ASO metadata alanları kaydedildi.
- [ ] App Privacy formu tamamlandı ve yayımlandı.
- [ ] Yaş derecelendirme formu tamamlandı.
- [ ] Demo hesap ve App Review notu girildi.
- [ ] iPhone 6.9 inç ekran görüntüleri yüklendi.
- [ ] Codemagic environment group'ları oluşturuldu.
- [ ] IPA başarıyla üretildi ve App Store Connect'e yüklendi.
- [ ] TestFlight gerçek cihaz smoke testi tamamlandı.
- [ ] Lisans/izin kanıtları hazır.
- [ ] Nihai Submit for Review için ayrı işlem-anı onayı alındı.
