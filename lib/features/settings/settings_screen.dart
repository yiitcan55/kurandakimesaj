import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/repositories.dart';
import '../../domain/models.dart';
import '../home/home_screens.dart' show myProfileProvider;
import '../../ui/core/theme/app_colors.dart';
import '../../ui/core/theme/app_theme.dart';
import '../../ui/core/widgets.dart';

/// Uygulama ayarları: tercihler (meal/bildirim/ilgi alanı), hakkında & yasal,
/// hesap (çıkış + kalıcı silme). Onboarding'de seçilen tercihler buradan
/// sonradan değiştirilebilir — `SettingsController` mutator'ları yeniden kullanılır.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static final Uri _privacyPolicyUri = Uri.parse(
    'https://yiitcan55.github.io/kurandakimesaj-legal/privacy.html',
  );
  static final Uri _termsUri = Uri.parse(
    'https://yiitcan55.github.io/kurandakimesaj-legal/terms.html',
  );
  static final Uri _supportUri = Uri.parse(
    'https://yiitcan55.github.io/kurandakimesaj-legal/support.html',
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final auth = ref.watch(authRepositoryProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppHeader(title: 'Ayarlar', onBack: () => context.pop()),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // ── Tercihler ──────────────────────────────────────────
                  SectionLabel(eyebrow: 'Kişiselleştirme', title: 'Tercihler'),
                  const SizedBox(height: 12),
                  _MealSetting(settings: settings),
                  const SizedBox(height: 12),
                  _NotificationSetting(settings: settings),
                  const SizedBox(height: 12),
                  _InterestSetting(settings: settings),

                  const SizedBox(height: 28),
                  // ── Görünüm ───────────────────────────────────────────
                  SectionLabel(eyebrow: 'Görünüm', title: 'Tema'),
                  const SizedBox(height: 12),
                  _ThemeSetting(settings: settings),

                  const SizedBox(height: 28),
                  // ── Hakkında & Yasal ──────────────────────────────────
                  SectionLabel(eyebrow: 'Bilgi', title: 'Hakkında & Yasal'),
                  const SizedBox(height: 12),
                  const _AboutCard(),
                  const SizedBox(height: 12),
                  _LegalRow(
                    icon: Icons.privacy_tip_rounded,
                    label: 'Gizlilik Politikası',
                    onTap: () => _openExternalUrl(context, _privacyPolicyUri),
                  ),
                  const SizedBox(height: 8),
                  _LegalRow(
                    icon: Icons.gavel_rounded,
                    label: 'Kullanım Koşulları',
                    onTap: () => _openExternalUrl(context, _termsUri),
                  ),
                  const SizedBox(height: 8),
                  _LegalRow(
                    icon: Icons.mail_rounded,
                    label: 'İletişim & Destek',
                    onTap: () => _openExternalUrl(context, _supportUri),
                  ),

                  const SizedBox(height: 28),
                  // ── Güvenlik & Moderasyon ─────────────────────────────
                  SectionLabel(eyebrow: 'Topluluk', title: 'Güvenlik'),
                  const SizedBox(height: 12),
                  _LegalRow(
                    icon: Icons.person_off_rounded,
                    label: 'Engellenen kullanıcılar',
                    onTap: () => context.push('/blocked-users'),
                  ),
                  // Moderasyon kuyruğu yalnız yöneticiye görünür; RLS zaten
                  // yetkisiz güncellemeyi reddediyor, bu sadece görünürlük.
                  if (ref.watch(myProfileProvider).value?['is_admin']
                          as bool? ??
                      false) ...[
                    const SizedBox(height: 8),
                    _LegalRow(
                      icon: Icons.shield_moon_rounded,
                      label: 'İçerik moderasyonu',
                      onTap: () => context.push('/moderation'),
                    ),
                  ],

                  const SizedBox(height: 28),
                  // ── Hesap ─────────────────────────────────────────────
                  SectionLabel(eyebrow: 'Oturum', title: 'Hesap'),
                  const SizedBox(height: 12),
                  if (auth.isSignedIn) ...[
                    FilledButton.tonal(
                      onPressed: () async {
                        await auth.signOut();
                        if (context.mounted) context.go('/home');
                      },
                      child: const Text('Çıkış yap'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => _confirmDeleteAccount(context, ref),
                      icon: Icon(
                        Icons.delete_forever_rounded,
                        color: AppColors.danger,
                      ),
                      label: Text(
                        'Hesabı sil',
                        style: AppTypography.body(
                          size: 15,
                          color: AppColors.danger,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.line),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ] else
                    FilledButton(
                      onPressed: () => context.push('/auth'),
                      child: const Text('Giriş yap / Kayıt ol'),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openExternalUrl(BuildContext context, Uri uri) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bağlantı açılamadı. Lütfen tekrar deneyin.'),
        ),
      );
    }
  }

  Future<void> _confirmDeleteAccount(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hesabı sil'),
        content: const Text(
          'Hesabınız ve tüm verileriniz (gönderiler, koleksiyonlar, mesajlar, '
          'takip ilişkileri) kalıcı olarak silinecektir. Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.dangerSurface,
              foregroundColor: AppColors.onDanger,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Evet, sil'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(authRepositoryProvider).deleteAccount();
      messenger.showSnackBar(
        const SnackBar(content: Text('Hesabınız silindi.')),
      );
      router.go('/home');
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Hesap silinemedi. İnternet bağlantınızı kontrol edin.',
          ),
        ),
      );
    }
  }
}

