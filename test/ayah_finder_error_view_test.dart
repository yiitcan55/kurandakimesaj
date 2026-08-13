import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kurandakimesaj/data/backend_repositories.dart';
import 'package:kurandakimesaj/domain/models.dart';
import 'package:kurandakimesaj/features/ayah_finder/ayah_finder_screen.dart';

/// `_ErrorView._messageFor` kod->mesaj tablosunun regresyon kilidi.
///
/// `AyahFinderScreen` özel (private) `_ErrorView` widget'ını dışa açmadığı için
/// gerçek kullanıcı yolundan (bağlantı alanına yaz → gönder) geçilip sahte repo
/// istenen hata koduyla sonuç döndürüyor; ekranda render edilen Türkçe mesaj
/// doğrulanıyor. Böylece hem eşleme hem gerçek widget ağacı aynı anda test
/// edilmiş oluyor (bkz. ayah_finder_controller_test.dart'taki fake kalıbı).
class _FakeAyahFinderRepository implements IAyahFinderRepository {
  _FakeAyahFinderRepository(this.errorCode);
  final String errorCode;

  @override
  Future<AyahFinderResult> findFromImage(Uint8List bytes, {String mime = 'image/jpeg'}) async =>
      AyahFinderResult(status: AyahFinderStatus.error, errorCode: errorCode);

  @override
  Future<AyahFinderResult> findFromUrl(String url) async =>
      AyahFinderResult(status: AyahFinderStatus.error, errorCode: errorCode);

  @override
  Future<AyahFinderResult> findFromVideo(String filePath) async =>
      AyahFinderResult(status: AyahFinderStatus.error, errorCode: errorCode);
}

Future<void> _pumpWithErrorCode(WidgetTester tester, String code) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ayahFinderRepositoryProvider.overrideWithValue(_FakeAyahFinderRepository(code)),
      ],
      child: const MaterialApp(home: AyahFinderScreen()),
    ),
  );
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const Key('ayahLinkInput')),
    'https://example.com/p/1',
  );
  await tester.tap(find.byKey(const Key('ayahLinkSubmit')));
  await tester.pumpAndSettle();
}

void main() {
  // Tablo, ekranın "Ekran raporu"nda belgelenen kod → mesaj eşlemesinin
  // birebir kopyası (ilk cümledeki ayırt edici parça).
  final cases = <String, String>{
    'link_unresolved': 'Bu bağlantıdan görsel alınamadı',
    'blocked_host': 'Bu bağlantı güvenlik nedeniyle açılamıyor',
    'invalid_url': 'Bu bir bağlantı gibi görünmüyor',
    'file_too_large': 'Video çok büyük',
    'video_missing': 'Video okunamadı',
    'no_video': 'Video isteği eksik gönderildi',
    'no_image': 'Bu içerikte okunabilecek bir görsel bulunamadı',
    'upload_failed': 'Video yüklenemedi',
    'asr_failed': 'Videodaki ses çözümlenemedi',
    'rate_limited': 'Şu an çok fazla istek var',
    'forbidden_path': 'Bu videoya erişim yetkin yok',
    'auth_required': 'Bu özellik için giriş yapman gerekir',
    'no_api_key': 'Ayet bulma servisi şu an yapılandırılmamış',
    'network': 'İnternete ulaşılamadı',
    'server_error': 'Sunucuda beklenmedik bir sorun oluştu',
    'bad_response': 'Sunucudan anlaşılmayan bir yanıt geldi',
  };

  for (final entry in cases.entries) {
    testWidgets('kod "${entry.key}" kendi Türkçe mesajını gösterir', (tester) async {
      await _pumpWithErrorCode(tester, entry.key);
      expect(find.textContaining(entry.value), findsWidgets);
    });
  }

  testWidgets(
    'bilinmeyen hata kodu jenerik mesaja düşer ve debugPrint ile loglanır',
    (tester) async {
      final logs = <String>[];
      final original = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) logs.add(message);
      };
      // addTearDown DEĞİL: flutter_test test bitiminde debug değişkenlerinin
      // varsayılana döndüğünü doğruluyor (`debugAssertAllFoundationVarsUnset`).
      // Geri alma, test gövdesi bitmeden (finally ile) yapılmalı.
      try {
        await _pumpWithErrorCode(tester, 'totally_unknown_code');

        expect(find.textContaining('Beklenmedik bir hata oluştu'), findsOneWidget);
        expect(logs, contains('AyahFinder hata: kod="totally_unknown_code" detay=-'));
      } finally {
        debugPrint = original;
      }
    },
  );
}
