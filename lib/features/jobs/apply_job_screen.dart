import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/providers/app_providers.dart';
import '../../../models/job_model.dart';
import '../../../shared/widgets/form_step.dart';
import '../../../shared/widgets/question_screen.dart';

/// The job application flow: two short questions answered by voice (typed
/// fallback always available), stored on the application as `cover_note`.
///
/// The answers go only to the employer with the application — the applicant's
/// private support preferences are never part of this payload.
class ApplyJobScreen extends ConsumerWidget {
  const ApplyJobScreen({super.key, required this.job});

  final Job job;

  /// Combines both answers into the single stored note, skipping empties.
  static String buildCoverNote(Map<String, Object> answers) {
    final why = ((answers['why'] as String?) ?? '').trim();
    final experience = ((answers['experience'] as String?) ?? '').trim();
    return <String>[
      if (why.isNotEmpty) why,
      if (experience.isNotEmpty) experience,
    ].join('\n');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    return QuestionScreen(
      flowTitle: AppStrings.applyFlowTitle,
      finalStepLabel: AppStrings.apply,
      steps: <FormStep>[
        FormStep(
          id: 'why',
          title: AppStrings.applyWhyQuestion,
          hint: AppStrings.applyWhyHint,
          simpleTitle: AppStrings.applyWhySimple,
          simpleHint: AppStrings.applyWhyHintSimple,
          inputType: FormInputType.voice,
        ),
        FormStep(
          id: 'experience',
          title: AppStrings.applyExperienceQuestion,
          hint: AppStrings.applyExperienceHint,
          simpleTitle: AppStrings.applyExperienceSimple,
          simpleHint: AppStrings.applyExperienceHintSimple,
          inputType: FormInputType.voice,
          required: false,
        ),
      ],
      onComplete: (answers) async {
        if (user == null) {
          // Session vanished mid-flow (e.g. token expired): bail out cleanly.
          if (context.mounted) context.pop();
          return;
        }
        final coverNote = buildCoverNote(answers);
        try {
          await ref.read(jobServiceProvider).applyToJob(
                jobId: job.id,
                userId: user.id,
                coverNote: coverNote.isEmpty ? null : coverNote,
              );
          ref.invalidate(jobApplicationsProvider);
          if (!context.mounted) return;
          // Grab the messenger before popping so the confirmation still shows
          // on the jobs screen underneath.
          final messenger = ScaffoldMessenger.of(context);
          context.pop();
          messenger.showSnackBar(
            const SnackBar(content: Text(AppStrings.applicationSent)),
          );
        } catch (_) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppStrings.applicationFailed)),
          );
        }
      },
    );
  }
}
