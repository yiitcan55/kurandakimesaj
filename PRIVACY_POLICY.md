# Gizlilik Politikası — Kur'an'da ki Mesaj

**Son güncelleme:** 21 Temmuz 2026
**Geçerli sürüm:** 1.0.0

---

## 1. Giriş

Bu Gizlilik Politikası, **Kur'an'da ki Mesaj** ("Uygulama", "biz") mobil uygulamasını kullandığınızda kişisel verilerinizin nasıl toplandığını, kullanıldığını, saklandığını ve korunduğunu açıklar. Uygulamayı kullanarak bu politikada açıklanan uygulamaları kabul etmiş olursunuz.

Uygulama sahibi / veri sorumlusu: **Eren Asan**
İletişim: **yiit55400@gmail.com**

Bu politika, 6698 sayılı **Kişisel Verilerin Korunması Kanunu (KVKK)** ve Apple App Store gerekliliklerine uygun olarak hazırlanmıştır.

---

## 2. Topladığımız Veriler ve Kullanım Amaçları

Uygulama, yalnızca işlevlerini yerine getirmek için gerekli olan verileri işler. Topladığımız veri türleri:

### 2.1 Hesap Bilgileri (isteğe bağlı — yalnızca giriş yaparsanız)
- **Toplanan:** E-posta adresi ve hesap kimliği.
- **Amaç:** Hesap oluşturma, oturum açma, koleksiyon/ilerleme verilerinizin cihazlar arası senkronizasyonu ve topluluk özelliklerinde kimliklendirme.
- **İşleyen:** Kimlik doğrulama ve veritabanı altyapımız **Supabase** (bkz. Bölüm 5).
- **Not:** Misafir (girişsiz) kullanımda hesap bilgisi toplanmaz; veriler yalnızca cihazınızda yerel olarak saklanır.

### 2.2 Konum Verisi
- **Toplanan:** Yaklaşık/kesin cihaz konumu (yalnızca uygulama kullanılırken).
- **Amaç:** Namaz vakitlerinin hesaplanması, kıble yönünün belirlenmesi ve yakındaki camilerin gösterilmesi.
- **Saklama:** Konum verisi **cihazınızda işlenir**; sunucularımızda saklanmaz ve üçüncü taraflarla paylaşılmaz.
- **İzin:** İlk kullanımda izniniz istenir; reddederseniz konuma dayalı özellikler çalışmaz, uygulamanın geri kalanı çalışmaya devam eder.

### 2.3 Ayet Bulucu Görsel ve Video İşleme
- **Toplanan:** Yalnızca sizin seçtiğiniz görsel veya kısa tilavet videosu.
- **Amaç:** Görseldeki ya da videodaki Arapça metni çıkarıp doğrulanmış Kur'an veri setinde ayet eşleştirmesi yapmak.
- **İşleme:** Görseller Supabase Edge Function üzerinden Google Gemini'ye; videolar geçici, özel Supabase Storage alanı üzerinden Groq Whisper'a iletilir.
- **Saklama:** Ayet bulma videosu işlem tamamlandığında depolama alanından silinmeye çalışılır. Uygulama mikrofon erişimi istemez ve arka planda ses kaydetmez.

### 2.4 Fotoğraf, Kamera ve Kullanıcı Tarafından Oluşturulan İçerik
- **Toplanan:** İçerik stüdyosunda veya topluluk paylaşımlarında eklediğiniz fotoğraf/video/metin.
- **Amaç:** Ayetlerden paylaşılabilir görsel/video içerik üretmeniz ve dilerseniz toplulukla paylaşmanız.
- **Saklama:** **Yalnızca siz paylaşmayı seçerseniz** içerik depolama altyapımıza (Supabase Storage) yüklenir. Aksi halde içerik cihazınızda kalır.

### 2.5 İbadet ve Öğrenme Verileri (cihazda yerel)
- **Toplanan:** Zikir sayaçları, sure ezberi, cüz/hizb ilerlemesi, okuma hedefi/serisi, favori sureler, koleksiyonlar, quiz skorları.
- **Amaç:** Kişisel ilerlemenizi takip etmek.
- **Saklama:** Bu veriler öncelikle **cihazınızda yerel olarak** (yerel veritabanı) saklanır. Giriş yaptıysanız bir kısmı hesabınıza senkronize edilebilir.

### 2.6 Bildirimler
- **Toplanan:** Bildirim izni durumu (kişisel veri içermez).
- **Amaç:** Ezan/namaz vakti, dua hatırlatıcıları ve dini gün/kandil bildirimleri. Bu bildirimler cihazınızda yerel olarak zamanlanır.

