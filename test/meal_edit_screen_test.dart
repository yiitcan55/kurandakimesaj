import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:kurandakimesaj/data/backend_repositories.dart';
import 'package:kurandakimesaj/domain/meal_cues.dart';
import 'package:kurandakimesaj/features/ayah_finder/ayah_finder_controller.dart';
import 'package:kurandakimesaj/domain/models.dart';
import 'package:kurandakimesaj/features/meal_edit/meal_edit_controller.dart';
import 'package:kurandakimesaj/features/meal_edit/meal_edit_screen.dart';
import 'package:kurandakimesaj/features/quran/quran_screens.dart';

/// Durumu sabit tutan, çağrıları kaydeden controller (gerçek analiz/ağ yok).
class _FakeMeal extends MealEditController {
  _FakeMeal(this.initial);
  final MealEditState initial;
  final calls = <String>[];

  @override
  MealEditState build() => initial;
  @override
  Future<void> loadVideo(String path) async => calls.add('loadVideo');
  @override
  Future<void> pickVideo() async => calls.add('pickVideo');
  @override
  Future<void> analyze() async => calls.add('analyze');
  @override
  void showLinkHint() => calls.add('showLinkHint');
  @override
  void setDuration(double sec) {}

  void set(MealEditState s) => state = s;
}

class _SeedShared extends SharedAyahInputNotifier {
  _SeedShared(this.seed);
  final SharedAyahInput? seed;
  @override
  SharedAyahInput? build() => seed;
}

const _range = AyahRange(
  surah: 1,
  fromAyah: 1,
  toAyah: 2,
  reference: 'Fâtiha, 1-2',
);
const _cue = MealCue(startSec: 0, endSec: 3, surah: 1, ayah: 1);

Future<_FakeMeal> _pump(
  WidgetTester tester,
  MealEditState state, {
  Size size = const Size(390, 844),
  double textScale = 1.0,
  bool signedIn = true,
  SharedAyahInput? shared,
}) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final fake = _FakeMeal(state);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        mealEditProvider.overrideWith(() => fake),
        isSignedInProvider.overrideWithValue(signedIn),
        sharedAyahInputProvider.overrideWith(() => _SeedShared(shared)),
        surahsProvider.overrideWith((ref) async => []),
      ],
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const MealEditScreen(),
      ),
    ),
  );
  // Sonsuz animasyon olabilir: pumpAndSettle yok.
  await tester.pump(const Duration(milliseconds: 100));
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 3));
  });
  return fake;
}

SharedAyahInput? _shared(WidgetTester tester) => ProviderScope.containerOf(
  tester.element(find.byType(MealEditScreen)),
).read(sharedAyahInputProvider);

