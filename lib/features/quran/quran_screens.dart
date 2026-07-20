import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../data/device_services.dart';
import '../../data/local/app_database.dart';
import '../../data/repositories.dart';
import '../../ui/core/theme/app_colors.dart';
import '../../ui/core/theme/app_theme.dart';
import '../../ui/core/widgets.dart';

final surahsProvider = FutureProvider<List<Surah>>(
  (ref) => ref.read(contentRepositoryProvider).surahs(),
);

final surahAyahsProvider = FutureProvider.family<List<Ayah>, int>(
  (ref, number) => ref.read(contentRepositoryProvider).ayahsForSurah(number),
);

String _ayahAudioUrl(int surah, int ayah) {
  String p(int n) => n.toString().padLeft(3, '0');
  return 'https://everyayah.com/data/Alafasy_128kbps/${p(surah)}${p(ayah)}.mp3';
}

/// Tilavet oynatıcı durumu — hangi sure/ayet çalıyor, sıradaki konum, oynuyor mu.
class QuranPlayback {
  const QuranPlayback({
    this.surahNumber,
    this.ayahNumbers = const [],
    this.index = -1,
    this.playing = false,
  });

  final int? surahNumber;
  final List<int> ayahNumbers; // sure içindeki ayet numaraları (sıra)
  final int index; // ayahNumbers içindeki çalan konum
  final bool playing;

  bool get active =>
      surahNumber != null && index >= 0 && index < ayahNumbers.length;
  int? get currentAyah => active ? ayahNumbers[index] : null;
  int get total => ayahNumbers.length;
  bool get hasPrev => active && index > 0;
  bool get hasNext => active && index < ayahNumbers.length - 1;

  /// Bu sure-ayet çifti şu an çalan ayet mi (satır vurgusu için).
  bool isCurrent(int surah, int ayah) =>
      surahNumber == surah && currentAyah == ayah;

  QuranPlayback copyWith({
    int? surahNumber,
    List<int>? ayahNumbers,
    int? index,
    bool? playing,
  }) =>
      QuranPlayback(
        surahNumber: surahNumber ?? this.surahNumber,
        ayahNumbers: ayahNumbers ?? this.ayahNumbers,
        index: index ?? this.index,
        playing: playing ?? this.playing,
      );
}

/// Tilavet ViewModel'ı — ayetleri sırayla çalar; bittiğinde otomatik sonraki
/// ayete geçer. Tüm oynatma [AudioService] üzerinden tek oynatıcıda yürür.
class QuranPlayerController extends Notifier<QuranPlayback> {
  AudioService get _audio => ref.read(audioServiceProvider);
  StreamSubscription<ProcessingState>? _stateSub;
  StreamSubscription<bool>? _playingSub;

  @override
  QuranPlayback build() {
    final player = ref.read(audioServiceProvider).player;
    // Ayet bittiğinde sıradaki ayete geç (yoksa oynatmayı durdur).
    _stateSub = player.processingStateStream.listen((st) {
      if (st == ProcessingState.completed) _onComplete();
    });
    // Gerçek oynatıcı durumunu (oynuyor/duraklatıldı) yansıt.
    _playingSub = player.playingStream.listen((p) {
      if (state.active && p != state.playing) {
        state = state.copyWith(playing: p);
      }
    });
    ref.onDispose(() {
      _stateSub?.cancel();
      _playingSub?.cancel();
    });
    return const QuranPlayback();
  }

  /// [ayahNumbers] sırasındaki [index] konumundan tilaveti başlatır.
  Future<void> playAt(int surahNumber, List<int> ayahNumbers, int index) async {
    if (index < 0 || index >= ayahNumbers.length) return;
    state = QuranPlayback(
      surahNumber: surahNumber,
      ayahNumbers: ayahNumbers,
      index: index,
      playing: true,
    );
    await _audio.playUrl(_ayahAudioUrl(surahNumber, ayahNumbers[index]));
  }

