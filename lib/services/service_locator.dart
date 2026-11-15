import '../core/config/supabase_config.dart';
import 'auth_service.dart';
import 'job_service.dart';
import 'profile_service.dart';
import 'supabase_auth_service.dart';
import 'supabase_job_service.dart';
import 'supabase_profile_service.dart';

/// A minimal service locator: a plain singleton that exposes the concrete
/// service implementations. No external dependency-injection library is
/// required.
///
/// The UI and state layers reach the services through riverpod providers that
/// read [instance] (see `lib/core/providers/app_providers.dart`).
///
/// Which implementation you get is decided once, on first access:
///
/// * **Supabase** ([SupabaseAuthService], [SupabaseProfileService],
///   [SupabaseJobService]) when `SupabaseBootstrap.useSupabase` is `true`,
///   i.e. the build carries `SUPABASE_URL` / `SUPABASE_ANON_KEY` and the
///   client initialised successfully.
/// * **In-memory** fallbacks otherwise, so unit tests, `flutter analyze` and
///   a first run without `config.json` still work end to end.
class ServiceLocator {
  ServiceLocator._();

  static final ServiceLocator instance = ServiceLocator._();

  AuthService? _auth;
  ProfileService? _profile;
  JobService? _jobs;

  AuthService get auth =>
      _auth ??= (SupabaseBootstrap.useSupabase
          ? SupabaseAuthService()
          : InMemoryAuthService());

  ProfileService get profile =>
      _profile ??= (SupabaseBootstrap.useSupabase
          ? SupabaseProfileService()
          : InMemoryProfileService());

  JobService get jobs =>
      _jobs ??= (SupabaseBootstrap.useSupabase
          ? SupabaseJobService()
          : InMemoryJobService());

  /// Drops the cached services so the next access re-resolves them.
  ///
  /// Only useful in tests that flip `SupabaseBootstrap` state.
  void reset() {
    _auth = null;
    _profile = null;
    _jobs = null;
  }
}
