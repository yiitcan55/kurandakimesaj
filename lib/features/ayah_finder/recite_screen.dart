import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ui/core/theme/app_colors.dart';
import '../../ui/core/theme/app_theme.dart';
import '../../ui/core/widgets.dart';
import 'ayah_finder_screen.dart';
import 'recite_controller.dart';

/// Okuyarak Bul — kullanıcı ayeti sesli okur, cihazın ses tanıyıcısı (Arapça)
/// dinler, tanınan metin yerel olarak Kur'an'la eşleştirilir. Mantık
/// `ReciteController`'dadır; ekran yalnız durumu çizer.
class ReciteScreen extends ConsumerWidget {
  const ReciteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matcher = ref.watch(quranMatcherProvider);
    final s = ref.watch(reciteControllerProvider);
    final controller = ref.read(reciteControllerProvider.notifier);

    final listening = s.status == ReciteStatus.listening;
    final preparing = s.status == ReciteStatus.preparing || matcher.isLoading;
    final canTap = matcher.hasValue && s.status != ReciteStatus.preparing;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppHeader(title: 'Okuyarak Bul'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                children: [
                  Text(
                    'Ayeti sesli oku; cihazının ses tanıyıcısı dinleyip hangi '
                    'ayet olduğunu bulur. Uygulama sesi kaydetmez; tanımayı '
                    'telefonun ses servisi (Google/Apple) yapar.',
                    style: AppTypography.body(size: 14, color: AppColors.muted),
                  ),
                  const SizedBox(height: 22),
                  if (matcher.hasError)
                    const EmptyState(
                      icon: Icons.error_outline_rounded,
                      message: 'Kur\'an verisi yüklenemedi.\n'
                          'Uygulamayı kapatıp yeniden açmayı dene.',
                    )
                  else ...[
                    Center(
                      child: _MicButton(
                        listening: listening,
                        enabled: canTap,
                        onTap: listening ? controller.stop : controller.start,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      listening
                          ? 'Dinliyorum… bitirince tekrar dokun'
                          : preparing
                              ? 'Hazırlanıyor…'
                              : 'Okumaya başlamak için dokun',
                      textAlign: TextAlign.center,
                      style: AppTypography.body(size: 13.5, color: AppColors.muted),
                    ),
                    if (preparing && !listening) ...[
                      const SizedBox(height: 14),
                      LinearProgressIndicator(
                        color: AppColors.goldInk,
                        backgroundColor: AppColors.goldFaint,
                      ),
                    ],
                  ],
                  if (s.error != null) ...[
                    const SizedBox(height: 18),
                    _ErrorNote(message: s.error!),
                  ],
                  if (s.heard.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    _HeardCard(text: s.heard),
                  ],
                  const SizedBox(height: 22),
                  if (s.matches.isNotEmpty) ...[
                    Text('Olası ayetler',
                        style: AppTypography.body(size: 14, color: AppColors.cream2)),
                    const SizedBox(height: 12),
                    for (var i = 0; i < s.matches.length; i++) ...[
                      AyahMatchCard(match: s.matches[i], primary: i == 0),
                      const SizedBox(height: 12),
                    ],
                  ] else if (!listening && s.heard.isNotEmpty)
                    const EmptyState(
                      icon: Icons.search_off_rounded,
                      message: 'Eşleşen bir ayet bulunamadı.\n'
                          'Biraz daha yavaş ve net okuyup tekrar dene.',
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Büyük mikrofon / durdur düğmesi (88 px — ≥44 px dokunma hedefi).
class _MicButton extends StatelessWidget {
  const _MicButton({
    required this.listening,
    required this.enabled,
    required this.onTap,
  });
  final bool listening;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = !enabled
        ? AppColors.goldFaint
        : (listening ? AppColors.danger : AppColors.gold);
    return Semantics(
      button: true,
      enabled: enabled,
      label: listening ? 'Dinlemeyi durdur' : 'Okumaya başla',
      onTap: enabled ? onTap : null,
      child: ExcludeSemantics(
        child: Material(
          key: const Key('reciteMicButton'),
          color: color,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: enabled ? onTap : null,
            child: SizedBox(
              width: 88,
              height: 88,
              child: Icon(
                listening ? Icons.stop_rounded : Icons.mic_rounded,
                size: 40,
                color: enabled ? AppColors.onGold : AppColors.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorNote extends StatelessWidget {
  const _ErrorNote({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.warning),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message,
                style: AppTypography.body(size: 14, color: AppColors.cream)),
          ),
        ],
      ),
    );
  }
}

/// Tanıyıcının duyduğu Arapça metin (RTL, Amiri Quran).
class _HeardCard extends StatelessWidget {
  const _HeardCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('DUYULAN', style: AppTypography.eyebrow()),
          const SizedBox(height: 8),
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              text,
              key: const Key('reciteHeardText'),
              textAlign: TextAlign.center,
              style: arabicStyle(size: 24),
            ),
          ),
        ],
      ),
    );
  }
}
