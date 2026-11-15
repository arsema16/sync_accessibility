import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/supabase_config.dart';
import '../models/applicant_profile_model.dart';
import 'profile_service.dart';

/// Serialises [profile] into a row for the `profiles` table.
///
/// [userId] becomes the primary key. Top-level (rather than private) so tests
/// can cover the mapping without a live client.
Map<String, Object?> profileToRow(
  ApplicantProfile profile, {
  required String userId,
}) {
  final passport = profile.accessPassport;
  final support = profile.privateSupport;
  return <String, Object?>{
    'user_id': userId,
    'full_name': profile.contact.fullName,
    'phone': profile.contact.phone,
    'email': profile.contact.email,
    'identity_route': profile.identityRoute?.name,
    'occupation': profile.skills.occupation,
    'education_level': profile.skills.educationLevel.name,
    'key_skills': profile.skills.keySkills,
    'languages': profile.skills.languages,
    'answer_mode': passport.answerMode.name,
    'read_aloud': passport.readAloud,
    'simpler_wording': passport.simplerWording,
    'larger_text': passport.largerText,
    'stronger_contrast': passport.strongerContrast,
    'extra_time': passport.extraTime,
    'written_instructions': support?.writtenInstructions ?? false,
    'extra_interview_time': support?.extraInterviewTime ?? false,
    'remote_interview': support?.remoteInterview ?? false,
    'step_free_location': support?.stepFreeLocation ?? false,
    'accessible_transportation': support?.accessibleTransportation ?? false,
    'other_support': support?.other,
  };
}

/// Reads a `profiles` row back into an [ApplicantProfile].
///
/// Missing or malformed sections fall back to their empty defaults so a
/// partially stored row never crashes the UI.
ApplicantProfile profileFromRow(Map<String, dynamic> row) {
  final identityName = row['identity_route'];
  final educationName = row['education_level'];
  final answerModeName = row['answer_mode'];

  final written = row['written_instructions'] == true;
  final extraTime = row['extra_interview_time'] == true;
  final remote = row['remote_interview'] == true;
  final stepFree = row['step_free_location'] == true;
  final transport = row['accessible_transportation'] == true;
  final other = row['other_support'] as String?;
  final hasSupport = written ||
      extraTime ||
      remote ||
      stepFree ||
      transport ||
      (other != null && other.trim().isNotEmpty);

  return ApplicantProfile(
    id: row['user_id'] as String?,
    userId: row['user_id'] as String?,
    contact: PersonalContact(
      fullName: (row['full_name'] as String?) ?? '',
      phone: (row['phone'] as String?) ?? '',
      email: row['email'] as String?,
    ),
    identityRoute: identityName is String
        ? IdentityRoute.values.firstWhere(
            (route) => route.name == identityName,
            orElse: () => IdentityRoute.nationalId,
          )
        : null,
    skills: SkillsInfo(
      occupation: (row['occupation'] as String?) ?? '',
      educationLevel: educationLevelFromName(educationName),
      keySkills: _stringList(row['key_skills']),
      languages: _stringList(row['languages']),
    ),
    accessPassport: AccessPassport(
      answerMode: answerModeFromName(answerModeName),
      readAloud: row['read_aloud'] == true,
      simplerWording: row['simpler_wording'] == true,
      largerText: row['larger_text'] == true,
      strongerContrast: row['stronger_contrast'] == true,
      extraTime: row['extra_time'] == true,
    ),
    privateSupport: hasSupport
        ? PrivateSupport(
            writtenInstructions: written,
            extraInterviewTime: extraTime,
            remoteInterview: remote,
            stepFreeLocation: stepFree,
            accessibleTransportation: transport,
            other: other,
          )
        : null,
    updatedAt: row['updated_at'] is String
        ? DateTime.tryParse(row['updated_at'] as String)
        : null,
  );
}

/// Parses an education-level name, falling back to [EducationLevel.noneOrOther].
EducationLevel educationLevelFromName(Object? name) =>
    EducationLevel.values.firstWhere(
      (level) => level.name == name,
      orElse: () => EducationLevel.noneOrOther,
    );

/// Parses an answer-mode name, falling back to [AnswerMode.either].
AnswerMode answerModeFromName(Object? name) => AnswerMode.values.firstWhere(
      (mode) => mode.name == name,
      orElse: () => AnswerMode.either,
    );

List<String> _stringList(Object? raw) {
  if (raw is List) {
    return raw.map((item) => item.toString()).toList();
  }
  return const <String>[];
}

/// Supabase-backed [ProfileService] persisting to the `profiles` table.
///
/// One row per user (`user_id` primary key), guarded by row-level security so
/// a user can only read and write their own profile.
class SupabaseProfileService implements ProfileService {
  SupabaseProfileService({SupabaseClient? client})
      : _client = client ?? SupabaseBootstrap.client;

  final SupabaseClient _client;

  @override
  Future<ApplicantProfile> saveProfile(ApplicantProfile profile) async {
    final userId = profile.userId ?? _client.auth.currentUser?.id;
    if (userId == null) {
      throw const ProfileException(
        'Sign in to SYNC before saving your profile.',
      );
    }
    try {
      final row = await _client
          .from('profiles')
          .upsert(profileToRow(profile, userId: userId), onConflict: 'user_id')
          .select()
          .single();
      return profileFromRow(row);
    } on PostgrestException catch (error) {
      debugPrint('Supabase saveProfile failed: $error');
      throw ProfileException(_friendlyProfileMessage(error));
    }
  }

  @override
  Future<ApplicantProfile?> getProfile(String userId) async {
    try {
      final row = await _client
          .from('profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      return row == null ? null : profileFromRow(row);
    } on PostgrestException catch (error) {
      debugPrint('Supabase getProfile failed: $error');
      throw ProfileException(_friendlyProfileMessage(error));
    }
  }

  @override
  Future<ApplicantProfile> updateProfile(ApplicantProfile profile) =>
      saveProfile(profile);

  /// Turns a Postgres error into copy a person can act on.
  static String _friendlyProfileMessage(PostgrestException error) {
    if (error.code == '42501' ||
        error.message.contains('row-level security')) {
      return 'Sign in to SYNC before saving your profile.';
    }
    if (error.code == 'PGRST205' || error.message.contains('schema cache')) {
      return 'SYNC is not set up for this project yet. '
          'Run supabase/schema.sql in the Supabase SQL editor.';
    }
    return 'Could not save your profile. Please try again.';
  }
}
