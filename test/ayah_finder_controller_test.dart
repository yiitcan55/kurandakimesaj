import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kurandakimesaj/data/backend_repositories.dart';
import 'package:kurandakimesaj/features/ayah_finder/ayah_finder_controller.dart';

import 'support/fake_ayah_finder_repository.dart';

void main() {
  test("sharedRouteFor: görsel Ayet Bul'a, video ve bağlantı Meal Düzenle'ye gider", () {
    expect(sharedRouteFor((imagePath: '/tmp/a.png', videoPath: null, url: null)), '/ayah-finder');
    expect(sharedRouteFor((imagePath: null, videoPath: '/tmp/v.mp4', url: null)), '/meal-edit');
    expect(sharedRouteFor((imagePath: null, videoPath: null, url: 'https://x.com/a')), '/meal-edit');
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

  test('fromSharedImage okunamayan dosyada repo çağrılmadan hataya düşer', () async {
    final fake = FakeAyahFinderRepository();
    final container = ProviderContainer(
      overrides: [ayahFinderRepositoryProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);

    await container.read(ayahFinderProvider.notifier).fromSharedImage('/yok/a.png');

    expect(container.read(ayahFinderProvider).hasError, isTrue);
    expect(fake.calls, isEmpty);
  });
}
