import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

/// Geri butonlu üst başlık + opsiyonel sağ aksiyon.
class AppHeader extends StatelessWidget {
  const AppHeader({super.key, required this.title, this.trailing, this.onBack});

  final String title;
  final Widget? trailing;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack ?? () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            color: AppColors.gold,
          ),
          Expanded(
            child: Text(
              title,
              style: AppTypography.display(size: 24),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Koyu yeşil gradyan + altın hairline kart.
///
/// [onTap] verildiğinde basışta hafif ölçek-küçülme (~0.97) geri bildirimi
/// uygulanır. "Hareketi azalt" açıkken bu efekt atlanır.
class AppCard extends StatefulWidget {
  const AppCard({super.key, required this.child, this.padding, this.onTap});

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onTap == null) return;
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final card = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        borderRadius: AppRadii.mdAll,
        child: Ink(
          decoration: BoxDecoration(
            gradient: AppColors.cardGradient,
            borderRadius: AppRadii.mdAll,
            border: Border.all(color: AppColors.line),
          ),
          padding: widget.padding ?? const EdgeInsets.all(18),
          child: widget.child,
        ),
      ),
    );

    if (widget.onTap == null || reduceMotion) return card;

    return AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: AppDurations.fast,
      curve: AppDurations.easeOut,
      child: card,
    );
  }
}

/// Zümrüt→koyu gradyan, altın daire filigranlı hero kart (Günün Ayeti vb.).
class HeroCard extends StatelessWidget {
  const HeroCard({super.key, required this.child, this.height});

  final Widget child;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: AppRadii.lgAll,
        border: Border.all(color: AppColors.line),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -36,
            top: -36,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.goldFaint, width: 24),
              ),
            ),
          ),
          Padding(padding: const EdgeInsets.all(22), child: child),
        ],
      ),
    );
  }
}

/// Pill çip; seçiliyken altın dolgu (kategori / zikir / ruh hali seçimi).
///
/// Seçim değişiminde dolgu/kenarlık ve etiket rengi yumuşak geçer (snap
/// değil). [onTap] verildiğinde basışta hafif ölçek-küçülme (~0.96) ile
/// AppCard/QuickAction ile aynı dokunsal dil korunur. "Hareketi azalt"
/// açıkken press efekti atlanır.
class GoldChip extends StatefulWidget {
  const GoldChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  State<GoldChip> createState() => _GoldChipState();
}

class _GoldChipState extends State<GoldChip> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onTap == null) return;
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final selected = widget.selected;
    final chip = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: widget.onTap,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        // Animasyonlu özellikler doğrudan bu konteynerde olmalı; aksi halde
        // (eski sürümde olduğu gibi) renk/kenarlık geçişi hiç çalışmaz.
        child: AnimatedContainer(
          duration: AppDurations.fast,
          curve: AppDurations.easeOut,
          // vertical:10 + 13.5px metin ≈ 40px chip yüksekliği; SizedBox(56) ile fit.
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.gold : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppColors.gold : AppColors.line,
            ),
          ),
          child: AnimatedDefaultTextStyle(
            duration: AppDurations.fast,
            curve: AppDurations.easeOut,
            style: AppTypography.body(
              size: 13.5,
              weight: FontWeight.w600,
              color: selected ? AppColors.onGold : AppColors.cream2,
            ),
            child: Text(widget.label),
          ),
        ),
      ),
    );

    if (widget.onTap == null || reduceMotion) return chip;
    return AnimatedScale(
      scale: _pressed ? 0.96 : 1.0,
      duration: AppDurations.fast,
      curve: AppDurations.easeOut,
      child: chip,
    );
  }
}

/// Glassmorphism (cam) animasyonlu segment seçici — arkası bulanık, seçili
/// segmentin altında kayan altın gösterge. Feed Gönderiler↔Reels geçişi için.
///
/// Implicit `AnimatedAlign` kullanır (controller yaşam döngüsü riski yok);
/// reduced-motion açıkken geçiş anında olur (erişilebilirlik).
class GlassSegmentedToggle extends StatelessWidget {
  const GlassSegmentedToggle({
    super.key,
    required this.segments,
    required this.index,
    required this.onChanged,
    this.height = 46,
  });

