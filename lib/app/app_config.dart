/// Derleme zamanı yapılandırması (tek tipli kaynak).
///
/// Supabase kimlik bilgileri `--dart-define` ile derleme zamanında verilir.
/// Anahtarlar repoda DEĞİL; CI/yerel ortam üzerinden enjekte edilir. Boşsa
/// Supabase başlatılmaz (iskelet, kimlik bilgisi olmadan da çalışır).
abstract class AppConfig {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Supabase yapılandırılmış mı? (URL + anon key dolu)
  static bool get hasSupabase => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Yalnız prototip/yerel test içindir. ÜRETİMDE anahtarlar istemciye GÖMÜLMEZ;
  /// ses/görsel tanıma Supabase Edge Function üzerinden (Deno.env) çağrılır.
  static const String groqApiKey = String.fromEnvironment('GROQ_API_KEY');
  static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');

  /// Google ile giriş için OAuth client ID'leri (Google Cloud Console).
  /// Bunlar GİZLİ DEĞİLDİR (public client ID); yine de tek kaynaktan
  /// `--dart-define` ile verilir, repoya gömülmez.
  ///   * Web client ID  → Android için `serverClientId` + Supabase provider.
  ///   * iOS client ID   → iOS için `clientId`.
  /// iOS'ta ayrıca `ios/Runner/Info.plist`'e REVERSED_CLIENT_ID URL şeması eklenir.
  static const String googleWebClientId =
      String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
  static const String googleIosClientId =
      String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');

  /// Native Google girişi yapılandırılmış mı? (en az web client ID gerekli)
  static bool get hasGoogleSignIn => googleWebClientId.isNotEmpty;
}