Future<void> _reveal(WidgetTester tester, Key key) async {
  await tester.scrollUntilVisible(
    find.byKey(key),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(find.byKey(key));
  await tester.pump();
}

void main() {
  testWidgets('boşta Video Seç düğmesi görünür ve pickVideo çağırır', (
    tester,
  ) async {
    final fake = await _pump(tester, const MealEditState());
    await tester.tap(find.byKey(const Key('mealPickVideo')));
    expect(fake.calls, ['pickVideo']);
    expect(find.text('Bekliyor'), findsOneWidget);
  });

  testWidgets('analiz sürerken durum hapı Analiz Ediliyor… der', (
    tester,
  ) async {
    await _pump(tester, const MealEditState(phase: MealEditPhase.analyzing));
    expect(
      find.descendant(
        of: find.byKey(const Key('mealAnalysisPill')),
        matching: find.text('Analiz Ediliyor…'),
      ),
      findsOneWidget,
    );
  });

  // Hap yapay zekânın yapmadığı işi "Tamamlandı" diye sahiplenmemeli: elle
  // seçilen aralıkta (tüm cue'lar yaklaşık) ve analizin hiç çalışmadığı 20 MB
  // üstü videoda durum dürüstçe yazılır.
  // Her durum AYRI testte: aynı testte ikinci `_pump` mevcut ProviderScope'u
  // yeniden kullanır, override yenilenmez ve assert yanlış duruma bakar.
  Finder pill(String text) => find.descendant(
    of: find.byKey(const Key('mealAnalysisPill')),
    matching: find.text(text),
  );
  const approxCue = MealCue(
    startSec: 0,
    endSec: 5,
    surah: 1,
    ayah: 1,
    approx: true,
  );

  testWidgets('durum hapı: yapay zekâ aralığında Tamamlandı der', (
    tester,
  ) async {
    await _pump(
      tester,
      const MealEditState(
        phase: MealEditPhase.ready,
        cues: [MealCue(startSec: 0, endSec: 5, surah: 1, ayah: 1)],
      ),
    );
    expect(pill('Tamamlandı'), findsOneWidget);
  });

  testWidgets('durum hapı: elle seçilen aralıkta Elle Seçildi der', (
    tester,
  ) async {
    await _pump(
      tester,
      const MealEditState(phase: MealEditPhase.ready, cues: [approxCue]),
    );
    expect(pill('Elle Seçildi'), findsOneWidget);
    expect(pill('Tamamlandı'), findsNothing);
  });

  testWidgets('durum hapı: 20 MB üstünde elle seçimden sonra da Analiz Yok '
      'der', (tester) async {
    await _pump(
      tester,
      const MealEditState(
        phase: MealEditPhase.ready,
        cues: [approxCue],
        tooLarge: true,
      ),
    );
    expect(pill('Analiz Yok'), findsOneWidget);
    expect(pill('Tamamlandı'), findsNothing);
  });

  testWidgets('aralık yokken kesikli kutu bekleme metnini gösterir', (
    tester,
  ) async {
    await _pump(tester, const MealEditState());
    await _reveal(tester, const Key('mealRangeBox'));
    expect(find.text('Henüz ayet aralığı seçilmedi.'), findsOneWidget);
    expect(
      find.text('Yapay zeka tamamlandığında otomatik seçilecektir.'),
      findsOneWidget,
    );
  });

  testWidgets('aralık varken referans ve ayet sayısı görünür', (tester) async {
    await _pump(
      tester,
      const MealEditState(
        range: _range,
        cues: [_cue],
        phase: MealEditPhase.ready,
      ),
    );
    await _reveal(tester, const Key('mealRangeBox'));
    expect(find.textContaining('Fâtiha, 1-2'), findsOneWidget);
    expect(find.textContaining('2 ayet'), findsOneWidget);
  });

  testWidgets('cue yokken alt düğme kapalı, cue varken açık', (tester) async {
    await _pump(tester, const MealEditState());
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('mealEditCta')))
          .onPressed,
      isNull,
    );
    await tester.pumpWidget(const SizedBox());
    await _pump(
      tester,
      const MealEditState(
        cues: [_cue],
        range: _range,
        phase: MealEditPhase.ready,
      ),
    );
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('mealEditCta')))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('bağlantı paylaşımında yönlendirme kartı görünür, loadVideo çağrılmaz', (
    tester,
  ) async {
    final fake = await _pump(tester, const MealEditState(linkShared: true));
    expect(find.byKey(const Key('mealLinkHint')), findsOneWidget);
    expect(
      find.textContaining('yalnızca bağlantısını paylaştı'),
      findsOneWidget,
    );
    expect(fake.calls, isNot(contains('loadVideo')));
  });

  testWidgets('yayınlandıktan sonra alt düğme kapalı', (tester) async {
    await _pump(
      tester,
      const MealEditState(
        videoPath: '/v.mp4',
        cues: [_cue],
        range: _range,
        phase: MealEditPhase.ready,
        published: true,
      ),
    );
    expect(
      tester.widget<FilledButton>(find.byKey(const Key('mealEditCta'))).onPressed,
      isNull,
    );
  });

  testWidgets('aralık var cue yok: süre okunamadı ipucu görünür', (tester) async {
    await _pump(tester, const MealEditState(range: _range, phase: MealEditPhase.ready));
    await _reveal(tester, const Key('mealRangeBox'));
    expect(find.byKey(const Key('mealNoDurationHint')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await _pump(
      tester,
      const MealEditState(range: _range, cues: [_cue], phase: MealEditPhase.ready),
    );
    await _reveal(tester, const Key('mealRangeBox'));
    expect(find.byKey(const Key('mealNoDurationHint')), findsNothing);
  });

  testWidgets('paylaşılan video açılışta loadVideo çağırır ve girdiyi temizler', (
    tester,
  ) async {
    final fake = await _pump(
      tester,
      const MealEditState(),
      shared: (imagePath: null, videoPath: '/x.mp4', url: null),
    );
    await tester.pump();
    expect(fake.calls, ['loadVideo']);
    expect(_shared(tester), isNull);
  });

  testWidgets('paylaşılan bağlantı yalnız showLinkHint çağırır', (tester) async {
    final fake = await _pump(
      tester,
      const MealEditState(),
      shared: (imagePath: null, videoPath: null, url: 'https://x'),
    );
    await tester.pump();
    expect(fake.calls, ['showLinkHint']);
    expect(_shared(tester), isNull);
  });

  testWidgets('ekran açıkken gelen video ref.listen ile tüketilir', (tester) async {
    final fake = await _pump(tester, const MealEditState());
    expect(fake.calls, isEmpty);
    ProviderScope.containerOf(tester.element(find.byType(MealEditScreen)))
        .read(sharedAyahInputProvider.notifier)
        .set((imagePath: null, videoPath: '/y.mp4', url: null));
    await tester.pump();
    expect(fake.calls, ['loadVideo']);
    expect(_shared(tester), isNull);
  });

  testWidgets('görsel girdiye dokunulmaz', (tester) async {
    final fake = await _pump(
      tester,
      const MealEditState(),
      shared: (imagePath: '/i.png', videoPath: null, url: null),
    );
    await tester.pump();
    expect(fake.calls, isEmpty);
    expect(_shared(tester)?.imagePath, '/i.png');
  });

  testWidgets('tam ekran açıkken video yolu değişirse sayfa kapanır', (tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    final fake = _FakeMeal(const MealEditState(videoPath: '/a.mp4'));
    final controller = VideoPlayerController.file(File('/a.mp4'));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [mealEditProvider.overrideWith(() => fake)],
        child: MaterialApp(
          home: Builder(
            builder: (ctx) => TextButton(
              onPressed: () => Navigator.of(ctx).push(
                MaterialPageRoute<void>(builder: (_) => MealFullscreen(controller: controller)),
              ),
              child: const Text('aç'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();
    expect(find.byType(MealFullscreen), findsOneWidget);
    fake.set(const MealEditState(videoPath: '/b.mp4'));
    await tester.pumpAndSettle();
    expect(find.byType(MealFullscreen), findsNothing);
  });

  testWidgets("20 MB üstünde yayın sheet'inde neden görünür ve yayın kapalı", (
    tester,
  ) async {
    await _pump(
      tester,
      const MealEditState(
        videoPath: '/yok/video.mp4',
        tooLarge: true,
        cues: [_cue],
        range: _range,
        phase: MealEditPhase.needsManual,
      ),
    );
    await tester.tap(find.byKey(const Key('mealEditCta')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      find.text("Video 20 MB'tan büyük olduğu için Reels'e yayınlanamaz."),
      findsOneWidget,
    );
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('meal_publish_button')))
          .onPressed,
      isNull,
    );
  });

  testWidgets("oturum yokken yayın sheet'i giriş nedenini gösterir", (
    tester,
  ) async {
    await _pump(
      tester,
      const MealEditState(
        cues: [_cue],
        range: _range,
        phase: MealEditPhase.ready,
      ),
      signedIn: false,
    );
    await tester.tap(find.byKey(const Key('mealEditCta')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Yayınlamak için giriş yapmalısın.'), findsOneWidget);
  });

  testWidgets("elle seç satırı sheet'i açar", (tester) async {
    await _pump(tester, const MealEditState());
    await _reveal(tester, const Key('mealManualRange'));
    await tester.tap(find.byKey(const Key('mealManualRange')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(BottomSheet), findsOneWidget);
  });

  testWidgets('hata kodu Türkçe mesaja çevrilir', (tester) async {
    await _pump(
      tester,
      const MealEditState(
        phase: MealEditPhase.needsManual,
        errorCode: 'not_found',
      ),
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('mealErrorText'))).data,
      contains('tilaveti bulunamadı'),
    );
    await tester.pumpWidget(const SizedBox());
    await _pump(
      tester,
      const MealEditState(phase: MealEditPhase.needsManual, errorCode: 'zzz'),
    );
    expect(
      find.text('Beklenmeyen bir sorun oluştu. Tekrar dene.'),
      findsOneWidget,
    );
  });

  testWidgets('auth_required Giriş Yap düğmesi gösterir', (tester) async {
    await _pump(
      tester,
      const MealEditState(
        phase: MealEditPhase.needsManual,
        errorCode: 'auth_required',
      ),
    );
    expect(find.text('Giriş Yap'), findsOneWidget);
  });

  testWidgets('needsManual durumunda Tekrar Dene analyze çağırır', (
    tester,
  ) async {
    final fake = await _pump(
      tester,
      const MealEditState(
        videoPath: '/yok/v.mp4',
        phase: MealEditPhase.needsManual,
        errorCode: 'network',
      ),
    );
    await tester.tap(find.byKey(const Key('mealAnalysisPill')));
    expect(fake.calls, contains('analyze'));
  });

  for (final c in [(320.0, 1.3), (390.0, 1.0)]) {
    testWidgets('${c.$1.toInt()} genişlik ${c.$2} ölçekte taşma yok', (
      tester,
    ) async {
      await _pump(
        tester,
        const MealEditState(
          videoPath: '/yok/v.mp4',
          phase: MealEditPhase.analyzing,
          errorCode: 'auth_required',
          range: _range,
          cues: [_cue],
          linkShared: true,
        ),
        size: Size(c.$1, 700),
        textScale: c.$2,
      );
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -2000));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
    });
  }
}
