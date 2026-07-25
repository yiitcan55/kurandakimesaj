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
  ///
  /// Ham metin kabul eder: hem ekrandaki alan hem paylaş menüsü buraya girer;
  /// doğrulama tek yerde (`normalizeAyahUrl`) yapılır ki paylaş-intent'ten gelen
  /// "Şuna bak https://…" gibi metinler sunucuya çöp olarak gitmesin.
  Future<void> fromUrl(String rawUrl) async {
    final url = normalizeAyahUrl(rawUrl);
    if (url == null) {
      state = const AsyncValue.data(
        AyahFinderResult(status: AyahFinderStatus.error, errorCode: 'invalid_url'),
      );
      return;
    }
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

/// Ham metinden tek bir http(s) bağlantısı çıkarır; çıkaramazsa `null`.
///
/// Girdi ya alandan yapıştırılan bağlantıdır ya da paylaş menüsünden gelen
/// serbest metindir ("Şuna bak: https://… 😊"), o yüzden metin içinden arar.
/// Bağlantı gövdesine sık yapışan sondaki noktalama temizlenir.
String? normalizeAyahUrl(String raw) {
  final text = raw.trim();
  if (text.isEmpty) return null;
  final match = RegExp(r'https?://[^\s<>"]+', caseSensitive: false).firstMatch(text);
  // Şema yazılmamış tek parça girdi ("instagram.com/p/abc") https varsayılır.
  var candidate = match?.group(0) ??
      (text.contains(RegExp(r'\s')) ? null : 'https://$text');
  if (candidate == null) return null;
  candidate = candidate.replaceAll(RegExp(r'''[.,;:!?)\]'"]+$'''), '');
  final uri = Uri.tryParse(candidate);
  if (uri == null || !uri.hasAuthority || !uri.host.contains('.')) return null;
  return uri.toString();
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
