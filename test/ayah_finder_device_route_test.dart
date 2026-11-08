import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kurandakimesaj/data/backend_repositories.dart';
import 'package:kurandakimesaj/data/local/app_database.dart' show Surah;
import 'package:kurandakimesaj/data/video_speech.dart';
import 'package:kurandakimesaj/domain/models.dart';
import 'package:kurandakimesaj/domain/quran_matcher.dart';
import 'package:kurandakimesaj/features/ayah_finder/recite_controller.dart';
import 'package:kurandakimesaj/features/quran/quran_screens.dart';

/// `AyahFinderRepository.findFromVideo` yönlendirmesi: cihaz tanıyıcısı varsa
/// oturumsuz ve yüklemesiz cihaz yolu, yoksa `device_unsupported` (Groq yolu
/// 2026-11-08'de kaldırıldı; sunucu yedeği yok).
class _FakeSpeech implements VideoSpeechService {
  _FakeSpeech({this.supported = true, this.granted = true, this.error});

  final bool supported;
  final bool granted;
  final PlatformException? error;
  final calls = <String>[];

  @override
  Future<bool> isSupported() async => supported;

  @override
  Future<bool> requestPermission() async {
    calls.add('permission');
    return granted;
  }

  @override
  Future<List<SpeechSegment>> transcribe(String path, {String locale = 'ar-SA'}) async {
    calls.add('transcribe');
    if (error != null) throw error!;
    return const [
      (start: 0.0, end: 2.4, text: 'الحمد لله رب العالمين'),
      (start: 2.8, end: 4.0, text: 'الرحمن الرحيم'),
      (start: 4.4, end: 6.2, text: 'مالك يوم الدين'),
    ];
  }

  @override
  Future<void> cancel() async {}
}

void main() {
  late QuranMatcher matcher;
  late File video;

  setUpAll(() {
    matcher = QuranMatcher.fromJson(
      File('assets/quran/quran_full.json').readAsStringSync(),
    );
    final dir = Directory.systemTemp.createTempSync('video_speech_test');
    video = File('${dir.path}/tilavet.mp4')..writeAsBytesSync([0, 1, 2, 3]);
    addTearDown(() => dir.deleteSync(recursive: true));
  });

  IAyahFinderRepository repoWith(_FakeSpeech speech) {
    final container = ProviderContainer(overrides: [
      supabaseClientProvider.overrideWithValue(null),
      videoSpeechServiceProvider.overrideWithValue(speech),
      quranMatcherProvider.overrideWith((ref) async => matcher),
      surahsProvider.overrideWith((ref) async => const [
            Surah(
              number: 1,
              nameTr: 'Fâtiha',
              nameArabic: 'الفاتحة',
              meaning: 'Açılış',
              ayahCount: 7,
              revelation: 'Mekki',
              juzStart: 1,
            ),
          ]),
    ]);
    addTearDown(container.dispose);
    return container.read(ayahFinderRepositoryProvider);
  }

  test('cihaz yolu: oturum yokken de tanır ve eşleştirir', () async {
    final speech = _FakeSpeech();
    final r = await repoWith(speech).findFromVideo(video.path);
    expect(r.status, AyahFinderStatus.matched);
    expect(r.range?.reference, 'Fâtiha, 2-4');
    expect(r.timeline, hasLength(3));
    expect(speech.calls, ['permission', 'transcribe']);
  });

  test('izin reddedilirse speech_permission, tanıma başlamaz', () async {
    final speech = _FakeSpeech(granted: false);
    final r = await repoWith(speech).findFromVideo(video.path);
    expect(r.errorCode, 'speech_permission');
    expect(speech.calls, ['permission']);
  });

  test('yerel hata kodu aynen, bilinmeyen kod speech_unavailable olur', () async {
    final net = await repoWith(_FakeSpeech(error: PlatformException(code: 'speech_network')))
        .findFromVideo(video.path);
    expect(net.status, AyahFinderStatus.error);
    expect(net.errorCode, 'speech_network');

    final odd = await repoWith(_FakeSpeech(error: PlatformException(code: 'tuhaf')))
        .findFromVideo(video.path);
    expect(odd.errorCode, 'speech_unavailable');
  });

  test('cihaz yolunda da dosya kontrolü: olmayan video -> video_missing', () async {
    final speech = _FakeSpeech();
    final r = await repoWith(speech).findFromVideo('${video.parent.path}/yok.mp4');
    expect(r.errorCode, 'video_missing');
    expect(speech.calls, isEmpty);
  });

  test('cihaz desteklemiyorsa device_unsupported; sunucuya/yüklemeye gidilmez, oturum şartı yok', () async {
    final speech = _FakeSpeech(supported: false);
    final r = await repoWith(speech).findFromVideo(video.path);
    expect(r.status, AyahFinderStatus.error);
    expect(r.errorCode, 'device_unsupported');
    expect(speech.calls, isEmpty);
  });
}
