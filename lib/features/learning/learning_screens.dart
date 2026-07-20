import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/local/app_database.dart';
import '../../data/repositories.dart';
import '../../ui/core/theme/app_colors.dart';
import '../../ui/core/theme/app_theme.dart';
import '../../ui/core/widgets.dart';

final miraclesProvider = FutureProvider<List<Miracle>>(
  (ref) => ref.read(contentRepositoryProvider).miracles(),
);
final storiesProvider = FutureProvider<List<Story>>(
  (ref) => ref.read(contentRepositoryProvider).stories(),
);
final tajweedProvider = FutureProvider<List<TajweedLesson>>(
  (ref) => ref.read(contentRepositoryProvider).tajweed(),
);

// ── Kuran Mucizeleri ────────────────────────────────────────────────────────

class MiraclesScreen extends ConsumerWidget {
  const MiraclesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(miraclesProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppHeader(title: 'Kuran Mucizeleri'),
            Expanded(
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => EmptyState(icon: Icons.error_outline_rounded, message: '$e'),
                data: (items) {
                  final cats = <String>{for (final m in items) m.category}.toList();
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    children: [
                      for (final c in cats) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(c, style: AppTypography.display(size: 20)),
                        ),
                        for (final m in items.where((m) => m.category == c))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: AppCard(
                              onTap: () => _showText(context, m.title, m.body),
                              child: Row(
                                children: [
                                  const Icon(Icons.science_rounded, color: AppColors.gold),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(m.title,
                                        style: AppTypography.body(
                                            size: 15.5, weight: FontWeight.w600, color: AppColors.cream)),
                                  ),
                                  Icon(Icons.chevron_right_rounded, color: AppColors.muted),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ],
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

// ── Peygamber Kıssaları ─────────────────────────────────────────────────────

class StoriesScreen extends ConsumerWidget {
  const StoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(storiesProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppHeader(title: 'Peygamber Kıssaları'),
            Expanded(
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => EmptyState(icon: Icons.error_outline_rounded, message: '$e'),
                data: (items) => ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: [
                    for (final s in items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: AppCard(
                          onTap: () => _showText(context, s.title, s.body),
                          child: Row(
                            children: [
                              const Icon(Icons.history_edu_rounded, color: AppColors.gold),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(s.title,
                                        style: AppTypography.body(
                                            size: 16, weight: FontWeight.w600, color: AppColors.cream)),
                                    Text('${s.summary} · ${s.readMinutes} dk',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.body(size: 12.5, color: AppColors.muted)),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right_rounded, color: AppColors.muted),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(duration: AppDurations.fast),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tecvid Dersleri (PRO) ───────────────────────────────────────────────────

class TajweedScreen extends ConsumerWidget {
  const TajweedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(tajweedProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppHeader(title: 'Tecvid Dersleri'),
            Expanded(
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => EmptyState(icon: Icons.error_outline_rounded, message: '$e'),
                data: (lessons) => ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: () => _startQuiz(context, lessons),
                      icon: const Icon(Icons.quiz_rounded),
                      label: const Text('Mini Quiz başlat'),
                    ),
                    const SizedBox(height: 14),
                    for (final l in lessons)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: AppCard(
                          onTap: () => _showLesson(context, l),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l.title,
                                  style: AppTypography.body(
                                      size: 16, weight: FontWeight.w700, color: AppColors.cream)),
                              const SizedBox(height: 4),
                              Text(l.rule, style: AppTypography.body(size: 13.5, color: AppColors.muted)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLesson(BuildContext context, TajweedLesson l) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          children: [
            Text(l.title, style: AppTypography.display(size: 24)),
            const SizedBox(height: 6),
            Text(l.rule, style: AppTypography.body(size: 15, color: AppColors.gold)),
            const SizedBox(height: 16),
            AyetFrame(arabic: l.example, fontSize: 24),
            const SizedBox(height: 16),
            Text(l.body, style: AppTypography.body(size: 16, color: AppColors.cream)),
          ],
        ),
      ),
    );
  }

  void _startQuiz(BuildContext context, List<TajweedLesson> lessons) {
    if (lessons.length < 4) return;
    showDialog<void>(
      context: context,
      builder: (_) => _TajweedQuizDialog(lessons: lessons),
    );
  }
}

void _showText(BuildContext context, String title, String body) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      builder: (_, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          Text(title, style: AppTypography.display(size: 24)),
          const SizedBox(height: 14),
          Text(body, style: AppTypography.body(size: 16, color: AppColors.cream)),
        ],
      ),
    ),
  );
}

class _TajweedQuizDialog extends StatefulWidget {
  const _TajweedQuizDialog({required this.lessons});
  final List<TajweedLesson> lessons;
  @override
  State<_TajweedQuizDialog> createState() => _TajweedQuizDialogState();
}

class _TajweedQuizDialogState extends State<_TajweedQuizDialog> {
  int _i = 0;
  int _score = 0;
  bool _answered = false;

  @override
  Widget build(BuildContext context) {
    final lessons = widget.lessons;
    final count = lessons.length < 5 ? lessons.length : 5;
    final lesson = lessons[_i % lessons.length];
    final options = <String>{lesson.title};
    for (final l in lessons) {
      if (options.length >= 4) break;
      options.add(l.title);
    }
    final shuffled = options.toList()..sort((a, b) => a.length.compareTo(b.length));

    return AlertDialog(
      backgroundColor: AppColors.emerald850,
      title: Text('Soru ${_i + 1} / $count', style: AppTypography.display(size: 20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bu kural hangi tecvid konusudur?',
              style: AppTypography.body(size: 14, color: AppColors.muted)),
          const SizedBox(height: 10),
          Text(lesson.rule, style: AppTypography.body(size: 15, color: AppColors.cream)),
          const SizedBox(height: 14),
          for (final o in shuffled)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GoldChip(
                label: o,
                selected: false,
                onTap: _answered
                    ? null
                    : () {
                        final navigator = Navigator.of(context);
                        final messenger = ScaffoldMessenger.of(context);
                        setState(() {
                          _answered = true;
                          if (o == lesson.title) _score++;
                        });
                        Future<void>.delayed(const Duration(milliseconds: 400), () {
                          if (!mounted) return;
                          if (_i + 1 >= count) {
                            navigator.pop();
                            messenger.showSnackBar(
                              SnackBar(content: Text('Quiz bitti! Skor: $_score / $count')),
                            );
                          } else {
                            setState(() {
                              _i++;
                              _answered = false;
                            });
                          }
                        });
                      },
              ),
            ),
        ],
      ),
    );
  }
}

// ── Sure Bilgisi Quiz ────────────────────────────────────────────────────────

/// Sure quiz soru tipleri.
enum _QuizType { orderToName, nameToVerseCount, nameToRevelation, nameToMeaning }

/// Tek bir quiz sorusu.
class _Question {
  const _Question({
    required this.prompt,
    required this.correctAnswer,
    required this.choices,
    required this.type,
  });

  final String prompt;
  final String correctAnswer;
  final List<String> choices; // 4 şık, karışık sırada
  final _QuizType type;
}

/// SharedPreferences anahtarı.
const _kHighScoreKey = 'surah_quiz_high_score';

final _surahsForQuizProvider = FutureProvider<List<Surah>>(
  (ref) => ref.read(contentRepositoryProvider).surahs(),
);

class SurahQuizScreen extends ConsumerStatefulWidget {
  const SurahQuizScreen({super.key});

  @override
  ConsumerState<SurahQuizScreen> createState() => _SurahQuizScreenState();
}

class _SurahQuizScreenState extends ConsumerState<SurahQuizScreen> {
  // Ekran aşamaları: 'start' | 'quiz' | 'result'
  String _phase = 'start';

  List<_Question> _questions = [];
  int _current = 0;
  int _score = 0;
  String? _selectedChoice; // kullanıcının seçtiği şık
  bool _answered = false;
  int _highScore = 0;

  // Yanlış cevaplanan soruların özeti
  final List<({String prompt, String correct, String selected})> _wrongs = [];

  @override
  void initState() {
    super.initState();
    _loadHighScore();
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _highScore = prefs.getInt(_kHighScoreKey) ?? 0);
    }
  }

  Future<void> _saveHighScore(int score) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_kHighScoreKey) ?? 0;
    if (score > current) {
      await prefs.setInt(_kHighScoreKey, score);
      if (mounted) setState(() => _highScore = score);
    }
  }

