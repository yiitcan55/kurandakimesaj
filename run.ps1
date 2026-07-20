# Uygulamayı env.json'daki tüm --dart-define değerleriyle çalıştırır.
# Kullanım:  ./run.ps1            (debug)
#            ./run.ps1 --release  (ekstra argümanlar olduğu gibi iletilir)
flutter run --dart-define-from-file=env.json @args
