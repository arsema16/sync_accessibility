import 'auth_service.dart';
import 'job_service.dart';
import 'profile_service.dart';

/// A minimal service locator: a plain singleton that exposes the stub service
/// implementations. No external dependency-injection library is required.
///
/// The UI and state layers reach the services through riverpod providers that
/// read [instance] (see `lib/core/providers/app_providers.dart`). When the
/// real backend is wired up, only the field initializers below need to change.
class ServiceLocator {
  ServiceLocator._();

  static final ServiceLocator instance = ServiceLocator._();

  final AuthService auth = InMemoryAuthService();
  final ProfileService profile = InMemoryProfileService();
  final JobService jobs = InMemoryJobService();
}
