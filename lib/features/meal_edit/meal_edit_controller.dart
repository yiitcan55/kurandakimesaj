import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/backend_repositories.dart';
import '../../data/meal_video_store.dart';
import '../../domain/meal_cues.dart';
import '../../domain/models.dart';
import '../quran/quran_screens.dart';

enum MealEditPhase { idle, analyzing, ready, needsManual }

const _keep = Object();

class MealEditState {
  const MealEditState({
    this.videoPath,
    this.loadSeq = 0,
    this.phase = MealEditPhase.idle,
    this.errorCode,
    this.range,
    this.cues = const [],
    this.style = MealCueStyle.standard,
    this.durationSec = 0,
    this.tooLarge = false,
    this.linkShared = false,
    this.publishing = false,
    this.published = false,
  });

  final String? videoPath;

  /// Her yeni video yüklemesinde artar; geç gelen eski analizi ayıklamak için.
  final int loadSeq;
  final MealEditPhase phase;
  final String? errorCode;
  final AyahRange? range;
  final List<MealCue> cues;
  final MealCueStyle style;
  final double durationSec;
  final bool tooLarge;
  final bool linkShared;
  final bool publishing;
  final bool published;

  bool get canPublish => videoPath != null && cues.isNotEmpty && !tooLarge && !publishing && !published;

  /// `errorCode` null'a çekilebilsin diye sentinel ile ayrılır.
  MealEditState copyWith({
    MealEditPhase? phase,
    Object? errorCode = _keep,
    AyahRange? range,
    List<MealCue>? cues,
    MealCueStyle? style,
    double? durationSec,
    bool? tooLarge,
    bool? linkShared,
    bool? publishing,
    bool? published,
  }) =>
      MealEditState(
        videoPath: videoPath,
        loadSeq: loadSeq,
        phase: phase ?? this.phase,
        errorCode: identical(errorCode, _keep) ? this.errorCode : errorCode as String?,
        range: range ?? this.range,
        cues: cues ?? this.cues,
        style: style ?? this.style,
        durationSec: durationSec ?? this.durationSec,
        tooLarge: tooLarge ?? this.tooLarge,
        linkShared: linkShared ?? this.linkShared,
        publishing: publishing ?? this.publishing,
        published: published ?? this.published,
      );
}

class MealEditController extends Notifier<MealEditState> {
  // Süre sonradan öğrenilince cue'ları yeniden üretmek için son girdiler.
  List<CueAyah> _ayahs = const [];
  List<AyahTimelineEntry> _timeline = const [];
  int _manualSeq = 0;
  // onDispose içinde `state` okunamaz (Riverpod 3); silinecek yolu aynalarız.
  String? _ownedPath;

  @override
  MealEditState build() {
    final store = ref.read(mealVideoStoreProvider);
    ref.onDispose(() {
      final path = _ownedPath;
      if (path != null) {
        store.discard(path);
        store.clearPending();
      }
    });
    return const MealEditState();
  }

  MealVideoStore get _store => ref.read(mealVideoStoreProvider);

  Future<void> loadVideo(String path) async {
    final prev = state;
    if (prev.videoPath == path) return;
    if (prev.videoPath != null && !prev.published) _store.discard(prev.videoPath!);
    _ayahs = const [];
    _timeline = const [];
    _ownedPath = path;
    state = MealEditState(videoPath: path, loadSeq: prev.loadSeq + 1);
    _store.markPending(path);

    final file = File(path);
    if (!file.existsSync()) {
      state = state.copyWith(phase: MealEditPhase.needsManual, errorCode: 'video_missing');
    } else if (file.lengthSync() > kAyahVideoMaxBytes) {
      state = state.copyWith(
        tooLarge: true,
        phase: MealEditPhase.needsManual,
        errorCode: 'file_too_large',
      );
    } else {
      await analyze();
    }
  }

  Future<void> pickVideo() async {
    final file = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (file == null || !ref.mounted) return;
    await loadVideo(file.path);
  }

