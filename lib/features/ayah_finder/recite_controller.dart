import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../domain/models.dart';
import '../../domain/quran_matcher.dart';
import '../quran/quran_screens.dart';

/// Paketli Kur'an (6236 ayet) üzerinde kurulu eşleştirici. İndeks kurulumu
/// ana thread'i kilitlemesin diye ayrı isolate'te yapılır; sonuç yaşatılır
/// (ikinci açılış anlıktır).
final quranMatcherProvider = FutureProvider<QuranMatcher>((ref) async {
  final raw = await rootBundle.loadString('assets/quran/quran_full.json');
  return Isolate.run(() => QuranMatcher.fromJson(raw));
});

/// hazırlanıyor: ses tanıyıcı başlatılıyor / izin isteniyor · hazır: mikrofona
/// basılabilir · dinliyor · kullanılamaz: izin, cihaz ya da Arapça dil eksik
/// (mikrofona yeniden basmak başlatmayı yeniden dener).
enum ReciteStatus { preparing, ready, listening, unavailable }

@immutable
class ReciteState {
  const ReciteState({
    this.status = ReciteStatus.ready,
    this.heard = '',
    this.matches = const [],
    this.error,
  });

  final ReciteStatus status;

  /// Ses tanıyıcının duyduğu Arapça metin (kısmi sonuçlar dahil).
  final String heard;
  final List<AyahMatch> matches;

  /// Kullanıcıya gösterilecek Türkçe hata mesajı.
  final String? error;

  ReciteState copyWith({
    ReciteStatus? status,
    String? heard,
    List<AyahMatch>? matches,
    String? error,
    bool clearError = false,
  }) =>
      ReciteState(
        status: status ?? this.status,
        heard: heard ?? this.heard,
        matches: matches ?? this.matches,
        error: clearError ? null : (error ?? this.error),
      );
}

const _msgUnavailable = 'Ses tanıma kullanılamıyor. Mikrofon ya da konuşma '
    'tanıma izni verilmemiş olabilir (Ayarlar\'dan izin verebilirsiniz) '
    'veya cihaz bunu desteklemiyor.';
const _msgNoArabic = 'Cihazda Arapça ses tanıma dili bulunamadı. '
    'Google uygulaması › Ayarlar › Ses › Diller kısmından Arapça ekleyin.';
const _msgNoMatch = 'Ses anlaşılamadı, tekrar deneyin.';

/// Mikrofon → cihazın ses tanıyıcısı (Arapça) → yerel eşleştirici → ayet
/// kartları. Uygulama sesi kaydetmez ve kendi sunucusuna göndermez; tanımayı
/// işletim sisteminin servisi yapar (Android'de Google, çevrimdışı paket yoksa
/// sesi Google sunucusuna gönderebilir). Eşleştirme tamamen cihazda. Mantığın
/// tamamı burada, ekran saf.
class ReciteController extends Notifier<ReciteState> {
  /// Kısmi sonuçlar çok sık gelir; eşleştirmeyi biraz geciktir.
  static const _debounce = Duration(milliseconds: 350);

  // İlk init()'te oluşturulur: build'de oluşturulsa testler platform
  // kanalına dokunurdu.
  SpeechToText? _speech;
  String? _localeId;
  Timer? _timer;

  /// Bu dinlemede biten bölümlerin metni ve içinde bulunulan bölüm.
  String _committed = '';
  String _segment = '';

  @override
  ReciteState build() {
    ref.onDispose(() {
      _timer?.cancel();
      final speech = _speech;
      if (speech != null) {
        // `SpeechToText()` tekil: yeniden açılışta eski dinleyiciler kalmasın.
        speech.errorListener = null;
        speech.statusListener = null;
        unawaited(speech.cancel().catchError((Object e) {
          debugPrint('Okuyarak Bul: dinleme iptal edilemedi: $e');
        }));
      }
    });
    return const ReciteState();
  }