  final List<String> segments;
  final int index;
  final ValueChanged<int> onChanged;
  final double height;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final n = segments.length;
    final radius = BorderRadius.circular(height / 2);
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, c) {
          final segW = c.maxWidth / n;
          // Gösterge hizası: n>1 için -1..1 aralığında segment merkezine oturur.
          final align = n <= 1 ? 0.0 : -1.0 + 2.0 * index / (n - 1);
          return ClipRRect(
            borderRadius: radius,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.08),
                  borderRadius: radius,
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.22)),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Kayan altın gösterge.
                    AnimatedAlign(
                      duration: reduceMotion ? Duration.zero : AppDurations.normal,
                      curve: Curves.easeOutCubic,
                      alignment: Alignment(align, 0),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Container(
                          width: segW - 8,
                          decoration: BoxDecoration(
                            color: AppColors.gold,
                            borderRadius: BorderRadius.circular(height / 2 - 4),
                          ),
                        ),
                      ),
                    ),
                    // Segment etiketleri.
                    Row(
                      children: [
                        for (var i = 0; i < n; i++)
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => onChanged(i),
                              child: Center(
                                child: AnimatedDefaultTextStyle(
                                  duration:
                                      reduceMotion ? Duration.zero : AppDurations.fast,
                                  style: AppTypography.body(
                                    size: 14,
                                    weight: FontWeight.w600,
                                    color: i == index
                                        ? AppColors.onGold
                                        : AppColors.cream2,
                                  ),
                                  child: Text(segments[i]),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Altın kenarlı, ortalanmış Arapça vurgu kutusu.
class AyetFrame extends StatelessWidget {
  const AyetFrame({super.key, required this.arabic, this.fontSize = 28});

  final String arabic;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
      decoration: BoxDecoration(
        borderRadius: AppRadii.mdAll,
        border: Border.all(color: AppColors.goldFaint),
        color: AppColors.gold.withValues(alpha: 0.04),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Text(
          arabic,
          textAlign: TextAlign.center,
          style: arabicStyle(size: fontSize),
        ),
      ),
    );
  }
}

/// Markanın çekirdek döngüsünü her ayet yüzeyinde görünür kılan üç-eylemli
/// alt şerit: **Anla · Düşün · Paylaş**. Altın bilinçli olarak kullanılmaz
/// (kıt tutulur); üç eylem eşit ağırlıkta, krem/muted dilinde.
class AyetActionBar extends StatelessWidget {
  const AyetActionBar({
    super.key,
    required this.onUnderstand,
    required this.onReflect,
    required this.onShare,
  });

  final VoidCallback onUnderstand;
  final VoidCallback onReflect;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          _AyetAction(
            icon: Icons.menu_book_rounded,
            label: 'Anla',
            onTap: onUnderstand,
          ),
          _AyetAction(
            icon: Icons.edit_note_rounded,
            label: 'Düşün',
            onTap: onReflect,
          ),
          _AyetAction(
            icon: Icons.ios_share_rounded,
            label: 'Paylaş',
            onTap: onShare,
          ),
        ],
      ),
    );
  }
}

