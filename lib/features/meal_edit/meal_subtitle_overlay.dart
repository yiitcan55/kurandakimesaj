import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../domain/meal_cues.dart';
import '../../ui/core/theme/app_colors.dart';
import '../../ui/core/theme/app_theme.dart';
import '../quran/quran_screens.dart';

/// Videonun üstüne binen zaman kodlu altyazı: etkin cue'nun ayet no'su + meali
/// (+ Arapça stilinde Arapça satır). İçsel boyutlu kutudur; yerleşimi
/// (Positioned/Align) ebeveyn yapar. Meal cue'da taşınmaz, `surahAyahsProvider`
/// ile çözülür. Renkler video üstünde sabittir (tema dönmez).
class MealSubtitleOverlay extends ConsumerWidget {
  const MealSubtitleOverlay({
    super.key,
    required this.position,
    required this.cues,
    this.style = MealCueStyle.standard,
  });

  final ValueListenable<VideoPlayerValue> position;
  final List<MealCue> cues;
  final MealCueStyle style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: position,
      builder: (context, v, _) {
        final sec = v.position.inMilliseconds / 1000;
        final cue = cueAt(cues, sec);
        if (cue == null) return const SizedBox.shrink();
        final ayahs = ref.watch(surahAyahsProvider(cue.surah)).asData?.value;
        if (ayahs == null) return const SizedBox.shrink();
        final i = ayahs.indexWhere((a) => a.numberInSurah == cue.ayah);
        if (i < 0) return const SizedBox.shrink();

        // Cue içindeki ilerleme → sayfa; uzun metin kırpılmaz, sayfalanır.
        final t = ((sec - cue.startSec) / (cue.endSec - cue.startSec))
            .clamp(0.0, 1.0);
        String pageOf(List<String> pages) =>
            pages.isEmpty ? '' : pages[(t * pages.length).floor().clamp(0, pages.length - 1)];

        final a = ayahs[i];
        final meal = pageOf(splitMealPages(a.meal));
        final arabic = style == MealCueStyle.arabic
            ? pageOf(splitMealPages(a.arabic, maxChars: 80))
            : '';
        final label = '${cue.ayah}. ayet${cue.approx ? ' · yaklaşık' : ''}';

        return IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.mediaLetterbox.withValues(alpha: 0.62),
              borderRadius: AppRadii.mdAll,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: AppColors.onMediaMuted),
                  ),
                  if (arabic.isNotEmpty)
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        arabic,
                        textAlign: TextAlign.center,
                        style: arabicStyle(size: 22, color: AppColors.onMedia),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    meal,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: style == MealCueStyle.large ? 20 : 16,
                      height: 1.35,
                      color: AppColors.onMedia,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// [Positioned] (top+bottom+left+right) içine konur: altyazı ayrılan alana
/// sığmazsa kırpılmaz, ölçeklenip küçülür.
class FittedMealSubtitle extends StatelessWidget {
  const FittedMealSubtitle({
    super.key,
    required this.position,
    required this.cues,
    required this.style,
  });

  final ValueListenable<VideoPlayerValue> position;
  final List<MealCue> cues;
  final MealCueStyle style;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, box) => Align(
      alignment: Alignment.bottomCenter,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: box.maxWidth),
          child: MealSubtitleOverlay(position: position, cues: cues, style: style),
        ),
      ),
    ),
  );
}