  /// Ses tanıyıcıyı hazırlar (izin istemi burada çıkar) ve Arapça yerel ayarı
  /// seçer. Başarıyla biten çağrıdan sonra tekrar çağrı bedavadır.
  Future<bool> init() async {
    if (_localeId != null) return true;
    state = state.copyWith(status: ReciteStatus.preparing, clearError: true);
    try {
      final speech = _speech ??= SpeechToText();
      final ready = await speech.initialize(onError: _onError, onStatus: _onStatus);
      // `initialize` zaten hazırsa dinleyicileri YENİLEMEZ; tekil örnek
      // başka bir denetleyiciden kalmış olabilir.
      speech.errorListener = _onError;
      speech.statusListener = _onStatus;
      if (!ref.mounted) return false;
      if (!ready) return _unavailable(_msgUnavailable);

      // Android 13+'ta locales() yalnız CİHAZ ÜSTÜ tanıyıcının dillerini
      // döndürür (`supportedOnDeviceLanguages`); Arapça orada yoksa bile
      // varsayılan (çevrimiçi) tanıyıcı ar-SA'yı tanıyabilir. Liste yalnız
      // tercih için okunur; gerçek "dil yok" durumu dinlemede
      // `error_language_*` olarak gelir ve _onError yönergeyi gösterir.
      final locale = _pickArabicLocale([
        for (final l in await speech.locales()) l.localeId,
      ]);
      if (!ref.mounted) return false;
      _localeId = locale ?? 'ar-SA';
      state = state.copyWith(status: ReciteStatus.ready);
      return true;
    } catch (e) {
      debugPrint('Okuyarak Bul: ses tanıma başlatılamadı: $e');
      return ref.mounted ? _unavailable(_msgUnavailable) : false;
    }
  }

  bool _unavailable(String message) {
    state = state.copyWith(status: ReciteStatus.unavailable, error: message);
    return false;
  }

  /// Platforma göre 'ar-SA' ya da 'ar_SA' gelir; Suudi Arapçası tercih edilir.
  static String? _pickArabicLocale(List<String> ids) {
    final arabic = ids
        .where((id) => id.toLowerCase().split(RegExp('[-_]')).first == 'ar')
        .toList();
    if (arabic.isEmpty) return null;
    return arabic.firstWhere(
      (id) => id.toUpperCase().endsWith('SA'),
      orElse: () => arabic.first,
    );
  }

  Future<void> start() async {
    if (state.status == ReciteStatus.preparing ||
        state.status == ReciteStatus.listening) {
      return;
    }
    // Eşleştirici yüklenmeden dinlemenin anlamı yok (ekran düğmeyi kapalı tutar).
    if (!ref.read(quranMatcherProvider).hasValue) return;
    if (!await init()) return;
    final speech = _speech;
    if (speech == null || !ref.mounted) return;

    _timer?.cancel();
    _committed = _segment = '';
    state = const ReciteState(status: ReciteStatus.listening);
    try {
      await speech.listen(
        onResult: _onResult,
        listenOptions: SpeechListenOptions(
          localeId: _localeId,
          listenFor: const Duration(seconds: 60), // iOS zaten ~1 dk ile sınırlı
          pauseFor: const Duration(seconds: 5), // Android bunu çoğu zaman kısaltır
          partialResults: true,
          listenMode: ListenMode.dictation,
          cancelOnError: true,
        ),
      );
    } catch (e) {
      debugPrint('Okuyarak Bul: dinleme başlatılamadı: $e');
      if (!ref.mounted) return;
      state = state.copyWith(
        status: ReciteStatus.ready,
        error: 'Dinleme başlatılamadı. Tekrar deneyin.',
      );
    }
  }

  Future<void> stop() async {
    await _speech?.stop();
    if (ref.mounted && state.status == ReciteStatus.listening) {
      state = state.copyWith(status: ReciteStatus.ready);
    }
  }

  void _onResult(SpeechRecognitionResult r) => onRecognized(
        r.recognizedWords,
        [for (final a in r.alternates) a.recognizedWords],
        isFinal: r.finalResult,
      );

