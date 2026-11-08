import 'package:flutter/material.dart';

/// Hata kodunu eyleme dönük Türkçe mesaja çevirir; bilinmeyen kod için `null`
/// (çağıran jenerik mesaj gösterir ve kodu loglar).
///
/// Kod listesi sözleşmenin bir parçası: görsel `ayah-finder` Edge Function'ı,
/// cihaz tanıyıcısı (`VideoSpeechChannel`, Android + iOS), `AyahFinderRepository`
/// ve Meal Düzenle bu kodları üretir. Yeni kod eklenirse burası da güncellenmeli.
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
    'no_image' => (
        Icons.image_not_supported_rounded,
        'Bu içerikte okunabilecek bir görsel bulunamadı.\n'
            'Ayetin net göründüğü bir ekran görüntüsü seçip tekrar dene.'
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
    // Cihazda tanıma (Android 13+ `VideoSpeechChannel.kt`, iPhone
    // `AppDelegate.swift` `VideoSpeechChannel`).
    'device_unsupported' => (
        Icons.phonelink_erase_rounded,
        'Bu telefonda videodan otomatik ayet bulma desteklenmiyor (Android 13 ve '
            'üstü ya da iPhone gerekir). Ayetleri elle seçebilirsin.',
      ),
    'speech_permission' => (
        Icons.mic_off_rounded,
        'Videodaki sesi tanımak için ses tanıma izni gerekiyor '
            "(mikrofon açılmaz). Ayarlar'dan izin verip tekrar deneyin."
      ),
    'speech_network' => (
        Icons.wifi_off_rounded,
        'Ses tanıma için internet bağlantısı gerekiyor. '
            'Bağlantını kontrol edip tekrar dene.'
      ),
    'speech_language' => (
        Icons.translate_rounded,
        'Telefonun ses tanıyıcısı Arapçayı desteklemiyor. '
            'Ayetleri elle seçebilirsin.'
      ),
    'speech_busy' => (
        Icons.hourglass_bottom_rounded,
        'Ses tanıyıcı meşgul. Birkaç saniye sonra tekrar dene.'
      ),
    'speech_no_audio' => (
        Icons.volume_off_rounded,
        'Videoda okunabilir bir ses bulunamadı.'
      ),
    'speech_unavailable' => (
        Icons.hearing_disabled_rounded,
        'Ses tanıma şu an kullanılamıyor. Tekrar dene ya da ayetleri elle seç.'
      ),
    _ => null,
  };
}