  Future<void> analyze() async {
    final path = state.videoPath;
    if (path == null) return;
    final seq = state.loadSeq;
    final manual = _manualSeq;
    final repo = ref.read(ayahFinderRepositoryProvider);
    state = state.copyWith(phase: MealEditPhase.analyzing, errorCode: null);

    final result = await repo.findFromVideo(path);
    if (!ref.mounted || state.loadSeq != seq || _manualSeq != manual) return;

    final range = result.range;
    if (result.status == AyahFinderStatus.matched && range != null && result.matches.isNotEmpty) {
      _ayahs = [
        for (final m in result.matches) (surah: m.surah, ayah: m.ayah, weight: m.arabic.length),
      ];
      _timeline = result.timeline;
      state = state.copyWith(
        range: range,
        cues: buildCues(ayahs: _ayahs, timeline: _timeline, durationSec: state.durationSec),
        phase: MealEditPhase.ready,
      );
    } else {
      state = state.copyWith(
        phase: MealEditPhase.needsManual,
        errorCode: result.errorCode ??
            switch (result.status) {
              AyahFinderStatus.notFound => 'not_found',
              AyahFinderStatus.ambiguous => 'ambiguous',
              _ => 'unexpected',
            },
      );
    }
  }

  Future<void> setManualRange({required int surah, required int from, required int to}) async {
    _manualSeq++;
    final ayahs = await ref.read(surahAyahsProvider(surah).future);
    final surahs = await ref.read(surahsProvider.future);
    if (!ref.mounted) return;
    final name = surahs.where((s) => s.number == surah).firstOrNull?.nameTr ?? 'Sure $surah';
    _ayahs = [
      for (final a in ayahs)
        if (a.numberInSurah >= from && a.numberInSurah <= to)
          (surah: surah, ayah: a.numberInSurah, weight: a.arabic.length),
    ];
    _timeline = const [];
    state = state.copyWith(
      range: AyahRange(
        surah: surah,
        fromAyah: from,
        toAyah: to,
        reference: from == to ? '$name, $from' : '$name, $from-$to',
      ),
      cues: buildCues(ayahs: _ayahs, durationSec: state.durationSec),
      phase: MealEditPhase.ready,
      errorCode: null,
    );
  }

  void setDuration(double sec) {
    state = state.copyWith(
      durationSec: sec,
      cues: _ayahs.isEmpty
          ? null
          : buildCues(ayahs: _ayahs, timeline: _timeline, durationSec: sec),
    );
  }

  void setStyle(MealCueStyle s) => state = state.copyWith(style: s);

  void showLinkHint() => state = state.copyWith(linkShared: true);

  Future<void> publish({required String caption}) async {
    final s = state;
    final range = s.range;
    if (!s.canPublish || range == null) {
      throw StateError('Yayınlamak için önce bir video ve ayet aralığı seçmelisin.');
    }
    final social = ref.read(socialRepositoryProvider);
    state = s.copyWith(publishing: true);
    try {
      final file = File(s.videoPath!);
      if (file.lengthSync() > kAyahVideoMaxBytes) {
        throw StateError("Video 20 MB'tan büyük olduğu için yayınlanamaz.");
      }
      final bytes = await file.readAsBytes();
      final url = await social.uploadPostMedia(bytes, isVideo: true);
      if (!ref.mounted) return;
      final first = (await ref.read(surahAyahsProvider(range.surah).future))
          .firstWhere((a) => a.numberInSurah == range.fromAyah);
      if (!ref.mounted) return;
      await social.createPost(
        reference: range.reference,
        arabic: first.arabic,
        meal: first.meal,
        caption: caption,
        kind: 'video',
        videoUrl: url,
        mealCues: s.cues,
        mealCueStyle: s.style,
      );
      if (!ref.mounted) return;
      _ownedPath = null; // yayınlanan dosyaya dispose'ta dokunulmaz
      state = state.copyWith(published: true);
      _store.clearPending();
      ref.invalidate(cloudReelsProvider);
    } on StateError {
      rethrow;
    } catch (e, st) {
      // Orijinal hata kaybolmasın; yüklenen mp4 yetim kalabilir (silme arayüzü yok).
      debugPrint('meal publish failed: $e\n$st');
      throw StateError(
        e is SocketException || e is TimeoutException
            ? 'Yayınlanamadı. Bağlantını kontrol edip tekrar dene.'
            : 'Yayınlanamadı. Lütfen tekrar dene; sorun sürerse bize bildir.',
      );
    } finally {
      if (ref.mounted) state = state.copyWith(publishing: false);
    }
  }
}

final mealEditProvider =
    NotifierProvider.autoDispose<MealEditController, MealEditState>(MealEditController.new);