  /// Oynat/duraklat — aynı ayette kaldığı yerden devam eder.
  Future<void> toggle() async {
    if (!state.active) return;
    if (state.playing) {
      await _audio.pause();
    } else {
      await _audio.player.play();
    }
  }

  Future<void> next() => _jump(state.index + 1);
  Future<void> previous() => _jump(state.index - 1);

  Future<void> _jump(int i) async {
    if (!state.active || i < 0 || i >= state.ayahNumbers.length) return;
    state = state.copyWith(index: i, playing: true);
    await _audio.playUrl(_ayahAudioUrl(state.surahNumber!, state.ayahNumbers[i]));
  }

  void _onComplete() {
    if (state.hasNext) {
      _jump(state.index + 1);
    } else if (state.active) {
      state = state.copyWith(playing: false);
    }
  }

  Future<void> stop() async {
    await _audio.stop();
    state = const QuranPlayback();
  }
}

final quranPlayerProvider =
    NotifierProvider<QuranPlayerController, QuranPlayback>(
        QuranPlayerController.new);

class QuranScreen extends ConsumerStatefulWidget {
  const QuranScreen({super.key});
  @override
  ConsumerState<QuranScreen> createState() => _QuranScreenState();
}

/// Sure listesi filtre seçenekleri.
enum _SurahFilter { all, favorites }

