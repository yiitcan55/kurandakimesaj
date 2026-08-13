# iOS Share Extension Kurulumu — Ayet Bul

> ## ⚠️ DURUM: MANUEL İŞ — bu sürümde kurulmadı
>
> - Bu adımların tamamı **macOS + Xcode** gerektirir. **Windows'ta yapılamaz** (Xcode target
>   ekleme, App Group capability, imzalama). Kod tarafında yapılacak bir şey yoktur; iş
>   tamamen Xcode proje yapılandırmasıdır.
> - **iOS kullanıcısı ENGELLENMİYOR.** Ayet Bul ekranındaki her iki giriş yolu da iOS'ta
>   sorunsuz çalışır: **“Video Seç”** / **“Galeriden Seç”** (galeri erişimi) ve
>   **“Bağlantı Yapıştır”** (panodan URL). Eksik olan tek şey, diğer uygulamaların
>   paylaş menüsünde **“Kur'an'da ki Mesaj”** satırının görünmesidir.
> - Yani bu **bloklayıcı değil, bir kolaylık iyileştirmesidir.** App Store gönderimi için
>   şart değildir.
> - **Android tarafı zaten çalışıyor** (`android/app/src/main/AndroidManifest.xml` içinde
>   3 adet `ACTION_SEND` intent-filter: text, image, video).

