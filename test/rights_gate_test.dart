import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:kurandakimesaj/features/community/community_screens.dart';
import 'package:kurandakimesaj/features/studio/studio_screens.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Guideline 5.2.3 kanıtı: iki paralel yayın yolu (CreatePostSheet + StudioScreen)
/// telif onay kutusuna kadar AYNI kurala tabi olmalı — biri unutulursa kural
/// fiilen uygulanmıyor demektir (bkz. Faz 3 incelemesinin açtığı eksik).

/// `image_picker`'ın gerçek platform kanalına dokunmadan `CreatePostSheet._pickVideo`
/// yolunu tetiklemek için sahte platform — mockito/kod üretimi gerektirmez,
/// paketin kendi `MockPlatformInterfaceMixin`'i token doğrulamasını atlar.
class _FakeImagePickerPlatform extends ImagePickerPlatform with MockPlatformInterfaceMixin {
  _FakeImagePickerPlatform(this._path);
  final String _path;

  @override
  Future<XFile?> getVideo({
    required ImageSource source,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    Duration? maxDuration,
  }) async => XFile(_path);
}

Future<void> _pickVideo(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('create_post_pick_video')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'StudioScreen: telif onayı işaretsizken "Reels\'e Yayınla" devre dışı, '
    'işaretlenince etkinleşir; ipucu yalnız onaysızken görünür',
    (tester) async {
      // StudioScreen'in `ListView(children:)`si viewport'a göre TEMBEL mount
      // olur (SliverList Element'leri yalnız görünür+cache alanı için kurar) —
      // varsayılan küçük test yüzeyinde alt taraftaki onay kutusu/buton hiç
      // MOUNT edilmez. Yüzeyi tüm form + 9:16 önizlemeyi kapsayacak kadar
      // büyütmek, gerçek bir telefon ekranının yaptığını taklit eder.
      await tester.binding.setSurfaceSize(const Size(400, 2500));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: StudioScreen())),
      );
      await tester.pumpAndSettle();

      // `FilledButton.icon(...)` gerçekte private bir alt tür (`_FilledButtonWithIcon`)
      // döndürür; `find.byType(FilledButton)`/`widgetWithText` TAM tür eşleştirir ve
      // bulamaz. `byWidgetPredicate` + `is FilledButton` alt türleri de kapsar.
      FilledButton publishButton() => tester.widget<FilledButton>(
        find.ancestor(
          of: find.text("Reels'e Yayınla"),
          matching: find.byWidgetPredicate((w) => w is FilledButton),
        ),
      );

      expect(publishButton().onPressed, isNull);
      expect(find.byKey(const Key('studio_rights_hint')), findsOneWidget);

      await tester.tap(find.byKey(const Key('studio_rights_checkbox')));
      await tester.pumpAndSettle();

      expect(publishButton().onPressed, isNotNull);
      expect(find.byKey(const Key('studio_rights_hint')), findsNothing);
    },
  );

  testWidgets(
    'CreatePostSheet: medya seçili olsa bile telif onayı işaretsizken '
    '"Yayınla" devre dışı; işaretlenince etkinleşir (StudioScreen ile AYNI kural)',
    (tester) async {
      // `_pickVideo` seçimden hemen sonra dosya boyutunu kontrol ediyor
      // (kAyahVideoMaxBytes) — var olmayan bir yol veren sahte seçici seçimi
      // iptal ettirir. Gerçek ama küçük bir geçici dosya kullanıyoruz.
      final tempDir = Directory.systemTemp.createTempSync('reel_rights_test');
      addTearDown(() => tempDir.deleteSync(recursive: true));
      final small = File('${tempDir.path}/reel.mp4')
        ..writeAsBytesSync(List<int>.filled(1024, 0));

      final original = ImagePickerPlatform.instance;
      ImagePickerPlatform.instance = _FakeImagePickerPlatform(small.path);
      addTearDown(() => ImagePickerPlatform.instance = original);

      // Sheet normalde gerçek bir telefon boyunda açılır; test yüzeyinin
      // varsayılan (küçük) yüksekliği video önizlemesiyle birlikte taşırır —
      // bu ürün hatası değil, test yüzeyi darlığı.
      await tester.binding.setSurfaceSize(const Size(400, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: Scaffold(body: CreatePostSheet())),
        ),
      );
      await tester.pumpAndSettle();

      await _pickVideo(tester);

      ElevatedButton publishButton() =>
          tester.widget<ElevatedButton>(find.byKey(const Key('create_post_publish')));

      // Medya seçili ama telif onayı yok → hâlâ kilitli.
      expect(publishButton().onPressed, isNull);
      expect(find.byKey(const Key('create_post_publish_hint')), findsOneWidget);

      await tester.tap(find.byKey(const Key('create_post_rights_checkbox')));
      await tester.pumpAndSettle();

      expect(publishButton().onPressed, isNotNull);
      expect(find.byKey(const Key('create_post_publish_hint')), findsNothing);
    },
  );

  // `_publish` videoyu `readAsBytes()` ile TAMAMEN belleğe alıyor; sınırsız
  // bırakılırsa birkaç yüz MB'lık bir galeri videosu düşük RAM'li cihazda OOM
  // ile uygulamayı düşürür. Ayet Bulucu yolundaki sınırın aynısı burada da
  // uygulanmalı — iki yol farklı davranırsa kapı anlamsızlaşır.
  testWidgets(
    'CreatePostSheet: 20 MB üstü video seçilirse medya kabul edilmez ve '
    'kullanıcıya Türkçe uyarı gösterilir',
    (tester) async {
      final tempDir = Directory.systemTemp.createTempSync('reel_size_test');
      addTearDown(() => tempDir.deleteSync(recursive: true));
      // Seyrek (sparse) dosya: 21 MB'lık gerçek bayt yazmadan o uzunlukta bir
      // dosya üretir — test hızlı kalır.
      final big = File('${tempDir.path}/big.mp4');
      final raf = big.openSync(mode: FileMode.write);
      raf.setPositionSync(21 * 1024 * 1024);
      raf.writeByteSync(0);
      raf.closeSync();

      final original = ImagePickerPlatform.instance;
      ImagePickerPlatform.instance = _FakeImagePickerPlatform(big.path);
      addTearDown(() => ImagePickerPlatform.instance = original);

      await tester.binding.setSurfaceSize(const Size(400, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: Scaffold(body: CreatePostSheet())),
        ),
      );
      await tester.pumpAndSettle();

      await _pickVideo(tester);

      expect(find.textContaining('Video çok büyük'), findsOneWidget);

      // Telif onayı verilse bile medya seçilmediği için yayın kilitli kalır.
      await tester.tap(find.byKey(const Key('create_post_rights_checkbox')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ElevatedButton>(
              find.byKey(const Key('create_post_publish')),
            )
            .onPressed,
        isNull,
      );
    },
  );
}
