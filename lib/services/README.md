# SYNC service layer

This folder defines the **abstract** service contracts used across the app
and their two implementations:

| Contract | Production implementation (Supabase) | Fallback implementation |
| --- | --- | --- |
| `AuthService` | `SupabaseAuthService` — `auth.users` via GoTrue | `InMemoryAuthService` |
| `ProfileService` | `SupabaseProfileService` — `profiles` table | `InMemoryProfileService` |
| `JobService` | `SupabaseJobService` — `jobs` + `job_applications` tables | `InMemoryJobService` |

Everything goes through the riverpod providers in
`lib/core/providers/app_providers.dart`, so no UI or state code talks to a
concrete class directly.

## Which implementation runs?

`ServiceLocator` resolves on first access:

* **Supabase** when `SupabaseBootstrap.useSupabase` is `true` — i.e. the
  build carries `SUPABASE_URL` / `SUPABASE_ANON_KEY`
  (`flutter run --dart-define-from-file=config.json`) *and* the client
  initialised successfully in `main()`.
* **In-memory** otherwise, so unit tests, `flutter analyze` and a first run
  without `config.json` still work end to end.

The two implementations behave identically, including error semantics:
auth and profile failures throw typed exceptions (`AuthFailure`,
`ProfileException`) carrying a message that is safe to show in the UI.

## Contracts

### `AuthService` — `lib/services/auth_service.dart`
```dart
Future<SyncUser> signUp({required String email, required String password, String? displayName});
Future<SyncUser> signIn({required String email, required String password});
Future<void> signOut();
SyncUser? get currentUser;
Stream<SyncUser?> get authStateChanges;
```
- Both auth calls throw `AuthFailure` on failure (bad credentials, duplicate
  account, network down) instead of returning `null`, so the UI can show the
  real reason.
- `authStateChanges` emits the current session immediately, then every
  sign-in / sign-out; the UI watches it through `authStateChangesProvider`
  and `currentUserProvider`.
- If the Supabase project requires email confirmation, `signUp` succeeds but
  `currentUser` stays `null` until the address is confirmed — the auth form
  uses that to show the "check your email" notice.

### `ProfileService` — `lib/services/profile_service.dart`
```dart
Future<ApplicantProfile> saveProfile(ApplicantProfile profile);
Future<ApplicantProfile?> getProfile(String userId);
Future<ApplicantProfile> updateProfile(ApplicantProfile profile);
```
- `saveProfile`/`updateProfile` return the stored copy with `id` and
  `updatedAt` set, upserted on `user_id`.
- Falls back to the signed-in user when `profile.userId` is null; throws
  `ProfileException` when nobody is signed in (RLS would reject the write).
- Row mapping lives in `profileToRow` / `profileFromRow`
  (`supabase_profile_service.dart`) and is unit tested.

### `JobService` — `lib/services/job_service.dart`
```dart
Future<List<Job>> listJobs();
Future<Job?> getJob(String id);
Future<List<JobApplication>> listApplications(String userId);
Future<JobApplication> applyToJob({required String jobId, required String userId});
Future<void> removeApplication(String applicationId);
```
- `listJobs` returns active listings newest first.
- `applyToJob` upserts on `(user_id, job_id)` so re-applying never duplicates.

## Database

The full schema (tables, RLS policies, seed jobs) is
[`supabase/schema.sql`](../../supabase/schema.sql); setup steps are in
[`supabase/README.md`](../../supabase/README.md).

## Injected capabilities (not backend)

Two capabilities are device APIs rather than backend calls:

- **Voice input** (`VoiceInputCallback`): a mic button calls this. Backed by
  `speech_to_text`.
- **Read aloud** (`ReadAloudCallback`): the Welcome "read aloud" button
  calls this. Backed by `flutter_tts`.

Both are defined in `lib/core/access/access_callbacks.dart` and exposed as
riverpod providers in `app_providers.dart`.
