import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:kurandakimesaj/data/backend_repositories.dart';
import 'package:kurandakimesaj/features/studio/studio_screens.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'support/recording_social_repository.dart';

/// Stüdyo video desteği regresyonları — `rights_gate_test.dart` kalıbının
/// aynısı (sahte platform arayüzleri + provider override, kod üretimi YOK).
///
/// Kilitlenen üç davranış:
/// 1. Video seçiliyken "PNG Kaydet" GİZLİ (hareketliyi tek kareye indirip
///    "kaydettin" demek kullanıcıyı yanıltır).
/// 2. Telif onayı (App Store Guideline 5.2.3) video yolunda da kapı: onaysız
///    yayınla devre dışı, onaylanınca etkin.
/// 3. Yayınlanan post `kind: 'video'` ve `arabic`/`meal`/`reference` DOLU —
///    hepsini `meal` içine gömmek Reels'in RTL Arapça bloğunu boş bırakırdı.

// ── Sahte platformlar ────────────────────────────────────────────────────────

class _FakeImagePickerPlatform extends ImagePickerPlatform
    with MockPlatformInterfaceMixin {
  _FakeImagePickerPlatform(this._path);
  final String _path;

  @override
  Future<XFile?> getVideo({
    required ImageSource source,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    Duration? maxDuration,
  }) async => XFile(_path);
}

/// `isSignedInProvider` reaktivitesi için (moderation_queue_test kalıbı).
class _FakeGateway extends SupabaseGateway {
  _FakeGateway() : super(null);
  @override
  bool get isSignedIn => true;
}

// ── Yardımcılar ──────────────────────────────────────────────────────────────

/// Stüdyonun `ListView(children:)`si viewport'a göre TEMBEL mount olur;
/// varsayılan küçük test yüzeyinde alt taraftaki butonlar hiç kurulmaz.
Future<void> _pumpStudio(
  WidgetTester tester, {
  required RecordingSocialRepository repo,
}) async {
  await tester.binding.setSurfaceSize(const Size(400, 2600));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        socialRepositoryProvider.overrideWithValue(repo),
        supabaseGatewayProvider.overrideWithValue(_FakeGateway()),
      ],
      child: const MaterialApp(
        home: StudioScreen(
          initialArabic: 'وَبَشِّرِ الصَّابِرِينَ',
          initialText: 'Sabredenleri müjdele',
          initialReference: 'Bakara, 155',
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pickVideo(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('studio_pick_video')));
  await tester.pumpAndSettle();
}

/// `FilledButton.icon(...)` private bir alt tür döndürür; `byType` TAM tür
/// eşleştirir ve bulamaz (bkz. rights_gate_test).
FilledButton _publishButton(WidgetTester tester) => tester.widget<FilledButton>(
  find.ancestor(
    of: find.text("Reels'e Yayınla"),
    matching: find.byWidgetPredicate((w) => w is FilledButton),
  ),
);

File _smallVideo() {
  final dir = Directory.systemTemp.createTempSync('studio_video_test');
  // Windows'ta oynatıcı dosyayı hâlâ açık tutuyor olabilir; geçici dizin
  // temizliği testi düşürmemeli.
  addTearDown(() {
    try {
      dir.deleteSync(recursive: true);
    } catch (_) {}
  });
  return File('${dir.path}/reel.mp4')
    ..writeAsBytesSync(List<int>.filled(2048, 0));
}

/// Yalnız `image_picker` sahtelenir. `video_player`'ın native kanalı testte
/// yoktur: stüdyo önizleme oynatıcısını BEST-EFFORT kurar, kurulamazsa seçim
/// yine de geçerli kalır (yüklenen şey dosyanın kendisidir). Bu testler tam da
/// o sözleşmeyi kilitler.
void _installPicker(String videoPath) {
  final original = ImagePickerPlatform.instance;
  ImagePickerPlatform.instance = _FakeImagePickerPlatform(videoPath);
  addTearDown(() => ImagePickerPlatform.instance = original);
}

/// Yayınlama gerçek async iş yapar (dosya okuma, `toByteData` PNG kodlaması) —
/// `testWidgets`in sahte zamanı bunları ilerletmez, `runAsync` şart.
Future<void> _tapPublish(WidgetTester tester) async {
  await tester.tap(find.text("Reels'e Yayınla"));
  // Zincirin her halkası (dosya okuma → yükleme → createPost) ayrı bir async
  // sıçraması: her birinde önce GERÇEK zaman ilerlemeli (`runAsync`), sonra
  // sahte zonun mikro görev kuyruğu boşalmalı (`pump`).
  for (var i = 0; i < 10; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    await tester.pump();
  }
}