class _QuranScreenState extends ConsumerState<QuranScreen> {
  String _query = '';
  _SurahFilter _filter = _SurahFilter.all;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(surahsProvider);
    final favoriteIds = ref
        .watch(favoritesServiceProvider)
        .watchFavoriteIds();
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppHeader(title: 'Kur\'an Okuma'),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: TextField(
                onChanged: (v) => setState(() => _query = v.toLowerCase()),
                decoration: const InputDecoration(
                  hintText: 'Sure ara…',
                  prefixIcon: Icon(Icons.search_rounded, color: AppColors.gold),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: SegmentedButton<_SurahFilter>(
                segments: const [
                  ButtonSegment(
                    value: _SurahFilter.all,
                    label: Text('Tüm Sureler'),
                    icon: Icon(Icons.menu_book_rounded),
                  ),
                  ButtonSegment(
                    value: _SurahFilter.favorites,
                    label: Text('Favoriler'),
                    icon: Icon(Icons.star_rounded),
                  ),
                ],
                selected: {_filter},
                onSelectionChanged: (s) => setState(() => _filter = s.first),
                style: ButtonStyle(
                  foregroundColor: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.selected)
                        ? AppColors.onGold
                        : AppColors.muted,
                  ),
                  backgroundColor: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.selected)
                        ? AppColors.gold
                        : Colors.transparent,
                  ),
                ),
              ),
            ),
            Expanded(
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => EmptyState(icon: Icons.error_outline_rounded, message: '$e'),
                data: (surahs) {
                  return StreamBuilder<List<int>>(
                    stream: favoriteIds,
                    initialData: const [],
                    builder: (context, snapshot) {
                      final favIds = snapshot.data ?? [];
                      var list = _query.isEmpty
                          ? surahs
                          : surahs
                              .where((s) =>
                                  s.nameTr.toLowerCase().contains(_query) ||
                                  s.number.toString() == _query)
                              .toList();
                      if (_filter == _SurahFilter.favorites) {
                        list = list
                            .where((s) => favIds.contains(s.number))
                            .toList();
                      }
                      if (list.isEmpty && _filter == _SurahFilter.favorites) {
                        return const EmptyState(
                          icon: Icons.star_border_rounded,
                          message: 'Henüz favori sure eklemediniz.\nSure listesinde yıldız simgesine dokunun.',
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        itemCount: list.length,
                        itemBuilder: (context, i) {
                          final s = list[i];
                          final isFav = favIds.contains(s.number);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: AppCard(
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => SurahReaderScreen(surah: s),
                                ),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 40,
                                    child: Text('${s.number}',
                                        textAlign: TextAlign.center,
                                        style: AppTypography.display(size: 20, color: AppColors.gold)),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(s.nameTr,
                                            style: AppTypography.body(
                                                size: 16, weight: FontWeight.w600, color: AppColors.cream)),
                                        Text('${s.meaning} · ${s.ayahCount} ayet · ${s.revelation}',
                                            style: AppTypography.body(size: 12, color: AppColors.muted)),
                                      ],
                                    ),
                                  ),
                                  Directionality(
                                    textDirection: TextDirection.rtl,
                                    child: Text(s.nameArabic, style: arabicStyle(size: 22)),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: Icon(
                                      isFav ? Icons.star_rounded : Icons.star_border_rounded,
                                      color: isFav ? AppColors.gold : AppColors.muted,
                                    ),
                                    tooltip: isFav ? 'Favorilerden çıkar' : 'Favorilere ekle',
                                    onPressed: () => ref
                                        .read(favoritesServiceProvider)
                                        .toggleFavorite(s.number),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SurahReaderScreen extends ConsumerStatefulWidget {
  const SurahReaderScreen({super.key, required this.surah, this.initialAyah});
  final Surah surah;

  /// Ayet Bulucu "Okuyucuda Aç" ile gelindiğinde bu ayete kaydırılır + vurgulanır.
  final int? initialAyah;

  @override
  ConsumerState<SurahReaderScreen> createState() => _SurahReaderScreenState();
}

class _SurahReaderScreenState extends ConsumerState<SurahReaderScreen> {
  bool _sepia = false;
  final _stopwatch = Stopwatch();

  // "Okuyucuda Aç" hedef ayeti: kaydırma anahtarı + tek seferlik kaydırma + vurgu.
  final _targetKey = GlobalKey();
  bool _didScroll = false;
  bool _highlight = false;

  @override
  void initState() {
    super.initState();
    _stopwatch.start();
  }

  /// Veri yüklendikten sonra hedef ayete bir kez kaydır + kısa vurgu.
  void _scrollToInitial() {
    if (_didScroll || widget.initialAyah == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _targetKey.currentContext;
      if (ctx == null || !mounted) return;
      _didScroll = true;
      Scrollable.ensureVisible(ctx,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
          alignment: 0.12);
      setState(() => _highlight = true);
      Future.delayed(const Duration(milliseconds: 1900), () {
        if (mounted) setState(() => _highlight = false);
      });
    });
  }

  @override
  void dispose() {
    _stopwatch.stop();
    ref.read(statsServiceProvider).recordReading(
      surahId: widget.surah.number,
      ayahCount: widget.surah.ayahCount,
      durationSeconds: _stopwatch.elapsed.inSeconds,
    );
    // Ekrandan çıkınca tilaveti durdur — kontrolü olmayan arka plan sesi kalmasın.
    ref.read(quranPlayerProvider.notifier).stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.surah;
    final async = ref.watch(surahAyahsProvider(s.number));
    final bg = _sepia ? const Color(0xFFF3EADB) : AppColors.emerald950;
    final fg = _sepia ? const Color(0xFF2C2418) : AppColors.cream;
    final sub = _sepia ? const Color(0xFF6A5B41) : AppColors.muted;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppHeader(
              title: s.nameTr,
              trailing: IconButton(
                icon: Icon(_sepia ? Icons.dark_mode_rounded : Icons.wb_sunny_rounded,
                    color: AppColors.gold),
                onPressed: () => setState(() => _sepia = !_sepia),
              ),
            ),
            Expanded(
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => EmptyState(icon: Icons.error_outline_rounded, message: '$e'),
                data: (ayahs) {
                  if (ayahs.isEmpty) {
                    return EmptyState(
                      icon: Icons.menu_book_rounded,
                      message:
                          '${s.nameTr} suresinin metni bu sürümde henüz paketlenmedi.\nKısa ve meşhur sureler okunmaya hazır.',
                    );
                  }
                  final ayahNumbers = [for (final a in ayahs) a.numberInSurah];
                  _scrollToInitial(); // veri hazır → hedef ayete kaydır
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    children: [
                      if (s.number != 9)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: Directionality(
                            textDirection: TextDirection.rtl,
                            child: Text('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                                textAlign: TextAlign.center,
                                style: arabicStyle(size: 24, color: AppColors.gold)),
                          ),
                        ),
                      for (var i = 0; i < ayahs.length; i++)
                        Builder(builder: (_) {
                          final isTarget = ayahs[i].numberInSurah == widget.initialAyah;
                          final tile = _AyahTile(
                            surah: s,
                            ayah: ayahs[i],
                            index: i,
                            ayahNumbers: ayahNumbers,
                            fg: fg,
                            sub: sub,
                          );
                          if (!isTarget) return tile;
                          // Hedef ayet: kaydırma anahtarı + solup giden altın vurgu.
                          return AnimatedContainer(
                            key: _targetKey,
                            duration: AppDurations.slow,
                            curve: Curves.easeOut,
                            decoration: BoxDecoration(
                              color: _highlight
                                  ? AppColors.gold.withValues(alpha: 0.14)
                                  : Colors.transparent,
                              borderRadius: AppRadii.mdAll,
                            ),
                            child: tile,
                          );
                        }),
                    ],
                  );
                },
              ),
            ),
            _TilawahBar(surahNumber: s.number, sepia: _sepia),
          ],
        ),
      ),
    );
  }
}

