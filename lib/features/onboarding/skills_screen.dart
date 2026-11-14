import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/providers/app_providers.dart';
import '../../../models/applicant_profile_model.dart';
import '../../../shared/widgets/form_step.dart';
import '../../../shared/widgets/question_screen.dart';

/// Collects occupation, education level, key skills and languages. Free-text
/// steps include a voice slot (typed fallback always available).
///
/// When [editMode] is true the screen was pushed from Profile Review to edit
/// this section; completing it pops back to review instead of advancing to the
/// support screen.
class SkillsScreen extends ConsumerWidget {
  const SkillsScreen({super.key, this.editMode = false});

  final bool editMode;

  static List<String> _split(String value) => value
      .split(',')
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(onboardingDraftProvider);
    final skills = draft.skills;
    return QuestionScreen(
      flowTitle: AppStrings.skillsFlowTitle,
      finalStepLabel: AppStrings.continueLabel,
      voiceInput: ref.read(voiceInputProvider),
      initialAnswers: <String, Object>{
        if (skills.occupation.isNotEmpty) 'occupation': skills.occupation,
        'education': skills.educationLevel.name,
        if (skills.keySkills.isNotEmpty) 'keySkills': skills.keySkills.join(', '),
        if (skills.languages.isNotEmpty) 'languages': skills.languages.join(', '),
      },
      steps: <FormStep>[
        FormStep(
          id: 'occupation',
          title: AppStrings.occupationQuestion,
          hint: AppStrings.occupationHint,
          inputType: FormInputType.voice,
        ),
        FormStep(
          id: 'education',
          title: AppStrings.educationQuestion,
          hint: AppStrings.educationHint,
          inputType: FormInputType.choice,
          options: const <FormOption>[
            FormOption(id: 'primary', label: AppStrings.educationPrimary),
            FormOption(id: 'secondary', label: AppStrings.educationSecondary),
            FormOption(id: 'vocational', label: AppStrings.educationVocational),
            FormOption(id: 'university', label: AppStrings.educationUniversity),
            FormOption(id: 'noneOrOther', label: AppStrings.educationNoneOrOther),
          ],
        ),
        FormStep(
          id: 'keySkills',
          title: AppStrings.keySkillsQuestion,
          hint: AppStrings.keySkillsHint,
          inputType: FormInputType.voice,
        ),
        FormStep(
          id: 'languages',
          title: AppStrings.languagesQuestion,
          hint: AppStrings.languagesHint,
          inputType: FormInputType.voice,
        ),
      ],
      onComplete: (answers) {
        final occupation = (answers['occupation'] as String?) ?? '';
        final educationName = answers['education'] as String?;
        final education = EducationLevel.values.firstWhere(
          (e) => e.name == educationName,
          orElse: () => EducationLevel.noneOrOther,
        );
        final keySkills = _split((answers['keySkills'] as String?) ?? '');
        final languages = _split((answers['languages'] as String?) ?? '');
        ref.read(onboardingDraftProvider.notifier).setSkills(
              SkillsInfo(
                occupation: occupation,
                educationLevel: education,
                keySkills: keySkills,
                languages: languages,
              ),
            );
        if (editMode) {
          context.pop();
        } else {
          context.pushNamed(RouteNames.support);
        }
      },
    );
  }
}