void main() {
  testWidgets(
    'StudioScreen: video arka plan seçilince "PNG Kaydet" gizlenir '
    '(video karesini PNG sanmak kullanıcıyı yanıltır)',
    (tester) async {
      _installPicker(_smallVideo().path);
      final repo = RecordingSocialRepository();
      await _pumpStudio(tester, repo: repo);

      // Şablon (still) modunda PNG çıktısı VAR.
      expect(find.byKey(const Key('studio_export_png')), findsOneWidget);

      await _pickVideo(tester);

      // Video modunda yalnız "Reels'te Paylaş" kalır.
      expect(find.byKey(const Key('studio_export_png')), findsNothing);
      expect(find.text("Reels'e Yayınla"), findsOneWidget);
    },
  );

  testWidgets(
    'StudioScreen: video seçili olsa bile telif onayı işaretsizken yayın '
    'kilitli; işaretlenince açılır (Guideline 5.2.3 — video yolunda da)',
    (tester) async {
      _installPicker(_smallVideo().path);
      final repo = RecordingSocialRepository();
      await _pumpStudio(tester, repo: repo);

      await _pickVideo(tester);

      expect(_publishButton(tester).onPressed, isNull);
      expect(find.byKey(const Key('studio_rights_hint')), findsOneWidget);

      await tester.tap(find.byKey(const Key('studio_rights_checkbox')));
      await tester.pumpAndSettle();

      expect(_publishButton(tester).onPressed, isNotNull);
      expect(find.byKey(const Key('studio_rights_hint')), findsNothing);
    },
  );

  testWidgets(
    'StudioScreen: video yayınlanınca medya YÜKLENİR ve post kind:"video" + '
    'arabic/meal/reference DOLU gider',
    (tester) async {
      _installPicker(_smallVideo().path);
      final repo = RecordingSocialRepository();
      await _pumpStudio(tester, repo: repo);

      await _pickVideo(tester);
      await tester.tap(find.byKey(const Key('studio_rights_checkbox')));
      await tester.pumpAndSettle();
      await _tapPublish(tester);

      // Medya gerçekten yüklendi (eski kusur: hiç yüklenmiyordu).
      expect(repo.uploads, [true]);

      final post = repo.lastPost;
      expect(post, isNotNull);
      expect(post!['kind'], 'video');
      expect(post['videoUrl'], isNotNull);
      expect(post['mediaUrl'], isNull);
      // Şema kısıtı (K1/K2): kind YALNIZ 'video' | 'still'.
      expect(post['kind'], anyOf('video', 'still'));
      // Ayrı alanlar — hiçbiri boş değil.
      expect(post['arabic'], 'وَبَشِّرِ الصَّابِرِينَ');
      expect(post['meal'], 'Sabredenleri müjdele');
      expect(post['reference'], 'Bakara, 155');
    },
  );

  testWidgets(
    'StudioScreen: video seçilmemişken yayın "still" olur ve önizlemenin '
    'PNG\'si yüklenir',
    (tester) async {
      _installPicker(_smallVideo().path);
      final repo = RecordingSocialRepository();
      await _pumpStudio(tester, repo: repo);

      await tester.tap(find.byKey(const Key('studio_rights_checkbox')));
      await tester.pumpAndSettle();
      await _tapPublish(tester);

      expect(repo.uploads, [false]);
      expect(repo.lastPost!['kind'], 'still');
      expect(repo.lastPost!['mediaUrl'], isNotNull);
      expect(repo.lastPost!['videoUrl'], isNull);
      expect(repo.lastPost!['arabic'], isNotEmpty);
    },
  );

  testWidgets(
    'StudioScreen: 20 MB üstü video reddedilir (CreatePostSheet ile AYNI sınır)',
    (tester) async {
      final dir = Directory.systemTemp.createTempSync('studio_big_video');
      addTearDown(() => dir.deleteSync(recursive: true));
      // Seyrek dosya: 21 MB'lık gerçek bayt yazmadan o uzunlukta dosya.
      final big = File('${dir.path}/big.mp4');
      final raf = big.openSync(mode: FileMode.write);
      raf.setPositionSync(21 * 1024 * 1024);
      raf.writeByteSync(0);
      raf.closeSync();

      _installPicker(big.path);
      final repo = RecordingSocialRepository();
      await _pumpStudio(tester, repo: repo);

      await _pickVideo(tester);

      expect(find.textContaining('Video çok büyük'), findsOneWidget);
      // Reddedildi → hâlâ 'still' modundayız, PNG butonu duruyor.
      expect(find.byKey(const Key('studio_export_png')), findsOneWidget);
    },
  );
}
