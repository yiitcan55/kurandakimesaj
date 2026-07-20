# iOS Ana Ekran Widget'ı — Xcode Kurulumu

Swift kaynak + plist + entitlement dosyaları hazır (`ios/KuranWidget/`). Bir
Widget Extension **target'ı** ise `.pbxproj`'a el değmeden güvenle eklenemez;
aşağıdaki adımları **macOS + Xcode** ile bir kez yap. (Android tarafı tamamen
hazır ve çalışıyor; bu yalnızca iOS içindir.)

## 1. Widget Extension target ekle
1. `open ios/Runner.xcworkspace`
2. **File → New → Target… → Widget Extension**
3. Product Name: **KuranWidget** · Dil: Swift · "Include Live Activity" KAPALI ·
   "Include Configuration Intent" KAPALI
4. Activate scheme sorulursa **Cancel** (Runner şeması kalsın).
5. Xcode'un oluşturduğu varsayılan `KuranWidget.swift` ve `Assets`/`Info.plist`
   dosyalarını sil; bunun yerine bu klasördeki dosyaları kullan:
   - `KuranWidgets.swift` → KuranWidget target'ına ekle (Target Membership ✔)
   - `Info.plist` → target'ın Info.plist'i olarak ayarla
     (Build Settings → Packaging → Info.plist File = `KuranWidget/Info.plist`)

## 2. App Group (paylaşılan veri) — HER İKİ target'ta
App Group id: **`group.com.kurandakimesaj.app`** (Dart tarafıyla birebir aynı).

1. **Runner** target → Signing & Capabilities → **+ Capability → App Groups** →
   `group.com.kurandakimesaj.app` ekle. (Entitlements: `Runner/Runner.entitlements`)
2. **KuranWidget** target → aynı şekilde App Groups → aynı grubu ekle.
   (Entitlements: `KuranWidget/KuranWidget.entitlements`)
3. Apple Developer hesabında bu App Group'un iki bundle id için de etkin
   olduğundan emin ol (Xcode otomatik halleder; "Automatically manage signing").

## 3. Deep-link (zaten kodda hazır)
- Widget'lar `homeWidget://prayer` ve `homeWidget://ayah` ile açılır.
- `Runner/Info.plist` içine `homeWidget` URL şeması eklendi.
- Flutter tarafı (`app.dart`) bu URI'leri `/prayer` ve `/daily-ayah`'a yönlendirir.

## 4. Doğrula
```bash
flutter build ios --debug --no-codesign   # veya gerçek cihazda flutter run
```
- Uygulamayı bir kez aç (Ana Sayfa → veri App Group'a yazılır).
- Ana ekrana **Ezan Saati** / **Günün Ayeti** widget'ını ekle.
- Widget'a dokun → uygulamada ilgili ekran açılmalı.

## Notlar
- **Domain kuralı #2:** Ayet widget'ında Arapça hat gösterilmez; yalnızca Türkçe
  meal + kaynak. Amiri Quran fontu extension'a paketlenmediğinden mushaf hattını
  yanlış fontla render etmemek için bilinçli tercih.
- RemoteViews/WidgetKit canlı saniye sayacı çalıştırmaz; widget "sıradaki vakit +
  saat" gösterir. Geri sayım uygulama içi kartta sürüyor.
- Arka planda otomatik yenileme yarım saatte bir (WidgetKit timeline policy).

## Faz 4 — iOS arka plan yenileme (opsiyonel, ekstra native ayar)
`workmanager` ile periyodik ezan yenilemesi **Android'de hazır ve çalışıyor**.
iOS'ta BGTaskScheduler gerektirir:
1. **Runner** target → Signing & Capabilities → **+ Background Modes** →
   "Background fetch" ve "Background processing" işaretle.
2. `Runner/Info.plist`'e `BGTaskSchedulerPermittedIdentifiers` dizisi ekle
   (workmanager task id'si ile).
3. `AppDelegate.swift` içinde `WorkmanagerPlugin.registerPeriodicTask(...)` /
   `registerBGProcessingTask(...)` çağır (workmanager_apple README'sine göre).
Bu adımlar yapılmazsa iOS'ta yalnızca WidgetKit'in 30 dk'lık timeline'ı + uygulama
açılış senkronu devrede kalır (uygulama tamamen yine de çalışır).
