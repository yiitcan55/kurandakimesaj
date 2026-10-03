import 'package:flutter/material.dart';

/// Hata kodunu eyleme dönük Türkçe mesaja çevirir; bilinmeyen kod için `null`
/// (çağıran jenerik mesaj gösterir ve kodu loglar).
///
/// Kod listesi sözleşmenin bir parçası: `ayah-finder` + `ayah-finder-audio`
/// Edge Function'ları, `AyahFinderRepository` ve Meal Düzenle bu kodları
/// üretir. Yeni kod eklenirse burası da güncellenmeli.
(IconData, String)? ayahErrorMessage(String? code) {
  return switch (code) {
    'file_too_large' => (
        Icons.video_settings_rounded,
        'Dosya çok büyük. Görsel en fazla 10 MB, video en fazla 20 MB olabilir.'
      ),
    'video_missing' => (
        Icons.videocam_off_rounded,
        'Video okunamadı. Dosyayı tekrar seçip dene.'
      ),
    'no_video' => (
        Icons.upload_file_rounded,
        'Video isteği eksik gönderildi.\n'
            'Videoyu yeniden seçip tekrar dene.'
      ),
    'no_image' => (
        Icons.image_not_supported_rounded,
        'Bu içerikte okunabilecek bir görsel bulunamadı.\n'
            'Ayetin net göründüğü bir ekran görüntüsü seçip tekrar dene.'
      ),
    'upload_failed' => (
        Icons.cloud_upload_outlined,
        'Video yüklenemedi. İnternetini kontrol edip tekrar dene.'
      ),
    'asr_failed' => (
        Icons.hearing_disabled_rounded,
        'Videodaki ses çözümlenemedi.\n'
            'Tilavetin net duyulduğu bir klip ile tekrar dene.'
      ),
    'rate_limited' => (
        Icons.hourglass_bottom_rounded,
        'Şu an çok fazla istek var. Birkaç dakika sonra tekrar dene.'
      ),
    'forbidden_path' => (
        Icons.lock_outline_rounded,
        'Bu videoya erişim yetkin yok. Videoyu tekrar seçip dene.'
      ),
    'auth_required' => (
        Icons.login_rounded,
        'Bu özellik için giriş yapman gerekir.'
      ),
    'no_api_key' => (
        Icons.cloud_off_rounded,
        'Ayet bulma servisi şu an yapılandırılmamış.\n'
            'Bu bizden kaynaklı; kısa süre içinde tekrar dene.'
      ),
    'network' => (
        Icons.wifi_off_rounded,
        'İnternete ulaşılamadı.\n'
            'Wi-Fi ya da mobil veri bağlantını kontrol edip tekrar dene.'
      ),
    'server_error' => (
        Icons.warning_amber_rounded,
        'Sunucuda beklenmedik bir sorun oluştu.\n'
            'Birkaç dakika sonra tekrar dene.'
      ),
    'bad_response' => (
        Icons.sync_problem_rounded,
        'Sunucudan anlaşılmayan bir yanıt geldi.\n'
            'Uygulamanın güncel olduğundan emin olup tekrar dene.'
      ),
    'not_found' => (
        Icons.search_off_rounded,
        "Bu videoda Kur'an tilaveti bulunamadı. Ayet aralığını elle seçebilirsin."
      ),
    'ambiguous' => (
        Icons.rule_rounded,
        'Ayetler kesin belirlenemedi. Ayet aralığını elle seçebilirsin.'
      ),
    _ => null,
  };
}
