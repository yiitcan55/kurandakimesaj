import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../domain/recitation_timeline.dart' show SpeechSegment, wordsToSegments;

export '../domain/recitation_timeline.dart' show SpeechSegment;

/// Videonun sesini CİHAZIN ses tanıyıcısıyla metne çevirir: Android 13+
/// (`VideoSpeechChannel.kt`, bölüm döner) ve iPhone (`AppDelegate.swift`
/// `VideoSpeechChannel`, `SFSpeechRecognizer`; kelime döner → [wordsToSegments]).
/// Video uygulamadan çıkmaz; tanımayı işletim sisteminin servisi yapar (Google
/// ya da Apple; cihaz üstü model yoksa sesi kendi sunucusuna gönderebilir).
/// Hatalar `PlatformException.code` ile gelir: `speech_permission`,
/// `speech_network`, `speech_language`, `speech_busy`, `speech_no_audio`,
/// `speech_unavailable`.
class VideoSpeechService {
  const VideoSpeechService();

  static const _channel = MethodChannel('kurandakimesaj/video_speech');

  /// Android ve iOS dışında her zaman false (Android < 13'te kanal false döner).
  Future<bool> isSupported() async {
    if (!Platform.isAndroid && !Platform.isIOS) return false;
    try {
      return await _channel.invokeMethod<bool>('isSupported') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Android: tanıyıcı `RECORD_AUDIO` ister (mikrofon açılmasa bile; yoksa
  /// ERROR 9). iOS: dosyadan tanıma yalnız konuşma tanıma iznini ister
  /// (mikrofon değil).
  Future<bool> requestPermission() async {
    if (Platform.isIOS) {
      try {
        return await _channel.invokeMethod<bool>('requestPermission') ?? false;
      } on PlatformException {
        return false;
      }
    }
    return (await Permission.microphone.request()).isGranted;
  }

  Future<List<SpeechSegment>> transcribe(String path, {String locale = 'ar-SA'}) async {
    final raw = await _channel.invokeListMethod<Object?>(
          'transcribe',
          {'path': path, 'locale': locale},
        ) ??
        const [];
    final items = [
      for (final m in raw.whereType<Map>())
        (
          start: (m['start'] as num?)?.toDouble() ?? 0,
          end: (m['end'] as num?)?.toDouble() ?? 0,
          text: (m['text'] ?? '').toString(),
        ),
    ];
    return Platform.isIOS ? wordsToSegments(items) : items;
  }

  Future<void> cancel() => _channel.invokeMethod<void>('cancel');
}

final videoSpeechServiceProvider = Provider<VideoSpeechService>(
  (ref) => const VideoSpeechService(),
);
