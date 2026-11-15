import 'package:flutter_test/flutter_test.dart';

import 'package:sync_accessibility/models/applicant_profile_model.dart';
import 'package:sync_accessibility/services/supabase_profile_service.dart';

void main() {
  group('profileToRow', () {
    test('maps every section onto the profiles columns', () {
      final profile = ApplicantProfile(
        id: 'u1',
        userId: 'u1',
        contact: const PersonalContact(
          fullName: 'Arsema Tefera',
          phone: '0912345678',
          email: 'arsema@example.com',
        ),
        identityRoute: IdentityRoute.refugeeId,
        skills: const SkillsInfo(
          occupation: 'Farming',
          educationLevel: EducationLevel.secondary,
          keySkills: <String>['Punctual', 'Teamwork'],
          languages: <String>['Amharic', 'English'],
        ),
        accessPassport: const AccessPassport(
          answerMode: AnswerMode.voice,
          readAloud: true,
          simplerWording: true,
          largerText: false,
          strongerContrast: true,
          extraTime: true,
        ),
        privateSupport: const PrivateSupport(
          writtenInstructions: true,
          extraInterviewTime: false,
          remoteInterview: true,
          stepFreeLocation: true,
          other: 'A quiet room please',
        ),
      );

      final row = profileToRow(profile, userId: 'u1');

      expect(row['user_id'], 'u1');
      expect(row['full_name'], 'Arsema Tefera');
      expect(row['phone'], '0912345678');
      expect(row['email'], 'arsema@example.com');
      expect(row['identity_route'], 'refugeeId');
      expect(row['occupation'], 'Farming');
      expect(row['education_level'], 'secondary');
      expect(row['key_skills'], <String>['Punctual', 'Teamwork']);
      expect(row['languages'], <String>['Amharic', 'English']);
      expect(row['answer_mode'], 'voice');
      expect(row['read_aloud'], true);
      expect(row['stronger_contrast'], true);
      expect(row['written_instructions'], true);
      expect(row['remote_interview'], true);
      expect(row['step_free_location'], true);
      expect(row['other_support'], 'A quiet room please');
      // updated_at is owned by the database trigger, never the client.
      expect(row.containsKey('updated_at'), isFalse);
    });

    test('fills defaults for an empty profile', () {
      final row = profileToRow(ApplicantProfile.empty(), userId: 'u9');

      expect(row['user_id'], 'u9');
      expect(row['full_name'], '');
      expect(row['email'], isNull);
      expect(row['identity_route'], isNull);
      expect(row['read_aloud'], false);
      expect(row['written_instructions'], false);
      expect(row['other_support'], isNull);
    });
  });

  group('profileFromRow', () {
    test('round-trips through the row mapping', () {
      final original = ApplicantProfile(
        userId: 'u1',
        contact: const PersonalContact(
          fullName: 'Arsema Tefera',
          phone: '0912345678',
          email: 'arsema@example.com',
        ),
        identityRoute: IdentityRoute.otherDocument,
        skills: const SkillsInfo(
          occupation: 'Retail',
          educationLevel: EducationLevel.vocational,
          keySkills: <String>['Cash handling'],
          languages: <String>['English'],
        ),
        accessPassport: const AccessPassport(
          answerMode: AnswerMode.typed,
          readAloud: false,
          simplerWording: true,
          largerText: true,
          strongerContrast: false,
          extraTime: false,
        ),
        privateSupport: const PrivateSupport(
          writtenInstructions: true,
          extraInterviewTime: true,
          remoteInterview: false,
        ),
      );

      final restored = profileFromRow(
        profileToRow(original, userId: 'u1'),
      );

      expect(restored.id, 'u1');
      expect(restored.userId, 'u1');
      expect(restored.contact, original.contact);
      expect(restored.identityRoute, IdentityRoute.otherDocument);
      expect(restored.skills, original.skills);
      expect(restored.accessPassport, original.accessPassport);
      expect(restored.privateSupport, original.privateSupport);
    });

    test('tolerates a sparse row with missing sections', () {
      final restored = profileFromRow(<String, dynamic>{
        'user_id': 'u2',
        'full_name': 'New User',
      });

      expect(restored.userId, 'u2');
      expect(restored.contact.fullName, 'New User');
      expect(restored.contact.phone, '');
      expect(restored.identityRoute, isNull);
      expect(restored.skills.educationLevel, EducationLevel.noneOrOther);
      expect(restored.skills.keySkills, isEmpty);
      expect(restored.accessPassport.answerMode, AnswerMode.either);
      expect(restored.privateSupport, isNull);
      expect(restored.updatedAt, isNull);
    });

    test('keeps privateSupport null when every flag is off', () {
      final restored = profileFromRow(<String, dynamic>{
        'user_id': 'u3',
        'written_instructions': false,
        'extra_interview_time': false,
        'remote_interview': false,
        'step_free_location': false,
        'accessible_transportation': false,
        'other_support': null,
      });

      expect(restored.privateSupport, isNull);
    });

    test('reads an ISO timestamp into updatedAt', () {
      final restored = profileFromRow(<String, dynamic>{
        'user_id': 'u4',
        'updated_at': '2026-01-05T10:30:00.000Z',
      });

      expect(restored.updatedAt, isNotNull);
      expect(restored.updatedAt!.year, 2026);
    });
  });
}