class _AyetAction extends StatelessWidget {
  const _AyetAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      // AppCard/GoldChip ile aynı desen: InkWell'i şeffaf Material'a sar ki
      // ripple, kartın gradyan zemininden bağımsız tutarlı render edilsin.
      child: Material(
        color: Colors.transparent,
        child: Semantics(
          button: true,
          label: label,
          child: InkWell(
            onTap: onTap,
            // dikey 12 + ikon 20 + 4 + ~14 etiket ≈ 62px → ≥44px dokunma hedefi.
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 20, color: AppColors.cream2),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: AppTypography.body(size: 12, color: AppColors.muted),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "Düşün" adımı — ayet üzerine kısa not aldıran alttan sheet. Notu (boş da
/// olabilir) [onSave]'e geçer; kalıcılık çağırana bırakılır (genellikle
/// koleksiyona `note` ile kaydedilir). Çekirdek döngünün eksik ayağını doldurur.
Future<void> showReflectionSheet(
  BuildContext context, {
  required String reference,
  required Future<void> Function(String note) onSave,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.emerald850,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _ReflectionSheet(reference: reference, onSave: onSave),
  );
}

class _ReflectionSheet extends StatefulWidget {
  const _ReflectionSheet({required this.reference, required this.onSave});

  final String reference;
  final Future<void> Function(String note) onSave;

  @override
  State<_ReflectionSheet> createState() => _ReflectionSheetState();
}

class _ReflectionSheetState extends State<_ReflectionSheet> {
  final _controller = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await widget.onSave(_controller.text.trim());
    } catch (_) {
      // Kayıt (DB insert) başarısız olursa buton "Kaydediliyor…"da asılı kalmasın
      // ve not sessizce kaybolmasın — durumu geri al, kullanıcıyı bilgilendir.
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kaydedilemedi, tekrar deneyin.')),
      );
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: 20 + bottomInset,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DÜŞÜN', style: AppTypography.eyebrow()),
          const SizedBox(height: 8),
          Text(
            'Bu ayet bugün sana ne anlatıyor?',
            style: AppTypography.display(size: 20),
          ),
          const SizedBox(height: 4),
          Text(
            widget.reference,
            style: AppTypography.body(size: 13, color: AppColors.gold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            minLines: 3,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            style: AppTypography.body(size: 15, color: AppColors.cream),
            decoration: InputDecoration(
              hintText:
                  'Düşünceni yaz… (boş bırakırsan yalnızca ayeti kaydederiz)',
              hintStyle: AppTypography.body(size: 14, color: AppColors.muted2),
              filled: true,
              fillColor: AppColors.emerald900,
              border: OutlineInputBorder(
                borderRadius: AppRadii.mdAll,
                borderSide: BorderSide(color: AppColors.line),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadii.mdAll,
                borderSide: BorderSide(color: AppColors.line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadii.mdAll,
                borderSide: BorderSide(color: AppColors.gold),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.bookmark_add_rounded, size: 18),
              label: Text(_saving ? 'Kaydediliyor…' : 'Koleksiyona kaydet'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Rakam + etiket istatistik kutusu (tabular figürler).
class StatBox extends StatelessWidget {
  const StatBox({super.key, required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: AppTypography.display(
            size: 28,
            color: AppColors.gold,
          ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.body(size: 12.5, color: AppColors.muted),
        ),
      ],
    );
  }
}

/// Eyebrow + başlık satırı (bölüm etiketi).
class SectionLabel extends StatelessWidget {
  const SectionLabel({
    super.key,
    required this.title,
    this.eyebrow,
    this.trailing,
  });

  final String title;
  final String? eyebrow;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (eyebrow != null) ...[
                Text(eyebrow!.toUpperCase(), style: AppTypography.eyebrow()),
                const SizedBox(height: 3),
              ],
              Text(title, style: AppTypography.display(size: 24)),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// Boş durum yer tutucusu (ileride Lottie illüstrasyonu ile değişecek).
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 54, color: AppColors.goldFaint),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.body(color: AppColors.muted),
          ),
          if (action != null) ...[const SizedBox(height: 18), action!],
        ],
      ).animate().fadeIn(duration: AppDurations.normal),
    );
  }
}

/// İmplicit animasyonlu sayaç (zikir, seri, hedef rakamları).
class AnimatedCounter extends StatelessWidget {
  const AnimatedCounter({super.key, required this.value, this.style});

  final int value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: AppDurations.slow,
      curve: AppDurations.easeOut,
      builder: (_, v, _) => Text(
        v.round().toString(),
        style: (style ?? AppTypography.display(size: 48, color: AppColors.gold))
            .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
      ),
    );
  }
}

/// Yükleme iskeleti (shimmer).
class ShimmerSkeleton extends StatelessWidget {
  const ShimmerSkeleton({
    super.key,
    this.height = 16,
    this.width = double.infinity,
  });

  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            color: AppColors.emerald850,
            borderRadius: BorderRadius.circular(8),
          ),
        )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(duration: 1200.ms, color: AppColors.goldFaint);
  }
}

/// Henüz inşa edilmemiş özellik ekranları için ortak placeholder.
/// Tüm 31 ekranın route'u Sprint 0'da buraya gelir; sonraki sprint'lerde
/// gerçek ekranla değiştirilir.
class FeaturePlaceholder extends StatelessWidget {
  const FeaturePlaceholder({
    super.key,
    required this.title,
    required this.description,
    this.icon = Icons.auto_awesome,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppHeader(title: title),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 64, color: AppColors.gold)
                        .animate()
                        .fadeIn(duration: AppDurations.slow)
                        .scale(begin: const Offset(0.8, 0.8)),
                    const SizedBox(height: 20),
                    Text(
                      description,
                      textAlign: TextAlign.center,
                      style: AppTypography.body(
                        size: 16,
                        color: AppColors.cream2,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Bu ekran yakında geliyor.',
                      style: AppTypography.body(
                        size: 13,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: AppDurations.normal),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
