# iOS Share Extension Kurulumu — Ayet Bul (Faz 3)

> Bu adımlar **macOS + Xcode** gerektirir; Windows'ta yapılamaz. Android paylaşımı
> (`AndroidManifest.xml` intent-filter'ları) zaten çalışır. iOS'ta paylaş menüsü
> bu kurulum yapılana kadar **görünmez** — galeri ve bağlantı yolu iOS'ta config'siz
> çalışmaya devam eder.

Referans: `receive_sharing_intent` paketi README → "iOS Share Extension".

## 1. Share Extension target ekle
Xcode → File → New → Target → **Share Extension**.
- Product Name: `ShareExtension`
- Bundle ID: `com.kurandakimesaj.app.ShareExtension`
- "Activate scheme" sorusuna **Cancel** (ana şema kalsın).

## 2. App Group (host app + extension ortak)
Her İKİ target'ta da (Runner + ShareExtension) → Signing & Capabilities → **+ App Groups**:
- Grup: `group.com.kurandakimesaj.app`

(Bu grup ana ekran widget'ı kurulumuyla aynı olabilir — bkz. `ios/KuranWidget/SETUP.md`. Aynı grubu kullanmak sorun değildir.)

## 3. ShareViewController.swift
Paket README'sindeki `ShareViewController` örneğini olduğu gibi kopyala. Özet: paylaşılan
görsel/URL'yi App Group konteynerine yazar ve host app'i `ShareMedia-$(bundleId)` URL
şemasıyla açar.

## 4. Info.plist — ShareExtension/Info.plist
`NSExtension > NSExtensionAttributes > NSExtensionActivationRule` ile görsel + URL kabul et:

```xml
<key>NSExtensionActivationRule</key>
<dict>
    <key>NSExtensionActivationSupportsImageWithMaxCount</key>
    <integer>1</integer>
    <key>NSExtensionActivationSupportsWebURLWithMaxCount</key>
    <integer>1</integer>
    <key>NSExtensionActivationSupportsText</key>
    <true/>
</dict>
```

## 5. Runner/Info.plist — URL şeması + custom scheme
`CFBundleURLTypes` altına host app'in geri açılması için şema ekle (README'deki
`ShareMedia-com.kurandakimesaj.app`).

## 6. Doğrulama
Gerçek cihazda: Fotoğraflar / Safari → Paylaş → **Kur'an'da ki Mesaj** → uygulama
`/ayah-finder` ekranını otomatik açıp aramayı başlatmalı (`app.dart` `_onShared`).

> Dart tarafı hazır: `ReceiveSharingIntent.instance.getMediaStream()/getInitialMedia()`
> dinleyicisi `lib/app/app.dart`'ta; gelen görsel/URL `sharedAyahInputProvider`'a yazılıp
> AyahFinderScreen tüketir.
