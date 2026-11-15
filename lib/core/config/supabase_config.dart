import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Compile-time Supabase credentials.
///
/// The values are injected by the Flutter tool, never hard-coded in source:
///
/// ```sh
/// flutter run --dart-define-from-file=config.json
/// ```
///
/// where `config.json` (gitignored — see `config.json.example`) looks like:
///
/// ```json
/// {
///   "SUPABASE_URL": "https://your-project.supabase.co",
///   "SUPABASE_ANON_KEY": "your-anon-key"
/// }
/// ```
class SupabaseConfig {
  const SupabaseConfig({required this.url, required this.anonKey});

  /// Reads the credentials passed with `--dart-define` /
  /// `--dart-define-from-file`.
  factory SupabaseConfig.fromEnvironment() => const SupabaseConfig(
        url: String.fromEnvironment('SUPABASE_URL'),
        anonKey: String.fromEnvironment('SUPABASE_ANON_KEY'),
      );

  final String url;
  final String anonKey;

  /// `true` when both credentials are present and look like a Supabase
  /// project (scheme + host). Empty/placeholder values leave this `false`.
  bool get isConfigured {
    if (url.isEmpty || anonKey.isEmpty) return false;
    final uri = Uri.tryParse(url);
    return uri != null && uri.hasScheme && uri.hasAuthority;
  }
}

/// Bootstraps the Supabase client before `runApp`.
///
/// When [SupabaseConfig.isConfigured] is `false` (unit tests, `flutter analyze`,
/// or a developer who has not created `config.json` yet) initialization is
/// skipped and [isReady] stays `false`; the service locator then falls back to
/// the local in-memory implementations so the app still runs end to end.
class SupabaseBootstrap {
  SupabaseBootstrap._();

  static bool _ready = false;

  /// The credentials compiled into this build.
  static final SupabaseConfig config = SupabaseConfig.fromEnvironment();

  /// `true` once the Supabase client has been successfully initialised.
  static bool get isReady => _ready;

  /// `true` when the build carries credentials *and* the client initialised.
  static bool get useSupabase => _ready && config.isConfigured;

  /// Initialises Supabase. Safe to call when not configured.
  static Future<void> initialize() async {
    if (!config.isConfigured) {
      debugPrint(
        'Supabase: no SUPABASE_URL/SUPABASE_ANON_KEY supplied '
        '(run with --dart-define-from-file=config.json). '
        'Falling back to local in-memory storage.',
      );
      return;
    }
    try {
      await Supabase.initialize(
        url: config.url,
        // The classic anon key and a publishable key are interchangeable
        // here; Supabase has renamed the parameter to publishableKey.
        publishableKey: config.anonKey,
        debug: kDebugMode,
      );
      _ready = true;
      debugPrint('Supabase: connected to ${config.url}');
    } catch (error) {
      _ready = false;
      debugPrint(
        'Supabase: initialisation failed ($error). '
        'Falling back to local in-memory storage.',
      );
    }
  }

  /// The initialised client.
  ///
  /// Throws a [StateError] when Supabase is not ready; call sites go through
  /// [ServiceLocator], which only builds Supabase services when [useSupabase]
  /// is `true`.
  static SupabaseClient get client {
    if (!_ready) {
      throw StateError(
        'Supabase is not initialised. Call SupabaseBootstrap.initialize() '
        'in main() and supply SUPABASE_URL / SUPABASE_ANON_KEY.',
      );
    }
    return Supabase.instance.client;
  }
}
