import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/device_services.dart';
import '../../data/local/app_database.dart';
import '../../data/repositories.dart';
import '../../ui/core/theme/app_colors.dart';
import '../../ui/core/theme/app_theme.dart';
import '../../ui/core/widgets.dart';

/// Dini içerik uyarısı (Zekât, Rüya gibi hüküm gerektiren ekranlarda zorunlu).
class _Disclaimer extends StatelessWidget {
  const _Disclaimer(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        borderRadius: AppRadii.smAll,
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.accent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: AppTypography.body(size: 12.5, color: AppColors.cream2)),
          ),
        ],
      ),
    );
  }
}

// ── Zekât Hesaplama ─────────────────────────────────────────────────────────

/// Hanafi'de nisab = min(85g altın, 595g gümüş) cinsinden hesaplanan düşük eşik.
/// Şafi/Hanbeli/Maliki'de nisab = 85g altın (altın nisabı esas alınır).
enum _Mezhep { hanafi, safi }

class ZakatScreen extends ConsumerStatefulWidget {
  const ZakatScreen({super.key});
  @override
  ConsumerState<ZakatScreen> createState() => _ZakatScreenState();
}

class _ZakatScreenState extends ConsumerState<ZakatScreen> {
  final _cash = TextEditingController(text: '0');
  final _goldG = TextEditingController(text: '0');
  final _silverG = TextEditingController(text: '0');
  final _receivables = TextEditingController(text: '0');
  final _debts = TextEditingController(text: '0');
  late final TextEditingController _goldPrice;
  late final TextEditingController _silverPrice;

  bool _pricesLoaded = false;
  _Mezhep _mezhep = _Mezhep.hanafi;

  /// Hanafi: nisab = 85g altın (ya da 595g gümüş; düşük olan esas alınır)
  /// Şafi/Hanbeli/Maliki: nisab = 85g altın
  static const double _nisabGoldGrams = 85.0;
  static const double _nisabSilverGrams = 595.0;

