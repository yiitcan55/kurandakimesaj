import 'package:flutter_test/flutter_test.dart';
import 'package:kurandakimesaj/features/ayah_finder/ayah_finder_controller.dart';

/// `normalizeAyahUrl` hem ekrandaki alanın hem paylaş menüsünün tek kapısı:
/// bozuk girdi buradan geçerse sunucuya çöp gider.
void main() {
  test('paylaş menüsünden gelen serbest metinden bağlantıyı çıkarır', () {
    expect(
      normalizeAyahUrl('Şuna bak: https://www.instagram.com/p/abc123/ 😊'),
      'https://www.instagram.com/p/abc123/',
    );
  });

  test('sondaki noktalama bağlantıya dahil edilmez', () {
    expect(
      normalizeAyahUrl('link burada https://x.com/a/status/1.'),
      'https://x.com/a/status/1',
    );
  });

  test('şemasız tek parça girdiye https eklenir', () {
    expect(normalizeAyahUrl('instagram.com/p/abc'), 'https://instagram.com/p/abc');
  });

  test('bağlantı olmayan girdi null döner', () {
    expect(normalizeAyahUrl(''), isNull);
    expect(normalizeAyahUrl('   '), isNull);
    expect(normalizeAyahUrl('merhaba'), isNull);
    expect(normalizeAyahUrl('bugün hava güzel'), isNull);
  });
}
