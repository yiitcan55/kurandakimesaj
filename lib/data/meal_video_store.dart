import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'repositories.dart';

/// Meal düzenleyicinin video dosyası yaşam döngüsü. Paylaşım eklentisi bazı URI
/// türlerinde (file://, 'primary:' belge URI'si) kullanıcının ORİJİNAL dosyasını
/// döndürür; bu sınıf yalnız uygulamanın kendi önbellek/geçici dizinindeki
/// dosyaları siler, kullanıcının dosyasına asla dokunmaz.
class MealVideoStore {
  MealVideoStore({required SharedPreferences prefs, Future<List<String>> Function()? roots})
      // ignore: prefer_initializing_formals — sözleşme genel adlı parametre ister
      : _prefs = prefs,
        _roots = roots ?? _defaultRoots;

  static const _pendingKey = 'meal_edit_pending_path';

  final SharedPreferences _prefs;
  final Future<List<String>> Function() _roots;

  // iOS'ta image_picker NSTemporaryDirectory'ye yazar, path_provider Caches döndürür.
  static Future<List<String>> _defaultRoots() async =>
      [(await getTemporaryDirectory()).path, Directory.systemTemp.path];

  /// Symlink/'..'/'/private' önekini çözer; yol yoksa null.
  static String? _canon(String path) {
    try {
      return File(path).resolveSymbolicLinksSync();
    } on FileSystemException {
      return null;
    }
  }

  /// Dosya var ve kanonik yolu bir kökün ALTINDA ise true (kökün kendisi sahipli değil).
  Future<bool> isOwned(String path) async {
    if (path.isEmpty || !File(path).existsSync()) return false;
    final p = _canon(path);
    if (p == null) return false;
    for (final r in await _roots()) {
      final root = Directory(r).existsSync() ? Directory(r).resolveSymbolicLinksSync() : null;
      if (root != null && p.startsWith('$root${Platform.pathSeparator}')) return true;
    }
    return false;
  }

  /// Sahipli değilse NO-OP. Küçük resmi ve boşalan üst klasörü de siler. Fırlatmaz.
  Future<void> discard(String path) async {
    try {
      if (!await isOwned(path)) return;
      final parent = File(path).parent;
      File(path).deleteSync();
      final thumb = File('$path.png');
      if (thumb.existsSync()) thumb.deleteSync();
      final canonParent = parent.resolveSymbolicLinksSync();
      final roots = [
        for (final r in await _roots())
          if (Directory(r).existsSync()) Directory(r).resolveSymbolicLinksSync(),
      ];
      if (!roots.contains(canonParent) && parent.listSync().isEmpty) parent.deleteSync();
    } catch (e, st) {
      debugPrint('MealVideoStore.discard başarısız: $e\n$st');
    }
  }

  Future<void> markPending(String path) => _prefs.setString(_pendingKey, path);

  Future<void> clearPending() => _prefs.remove(_pendingKey);

  /// Önceki oturumdan kalan bekleyen dosyayı siler; [except] ile aynıysa dokunmaz.
  Future<void> sweepOrphan({String? except}) async {
    final pending = _prefs.getString(_pendingKey);
    if (pending == null) return;
    if (except != null && (_canon(except) ?? except) == (_canon(pending) ?? pending)) return;
    await discard(pending);
    await clearPending();
  }
}

final mealVideoStoreProvider =
    Provider<MealVideoStore>((ref) => MealVideoStore(prefs: ref.watch(prefsProvider)));
