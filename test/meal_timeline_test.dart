// MealTimeline: dalga formu + kaydırıcı + süre etiketleri.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kurandakimesaj/domain/meal_cues.dart';
import 'package:kurandakimesaj/features/meal_edit/meal_timeline.dart';
import 'package:video_player/video_player.dart';

const _cues = [
  MealCue(startSec: 0, endSec: 40, surah: 1, ayah: 1),
  MealCue(startSec: 40, endSec: 84, surah: 1, ayah: 2),
];

ValueNotifier<VideoPlayerValue> _pos(int sec, {int dur = 84}) => ValueNotifier(
  VideoPlayerValue(
    duration: Duration(seconds: dur),
    position: Duration(seconds: sec),
  ),
);

Future<void> _pump(
  WidgetTester t,
  ValueNotifier<VideoPlayerValue> v, {
  ValueChanged<Duration>? onSeek,
  List<MealCue> cues = _cues,
}) async {
  await t.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 360,
            child: MealTimeline(position: v, cues: cues, onSeek: onSeek),
          ),
        ),
      ),
    ),
  );
  await t.pump(const Duration(milliseconds: 100));
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('formatClock', () {
    expect(formatClock(Duration.zero), '0:00');
    expect(formatClock(const Duration(seconds: 84)), '1:24');
    expect(formatClock(const Duration(minutes: 12, seconds: 5)), '12:05');
  });

  testWidgets('etiketler: 0:00, orta, toplam', (t) async {
    await _pump(t, _pos(0), onSeek: (_) {});
    expect(find.text('0:00'), findsOneWidget);
    expect(find.text('0:42'), findsOneWidget);
    expect(find.text('1:24'), findsOneWidget);
  });

  testWidgets('kaydırıcı onSeek\'i doğru süreyle çağırır', (t) async {
    Duration? got;
    final sem = t.ensureSemantics();
    await _pump(t, _pos(0), onSeek: (d) => got = d);
    await t.tap(find.byType(Slider));
    await t.pump();
    expect(got, isNotNull);
    expect(got!.inSeconds, inInclusiveRange(40, 44));
    expect(t.getSize(find.byType(Slider)).height, greaterThanOrEqualTo(44));
    expect(find.bySemanticsLabel('Video konumu'), findsOneWidget);
    sem.dispose();
  });

  testWidgets('süre sıfırken kaydırıcı kapalı', (t) async {
    await _pump(t, _pos(0, dur: 0), onSeek: (_) {});
    expect(t.widget<Slider>(find.byType(Slider)).onChanged, isNull);
  });

  testWidgets('onSeek yoksa kaydırıcı kapalı', (t) async {
    await _pump(t, _pos(0));
    expect(t.widget<Slider>(find.byType(Slider)).onChanged, isNull);
  });

  test('cue listesi değişince painter yeniden boyanır', () {
    final a = MealWaveformPainter(
      cues: _cues,
      durationSec: 84,
      progress: 0.2,
      lit: Colors.green,
      dim: Colors.grey,
      played: Colors.white,
    );
    final same = MealWaveformPainter(
      cues: _cues,
      durationSec: 84,
      progress: 0.2,
      lit: Colors.green,
      dim: Colors.grey,
      played: Colors.white,
    );
    final other = MealWaveformPainter(
      cues: const [],
      durationSec: 84,
      progress: 0.2,
      lit: Colors.green,
      dim: Colors.grey,
      played: Colors.white,
    );
    expect(a.shouldRepaint(same), isFalse);
    expect(a.shouldRepaint(other), isTrue);
  });
}
