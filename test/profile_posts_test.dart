import 'package:flutter_test/flutter_test.dart';
import 'package:kurandakimesaj/data/backend_repositories.dart';

void main() {
  group('FeedPost.fromMap — thumbnailUrl önceliği', () {
    test('thumbnail_url yokken media_url\'e düşer (profil ızgarası boş kalmasın)', () {
      final post = FeedPost.fromMap(
        {'id': '1', 'media_url': 'https://x/a.png'},
        myId: null,
      );
      expect(post.thumbnailUrl, 'https://x/a.png');
    });

    test('thumbnail_url varsa media_url yerine o kazanır', () {
      final post = FeedPost.fromMap(
        {
          'id': '1',
          'thumbnail_url': 'https://x/t.png',
          'media_url': 'https://x/a.png',
        },
        myId: null,
      );
      expect(post.thumbnailUrl, 'https://x/t.png');
    });
  });

  group('FeedPost.fromMap — isPending ("İncelemede" rozeti)', () {
    test('status "pending" ise isPending true döner', () {
      final post = FeedPost.fromMap({'id': '1', 'status': 'pending'}, myId: null);
      expect(post.isPending, isTrue);
    });

    test('status kolonu SELECT\'te yoksa varsayılan "approved" kabul edilir', () {
      final post = FeedPost.fromMap({'id': '1'}, myId: null);
      expect(post.isPending, isFalse);
    });
  });
}