class _MealSetting extends ConsumerWidget {
  const _MealSetting({required this.settings});
  final AppSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Meal kaynağı',
            style: AppTypography.body(
              size: 15,
              weight: FontWeight.w600,
              color: AppColors.cream,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in MealOption.values)
                GoldChip(
                  label: m.label,
                  selected: settings.mealOption == m,
                  onTap: () => ref.read(settingsProvider.notifier).setMeal(m),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NotificationSetting extends ConsumerWidget {
  const _NotificationSetting({required this.settings});
  final AppSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      child: Row(
        children: [
          Icon(Icons.notifications_active_rounded, color: AppColors.goldInk),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bildirimler',
                  style: AppTypography.body(
                    size: 15,
                    weight: FontWeight.w600,
                    color: AppColors.cream,
                  ),
                ),
                Text(
                  'Ezan, günün ayeti ve kandil hatırlatmaları',
                  style: AppTypography.body(size: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
          Switch(
            value: settings.notificationsGranted,
            onChanged: (on) async {
              final ctrl = ref.read(settingsProvider.notifier);
              if (on) {
                final granted = await ref
                    .read(notificationServiceProvider)
                    .requestPermission();
                await ctrl.setNotifications(granted);
              } else {
                await ref.read(notificationServiceProvider).cancelAll();
                await ctrl.setNotifications(false);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _ThemeSetting extends ConsumerWidget {
  const _ThemeSetting({required this.settings});
  final AppSettings settings;

  static const _labels = {
    ThemeMode.system: 'Sistem',
    ThemeMode.light: 'Açık',
    ThemeMode.dark: 'Koyu',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Uygulama teması',
            style: AppTypography.body(
              size: 15,
              weight: FontWeight.w600,
              color: AppColors.cream,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Sistem, cihaz ayarını takip eder',
            style: AppTypography.body(size: 12, color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in ThemeMode.values)
                GoldChip(
                  label: _labels[m]!,
                  selected: settings.themeMode == m,
                  onTap: () =>
                      ref.read(settingsProvider.notifier).setThemeMode(m),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InterestSetting extends ConsumerWidget {
  const _InterestSetting({required this.settings});
  final AppSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'İlgi alanları',
            style: AppTypography.body(
              size: 15,
              weight: FontWeight.w600,
              color: AppColors.cream,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ana ekran ve önerileri kişiselleştirir',
            style: AppTypography.body(size: 12, color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final i in AppInterest.values)
                GoldChip(
                  label: i.label,
                  selected: settings.interests.contains(i),
                  onTap: () =>
                      ref.read(settingsProvider.notifier).toggleInterest(i),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Kur'an'da ki Mesaj",
            style: AppTypography.body(
              size: 16,
              weight: FontWeight.w600,
              color: AppColors.cream,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Sürüm 1.0.0',
            style: AppTypography.body(size: 13, color: AppColors.muted),
          ),
          const SizedBox(height: 8),
          Text(
            'Kur\'an okuma, günlük ibadet, öğrenme ve paylaşılabilir ayet '
            'içerikleri bir arada.',
            style: AppTypography.body(size: 13, color: AppColors.cream),
          ),
        ],
      ),
    );
  }
}

class _LegalRow extends StatelessWidget {
  const _LegalRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: AppColors.goldInk, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: AppTypography.body(size: 15, color: AppColors.cream),
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ],
      ),
    );
  }
}
