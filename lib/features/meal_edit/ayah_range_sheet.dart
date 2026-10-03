import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/app_database.dart';
import '../../ui/core/theme/app_colors.dart';
import '../../ui/core/theme/app_theme.dart';
import '../quran/quran_screens.dart' show surahsProvider;

typedef AyahRangePick = ({int surah, int from, int to});

/// Elle ayet aralığı seçer: önce sure, sonra başlangıç/bitiş ayeti.
/// Vazgeçilirse `null` döner.
Future<AyahRangePick?> showAyahRangeSheet(
  BuildContext context, {
  int maxAyahs = 60,
  int? initialSurah,
}) =>
    showModalBottomSheet<AyahRangePick>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _RangeSheet(maxAyahs: maxAyahs, initialSurah: initialSurah),
    );

class _RangeSheet extends ConsumerStatefulWidget {
  const _RangeSheet({required this.maxAyahs, this.initialSurah});
  final int maxAyahs;
  final int? initialSurah;

  @override
  ConsumerState<_RangeSheet> createState() => _RangeSheetState();
}

class _RangeSheetState extends ConsumerState<_RangeSheet> {
  String _query = '';
  Surah? _surah;
  int _from = 1;
  int _to = 1;

  void _pick(Surah s) => setState(() {
        _surah = s;
        _from = 1;
        _to = 1;
      });

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(surahsProvider);
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.85,
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e', style: AppTypography.body())),
        data: (surahs) {
          // initialSurah yalnız ilk açılışta adım 2'yi önceden seçer.
          if (_surah == null && widget.initialSurah != null && _query.isEmpty) {
            for (final s in surahs) {
              if (s.number == widget.initialSurah) _surah = s;
            }
          }
          return _surah == null ? _surahList(surahs) : _rangeStep(_surah!);
        },
      ),
    );
  }

  Widget _surahList(List<Surah> surahs) {
    final list = _query.isEmpty
        ? surahs
        : surahs
            .where((s) =>
                s.nameTr.toLowerCase().contains(_query) ||
                s.number.toString() == _query)
            .toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: TextField(
            key: const Key('rangeSearch'),
            onChanged: (v) => setState(() => _query = v.toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Sûre ara…',
              prefixIcon: Icon(Icons.search_rounded, color: AppColors.goldInk),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: list.length,
            itemBuilder: (_, i) {
              final s = list[i];
              return ListTile(
                key: Key('rangeSurah_${s.number}'),
                minTileHeight: 56,
                leading: Text('${s.number}', style: AppTypography.body(weight: FontWeight.w700)),
                title: Text(s.nameTr, style: AppTypography.body(color: AppColors.cream)),
                subtitle: Text('${s.ayahCount} ayet', style: AppTypography.body(size: 13, color: AppColors.muted)),
                trailing: Text(s.nameArabic, textDirection: TextDirection.rtl, style: arabicStyle(size: 22)),
                onTap: () => _pick(s),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _rangeStep(Surah s) {
    final count = _to - _from + 1;
    final reason = _to < _from
        ? 'Bitiş ayeti başlangıçtan küçük olamaz.'
        : count > widget.maxAyahs
            ? 'En fazla ${widget.maxAyahs} ayet seçebilirsin.'
            : null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                key: const Key('rangeBack'),
                style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
                onPressed: () => setState(() => _surah = null),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Sureyi değiştir'),
              ),
            ),
            Text(s.nameTr, style: AppTypography.display(size: 28)),
            const SizedBox(height: 16),
            _dropdown('Başlangıç ayeti', const Key('rangeFrom'), s.ayahCount, _from,
                (v) => setState(() => _from = v)),
            const SizedBox(height: 12),
            _dropdown('Bitiş ayeti', const Key('rangeTo'), s.ayahCount, _to,
                (v) => setState(() => _to = v)),
            const SizedBox(height: 16),
            Text(
              reason ?? '${s.nameTr}, ${_from == _to ? _from : '$_from-$_to'} · $count ayet',
              style: AppTypography.body(
                weight: FontWeight.w600,
                color: reason == null ? AppColors.cream : AppColors.danger,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('rangeConfirm'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              onPressed: reason != null
                  ? null
                  : () => Navigator.of(context).pop<AyahRangePick>((surah: s.number, from: _from, to: _to)),
              child: const Text('Aralığı Onayla'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropdown(String label, Key key, int n, int value, ValueChanged<int> onChanged) =>
      InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            key: key,
            isExpanded: true,
            value: value,
            menuMaxHeight: 320,
            itemHeight: 48,
            items: [
              for (var i = 1; i <= n; i++)
                DropdownMenuItem(value: i, child: Text('$i', style: AppTypography.body(color: AppColors.cream))),
            ],
            onChanged: (v) => v == null ? null : onChanged(v),
          ),
        ),
      );
}
