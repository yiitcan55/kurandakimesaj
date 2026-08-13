import 'package:flutter_test/flutter_test.dart';
import 'package:kurandakimesaj/data/backend_repositories.dart';

/// Profilden 1:1 sohbet açma (madde 7-tam) sonrası sohbet listesinin başlık
/// kuralı.
///
/// `conversations.title` 1:1'de KULLANILAMAZ: tek kolon, iki taraf — her iki
/// kullanıcıya da aynı başlığı gösterirdi. Başlık, "benim olmayan üyelik
/// satırındaki profil adı"dır. Bu kural sessizce ters dönebilecek tek yer
/// olduğu için saf bir fonksiyona ayrıldı ve burada kilitleniyor.
void main() {
  const me = 'me-uuid';
  const other = 'other-uuid';

  Map<String, dynamic> uyelik(
    String convId,
    String userId, {
    required bool isGroup,
    String? title,
    String? displayName,
  }) => {
    'conversation_id': convId,
    'user_id': userId,
    'conversations': {'id': convId, 'title': title, 'is_group': isGroup},
    if (displayName != null) 'profiles': {'display_name': displayName},
  };

  test('1:1 sohbette başlık KARŞI TARAFIN adı olur', () {
    final out = resolveConversationTitles([
      uyelik('c1', me, isGroup: false, displayName: 'Ben'),
      uyelik('c1', other, isGroup: false, displayName: 'Ayşe'),
    ], me);

    expect(out, hasLength(1));
    expect(out.single['conversations']['title'], 'Ayşe');
  });

  test('kendi üyelik satırım başlığı ASLA ezmez (satır sırası önemsiz)', () {
    // Ters sırada da aynı sonuç çıkmalı: aksi hâlde başlık bazen "Ben" olurdu.
    final out = resolveConversationTitles([
      uyelik('c1', other, isGroup: false, displayName: 'Ayşe'),
      uyelik('c1', me, isGroup: false, displayName: 'Ben'),
    ], me);

    expect(out.single['conversations']['title'], 'Ayşe');
  });

  test('grup sohbetinde `conversations.title` KORUNUR', () {
    // Grupta başlık gerçekten anlamlıdır; üye adıyla ezilirse yanlış olur.
    final out = resolveConversationTitles([
      uyelik('g1', me, isGroup: true, title: 'Hatim Halkası'),
      uyelik('g1', other, isGroup: true, title: 'Hatim Halkası',
          displayName: 'Ayşe'),
    ], me);

    expect(out.single['conversations']['title'], 'Hatim Halkası');
  });

  test('aynı sohbetin birden çok üyelik satırı TEK kayda indirgenir', () {
    final out = resolveConversationTitles([
      uyelik('c1', me, isGroup: false),
      uyelik('c1', other, isGroup: false, displayName: 'Ayşe'),
      uyelik('c2', me, isGroup: false),
      uyelik('c2', 'ucuncu', isGroup: false, displayName: 'Mehmet'),
    ], me);

    expect(out.map((e) => e['conversation_id']), ['c1', 'c2']);
  });

  test('karşı tarafın adı yoksa çökmez, başlık dokunulmadan kalır', () {
    // `profiles` embed'i RLS/veri eksikliğinde boş gelebilir — defansif olmalı.
    final out = resolveConversationTitles([
      uyelik('c1', me, isGroup: false),
      uyelik('c1', other, isGroup: false),
    ], me);

    expect(out.single['conversations']['title'], isNull);
  });
}