  /// 114 sure listesinden 10 soru üretir.
  List<_Question> _buildQuestions(List<Surah> surahs) {
    final rng = Random();
    final shuffled = [...surahs]..shuffle(rng);

    // Her soru tipi için kullanılacak sure listesi (döngü)
    int idx = 0;
    Surah nextSurah() => shuffled[idx++ % shuffled.length];

    final questions = <_Question>[];

    // Tip dağılımı: 3 adet orderToName, 3 adet nameToVerseCount,
    //               2 adet nameToRevelation, 2 adet nameToMeaning
    final plan = [
      _QuizType.orderToName,
      _QuizType.orderToName,
      _QuizType.orderToName,
      _QuizType.nameToVerseCount,
      _QuizType.nameToVerseCount,
      _QuizType.nameToVerseCount,
      _QuizType.nameToRevelation,
      _QuizType.nameToRevelation,
      _QuizType.nameToMeaning,
      _QuizType.nameToMeaning,
    ]..shuffle(rng);

    for (final type in plan) {
      final surah = nextSurah();
      _Question? q;

      switch (type) {
        case _QuizType.orderToName:
          // "Kur'an'ın X. suresi hangisidir?"
          final correct = surah.nameTr;
          final wrongs = _pickWrong(surahs, surah, (s) => s.nameTr, rng);
          final choices = ([correct, ...wrongs])..shuffle(rng);
          q = _Question(
            type: type,
            prompt: "Kur'an'ın ${surah.number}. suresi hangisidir?",
            correctAnswer: correct,
            choices: choices,
          );

        case _QuizType.nameToVerseCount:
          // "X suresi kaç ayettir?"
          final correct = '${surah.ayahCount}';
          final wrongs = _pickWrong(surahs, surah, (s) => '${s.ayahCount}', rng);
          final choices = ([correct, ...wrongs])..shuffle(rng);
          q = _Question(
            type: type,
            prompt: '${surah.nameTr} suresi kaç ayettir?',
            correctAnswer: correct,
            choices: choices,
          );

        case _QuizType.nameToRevelation:
          // "X suresi nerede indi?"
          final correct = surah.revelation; // "Mekki" | "Medeni"
          const options = ['Mekki', 'Medeni'];
          q = _Question(
            type: type,
            prompt: '${surah.nameTr} suresi nerede indi?',
            correctAnswer: correct,
            choices: List<String>.from(options)..shuffle(rng),
          );

        case _QuizType.nameToMeaning:
          // "X suresinin anlamı nedir?"
          final correct = surah.meaning;
          final wrongs = _pickWrong(surahs, surah, (s) => s.meaning, rng);
          final choices = ([correct, ...wrongs])..shuffle(rng);
          q = _Question(
            type: type,
            prompt: '${surah.nameTr} suresinin anlamı nedir?',
            correctAnswer: correct,
            choices: choices,
          );
      }

      questions.add(q);
    }

    return questions;
  }

