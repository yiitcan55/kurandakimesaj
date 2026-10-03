import 'package:flutter/material.dart';

import '../../data/seed/ayah_notes_seed.dart';
import '../../data/seed/seed_data.dart' show kSurahSeed;
import 'theme/app_theme.dart';

/// Küratörlü ayetlerin altında katlanır "Kısa açıklama". Notu olmayan ayette
/// HİÇBİR ŞEY çizmez — 6236 ayetlik okuyucu listesi gürültülenmez.
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
  /// Çözülemezse not bulunmaz → hiçbir şey çizilmez.
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
    final no = kSurahSeed.where((s) => s.$2 == m.group(1)).map((s) => s.$1).firstOrNull;
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
    if (note == null) return const SizedBox.shrink();
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        key: Key('ayah_note_${surah}_$ayah'),
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 8),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        iconColor: ink,
        collapsedIconColor: ink,
        title: Text(
          'Kısa açıklama',
          style: AppTypography.body(
            size: 14,
            weight: FontWeight.w700,
            color: ink,
          ),
        ),
        children: [
          Text(note, style: AppTypography.body(size: 15, color: fg)),
          const SizedBox(height: 6),
          Text(
            'Ana akım tefsirlerin ortak anlayışına dayalı özet; tefsir yerine geçmez.',
            style: AppTypography.body(size: 12, color: fg.withValues(alpha: 0.75)),
          ),
        ],
      ),
    );
  }
}