### 2.7 Toplamadığımız Veriler
- Reklam kimliği veya reklam izleme **kullanmıyoruz**.
- Verilerinizi **satmıyoruz**.
- Üçüncü taraf reklam ağlarıyla **paylaşmıyoruz**.

---

## 3. Hukuki Dayanak (KVKK)

Kişisel verilerinizi şu hukuki sebeplere dayanarak işleriz:
- **Açık rızanız** (konum, mikrofon, fotoğraf erişimi ve isteğe bağlı hesap oluşturma için).
- Bir hizmetin ifası için **gerekli olması** (giriş yaptığınızda hesabınızın çalıştırılması).
- **Meşru menfaat** (uygulamanın güvenliği ve temel işlevselliği).

---

## 4. Veri Saklama Süresi

- **Cihazda yerel veriler:** Uygulamayı silene veya verileri temizleyene kadar saklanır.
- **Hesap ve bulut verileri:** Hesabınız aktif olduğu sürece saklanır. Hesap silme talebinizde makul süre içinde silinir.

---

## 5. Üçüncü Taraf Hizmet Sağlayıcılar

Uygulama, işlevlerini sağlamak için aşağıdaki altyapı hizmetlerini kullanır:

| Hizmet | Amaç | Gizlilik politikası |
|--------|------|---------------------|
| **Supabase** | Kimlik doğrulama, veritabanı, içerik depolama | https://supabase.com/privacy |
| **Google Gemini** | Kullanıcının seçtiği görselden Arapça metin çıkarma | https://policies.google.com/privacy |
| **Groq** | Kullanıcının seçtiği kısa tilavet videosunu metne dönüştürme | https://groq.com/privacy-policy/ |
| **Apple (App Store / iOS servisleri)** | Uygulama dağıtımı ve yerel bildirimler | https://www.apple.com/legal/privacy/ |

Bu sağlayıcılar yalnızca hizmeti sunmak için gerekli verilere erişir ve kendi gizlilik politikalarına tabidir.

---

## 6. Veri Güvenliği

- Verileriniz aktarım sırasında **HTTPS/TLS şifrelemesi** ile korunur.
- Gizli anahtarlar ve API kimlik bilgileri uygulama koduna gömülmez; güvenli şekilde yönetilir.
- Yetkisiz erişime karşı veritabanı düzeyinde erişim kontrolleri (satır düzeyi güvenlik) uygulanır.
- Hiçbir yöntem %100 güvenli olmasa da verilerinizi korumak için makul teknik ve idari tedbirler alırız.

---

## 7. Çocukların Gizliliği

Uygulama 13 yaşın altındaki çocuklara yönelik değildir ve bilerek bu yaş grubundan kişisel veri toplamayız. Bir çocuğun bize veri sağladığını fark edersek sileriz.

---

## 8. Haklarınız (KVKK m. 11)

Kişisel verilerinizle ilgili şu haklara sahipsiniz:
- İşlenip işlenmediğini öğrenme ve bilgi talep etme,
- Düzeltilmesini veya silinmesini isteme,
- İşlemenin sınırlandırılmasını talep etme,
- Rızanızı geri çekme,
- Verilerinizin bir kopyasını talep etme (taşınabilirlik).

**Hesap/veri silme talebi:** Uygulamada **Ayarlar → Hesabı sil** yolunu kullanabilir veya **yiit55400@gmail.com** adresine yazabilirsiniz. Talepler makul süre içinde yanıtlanır.

---

## 9. İçerik ve Topluluk Kuralları

- Toplulukta paylaşılan içerikler kullanıcılar tarafından oluşturulur.
- Uygunsuz içeriği **bildirme** ve kullanıcıları **engelleme** imkânı sunulur.
- Dini içerikler (meal, tefsir, hadis) güvenilir kaynaklara dayanır. Rüya Tabiri ve Zekât gibi bölümler bilgilendirme amaçlıdır ve **kesin dini hüküm niteliği taşımaz**.

---

## 10. Bu Politikadaki Değişiklikler

Bu Gizlilik Politikasını zaman zaman güncelleyebiliriz. Önemli değişikliklerde uygulama içinden veya bu sayfada bilgilendirme yaparız. "Son güncelleme" tarihi en güncel sürümü gösterir.

---

## 11. İletişim

Gizlilikle ilgili sorularınız veya talepleriniz için:

- **E-posta:** yiit55400@gmail.com
- **Uygulama sahibi:** Eren Asan
- **Ülke:** Türkiye

---

*Bu belge bilgilendirme amaçlıdır ve hukuki danışmanlık yerine geçmez. Yayın öncesi bir hukuk danışmanına gözden geçirtmeniz önerilir.*