  /// Doğru cevap dışından 3 farklı yanlış şık seçer.
  List<String> _pickWrong(
    List<Surah> all,
    Surah exclude,
    String Function(Surah) extract,
    Random rng,
  ) {
    final pool =
        all.where((s) => s.number != exclude.number).map(extract).toSet().toList()
          ..shuffle(rng);
    return pool.take(3).toList();
  }

  void _startQuiz(List<Surah> surahs) {
    final qs = _buildQuestions(surahs);
    setState(() {
      _questions = qs;
      _current = 0;
      _score = 0;
      _selectedChoice = null;
      _answered = false;
      _wrongs.clear();
      _phase = 'quiz';
    });
  }

  void _selectChoice(String choice) {
    if (_answered) return;
    final q = _questions[_current];
    final isCorrect = choice == q.correctAnswer;
    setState(() {
      _selectedChoice = choice;
      _answered = true;
      if (isCorrect) {
        _score++;
      } else {
        _wrongs.add((
          prompt: q.prompt,
          correct: q.correctAnswer,
          selected: choice,
        ));
      }
    });
  }

  void _next() {
    if (_current + 1 >= _questions.length) {
      // Quiz bitti
      _saveHighScore(_score);
      setState(() => _phase = 'result');
    } else {
      setState(() {
        _current++;
        _selectedChoice = null;
        _answered = false;
      });
    }
  }

