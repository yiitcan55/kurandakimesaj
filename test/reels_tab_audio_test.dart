import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kurandakimesaj/data/backend_repositories.dart';
import 'package:kurandakimesaj/data/device_services.dart';
import 'package:kurandakimesaj/data/repositories.dart';
import 'package:kurandakimesaj/features/community/community_screens.dart';

import 'support/recording_social_repository.dart';

/// Reels sekmesi görünmez olunca (StatefulShellRoute dalı Offstage + TickerMode
/// kapalı) arka plan müziği DURMALI. Eskiden `isActive` yalnız PageView
/// konumundan geldiği için sekme değişince hiçbir şey durmuyordu.
class _FakeAudio extends Fake implements AudioService {
  final calls = <String>[];
  @override
  Future<void> playUrl(String url, {required String title}) async =>
      calls.add('play');
  @override
  Future<void> pause() async => calls.add('pause');
  @override
  void dispose() {}
}

class _ReelsRepo extends RecordingSocialRepository {
  _ReelsRepo(this.reels);
  final List<FeedPost> reels;
  @override
  Future<List<FeedPost>> fetchReels() async => reels;
}

class _Unmuted extends ReelsMutedNotifier {
  @override
  bool build() => false;
}

class _FakeGateway extends SupabaseGateway {
  _FakeGateway() : super(null);
  @override
  bool get isSignedIn => true;
}

void main() {
  testWidgets('sekme görünmez olunca reel müziği durur, dönünce sürer', (
    tester,
  ) async {
    final audio = _FakeAudio();
    final tabVisible = ValueNotifier(true);
    addTearDown(tabVisible.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          supabaseGatewayProvider.overrideWithValue(_FakeGateway()),
          socialRepositoryProvider.overrideWithValue(
            _ReelsRepo(
              const [
                FeedPost(
                  id: 'r1',
                  authorId: 'a1',
                  authorName: 'Yazar',
                  reference: 'Yasin, 58',
                  arabic: '',
                  meal: 'Esenlik, çok esirgeyen Rab\'den bir sözdür.',
                  topic: '',
                  likeCount: 0,
                  likedByMe: false,
                  status: 'approved',
                  audioUrl: 'https://example.com/a.mp3',
                ),
              ],
            ),
          ),
          reelAudioServiceProvider.overrideWithValue(audio),
          reelsMutedProvider.overrideWith(_Unmuted.new),
        ],
        child: MaterialApp(
          home: ValueListenableBuilder<bool>(
            valueListenable: tabVisible,
            builder: (_, visible, _) =>
                TickerMode(enabled: visible, child: const FeedScreen()),
          ),
        ),
      ),
    );
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    expect(audio.calls, contains('play'), reason: 'görünürken müzik çalmalı');

    audio.calls.clear();
    tabVisible.value = false;
    await tester.pump(const Duration(seconds: 1));
    expect(audio.calls, contains('pause'));
    expect(audio.calls, isNot(contains('play')));

    audio.calls.clear();
    tabVisible.value = true;
    await tester.pump(const Duration(seconds: 1));
    expect(audio.calls, contains('play'), reason: 'dönünce devam etmeli');
  });
}
