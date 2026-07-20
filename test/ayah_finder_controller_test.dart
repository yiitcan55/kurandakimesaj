import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kurandakimesaj/data/backend_repositories.dart';
import 'package:kurandakimesaj/domain/models.dart';
import 'package:kurandakimesaj/features/ayah_finder/ayah_finder_controller.dart';

/// Sahte repo: hangi metodun hangi argümanla çağrıldığını kaydeder, sabit
/// sonuç döndürür. Gerçek Supabase/ağ olmadan controller mantığını doğrular.
class _FakeAyahFinderRepository implements IAyahFinderRepository {
  final List<String> calls = [];
  AyahFinderResult result = const AyahFinderResult(status: AyahFinderStatus.notFound);

  @override
  Future<AyahFinderResult> findFromImage(Uint8List bytes, {String mime = 'image/jpeg'}) async {
    calls.add('image');
    return result;
  }

  @override
  Future<AyahFinderResult> findFromUrl(String url) async {
    calls.add('url:$url');
    return result;
  }

  @override
  Future<AyahFinderResult> findFromVideo(String filePath) async {
    calls.add('video:$filePath');
    return result;
  }
}

ProviderContainer _containerWith(_FakeAyahFinderRepository fake) {
  final c = ProviderContainer(
    overrides: [ayahFinderRepositoryProvider.overrideWithValue(fake)],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('fromVideo controller durumunu repo sonucuyla doldurur', () async {
    final fake = _FakeAyahFinderRepository()
      ..result = const AyahFinderResult(
        status: AyahFinderStatus.matched,
        range: AyahRange(surah: 36, fromAyah: 58, toAyah: 61, reference: 'Yasin, 58-61'),
        matches: [
          AyahMatch(
            reference: 'Yasin, 58',
            surah: 36,
            ayah: 58,
            arabic: 'سلام',
            meal: 'Selam',
            confidence: 0.9,
          ),
        ],
      );
    final container = _containerWith(fake);
    final notifier = container.read(ayahFinderProvider.notifier);

    await notifier.fromVideo('/tmp/tilavet.mp4');

    final state = container.read(ayahFinderProvider);
    expect(state.hasValue, isTrue);
    expect(state.value!.status, AyahFinderStatus.matched);
    expect(state.value!.range!.reference, 'Yasin, 58-61');
    expect(fake.calls, ['video:/tmp/tilavet.mp4']);
  });

  test('file_too_large sonucu controller durumuna aynen yansır', () async {
    final fake = _FakeAyahFinderRepository()
      ..result = const AyahFinderResult(
        status: AyahFinderStatus.error,
        errorCode: 'file_too_large',
      );
    final container = _containerWith(fake);

    await container.read(ayahFinderProvider.notifier).fromVideo('/tmp/big.mp4');

    final state = container.read(ayahFinderProvider);
    expect(state.value!.status, AyahFinderStatus.error);
    expect(state.value!.errorCode, 'file_too_large');
  });

  test('SharedAyahInput video girdisi tüketilip temizlenir', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(sharedAyahInputProvider.notifier);

    notifier.set((imagePath: null, videoPath: '/tmp/v.mp4', url: null));
    expect(container.read(sharedAyahInputProvider)!.videoPath, '/tmp/v.mp4');

    notifier.clear();
    expect(container.read(sharedAyahInputProvider), isNull);
  });
}
