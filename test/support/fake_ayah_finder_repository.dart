import 'dart:async';
import 'dart:typed_data';

import 'package:kurandakimesaj/data/backend_repositories.dart';
import 'package:kurandakimesaj/domain/models.dart';

/// Sahte repo: hangi metodun hangi argümanla çağrıldığını `calls`a kaydeder;
/// `gate` doluysa onu bekler, yoksa sabit `result` döndürür.
class FakeAyahFinderRepository implements IAyahFinderRepository {
  FakeAyahFinderRepository({
    this.result = const AyahFinderResult(status: AyahFinderStatus.notFound),
  });

  final List<String> calls = [];
  AyahFinderResult result;
  Completer<AyahFinderResult>? gate;

  Future<AyahFinderResult> _answer() => gate?.future ?? Future.value(result);

  @override
  Future<AyahFinderResult> findFromImage(Uint8List bytes, {String mime = 'image/jpeg'}) {
    calls.add('image');
    return _answer();
  }

  @override
  Future<AyahFinderResult> findFromVideo(String filePath) {
    calls.add('video:$filePath');
    return _answer();
  }
}
