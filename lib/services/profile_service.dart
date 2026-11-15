import '../models/applicant_profile_model.dart';

/// Applicant profile storage contract.
///
/// The Supabase implementation (`SupabaseProfileService`) persists to the
/// `profiles` table; `InMemoryProfileService` remains as a local fallback for
/// tests and unconfigured builds.
abstract class ProfileService {
  /// Persists a profile (creating or replacing it) and returns the stored
  /// copy, with [ApplicantProfile.id] and [ApplicantProfile.updatedAt] set.
  ///
  /// When [ApplicantProfile.userId] is null the implementation falls back to
  /// the signed-in user. Throws [ProfileException] when no user is available.
  Future<ApplicantProfile> saveProfile(ApplicantProfile profile);

  /// Returns the profile for [userId], or `null` if none is stored.
  Future<ApplicantProfile?> getProfile(String userId);

  /// Updates an already-stored profile and returns the stored copy.
  Future<ApplicantProfile> updateProfile(ApplicantProfile profile);
}

/// A typed profile-storage failure with a message safe to show to the user.
class ProfileException implements Exception {
  const ProfileException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Local in-memory implementation of [ProfileService].
///
/// Profiles are keyed by `userId ?? id` so callers without a userId can still
/// retrieve by the id returned from [saveProfile].
class InMemoryProfileService implements ProfileService {
  final Map<String, ApplicantProfile> _store = <String, ApplicantProfile>{};
  int _nextId = 0;

  @override
  Future<ApplicantProfile> saveProfile(ApplicantProfile profile) async {
    final id = profile.id ?? 'profile-${_nextId++}';
    final saved = profile.copyWith(id: id, updatedAt: DateTime.now());
    _store[saved.userId ?? id] = saved;
    return saved;
  }

  @override
  Future<ApplicantProfile?> getProfile(String userId) async {
    return _store[userId];
  }

  @override
  Future<ApplicantProfile> updateProfile(ApplicantProfile profile) async {
    return saveProfile(profile);
  }
}
