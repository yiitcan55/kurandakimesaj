# App Store gönderim dosyası

> Uygulama: **Kur'an'da ki Mesaj**  
> Bundle ID: `com.kurandakimesaj.app` · SKU: `KDM-IOS-001` · Sürüm: `1.0.0`  
> Son doğrulama: **4 Ağustos 2026**

Bu belge, kod tabanının mevcut davranışıyla eşleşen App Store Connect alanlarını ve yayın durumunu kaydeder. Mağaza metninde henüz çalışmayan video üretimi, sesli tefsir, sesli asistan, iOS widget veya paylaşım uzantısı vaat edilmemelidir.

## 1. Gönderim durumu

**4 Ağustos 2026 güncellemesi — 1.0.0 (4) yeniden incelemede.** 1.0.0 (2) **Guideline 1.2 (User-Generated Content)** gerekçesiyle reddedilmişti (gönderim `cf08e6a4-b956-46b3-9064-2ecc40fa5742`, inceleme 24 Tem, cihaz iPad Air 11" M3). Apple beş önlem istedi: kayıt/giriş öncesi EULA onayı, uygunsuz içerik filtreleme, içerik bildirme, kullanıcı engelleme, bildirimlere 24 saat içinde müdahale — ayrıca bunların **fiziksel cihazda çekilmiş ekran kaydıyla** gösterilmesi.

Yapılanlar:

- [x] Codemagic `iOS App Store` iş akışı `main` / commit `b210eb3` ile çalıştı (build index 4, ID `6a710f3cc529f72d91069095`, Mac mini M2, 6m54s, `finished`; post-processing hatası yok). İmzalı IPA 30.49 MB.
- [x] App Store Connect'e yüklendi: **Version 1.0.0, Build (4)** — `Complete` (4 Ağu 01:06). `pubspec.yaml` `1.0.1+4` olsa da binary 1.0.0 (4) olarak göründüğü için inflight 1.0.0 sürümüne doğrudan atanabildi.
- [x] Sürümdeki **eski Build 2 çıkarılıp Build 4 atandı**.
- [x] **App Review Notes** İngilizce olarak Guideline 1.2'nin beş maddesine göre yeniden yazıldı: zorunlu EULA onay kutusu (kayıt/giriş engellenir), `pending/approved/rejected` moderasyon durumu, "Bildir", "Kullanıcı engelle" + Ayarlar → Engellenen Kullanıcılar, 24 saat taahhüdü, demo hesap ve ekran yolları. Kaydedildi (Save → disabled).
- [x] **Redde yanıt** Resolution Center'dan gönderildi (2690 karakter) + **ekran kaydı eklendi** (`apple review.mp4`, 2.6 MB; EULA onayı → Bildir → Kullanıcı engelle sırasıyla).
- [x] **Resubmit to App Review** yapıldı → sürüm yeniden incelemede.

Notlar: ASC'nin "Attach File" alanı programatik yüklemeyi kabul etmiyor, ek dosya elle seçilmek zorunda. Ekran kaydının kalıcı yeri Apple'ın istediği gibi App Review Information → Notes alanıdır; sonraki gönderimlerde kayıt oraya da eklenmelidir.

**23 Temmuz 2026 güncellemesi:** Codemagic `ios-app-store` iş akışı başarıyla çalıştı (build #2, commit `b210eb3`, 11m20s). İmzalı IPA (30.49 MB) üretilip App Store Connect'e yüklendi; ASC'de **Version 1.0.0, Build (2)** olarak göründü (Processing).

Çözülen engelleyiciler:

- [x] `com.kurandakimesaj.app` için App Store provisioning profile Apple Developer Portal'da oluşturuldu ve Codemagic Code signing identities'e `kurandakimesaj-distribution` olarak çekildi (sertifika: `deyiver-distribution`, son kullanım 02 May 2027).
- [x] Codemagic app ayarlarında `kdm_runtime` grubu oluşturuldu; `SUPABASE_URL` + `SUPABASE_ANON_KEY` (Secure) eklendi. (Kişisel hesaplarda global gruplar kaldırıldığı için app seviyesinde.)
- [x] İmzalı IPA üretilip App Store Connect'e yüklendi (Build 2, Processing).
- [x] iPhone 6.5" ekran görüntüleri yüklü (6/10) — App Store için yeterli.
- [x] App Review demo hesabı çalışıyor (`test@gmail.com`); Supabase Auth `signInWithPassword` HTTP 200 döndürdü, inceleme notuna girildi.
- [x] `ios/Runner.xcodeproj`: `IPHONEOS_DEPLOYMENT_TARGET` 13.0 → 14.0 (workmanager_apple iOS ≥14.0 gerektiriyordu; ilk build burada patlamıştı).

Gönderimden önce kalanlar (kullanıcı aksiyonu):

- [x] Apple işlemeyi bitirince (Processing → hazır) build sürüme eklenmeli. *(4 Ağu: Build 4 atandı.)*
- [ ] TestFlight'ta gerçek iPhone ile smoke test yapılmalı. *(4 Ağu itibarıyla hâlâ yapılmadı; doğrulama Android cihazda — SM S731B — yapıldı.)*
- [ ] Diyanet meal/metin, İslam Ansiklopedisi içeriği ve EveryAyah sesleri için dağıtım/lisans kanıtları hazır tutulmalı; Content Rights beyanı kanıt görülmeden işaretlenmemeli.
- [x] Nihai Submit for Review için ayrı işlem-anı onayı alınmalı. *(4 Ağu: kullanıcı redde yanıtı ekran kaydıyla gönderip Resubmit'e bastı.)*

İlk sürümde `What's New` alanı boş bırakılır. (Codemagic iş akışı `submit_to_app_store: false` ile yalnız binary yükler; incelemeyi başlatan işlem App Store Connect'te elle yapılır.)

## 2. Tamamlananlar

- Bundle ID, App Store Connect uygulama kaydı ve iPhone-only hedef ayarlandı.
- ASO metadata (ad, alt başlık, açıklama, anahtar kelimeler), kategoriler, sürüm numarası, telif ve inceleme notları App Store Connect'e kaydedildi.
- App Privacy beyanı yayımlandı; gizlilik ve kullanıcı tercihleri URL'leri kaydedildi.
- Yaş derecelendirme formu kaydedildi; nihai derece **13+**.
- App Review iletişim adı, telefonu ve e-postası kaydedildi.
- Gizlilik ve destek sayfaları canlı (bkz. §4).
- `Info.plist` yalnız gerçekten kullanılan konum ve fotoğraf kitaplığı izinlerini açıklıyor.
- iOS'ta Google giriş seçeneği gizlendi; Sign in with Apple zorunluluğu bu sürümde tetiklenmiyor.
- Moderasyon: gönderi/reel/yorum için bildir ve kullanıcı engelle akışları eklendi; engellenen kullanıcıların içerikleri akıştan filtreleniyor; hesap silme uygulama içinde mevcut.
- 1024×1024, alfasız App Store simgesi ve iOS simge boyutları üretildi.
- `codemagic.yaml` ile iOS App Store iş akışı hazırlandı; Codemagic özel GitHub deposuna bağlandı; `codemagic_appstore` Apple entegrasyonu ve `deyiver-distribution` dağıtım sertifikası iş akışına bağlandı.
- `flutter analyze`: 0 sorun · `flutter test`: 33/33 geçti.

## 3. Türkçe ASO metadata paketi

### Uygulama adı — 18/30 karakter

```text
Kur'an'da ki Mesaj
```

### Alt başlık — 26/30 karakter

```text
Meal, namaz vakti ve kıble
```

### Anahtar kelimeler — 92/100 karakter (94 UTF-8 bayt)

```text
ayet,sure,dua,zikir,tesbih,ezan,ibadet,hatim,cüz,hizb,tecvid,imsakiye,oruç,esma,hadis,mushaf
```

### Tanıtım metni — 148/170 karakter

```text
Kur'an'ı çevrimdışı oku, ibadetini takip et. Görsel veya kısa tilavet videosundaki ayeti bul, ayet kartını PNG olarak paylaş. Ücretsiz ve reklamsız.
```

### Açıklama — 4.000 karakter sınırının altında

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
- Telif: `2026 Eren Asan`

Apple telif işaretini arayüzde eklediği için alana ayrıca `©` yazılmaz. `Eren Asan` adı App Store Connect'teki hesap sahibi alanından doğrulanmıştır.

## 4. App Store Connect alanları

### URL'ler

- Privacy Policy URL: `https://yiitcan55.github.io/kurandakimesaj-legal/privacy.html`
- Support URL: `https://yiitcan55.github.io/kurandakimesaj-legal/support.html`
- Marketing URL: ilk sürümde boş bırakılabilir.

### Yaş derecelendirmesi

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

## 5. App Privacy beyanı

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

Codemagic hesabındaki mevcut kaynaklar kullanılır:

- Apple Developer Portal entegrasyonu: `codemagic_appstore`
- Apple Distribution sertifikası: `deyiver-distribution`
- App Store Connect kimlik doğrulaması: `auth: integration`

Bu nedenle ayrı `appstore_credentials` environment grubuna veya yeni bir `.p8` yüklemesine gerek yoktur. İş akışı gerekli API değişkenlerini entegrasyondan alır. `ios_signing` yapılandırması `app_store` dağıtım türü ve `com.kurandakimesaj.app` bundle ID'siyle eşleşen sertifika/profili Codemagic Code signing identities alanından alır.

### `kdm_runtime`

- `SUPABASE_URL` — canlı proje URL'si
- `SUPABASE_ANON_KEY` — canlı anon/publishable key, Secure

İş akışı sırasıyla paketleri alır, analiz ve testleri çalıştırır, App Store imzalama dosyalarını hazırlar, IPA üretir ve App Store Connect'e yükler. İlk güvenli koşuda `submit_to_testflight: false` ve `submit_to_app_store: false` bırakılmıştır; bu yalnızca imzalı binary yükler, otomatik inceleme başlatmaz.
