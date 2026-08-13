import 'package:flutter_test/flutter_test.dart';
import 'package:kurandakimesaj/data/device_services.dart';

/// Bildirim / kilit ekranı başlığı.
///
/// Tilavet artık arka planda da çaldığı için kullanıcının uygulamayı hiç
/// görmeden "ne çalıyor" sorusunu yanıtlayabilmesi gerekiyor: bildirimdeki
/// tek metin budur. `MediaItem.title` boş veya "null" giderse medya çubuğu
/// isimsiz görünür — bunu birim testiyle kilitliyoruz çünkü cihaz QA'sı
/// dışında görünür bir yeri yok.
void main() {
  test('mediaTitleFor — sure adı + ayet numarası okunabilir tek satır üretir', () {
    expect(AudioService.mediaTitleFor('Bakara', 155), 'Bakara, 155. ayet');
    expect(AudioService.mediaTitleFor('Yâsîn', 1), 'Yâsîn, 1. ayet');
  });

  test('mediaTitleFor — Türkçe karakterler ASCII\'ye düşürülmez', () {
    // Domain kuralı 3: kullanıcıya dönük her metin tam ortografiyle.
    final title = AudioService.mediaTitleFor('İhlâs', 3);
    expect(title, 'İhlâs, 3. ayet');
    expect(title.contains('Ihlas'), isFalse);
  });
}
