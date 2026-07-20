@echo off
REM Uygulamayi env.json'daki tum --dart-define degerleriyle calistirir.
REM Kullanim:  run.bat            (debug)
REM            run.bat --release  (ekstra argumanlar oldugu gibi iletilir)
flutter run --dart-define-from-file=env.json %*