  /// Tanınan metni işler. Kısmi sonuçta [_debounce] kadar bekler; son sonuçta
  /// ([isFinal]) hemen eşleştirir. Testler bunu platform kanalı olmadan çağırır.
  ///
  /// Google tanıyıcısı nefes/vakıf duraklamasında oturumu BÖLÜMLERE ayırır:
  /// araya boş sonuç koyar, yeni bölüm sıfırdan başlar ve son sonuç yalnız
  /// son bölümü taşır (emülatörde Husarî Fatiha 2-4 ile görüldü). Bölümler
  /// biriktirilir ki uzun ayetin tamamı eşleşsin ve duyulan metin kaybolmasın.
  void onRecognized(String text, List<String> alternates, {bool isFinal = true}) {
    if (!ref.mounted) return;
    final segment = text.trim();
    if (segment.isEmpty) {
      // Bölüm sınırı: bekleyen eşleştirme hâlâ geçerli, iptal edilmez.
      _committed = _join(_committed, _segment);
      _segment = '';
      return;
    }
    _segment = segment;
    final heard = _join(_committed, segment);
    state = state.copyWith(heard: heard);
    _timer?.cancel();
    final others = {
      for (final a in alternates)
        if (a.trim().isNotEmpty) _join(_committed, a.trim()),
    }..remove(heard);
    if (isFinal) {
      unawaited(_match(heard, others.toList()));
    } else {
      _timer = Timer(_debounce, () => unawaited(_match(heard, others.toList())));
    }
  }

  static String _join(String a, String b) => a.isEmpty ? b : (b.isEmpty ? a : '$a $b');

  Future<void> _match(String heard, List<String> alternates) async {
    final matcher = ref.read(quranMatcherProvider).value;
    if (matcher == null) return;
    final hits = matcher.match(heard, alternates: alternates);

    var names = const <int, String>{};
    try {
      names = {for (final s in await ref.read(surahsProvider.future)) s.number: s.nameTr};
    } catch (e) {
      debugPrint('Okuyarak Bul: sure adları okunamadı: $e'); // "Sure N" ile devam
    }
    // Bu arada daha yeni bir metin geldiyse eski sonucu yazma.
    if (!ref.mounted || state.heard != heard) return;
    state = state.copyWith(
      matches: [for (final h in hits) _toMatch(matcher, h, names)],
    );
  }

  static AyahMatch _toMatch(QuranMatcher matcher, QuranHit hit, Map<int, String> names) {
    final verses = matcher.versesOf(hit);
    final name = names[hit.surah] ?? 'Sure ${hit.surah}';
    final range = hit.fromAyah == hit.toAyah
        ? '${hit.fromAyah}'
        : '${hit.fromAyah}-${hit.toAyah}';
    return AyahMatch(
      reference: '$name, $range',
      surah: hit.surah,
      ayah: hit.fromAyah,
      arabic: verses.map((v) => v.arabic).join(' '),
      meal: verses.map((v) => v.meal).join(' '),
      confidence: hit.score,
    );
  }

  void _onStatus(String status) {
    // Android kısa sessizlikte kendiliğinden bitirir.
    if (!ref.mounted || state.status != ReciteStatus.listening) return;
    if (status == SpeechToText.notListeningStatus ||
        status == SpeechToText.doneStatus) {
      state = state.copyWith(status: ReciteStatus.ready);
    }
  }

  /// Ele alınmayan hata kodu hiçbir yerde kaybolmasın diye loglanır.
  static (String, bool) _unknownError(String code) {
    debugPrint('Okuyarak Bul: bilinmeyen ses tanıma hatası: $code');
    return ('Ses tanıma sırasında bir hata oluştu. Tekrar deneyin.', false);
  }

  void _onError(SpeechRecognitionError e) {
    if (!ref.mounted) return;
    // (mesaj, engelli): engelli hatalar mikrofonu "kullanılamaz"a alır.
    final (message, blocked) = switch (e.errorMsg) {
      'error_no_match' => (_msgNoMatch, false),
      'error_speech_timeout' => ('Ses duyulamadı. Mikrofona yaklaşıp tekrar deneyin.', false),
      'error_recognizer_busy' => ('Ses tanıyıcı meşgul. Birkaç saniye sonra tekrar deneyin.', false),
      'error_network' ||
      'error_network_timeout' ||
      'error_server' ||
      'error_server_disconnected' =>
        ('Ses tanıma sunucusuna ulaşılamadı. İnternet bağlantınızı kontrol edip tekrar deneyin.', false),
      'error_insufficient_permissions' => (_msgUnavailable, true),
      'error_language_not_supported' || 'error_language_unavailable' => (_msgNoArabic, true),
      _ => _unknownError(e.errorMsg),
    };
    if (blocked) _localeId = null; // sonraki dokunuşta init() yeniden denesin
    state = state.copyWith(
      status: blocked ? ReciteStatus.unavailable : ReciteStatus.ready,
      error: message,
    );
  }
}

final reciteControllerProvider =
    NotifierProvider.autoDispose<ReciteController, ReciteState>(ReciteController.new);
