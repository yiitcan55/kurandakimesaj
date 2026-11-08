import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../domain/recitation_timeline.dart' show SpeechSegment;

export '../domain/recitation_timeline.dart' show SpeechSegment;

/// Videonun sesini CİHAZIN ses tanıyıcısıyla metne çevirir (Android 13+,
/// `VideoSpeechChannel.kt`). Video uygulamadan çıkmaz; tanımayı işletim
/// sisteminin servisi yapar (Google, çevrimdışı paket yoksa sesi kendi
/// sunucusuna gönderebilir). Hatalar `PlatformException.code` ile gelir:
/// `speech_permission`, `speech_network`, `speech_language`, `speech_busy`,
/// `speech_no_audio`, `speech_unavailable`.
class VideoSpeechService {
  const VideoSpeechService();

  static const _channel = MethodChannel('kurandakimesaj/video_speech');

  /// Android dışında her zaman false (iOS/Android < 13 sunucu yolunu kullanır).
  Future<bool> isSupported() async {
    if (!Platform.isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('isSupported') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Tanıyıcı `RECORD_AUDIO` ister (mikrofon açılmasa bile; yoksa ERROR 9).
  Future<bool> requestPermission() async =>
      (await Permission.microphone.request()).isGranted;

  Future<List<SpeechSegment>> transcribe(String path, {String locale = 'ar-SA'}) async {
    final raw = await _channel.invokeListMethod<Object?>(
          'transcribe',
          {'path': path, 'locale': locale},
        ) ??
        const [];
    return [
      for (final m in raw.whereType<Map>())
        (
          start: (m['start'] as num?)?.toDouble() ?? 0,
          end: (m['end'] as num?)?.toDouble() ?? 0,
          text: (m['text'] ?? '').toString(),
        ),
    ];
  }

  Future<void> cancel() => _channel.invokeMethod<void>('cancel');
}

final videoSpeechServiceProvider = Provider<VideoSpeechService>(
  (ref) => const VideoSpeechService(),
);