  void _restart() {
    setState(() => _phase = 'start');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: switch (_phase) {
          'quiz' => _buildQuizPhase(),
          'result' => _buildResultPhase(),
          _ => _buildStartPhase(),
        },
      ),
    );
  }

  // ── Başlangıç ekranı ─────────────────────────────────────────────────────

  Widget _buildStartPhase() {
    final async = ref.watch(_surahsForQuizProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppHeader(title: 'Sure Quiz'),
        Expanded(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) =>
                EmptyState(icon: Icons.error_outline_rounded, message: '$e'),
            data: (surahs) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.quiz_rounded, size: 72, color: AppColors.gold),
                  const SizedBox(height: 20),
                  Text(
                    'Sure Bilgisi Testi',
                    style: AppTypography.display(size: 26),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '10 soruda sure adları, ayet sayıları, iniş yerleri ve anlamlarını test edin.',
                    style: AppTypography.body(size: 15, color: AppColors.muted),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  if (_highScore > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.emerald850,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.emoji_events_rounded,
                              color: AppColors.gold, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'En yüksek skor: $_highScore / 10',
                            style: AppTypography.body(
                                size: 15,
                                weight: FontWeight.w600,
                                color: AppColors.cream),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  FilledButton.icon(
                    onPressed: surahs.length >= 4 ? () => _startQuiz(surahs) : null,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Quiz\'e Başla'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Quiz ekranı ──────────────────────────────────────────────────────────

  Widget _buildQuizPhase() {
    final q = _questions[_current];
    final total = _questions.length;
    final progress = (_current + (_answered ? 1 : 0)) / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppHeader(title: 'Sure Quiz'),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Soru ${_current + 1}/$total',
                    style: AppTypography.body(
                        size: 13, color: AppColors.muted, weight: FontWeight.w600),
                  ),
                  Text(
                    'Skor: $_score',
                    style: AppTypography.body(
                        size: 13, color: AppColors.gold, weight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: AppColors.emerald850,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.gold),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Soru kartı
                AppCard(
                  child: Text(
                    q.prompt,
                    style: AppTypography.body(
                        size: 17, weight: FontWeight.w600, color: AppColors.cream),
                    textAlign: TextAlign.center,
                  ),
                ).animate().fadeIn(duration: AppDurations.fast),
                const SizedBox(height: 16),

                // 4 şık butonu
                for (final choice in q.choices) ...[
                  _ChoiceButton(
                    label: choice,
                    state: _choiceState(choice, q.correctAnswer),
                    onTap: _answered ? null : () => _selectChoice(choice),
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 6),

                // "İleri" butonu — sadece seçim yapıldıktan sonra görünür
                if (_answered)
                  FilledButton(
                    onPressed: _next,
                    child: Text(
                      _current + 1 >= total ? 'Sonuçları Gör' : 'İleri',
                    ),
                  ).animate().fadeIn(duration: AppDurations.fast),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Şık buton durumu: null = seçilmemiş, true = doğru, false = yanlış.
  bool? _choiceState(String choice, String correctAnswer) {
    if (!_answered) return null;
    if (choice == correctAnswer) return true;
    if (choice == _selectedChoice) return false;
    return null; // diğerleri nötr
  }

  // ── Sonuç ekranı ─────────────────────────────────────────────────────────

  Widget _buildResultPhase() {
    final isNewRecord = _score > 0 && _score >= _highScore;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppHeader(title: 'Sonuç'),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              children: [
                const SizedBox(height: 24),
                // Skor dairesi
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.gold, width: 3),
                    color: AppColors.emerald850,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$_score',
                        style: AppTypography.display(size: 42),
                      ),
                      Text(
                        '/ ${_questions.length}',
                        style:
                            AppTypography.body(size: 16, color: AppColors.muted),
                      ),
                    ],
                  ),
                ).animate().scale(duration: AppDurations.normal),
                const SizedBox(height: 16),

                if (isNewRecord)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.emoji_events_rounded,
                          color: AppColors.gold, size: 22),
                      const SizedBox(width: 6),
                      Text(
                        'Yeni Rekor!',
                        style: AppTypography.body(
                            size: 17,
                            weight: FontWeight.w700,
                            color: AppColors.gold),
                      ),
                    ],
                  ).animate().fadeIn(),

                const SizedBox(height: 8),
                Text(
                  _resultMessage(_score, _questions.length),
                  style: AppTypography.body(size: 15, color: AppColors.muted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),

                // Yanlışların özeti
                if (_wrongs.isNotEmpty) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Yanlış Cevaplarınız',
                      style: AppTypography.display(size: 18),
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (final w in _wrongs)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              w.prompt,
                              style: AppTypography.body(
                                  size: 13.5,
                                  color: AppColors.muted,
                                  weight: FontWeight.w500),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.check_circle_rounded,
                                    color: Color(0xFF4CAF50), size: 16),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    w.correct,
                                    style: AppTypography.body(
                                        size: 14,
                                        color: Color(0xFF4CAF50),
                                        weight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.cancel_rounded,
                                    color: Color(0xFFEF5350), size: 16),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    w.selected,
                                    style: AppTypography.body(
                                        size: 14,
                                        color: Color(0xFFEF5350)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                ],

                FilledButton.icon(
                  onPressed: _restart,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Tekrar Dene'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _resultMessage(int score, int total) {
    final pct = score / total;
    if (pct == 1.0) return 'Mükemmel! Tüm soruları doğru cevapladınız.';
    if (pct >= 0.8) return 'Harika! Kur\'an bilginiz çok iyi.';
    if (pct >= 0.6) return 'İyi bir başlangıç, biraz daha çalışın.';
    if (pct >= 0.4) return 'Devam edin, her tekrar öğretir.';
    return 'Sureleri gözden geçirmeye ne dersiniz?';
  }
}

/// Şık butonu — seçim durumuna göre renk değiştirir.
class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({
    required this.label,
    required this.state, // null=nötr, true=doğru, false=yanlış
    required this.onTap,
  });

  final String label;
  final bool? state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color border;
    final Color bg;
    final Color fg;

    switch (state) {
      case true:
        border = const Color(0xFF4CAF50);
        bg = const Color(0xFF4CAF50).withValues(alpha: 0.15);
        fg = const Color(0xFF4CAF50);
      case false:
        border = const Color(0xFFEF5350);
        bg = const Color(0xFFEF5350).withValues(alpha: 0.15);
        fg = const Color(0xFFEF5350);
      case null:
        border = AppColors.muted.withValues(alpha: 0.35);
        bg = Colors.transparent;
        fg = AppColors.cream;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 1.5),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Text(
            label,
            style: AppTypography.body(size: 15, color: fg, weight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
