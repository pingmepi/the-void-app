/// Runtime configuration injected via --dart-define-from-file=.env.json
///
/// Never hardcode secrets here. Values are baked in at compile time by the
/// Flutter toolchain and are NOT present in source control.
///
/// To run locally:
///   flutter run --dart-define-from-file=.env.json
///
/// To build for web:
///   flutter build web --dart-define-from-file=.env.json
class AppConfig {
  AppConfig._();

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Storage bucket name for gem audio files
  static const String audioBucket = 'gems-audio';

  /// Signed URL expiry for audio playback (1 year)
  static const int audioUrlExpirySeconds = 60 * 60 * 24 * 365;

  /// True when Supabase credentials have been provided.
  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
