import 'package:flutter_test/flutter_test.dart';
import 'package:kurandakimesaj/ui/core/theme/app_theme.dart';

/// `AppRadii.chatBubble` Mesajlar + AI asistan sohbet yüzeylerinin TEK kaynağı.
/// Bu testler kuyruğun doğru tarafta sivrildiğini ve token değerlerinin
/// sürüklenmediğini güvence altına alır (gelecekte elle BorderRadius yazımı geri
/// gelirse regresyon yakalanır).
void main() {
  group('AppRadii.chatBubble', () {
    test('üst köşeler her iki tarafta da yumuşak (bubble = 16)', () {
      for (final mine in [true, false]) {
        final r = AppRadii.chatBubble(mine: mine);
        expect(r.topLeft.x, AppRadii.bubble);
        expect(r.topRight.x, AppRadii.bubble);
      }
    });

    test('gönderen (mine) sağ-alt kuyruk sivrilir', () {
      final r = AppRadii.chatBubble(mine: true);
      expect(r.bottomRight.x, AppRadii.bubbleTail); // kuyruk = 4
      expect(r.bottomLeft.x, AppRadii.bubble); // diğer köşe yumuşak
    });

    test('karşı taraf sol-alt kuyruk sivrilir', () {
      final r = AppRadii.chatBubble(mine: false);
      expect(r.bottomLeft.x, AppRadii.bubbleTail); // kuyruk = 4
      expect(r.bottomRight.x, AppRadii.bubble); // diğer köşe yumuşak
    });

    test('kuyruk ve gövde yarıçapları beklenen token değerleri', () {
      expect(AppRadii.bubble, 16.0);
      expect(AppRadii.bubbleTail, 4.0);
    });
  });
}
