# SYNC service layer (stub)

This folder defines the **abstract** service contracts used across the app and
**in-memory** implementations that let the onboarding flow run end to end
without a backend.

## Why stubs?

Phase 1 must not depend on Supabase. Arsema Tefera owns the architecture and
onboarding; **Arsema Tewodros** owns wiring the real backend. To make that swap
easy, every concrete implementation is marked:

```dart
// TODO(arsema-tewodros): replace InMemory* with Supabase implementation
```

Each abstract class is the contract Arsema Tewodros needs to satisfy. Replace
the `InMemory*` classes with Supabase-backed implementations; no UI or state
code should need to change, because everything goes through the riverpod
providers in `lib/core/providers/app_providers.dart`.

## Contracts

### `AuthService` — `lib/services/auth_service.dart`
```dart
Future<SyncUser?> signUp({required String email, required String password, String? displayName});
Future<SyncUser?> signIn({required String email, required String password});
Future<void> signOut();
SyncUser? get currentUser;
```
- `signUp` returns the new user, or `null` if the account already exists.
- `signIn` returns the user, or `null` if credentials do not match.

### `ProfileService` — `lib/services/profile_service.dart`
```dart
Future<ApplicantProfile> saveProfile(ApplicantProfile profile);
Future<ApplicantProfile?> getProfile(String userId);
Future<ApplicantProfile> updateProfile(ApplicantProfile profile);
```
- `saveProfile` and `updateProfile` return the stored copy with `id` and
  `updatedAt` set.
- Profiles are keyed by `userId ?? id` so a caller without a `userId` can still
  retrieve by the `id` returned from `saveProfile`.

### `JobService` — `lib/services/job_service.dart` (Phase 2)
```dart
Future<List<Job>> listJobs();
Future<Job?> getJob(String id);
```
- Stub only in Phase 1. Phase 2 will flesh out the job and application flow.

## How to wire Supabase (Arsema Tewodros)

1. Add `supabase_flutter` to `pubspec.yaml`.
2. Create `SupabaseAuthService`, `SupabaseProfileService`,
   `SupabaseJobService` implementing the abstract classes.
3. In `lib/services/service_locator.dart`, change the three field
   initializers to construct the Supabase implementations.
4. Initialise the Supabase client in `main.dart` before `runApp` and inject any
   needed config (e.g. via a riverpod override).

No other file should need editing, because everything else consumes the
abstract types through the service locator / providers.

## Injected capabilities (not backend, but stubbed for the same reason)

Two capabilities are stubbed for a teammate to implement later:

- **Voice input** (`VoiceInputCallback`): a mic button calls this. The stub
  returns an empty string. **Bethel** wires the real speech-recognition API.
- **Read aloud** (`ReadAloudCallback`): the Welcome "read aloud" button calls
  this. The stub is a no-op. **Bethel** wires the real text-to-speech API.

Both are defined in `lib/core/access/access_callbacks.dart` and exposed as
riverpod providers in `app_providers.dart`, so they can be overridden the same
way as the services.