Referans: `receive_sharing_intent` **1.8.1** (pubspec.yaml'daki sürüm) README → “iOS”.
Sürüm yükseltilirse README adımları tekrar karşılaştırılmalıdır.

---

## 1. Share Extension target ekle
Xcode → File → New → Target → **Share Extension**.
- Product Name: `ShareExtension` (Podfile'da aynı ad birebir kullanılacak — 5. adım)
- Bundle ID: `com.kurandakimesaj.app.ShareExtension`
- “Activate scheme” sorusuna **Cancel** (ana şema kalsın).
- **Deployment target'ı Runner ile aynı yap: iOS 14.0** (`IPHONEOS_DEPLOYMENT_TARGET = 14.0`).
  Xcode yeni target'a daha yüksek bir değer atarsa elle düşür.

## 2. App Group + `CUSTOM_GROUP_ID`
Her İKİ target'ta da (Runner + ShareExtension) → Signing & Capabilities → **+ App Groups**:
- Grup: `group.com.kurandakimesaj.app`
  (Ana ekran widget'ıyla aynı grup — bkz. `ios/KuranWidget/SETUP.md`. Aynı grubu kullanmak sorun değil.)

Ayrıca her İKİ target'ta da **Build Settings → + → Add User-Defined Setting**:
- Ad: `CUSTOM_GROUP_ID`, değer: `group.com.kurandakimesaj.app`

Paket, grup kimliğini Info.plist'teki `AppGroupId` anahtarından okur; bu anahtar
`$(CUSTOM_GROUP_ID)`e bağlanır (3. ve 4. adım). Bu adım atlanırsa paylaşılan dosya
host app'e hiç ulaşmaz.

## 3. ShareExtension/Info.plist
Xcode'un ürettiği plist'i aşağıdaki gibi düzenle. **`PHSupportedMediaTypes` ve
`NSExtensionActivationRule` birlikte gerekir** — video paylaşımı için ikisinde de
video kaydı bulunmalıdır.

```xml
<key>AppGroupId</key>
<string>$(CUSTOM_GROUP_ID)</string>
<key>CFBundleShortVersionString</key>
<string>$(FLUTTER_BUILD_NAME)</string>
<key>CFBundleVersion</key>
<string>$(FLUTTER_BUILD_NUMBER)</string>
<key>NSExtension</key>
<dict>
    <key>NSExtensionAttributes</key>
    <dict>
        <!-- Fotoğraflar uygulamasından paylaşımda hangi medya türleri listelenecek -->
        <key>PHSupportedMediaTypes</key>
        <array>
            <string>Image</string>
            <string>Video</string>
        </array>
        <key>NSExtensionActivationRule</key>
        <dict>
            <!-- Görsel (ekran görüntüsü, kaydedilmiş kare) -->
            <key>NSExtensionActivationSupportsImageWithMaxCount</key>
            <integer>1</integer>
            <!-- Video (galerideki tilavet klibi, ekran kaydı) — YENİ -->
            <key>NSExtensionActivationSupportsMovieWithMaxCount</key>
            <integer>1</integer>
            <!-- Bağlantı (Safari / Instagram / TikTok “Paylaş → Bağlantıyı kopyala”) -->
            <key>NSExtensionActivationSupportsWebURLWithMaxCount</key>
            <integer>1</integer>
            <!-- Düz metin -->
            <key>NSExtensionActivationSupportsText</key>
            <true/>
        </dict>
    </dict>
    <key>NSExtensionMainStoryboard</key>
    <string>MainInterface</string>
    <key>NSExtensionPointIdentifier</key>
    <string>com.apple.share-services</string>
</dict>
```

`MaxCount` değerleri **bilerek `1`** — uygulama tek öğe işler (bkz. “Bilinen sınırlamalar”).
`CFBundleShortVersionString`/`CFBundleVersion` Runner ile aynı Flutter değişkenlerine
bağlanmazsa App Store Connect yüklemesi sürüm uyuşmazlığı hatası verir.

## 4. Runner/Info.plist — `AppGroupId` + URL şeması
`ios/Runner/Info.plist` dosyasına ekle:

```xml
<key>AppGroupId</key>
<string>$(CUSTOM_GROUP_ID)</string>
```

`CFBundleURLTypes` dizisine (dosyada zaten var — `homeWidget` ve `io.kurandakimesaj`
girdilerinin yanına) yeni bir sözlük ekle:

```xml
<dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
        <string>ShareMedia-$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    </array>
</dict>
```

Bu, `ShareMedia-com.kurandakimesaj.app` şemasına çözülür. `NSPhotoLibraryUsageDescription`
zaten mevcut, tekrar eklemeye gerek yok.

## 5. Podfile — iç içe target
`ios/Podfile` bu repoda **yok**; macOS'ta ilk `flutter build ios` / `pod install`
çalıştırıldığında üretilir. Üretildikten sonra `target 'Runner'` bloğunun **içine** ekle:

```ruby
target 'Runner' do
  use_frameworks!
  use_modular_headers!

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))

  target 'ShareExtension' do
    inherit! :search_paths
  end
end
```

Buradaki `'ShareExtension'` metni, 1. adımdaki Xcode target adıyla **birebir aynı** olmalı.
Ardından `pod install`.

## 6. Build Phases sırası
Runner target → Build Phases → **`Embed Foundation Extensions`** fazını
**`Thin Binary`nin ÜSTÜNE** taşı. (Eski Xcode sürümlerinde fazın adı
`Embed App Extensions`tır.) Bu yapılmazsa derleme
`No such module 'receive_sharing_intent'` hatası verir.

## 7. ShareViewController.swift
Xcode'un ürettiği sınıfın gövdesini sil ve `RSIShareViewController`dan türet:

```swift
import receive_sharing_intent

class ShareViewController: RSIShareViewController {
    // Otomatik yönlendirmeyi kapatmak istersen false döndür (varsayılan: true).
    // override func shouldAutoRedirect() -> Bool { return true }
}
```

Kendi UI'ını yazma; taban sınıf paylaşılan öğeyi App Group konteynerine yazıp host app'i
`ShareMedia-...` şemasıyla açar.

## 8. Doğrulama (gerçek cihaz, simülatörde paylaş menüsü güvenilmez)
1. Fotoğraflar → bir **görsel** → Paylaş → **Kur'an'da ki Mesaj**
2. Fotoğraflar → bir **video** → Paylaş → **Kur'an'da ki Mesaj**
3. Safari / Instagram → **Bağlantıyı paylaş** → **Kur'an'da ki Mesaj**

Üçünde de uygulama açılıp `/ayah-finder` ekranına gidip aramayı **otomatik başlatmalı**
(`lib/app/app.dart` → `_onShared`).

---

## Bilinen sınırlamalar (bu sürümde kabul edildi)

- **Çoklu paylaşım (`SEND_MULTIPLE`) desteklenmiyor.** `_onShared` yalnızca `files.first`
  öğesini alır; birden fazla öğe paylaşılırsa geri kalanı sessizce yok sayılır. Bu yüzden
  plist'teki `MaxCount` değerleri `1`e sabitlendi — iOS kullanıcıya en baştan tek öğe
  seçtirir, böylece “gönderdim ama işlenmedi” şaşkınlığı oluşmaz. Android tarafında da
  `SEND_MULTIPLE` intent-filter'ı bilerek eklenmedi.
- **Dosya (`NSExtensionActivationSupportsFileWithMaxCount`) desteklenmiyor.** Ayet Bul
  yalnızca görsel/video/bağlantı işler; genel dosya paylaşımı kapsam dışıdır.

## Sorun giderme
- `No such module 'receive_sharing_intent'` → 6. adım (Build Phases sırası).
- Extension derlenmiyor → ShareExtension target'ının Build Settings → `Other Linker Flags`
  altındaki, ana projeden miras kalan CocoaPods girdilerini temizle.
- Paylaş menüsünde uygulama görünmüyor ama derleme başarılı → `NSExtensionActivationRule`
  anahtarları yanlış target'ın plist'ine yazılmış olabilir; `ShareExtension/Info.plist`
  olduğunu doğrula.

> Dart tarafı hazır: `ReceiveSharingIntent.instance.getMediaStream()/getInitialMedia()`
> dinleyicisi `lib/app/app.dart`'ta; gelen görsel/video/URL `sharedAyahInputProvider`'a
> yazılır ve `AyahFinderScreen` tüketir. Bu kurulum yapıldığında ek Dart değişikliği
> gerekmez.