  @override
  void initState() {
    super.initState();
    _goldPrice = TextEditingController(
        text: GoldPriceService.defaultGoldPrice.toStringAsFixed(0));
    _silverPrice = TextEditingController(
        text: GoldPriceService.defaultSilverPrice.toStringAsFixed(0));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_pricesLoaded) {
      _pricesLoaded = true;
      _loadPrices();
    }
  }

  Future<void> _loadPrices() async {
    final svc = ref.read(goldPriceServiceProvider);
    final gold = await svc.getCachedGoldPrice();
    final silver = await svc.getCachedSilverPrice();
    if (!mounted) return;
    setState(() {
      if (gold != null) _goldPrice.text = gold.toStringAsFixed(0);
      if (silver != null) _silverPrice.text = silver.toStringAsFixed(0);
    });
  }

  double _v(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(',', '.')) ?? 0;

  @override
  void dispose() {
    for (final c in [
      _cash,
      _goldG,
      _silverG,
      _receivables,
      _debts,
      _goldPrice,
      _silverPrice,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Nisab eşiğini mezhebe göre hesaplar.
  /// Hanafi: altın nisabı ve gümüş nisabından düşük olanı esas alır.
  double _nisab(double goldPrice, double silverPrice) {
    final goldNisab = _nisabGoldGrams * goldPrice;
    if (_mezhep == _Mezhep.hanafi) {
      final silverNisab = _nisabSilverGrams * silverPrice;
      return goldNisab < silverNisab ? goldNisab : silverNisab;
    }
    return goldNisab;
  }

  String _nisabLabel(double goldPrice, double silverPrice) {
    if (_mezhep == _Mezhep.hanafi) {
      final goldNisab = _nisabGoldGrams * goldPrice;
      final silverNisab = _nisabSilverGrams * silverPrice;
      return goldNisab < silverNisab
          ? '${_nisabGoldGrams.toStringAsFixed(0)}g altın'
          : '${_nisabSilverGrams.toStringAsFixed(0)}g gümüş';
    }
    return '${_nisabGoldGrams.toStringAsFixed(0)}g altın';
  }

  @override
  Widget build(BuildContext context) {
    final goldPrice = _v(_goldPrice);
    final silverPrice = _v(_silverPrice);
    final total = _v(_cash) +
        _v(_goldG) * goldPrice +
        _v(_silverG) * silverPrice +
        _v(_receivables) -
        _v(_debts);
    final nisab = _nisab(goldPrice, silverPrice);
    final aboveNisab = total >= nisab && nisab > 0;
    final zakat = aboveNisab ? total * 0.025 : 0.0;

    String fmt(double v) => v
        .toStringAsFixed(2)
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.');

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppHeader(title: 'Zekât Hesaplama'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: [
                  // ── Sonuç kartı ───────────────────────────────────────────
                  HeroCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          aboveNisab ? 'ÖDENECEK ZEKÂT (%2,5)' : 'NİSAB ALTINDA',
                          style: AppTypography.eyebrow(),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${fmt(zakat)} ₺',
                          style: AppTypography.display(size: 40, color: AppColors.gold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          aboveNisab
                              ? 'Toplam zekâta tabi mal: ${fmt(total)} ₺'
                              : 'Nisab eşiği: ${fmt(nisab)} ₺ (${_nisabLabel(goldPrice, silverPrice)}). '
                                  'Malınız bu eşiğin altında.',
                          style: AppTypography.body(size: 13, color: AppColors.cream2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ── Mezhep seçimi ─────────────────────────────────────────
                  const SectionLabel(title: 'Mezhep / Nisab Hesabı', eyebrow: 'Fıkıh'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _MezhepButton(
                          label: 'Hanafi',
                          subtitle: 'Altın veya gümüş (düşük olan)',
                          selected: _mezhep == _Mezhep.hanafi,
                          onTap: () => setState(() => _mezhep = _Mezhep.hanafi),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MezhepButton(
                          label: 'Şafi / Hanbeli / Maliki',
                          subtitle: '85g altın nisabı',
                          selected: _mezhep == _Mezhep.safi,
                          onTap: () => setState(() => _mezhep = _Mezhep.safi),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // ── Varlıklar ─────────────────────────────────────────────
                  const SectionLabel(title: 'Zekâta Tabi Varlıklar', eyebrow: 'Mal'),
                  const SizedBox(height: 10),
                  _field('Nakit / banka (₺)', _cash),
                  _field('Altın (gram)', _goldG),
                  _field('Gümüş (gram)', _silverG),
                  _field('Alacaklar (₺)', _receivables),
                  _field('Borçlar (₺)', _debts),
                  const SizedBox(height: 8),

                  // ── Fiyatlar ──────────────────────────────────────────────
                  const SectionLabel(title: 'Güncel Fiyatlar', eyebrow: 'Gram · TL'),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Fiyatları güncelleyin — son girdiğiniz değer 24 saat boyunca hatırlanır.',
                      style: AppTypography.body(size: 12, color: AppColors.muted),
                    ),
                  ),
                  _priceField('Altın gram fiyatı (₺)', _goldPrice, isGold: true),
                  _priceField('Gümüş gram fiyatı (₺)', _silverPrice, isGold: false),
                  const SizedBox(height: 16),

                  // ── Uyarı ─────────────────────────────────────────────────
                  const _Disclaimer(
                    'Bu hesaplama yaklaşıktır ve kesin dinî hüküm değildir. '
                    'Kişisel durumunuz için bir din görevlisine/âlime danışınız.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  Widget _priceField(String label, TextEditingController c, {required bool isGold}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
        onChanged: (_) {
          setState(() {});
          final val = double.tryParse(c.text.replaceAll(',', '.'));
          if (val != null && val > 0) {
            final svc = ref.read(goldPriceServiceProvider);
            if (isGold) {
              svc.saveGoldPrice(val);
            } else {
              svc.saveSilverPrice(val);
            }
          }
        },
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}

/// Mezhep seçim düğmesi.
class _MezhepButton extends StatelessWidget {
  const _MezhepButton({
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.gold.withValues(alpha: 0.15)
              : AppColors.accent.withValues(alpha: 0.06),
          borderRadius: AppRadii.smAll,
          border: Border.all(
            color: selected
                ? AppColors.gold.withValues(alpha: 0.7)
                : AppColors.accent.withValues(alpha: 0.2),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.body(
                size: 13.5,
                weight: FontWeight.w600,
                color: selected ? AppColors.gold : AppColors.cream,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: AppTypography.body(size: 11.5, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Cami Bul ────────────────────────────────────────────────────────────────

class MosqueScreen extends ConsumerWidget {
  const MosqueScreen({super.key});

  Future<void> _openMaps(WidgetRef ref) async {
    final loc = await ref.read(locationServiceProvider).current();
    final lat = loc?.lat ?? LocationService.defaultLat;
    final lng = loc?.lng ?? LocationService.defaultLng;
    final geo = Uri.parse('geo:$lat,$lng?q=cami');
    final web = Uri.parse('https://www.google.com/maps/search/cami/@$lat,$lng,15z');
    if (await canLaunchUrl(geo)) {
      await launchUrl(geo, mode: LaunchMode.externalApplication);
    } else {
      await launchUrl(web, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppHeader(title: 'Cami Bul'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: [
                  HeroCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.mosque_rounded, color: AppColors.gold, size: 32),
                        const SizedBox(height: 12),
                        Text('Yakındaki Camiler', style: AppTypography.display(size: 24)),
                        const SizedBox(height: 6),
                        Text('Konumuna göre en yakın camileri haritada gör ve yol tarifi al.',
                            style: AppTypography.body(size: 13, color: AppColors.cream2)),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () => _openMaps(ref),
                          icon: const Icon(Icons.map_rounded),
                          label: const Text('Haritada aç'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Not: Uygulama içi harita ve cami listesi Google Places / harita servisi entegrasyonu gerektirir. '
                    'Şu an cihazınızın harita uygulamasında "cami" araması açılır.',
                    style: AppTypography.body(size: 12.5, color: AppColors.muted),
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

// ── Bağış & Sadaka ──────────────────────────────────────────────────────────

class _Campaign {
  const _Campaign(this.title, this.org, this.url);
  final String title;
  final String org;
  final String url;
}

const _kCampaigns = [
  _Campaign('Yetim Sponsorluğu', 'Türkiye Diyanet Vakfı', 'https://bagis.diyanet.gov.tr'),
  _Campaign('Su Kuyusu', 'TDV', 'https://bagis.diyanet.gov.tr'),
  _Campaign('Acil Yardım Fonu', 'Kızılay', 'https://www.kizilay.org.tr/Bagis'),
  _Campaign('İftar / Gıda Kolisi', 'TDV', 'https://bagis.diyanet.gov.tr'),
];

class DonateScreen extends ConsumerWidget {
  const DonateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppHeader(title: 'Bağış & Sadaka'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: [
                  AppCard(
                    child: Row(
                      children: [
                        const Icon(Icons.notifications_active_rounded, color: AppColors.gold),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text('Günlük sadaka hatırlatıcısı',
                              style: AppTypography.body(size: 15, color: AppColors.cream)),
                        ),
                        FilledButton.tonal(
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final n = ref.read(notificationServiceProvider);
                            await n.init();
                            await n.requestPermission();
                            await n.scheduleDaily(
                                500, 'Sadaka zamanı', 'Bugün küçük bir iyilik yapmaya ne dersin?', 12, 0);
                            messenger.showSnackBar(
                              const SnackBar(content: Text('Her gün 12:00\'de hatırlatılacak.')),
                            );
                          },
                          child: const Text('Kur'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const SectionLabel(title: 'Güvenilir Kampanyalar', eyebrow: 'Hayır'),
                  const SizedBox(height: 12),
                  for (final c in _kCampaigns)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: AppCard(
                        onTap: () => launchUrl(Uri.parse(c.url), mode: LaunchMode.externalApplication),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.goldFaint,
                                borderRadius: AppRadii.smAll,
                              ),
                              child: const Icon(Icons.favorite_rounded, color: AppColors.gold),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(c.title,
                                      style: AppTypography.body(
                                          size: 16, weight: FontWeight.w600, color: AppColors.cream)),
                                  Text(c.org, style: AppTypography.body(size: 12.5, color: AppColors.muted)),
                                ],
                              ),
                            ),
                            const Icon(Icons.open_in_new_rounded, color: AppColors.gold, size: 18),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  const _Disclaimer(
                    'Bağışlarınızı yalnızca güvenilir ve resmî kurumlar üzerinden yapınız. '
                    'Bağlantılar ilgili kurumun resmî sitesine yönlendirir.',
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

// ── Rüya Tabiri ─────────────────────────────────────────────────────────────

final dreamSearchProvider = FutureProvider.family<List<DreamSymbol>, String>(
  (ref, q) => ref.read(contentRepositoryProvider).searchDreams(q),
);

class DreamScreen extends ConsumerStatefulWidget {
  const DreamScreen({super.key});
  @override
  ConsumerState<DreamScreen> createState() => _DreamScreenState();
}

class _DreamScreenState extends ConsumerState<DreamScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(dreamSearchProvider(_query));
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppHeader(title: 'Rüya Tabiri'),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  hintText: 'Sembol ara (su, yılan, ev…)',
                  prefixIcon: Icon(Icons.search_rounded, color: AppColors.gold),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: _Disclaimer(
                'Rüya yorumları klasik kaynaklara dayalı genel açıklamalardır; '
                'kesin dinî hüküm değildir.',
              ),
            ),
            Expanded(
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => EmptyState(icon: Icons.error_outline_rounded, message: '$e'),
                data: (symbols) {
                  if (symbols.isEmpty) {
                    return const EmptyState(
                      icon: Icons.bedtime_rounded,
                      message: 'Bu sembol bulunamadı.',
                    );
                  }
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    children: [
                      for (final s in symbols)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.bedtime_rounded, color: AppColors.gold, size: 20),
                                    const SizedBox(width: 10),
                                    Text(s.term,
                                        style: AppTypography.body(
                                            size: 16, weight: FontWeight.w700, color: AppColors.cream)),
                                    const Spacer(),
                                    Text(s.category,
                                        style: AppTypography.body(size: 12, color: AppColors.gold)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(s.meaning, style: AppTypography.body(size: 14.5, color: AppColors.cream2)),
                              ],
                            ),
                          ),
                        ),
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
