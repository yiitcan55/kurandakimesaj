import 'package:flutter/material.dart';
import '../../ui/core/theme/app_colors.dart';
import '../../ui/core/theme/app_theme.dart';
import '../../ui/core/widgets.dart';

/// Meal Düzenle → Reels yayın sayfası. "Aptal" widget: provider'a bağlanmaz,
/// yalnız [onPublish] geri çağrısını kullanır. Başarıda sayfa kapanır ve
/// SnackBar gösterilir; hatada sayfa içinde mesaj görünür, düğme yeniden açılır.
Future<void> showMealPublishSheet(
  BuildContext context, {
  required Future<void> Function(String caption) onPublish,
  String? disabledReason,
}) {
  final messenger = ScaffoldMessenger.of(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.emerald850,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => _MealPublishSheet(
      onPublish: onPublish,
      disabledReason: disabledReason,
      messenger: messenger,
    ),
  );
}

class _MealPublishSheet extends StatefulWidget {
  const _MealPublishSheet({
    required this.onPublish,
    required this.messenger,
    this.disabledReason,
  });

  final Future<void> Function(String caption) onPublish;
  final ScaffoldMessengerState messenger;
  final String? disabledReason;

  @override
  State<_MealPublishSheet> createState() => _MealPublishSheetState();
}

class _MealPublishSheetState extends State<_MealPublishSheet> {
  final _caption = TextEditingController();
  bool _rightsAccepted = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  bool get _canPublish =>
      !_busy && _rightsAccepted && widget.disabledReason == null;

  Future<void> _publish() async {
    // Düğme zaten kilitli; kapı burada da dursun (stüdyo / CreatePostSheet ile aynı kalıp).
    if (!_canPublish) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onPublish(_caption.text.trim());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e is StateError
            ? e.message
            : 'Yayınlanamadı. Bağlantını kontrol edip tekrar dene.';
      });
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop();
    widget.messenger.showSnackBar(
      const SnackBar(
        content: Text(
          "İçeriğin incelemeye alındı. Onaylandığında Reels'te yayınlanacak.",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reason = widget.disabledReason;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          sheetBottomPadding(context),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Reels'e Yayınla",
                    style: AppTypography.display(size: 22),
                  ),
                ),
                IconButton(
                  tooltip: 'Kapat',
                  icon: Icon(Icons.close_rounded, color: AppColors.muted),
                  onPressed: _busy ? null : () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              key: const Key('meal_caption'),
              controller: _caption,
              enabled: !_busy,
              maxLines: 3,
              style: AppTypography.body(size: 15, color: AppColors.cream),
              decoration: InputDecoration(
                hintText: 'Bir şeyler yaz (isteğe bağlı)…',
                hintStyle: AppTypography.body(size: 15, color: AppColors.muted),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppColors.emerald900,
              ),
            ),
            const SizedBox(height: 8),
            // Telif beyanı (App Store Guideline 5.2.3) — metin stüdyodakiyle AYNI.
            CheckboxListTile(
              key: const Key('meal_rights_checkbox'),
              value: _rightsAccepted,
              activeColor: AppColors.success,
              checkColor: AppColors.onSuccess,
              onChanged: _busy
                  ? null
                  : (v) => setState(() => _rightsAccepted = v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(
                'Bu içeriğin bana ait olduğunu veya paylaşma hakkım '
                'olduğunu onaylıyorum.',
                style: AppTypography.body(size: 13),
              ),
            ),
            if (!_rightsAccepted)
              Padding(
                key: const Key('meal_rights_hint'),
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Yayınlamak için önce telif onayını işaretle.',
                  style: AppTypography.body(size: 12, color: AppColors.cream2),
                ),
              ),
            if (reason != null)
              Padding(
                key: const Key('meal_publish_disabled_reason'),
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  reason,
                  style: AppTypography.body(size: 13, color: AppColors.cream2),
                ),
              ),
            if (_error != null)
              Padding(
                key: const Key('meal_publish_error'),
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _error!,
                  style: AppTypography.body(size: 13, color: AppColors.danger),
                ),
              ),
            FilledButton.icon(
              key: const Key('meal_publish_button'),
              onPressed: _canPublish ? _publish : null,
              icon: _busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.publish_rounded, size: 18),
              label: const Text("Reels'e Yayınla"),
            ),
          ],
        ),
      ),
    );
  }
}
