import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/seed/ayah_notes_seed.dart';
import '../../data/seed/seed_data.dart' show kSurahSeed;
import '../../data/tafsir.dart';
import 'theme/app_theme.dart';

/// Ayetin altında katlanır iki bölüm: küratörlü "Kısa açıklama" (yalnız notu
/// olan ayette) ve Muhtasar "Tefsir" (her ayette). Çizilecek bir şey yoksa
/// (notsuz ayette tefsir yüklenemediyse) HİÇBİR ŞEY çizmez.
///
/// Renkler dışarıdan gelir: sepya modunda zemin global temadan okunamaz
/// (bkz. `_AyahTile`).
class AyahNote extends StatelessWidget {
  const AyahNote({
    super.key,
    required this.surah,
    required this.ayah,
    required this.fg,
    required this.ink,
  });

  /// "Bakara, 153" biçimli künyeden çözer (sure adı `kSurahSeed` ile birebir).
  /// Çözülemezse not/tefsir bulunmaz → hiçbir şey çizilmez.
  factory AyahNote.fromReference(
    String reference, {
    Key? key,
    required Color fg,
    required Color ink,
  }) {
    final p = _parse(reference);
    return AyahNote(
      key: key,
      surah: p?.$1 ?? -1,
      ayah: p?.$2 ?? -1,
      fg: fg,
      ink: ink,
    );
  }

  static (int, int)? _parse(String reference) {
    final m = RegExp(r'^\s*(.+?)\s*,\s*(\d+)\s*$').firstMatch(reference);
    if (m == null) return null;
    final no = kSurahSeed
        .where((s) => s.$2 == m.group(1))
        .map((s) => s.$1)
        .firstOrNull;
    return no == null ? null : (no, int.parse(m.group(2)!));
  }

  /// Künyeden ("Bakara, 153") not metni; yoksa null.
  static String? noteForReference(String reference) {
    final p = _parse(reference);
    return p == null ? null : noteFor(p.$1, p.$2);
  }

  final int surah;
  final int ayah;
  final Color fg;
  final Color ink;

  static String? noteFor(int surah, int ayah) => kAyahNotes['$surah:$ayah'];

  @override
  Widget build(BuildContext context) {
    final note = noteFor(surah, ayah);
    // Saydam Material: okuyucu hedef ayeti renkli DecoratedBox ile vurgular;
    // arada Material olmazsa ListTile (ExpansionTile) debug'da assert atar.
    return Material(
      type: MaterialType.transparency,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (note != null)
              _section(
                key: Key('ayah_note_${surah}_$ayah'),
                title: 'Kısa açıklama',
                ink: ink,
                children: [
                  Text(note, style: AppTypography.body(size: 15, color: fg)),
                  const SizedBox(height: 6),
                  Text(
                    'Ana akım tefsirlerin ortak anlayışına dayalı özet; tefsir yerine geçmez.',
                    style: AppTypography.body(
                      size: 12,
                      color: fg.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            _TafsirSection(surah: surah, ayah: ayah, fg: fg, ink: ink),
          ],
        ),
      ),
    );
  }
}

/// Muhtasar tefsir bölümü. Katlı "Tefsir" başlığı veriden BAĞIMSIZ çizilir:
/// varlık oturumda ilk kez okunurken (100–400 ms) başlık sonradan eklenirse her
/// ayetin altına ~56 px biner ve okuyucunun kaydırdığı hedef ayet ekrandan düşer.
/// Yalnız yükleme HATASINDA (nadir; `tafsirProvider`'da loglanır) ya da ayetin
/// tefsiri yoksa bölüm çizilmez.
class _TafsirSection extends ConsumerWidget {
  const _TafsirSection({
    required this.surah,
    required this.ayah,
    required this.fg,
    required this.ink,
  });

  final int surah;
  final int ayah;
  final Color fg;
  final Color ink;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(tafsirProvider);
    final tafsir = async.value;
    final text = tafsir?.of(surah, ayah);
    if (async.hasError || (tafsir != null && text == null)) {
      return const SizedBox.shrink();
    }
    final note = AppTypography.body(
      size: 12,
      color: fg.withValues(alpha: 0.75),
    );
    return _section(
      key: Key('ayah_tafsir_${surah}_$ayah'),
      title: 'Tefsir',
      ink: ink,
      children: [
        if (tafsir == null)
          Text('Yükleniyor…', style: note)
        else ...[
          Text(text!, style: AppTypography.body(size: 15, color: fg)),
          const SizedBox(height: 6),
          Text(tafsir.sourceLine, style: note),
        ],
      ],
    );
  }
}

Widget _section({
  required Key key,
  required String title,
  required Color ink,
  required List<Widget> children,
}) => ExpansionTile(
  key: key,
  tilePadding: EdgeInsets.zero,
  childrenPadding: const EdgeInsets.only(bottom: 8),
  expandedCrossAxisAlignment: CrossAxisAlignment.start,
  iconColor: ink,
  collapsedIconColor: ink,
  title: Text(
    title,
    style: AppTypography.body(size: 14, weight: FontWeight.w700, color: ink),
  ),
  children: children,
);
