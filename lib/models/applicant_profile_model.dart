import 'package:equatable/equatable.dart';

/// How the user prefers to provide answers in forms.
enum AnswerMode { voice, typed, either }

/// Highest education level the user has reached.
enum EducationLevel { primary, secondary, vocational, university, noneOrOther }

/// The route a user takes to verify their identity during onboarding.
enum IdentityRoute { nationalId, refugeeId, otherDocument, partnerReferral }

/// Name and contact details gathered on the Contact screen.
class PersonalContact extends Equatable {
  const PersonalContact({
    required this.fullName,
    required this.phone,
    this.email,
  });

  final String fullName;
  final String phone;
  final String? email;

  static PersonalContact empty() => const PersonalContact(
        fullName: '',
        phone: '',
      );

  PersonalContact copyWith({String? fullName, String? phone, String? email}) =>
      PersonalContact(
        fullName: fullName ?? this.fullName,
        phone: phone ?? this.phone,
        email: email ?? this.email,
      );

  @override
  List<Object?> get props => [fullName, phone, email];
}

/// Experience gathered on the Skills screen.
class SkillsInfo extends Equatable {
  const SkillsInfo({
    required this.occupation,
    required this.educationLevel,
    required this.keySkills,
    required this.languages,
  });

  final String occupation;
  final EducationLevel educationLevel;
  final List<String> keySkills;
  final List<String> languages;

  static SkillsInfo empty() => const SkillsInfo(
        occupation: '',
        educationLevel: EducationLevel.noneOrOther,
        keySkills: <String>[],
        languages: <String>[],
      );

  SkillsInfo copyWith({
    String? occupation,
    EducationLevel? educationLevel,
    List<String>? keySkills,
    List<String>? languages,
  }) =>
      SkillsInfo(
        occupation: occupation ?? this.occupation,
        educationLevel: educationLevel ?? this.educationLevel,
        keySkills: keySkills ?? this.keySkills,
        languages: languages ?? this.languages,
      );

  @override
  List<Object?> get props => [occupation, educationLevel, keySkills, languages];
}

/// The Access Passport: the interaction preferences chosen on the Access
/// Preferences screen. These also drive app-wide settings (larger text,
/// stronger contrast, extra time).
class AccessPassport extends Equatable {
  const AccessPassport({
    required this.answerMode,
    required this.readAloud,
    required this.simplerWording,
    required this.largerText,
    required this.strongerContrast,
    required this.extraTime,
  });

  final AnswerMode answerMode;
  final bool readAloud;
  final bool simplerWording;
  final bool largerText;
  final bool strongerContrast;
  final bool extraTime;

  static AccessPassport empty() => const AccessPassport(
        answerMode: AnswerMode.either,
        readAloud: false,
        simplerWording: false,
        largerText: false,
        strongerContrast: false,
        extraTime: false,
      );

  AccessPassport copyWith({
    AnswerMode? answerMode,
    bool? readAloud,
    bool? simplerWording,
    bool? largerText,
    bool? strongerContrast,
    bool? extraTime,
  }) =>
      AccessPassport(
        answerMode: answerMode ?? this.answerMode,
        readAloud: readAloud ?? this.readAloud,
        simplerWording: simplerWording ?? this.simplerWording,
        largerText: largerText ?? this.largerText,
        strongerContrast: strongerContrast ?? this.strongerContrast,
        extraTime: extraTime ?? this.extraTime,
      );

  /// Serialise for [SharedPreferences] persistence.
  Map<String, Object?> toMap() => <String, Object?>{
        'answerMode': answerMode.name,
        'readAloud': readAloud,
        'simplerWording': simplerWording,
        'largerText': largerText,
        'strongerContrast': strongerContrast,
        'extraTime': extraTime,
      };

  /// Deserialise from [SharedPreferences]. Unknown/missing values fall back to
  /// the defaults in [empty].
  factory AccessPassport.fromMap(Map<String, dynamic> map) {
    final mode = AnswerMode.values.firstWhere(
      (m) => m.name == map['answerMode'],
      orElse: () => AnswerMode.either,
    );
    return AccessPassport(
      answerMode: mode,
      readAloud: map['readAloud'] == true,
      simplerWording: map['simplerWording'] == true,
      largerText: map['largerText'] == true,
      strongerContrast: map['strongerContrast'] == true,
      extraTime: map['extraTime'] == true,
    );
  }

  @override
  List<Object?> get props => [
        answerMode,
        readAloud,
        simplerWording,
        largerText,
        strongerContrast,
        extraTime,
      ];
}

/// Private support preferences gathered on the optional Support Preferences
/// screen. Per the product, these are never shared with employers.
class PrivateSupport extends Equatable {
  const PrivateSupport({
    required this.writtenInstructions,
    required this.extraInterviewTime,
    required this.remoteInterview,
    this.other,
  });

  final bool writtenInstructions;
  final bool extraInterviewTime;
  final bool remoteInterview;
  final String? other;

  PrivateSupport copyWith({
    bool? writtenInstructions,
    bool? extraInterviewTime,
    bool? remoteInterview,
    String? other,
  }) =>
      PrivateSupport(
        writtenInstructions: writtenInstructions ?? this.writtenInstructions,
        extraInterviewTime: extraInterviewTime ?? this.extraInterviewTime,
        remoteInterview: remoteInterview ?? this.remoteInterview,
        other: other ?? this.other,
      );

  @override
  List<Object?> get props => [
        writtenInstructions,
        extraInterviewTime,
        remoteInterview,
        other,
      ];
}

/// The complete applicant profile built across the onboarding flow.
class ApplicantProfile extends Equatable {
  const ApplicantProfile({
    this.id,
    this.userId,
    required this.contact,
    required this.identityRoute,
    required this.skills,
    required this.accessPassport,
    this.privateSupport,
    this.updatedAt,
  });

  final String? id;
  final String? userId;
  final PersonalContact contact;
  final IdentityRoute? identityRoute;
  final SkillsInfo skills;
  final AccessPassport accessPassport;
  final PrivateSupport? privateSupport;
  final DateTime? updatedAt;

  static ApplicantProfile empty() => ApplicantProfile(
        contact: PersonalContact.empty(),
        identityRoute: null,
        skills: SkillsInfo.empty(),
        accessPassport: AccessPassport.empty(),
      );

  ApplicantProfile copyWith({
    String? id,
    String? userId,
    PersonalContact? contact,
    IdentityRoute? identityRoute,
    SkillsInfo? skills,
    AccessPassport? accessPassport,
    PrivateSupport? privateSupport,
    DateTime? updatedAt,
  }) =>
      ApplicantProfile(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        contact: contact ?? this.contact,
        identityRoute: identityRoute ?? this.identityRoute,
        skills: skills ?? this.skills,
        accessPassport: accessPassport ?? this.accessPassport,
        privateSupport: privateSupport ?? this.privateSupport,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  List<Object?> get props => [
        id,
        userId,
        contact,
        identityRoute,
        skills,
        accessPassport,
        privateSupport,
        updatedAt,
      ];
}
