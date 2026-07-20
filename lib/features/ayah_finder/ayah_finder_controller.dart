import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/backend_repositories.dart';
import '../../domain/models.dart';

/// Ayet Bulucu durumu — null: henüz arama yok. Mantık burada, View saf.
class AyahFinderController extends AsyncNotifier<AyahFinderResult?> {
  @override
  Future<AyahFinderResult?> build() async => null;

  IAyahFinderRepository get _repo => ref.read(ayahFinderRepositoryProvider);

  /// Galeriden/ekran görüntüsünden ayet bul.
  Future<void> fromGallery() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return; // kullanıcı vazgeçti — durum değişmez
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final bytes = await file.readAsBytes();
      final mime = file.mimeType ?? _guessMime(file.path);
      return _repo.findFromImage(bytes, mime: mime);
    });
  }

  /// Yapıştırılan gönderi bağlantısından ayet bul (Faz 2).
  Future<void> fromUrl(String url) async {
    if (url.trim().isEmpty) return;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.findFromUrl(url));
  }

  /// Paylaş menüsünden gelen görselle ayet bul (Faz 3).
  Future<void> fromSharedImage(String path) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final bytes = await File(path).readAsBytes();
      return _repo.findFromImage(bytes, mime: _guessMime(path));
    });
  }

  /// Galeriden Kur'an videosu seçip okunan ayetleri bul (ses hattı).
  Future<void> fromVideoGallery() async {
    final picker = ImagePicker();
    final file = await picker.pickVideo(source: ImageSource.gallery);
    if (file == null) return; // kullanıcı vazgeçti — durum değişmez
    await fromVideo(file.path);
  }

  /// Paylaş menüsünden gelen video (WhatsApp/Telegram/galeri) → ayet bul.
  Future<void> fromVideo(String path) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.findFromVideo(path));
  }

  String _guessMime(String path) {
    final p = path.toLowerCase();
    if (p.endsWith('.png')) return 'image/png';
    if (p.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}

final ayahFinderProvider =
    AsyncNotifierProvider<AyahFinderController, AyahFinderResult?>(
        AyahFinderController.new);

/// Paylaş menüsünden gelen girdi (Faz 3). `app.dart` `set` ile yazar,
/// AyahFinderScreen bir kez okuyup `clear()` ile null'a çeker.
/// imagePath: paylaşılan görsel; videoPath: paylaşılan video; url: paylaşılan metin.
typedef SharedAyahInput = ({String? imagePath, String? videoPath, String? url});

class SharedAyahInputNotifier extends Notifier<SharedAyahInput?> {
  @override
  SharedAyahInput? build() => null;

  void set(SharedAyahInput input) => state = input;
  void clear() => state = null;
}

final sharedAyahInputProvider =
    NotifierProvider<SharedAyahInputNotifier, SharedAyahInput?>(
        SharedAyahInputNotifier.new);