/// Tilavet media bar'ı — yalnızca bu sure çalarken görünür. Geri / oynat-duraklat
/// / ileri kontrolleri + ilerleme çubuğu + "Ayet X / N" göstergesi.
class _TilawahBar extends ConsumerWidget {
  const _TilawahBar({required this.surahNumber, required this.sepia});
  final int surahNumber;
  final bool sepia;

  static String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pb = ref.watch(quranPlayerProvider);
    // Sadece bu sureye ait aktif tilavette barı göster.
    if (!pb.active || pb.surahNumber != surahNumber) {
      return const SizedBox.shrink();
    }

    final ctrl = ref.read(quranPlayerProvider.notifier);
    final player = ref.read(audioServiceProvider).player;
    final barBg = sepia ? const Color(0xFFEADFCB) : AppColors.emerald900;
    final fg = sepia ? const Color(0xFF2C2418) : AppColors.cream;

    return Container(
      decoration: BoxDecoration(
        color: barBg,
        border: Border(top: BorderSide(color: AppColors.lineSoft)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // İlerleme çubuğu — gerçek oynatıcı konumundan beslenir.
          StreamBuilder<Duration?>(
            stream: player.durationStream,
            builder: (context, durSnap) {
              final dur = durSnap.data ?? Duration.zero;
              return StreamBuilder<Duration>(
                stream: player.positionStream,
                builder: (context, posSnap) {
                  var pos = posSnap.data ?? Duration.zero;
                  if (pos > dur) pos = dur;
                  final maxMs = dur.inMilliseconds.toDouble();
                  return Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 2.5,
                          activeTrackColor: AppColors.gold,
                          inactiveTrackColor: AppColors.lineSoft,
                          thumbColor: AppColors.gold,
                          overlayShape:
                              const RoundSliderOverlayShape(overlayRadius: 14),
                          thumbShape:
                              const RoundSliderThumbShape(enabledThumbRadius: 6),
                        ),
                        child: Slider(
                          value: maxMs <= 0
                              ? 0
                              : pos.inMilliseconds.clamp(0, dur.inMilliseconds).toDouble(),
                          max: maxMs <= 0 ? 1 : maxMs,
                          onChanged: maxMs <= 0
                              ? null
                              : (v) => player.seek(Duration(milliseconds: v.round())),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_fmt(pos),
                                style: AppTypography.body(size: 11, color: fg)),
                            Text(_fmt(dur),
                                style: AppTypography.body(size: 11, color: fg)),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          Row(
            children: [
              SizedBox(
                width: 64,
                child: Text('Ayet ${pb.currentAyah}/${pb.total}',
                    style: AppTypography.body(size: 12, color: fg)),
              ),
              const Spacer(),
              IconButton(
                iconSize: 34,
                icon: Icon(Icons.skip_previous_rounded,
                    color: pb.hasPrev ? AppColors.gold : AppColors.muted),
                onPressed: pb.hasPrev ? ctrl.previous : null,
              ),
              IconButton(
                iconSize: 48,
                icon: Icon(
                  pb.playing
                      ? Icons.pause_circle_filled_rounded
                      : Icons.play_circle_fill_rounded,
                  color: AppColors.gold,
                ),
                onPressed: ctrl.toggle,
              ),
              IconButton(
                iconSize: 34,
                icon: Icon(Icons.skip_next_rounded,
                    color: pb.hasNext ? AppColors.gold : AppColors.muted),
                onPressed: pb.hasNext ? ctrl.next : null,
              ),
              const Spacer(),
              SizedBox(
                width: 64,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    iconSize: 22,
                    icon: Icon(Icons.close_rounded, color: AppColors.muted),
                    onPressed: ctrl.stop,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AyahTile extends ConsumerWidget {
  const _AyahTile({
    required this.surah,
    required this.ayah,
    required this.index,
    required this.ayahNumbers,
    required this.fg,
    required this.sub,
  });
  final Surah surah;
  final Ayah ayah;
  final int index;
  final List<int> ayahNumbers;
  final Color fg;
  final Color sub;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pb = ref.watch(quranPlayerProvider);
    final isCurrent = pb.isCurrent(surah.number, ayah.numberInSurah);
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isCurrent ? AppColors.gold : AppColors.goldFaint,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.gold),
                ),
                child: Text('${ayah.numberInSurah}',
                    style: AppTypography.body(
                        size: 12,
                        weight: FontWeight.w700,
                        color: isCurrent ? AppColors.onGold : AppColors.gold)),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  isCurrent && pb.playing
                      ? Icons.pause_circle_outline_rounded
                      : Icons.play_circle_outline_rounded,
                  color: AppColors.gold,
                ),
                onPressed: () => isCurrent
                    ? ref.read(quranPlayerProvider.notifier).toggle()
                    : ref
                        .read(quranPlayerProvider.notifier)
                        .playAt(surah.number, ayahNumbers, index),
              ),
              Consumer(
                builder: (context, ref, _) {
                  final tts = ref.watch(ttsServiceProvider);
                  return IconButton(
                    icon: Icon(
                      tts.isSpeaking
                          ? Icons.stop_circle_outlined
                          : Icons.volume_up_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    tooltip: tts.isSpeaking ? 'Durdur' : 'Sesli Dinle',
                    onPressed: () {
                      if (tts.isSpeaking) {
                        tts.stop();
                      } else {
                        tts.speak(ayah.meal);
                      }
                    },
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.bookmark_add_outlined, color: AppColors.gold),
                onPressed: () async {
                  await ref.read(collectionsRepositoryProvider).add(
                        reference: '${surah.nameTr}, ${ayah.numberInSurah}',
                        arabic: ayah.arabic,
                        meal: ayah.meal,
                      );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Koleksiyona kaydedildi.')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(ayah.arabic,
                textAlign: TextAlign.right, style: arabicStyle(size: 28, color: AppColors.gold)),
          ),
          const SizedBox(height: 12),
          Text(ayah.meal, style: AppTypography.body(size: 16, color: fg)),
          const SizedBox(height: 12),
          Divider(color: AppColors.lineSoft),
        ],
      ),
    );
  }
}
