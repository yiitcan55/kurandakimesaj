import 'package:flutter_test/flutter_test.dart';
import 'package:kurandakimesaj/features/studio/studio_screens.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

/// Gelişmiş görsel editörün (madde 6) iki sessiz kırılma noktası.
///
/// İkisi de çalışma zamanında hata vermez: yanlış ayarla uygulama çalışmaya
/// devam eder, sorun aylar sonra depoda bozuk dosyalar veya App Store
/// incelemesinde ortaya çıkar. Bu yüzden birim testiyle kilitleniyorlar.
void main() {
  test('çıktı biçimi PNG — paket varsayılanı JPG ve depoya yalan söyler', () {
    // `uploadPostMedia` dosyayı `.png` adıyla ve `image/png` content-type'ıyla
    // yazıyor. Varsayılan JPG bırakılsaydı hem uzantı hem MIME yanlış olurdu.
    expect(
      kStudioEditorConfigs.imageGeneration.outputFormat,
      OutputFormat.png,
    );
  });

  test('sticker/emoji/audio araçları KAPALI — yeni UGC yüzeyi açılmamalı', () {
    final tools = kStudioEditorConfigs.mainEditor.tools;

    // Guideline 1.2: moderasyon kapısı `feed_posts` satırını koruyor.
    // Kullanıcının kartın üstüne yapıştırdığı rastgele sticker/emoji o kapıdan
    // geçmez — dolayısıyla bu araçlar açılırsa vaat ettiğimiz moderasyon
    // eksik kalır.
    expect(tools, isNot(contains(SubEditorMode.sticker)));
    expect(tools, isNot(contains(SubEditorMode.emoji)));
    // Ses, madde 5'in FK ile kilitli küratörlü kütüphanesiyle çakışırdı.
    expect(tools, isNot(contains(SubEditorMode.audio)));

    // İzin verilenler gerçekten mevcut olmalı; boş liste de bu testi geçerdi.
    expect(tools, containsAll(<SubEditorMode>[
      SubEditorMode.paint,
      SubEditorMode.text,
      SubEditorMode.cropRotate,
      SubEditorMode.filter,
    ]));
  });
}
