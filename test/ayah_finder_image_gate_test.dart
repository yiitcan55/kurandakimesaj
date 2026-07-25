import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kurandakimesaj/data/backend_repositories.dart';
import 'package:kurandakimesaj/domain/models.dart';

/// `kAyahImageMaxBytes` boyut kapısı — `findFromImage` gövdesinin ilk satırı,
/// `base64Encode`'dan ÖNCE çalışmalı (bkz. backend_repositories.dart yorumu).
///
/// Gerçek ağ çağrısı yok: `AyahFinderRepository(null)` ile çağrılan `_invoke`,
/// istemci `null` olduğunda `auth_required` ile döner (auth kısayolu). Bu yüzden
/// "sınırın ALTINDAKİ bayt kapıdan geçti mi?" sorusunun kanıtı, sonucun
/// `file_too_large` DEĞİL `auth_required` olmasıdır — gerçekten invoke yoluna
/// girdiğini gösterir.
void main() {
  test('sınırı aşan bayt dizisi file_too_large ile döner (ağa gitmez)', () async {
    final repo = AyahFinderRepository(null);
    final bytes = Uint8List(kAyahImageMaxBytes + 1);

    final result = await repo.findFromImage(bytes);

    expect(result.status, AyahFinderStatus.error);
    expect(result.errorCode, 'file_too_large');
  });

  test(
    'sınırın hemen altındaki bayt dizisi kapıyı geçer (invoke yoluna girer)',
    () async {
      final repo = AyahFinderRepository(null);
      final bytes = Uint8List(kAyahImageMaxBytes - 1);

      final result = await repo.findFromImage(bytes);

      expect(result.errorCode, isNot('file_too_large'));
      expect(result.errorCode, 'auth_required');
    },
  );

  test('tam sınır (== kAyahImageMaxBytes) geçerli kabul edilir (kapı sıkı ">")', () async {
    final repo = AyahFinderRepository(null);
    final bytes = Uint8List(kAyahImageMaxBytes);

    final result = await repo.findFromImage(bytes);

    expect(result.errorCode, 'auth_required');
  });
}
