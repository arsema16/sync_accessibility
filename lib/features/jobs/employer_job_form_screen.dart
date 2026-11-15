import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/providers/app_providers.dart';
import '../../../models/job_model.dart';
import '../../../shared/widgets/form_step.dart';
import '../../../shared/widgets/question_screen.dart';

/// Create / edit an employer job posting, one question per screen.
///
/// Reuses [QuestionScreen] so the employer gets the same accessibility
/// features as applicants: voice input on every field, simpler wording,
/// read-aloud and no timeouts. The "accommodations" step is the filterable
/// tag set job seekers match against their private support needs.
class EmployerJobFormScreen extends ConsumerWidget {
  const EmployerJobFormScreen({super.key, this.existing});

  /// The posting being edited, or `null` when creating a new one.
  final Job? existing;

  /// Accommodation tags employers can offer. Ids double as the stored tag
  /// strings so answers map straight onto [Job.tags].
  static const List<FormOption> accommodationOptions = <FormOption>[
    FormOption(id: 'Step-free Access', label: 'Step-free access'),
    FormOption(id: 'Remote OK', label: 'Remote or hybrid work'),
    FormOption(id: 'Written Instructions', label: 'Written instructions'),
    FormOption(id: 'With Support', label: 'A support worker on site'),
    FormOption(id: 'Flexible Hours', label: 'Flexible hours'),
  ];

  static const List<FormOption> activeOptions = <FormOption>[
    FormOption(
      id: 'live',
      label: 'Publish now',
      description: 'Job seekers can see and apply for this job.',
    ),
    FormOption(
      id: 'hidden',
      label: 'Save as draft',
      description: 'Only you can see it until you publish it.',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final job = existing;

    return QuestionScreen(
      flowTitle:
          job == null ? AppStrings.employerPostJob : AppStrings.employerEditJob,
      finalStepLabel: AppStrings.save,
      initialAnswers: <String, Object>{
        if (job != null && job.title.isNotEmpty) 'title': job.title,
        if (job != null && job.employer.isNotEmpty) 'employer': job.employer,
        if (job != null && job.location != null) 'location': job.location!,
        if (job != null && job.description != null)
          'description': job.description!,
        if (job != null && job.tags.isNotEmpty) 'tags': job.tags,
        'active': (job?.isActive ?? true) ? 'live' : 'hidden',
      },
      steps: <FormStep>[
        FormStep(
          id: 'title',
          title: AppStrings.employerJobTitleLabel,
          hint: AppStrings.employerJobTitleHint,
          simpleTitle: AppStrings.employerJobTitleSimple,
          inputType: FormInputType.text,
        ),
        FormStep(
          id: 'employer',
          title: AppStrings.employerJobEmployerLabel,
          hint: AppStrings.employerJobEmployerHint,
          simpleTitle: AppStrings.employerJobEmployerSimple,
          inputType: FormInputType.text,
        ),
        FormStep(
          id: 'location',
          title: AppStrings.employerJobLocationLabel,
          hint: AppStrings.employerJobLocationHint,
          simpleTitle: AppStrings.employerJobLocationSimple,
          inputType: FormInputType.text,
        ),
        FormStep(
          id: 'description',
          title: AppStrings.employerJobDescriptionLabel,
          hint: AppStrings.employerJobDescriptionHint,
          simpleTitle: AppStrings.employerJobDescriptionSimple,
          inputType: FormInputType.text,
          required: false,
        ),
        FormStep(
          id: 'tags',
          title: AppStrings.employerJobAccommodationsLabel,
          hint: AppStrings.employerJobAccommodationsHint,
          simpleTitle: AppStrings.employerJobAccommodationsSimple,
          inputType: FormInputType.multiChoice,
          options: accommodationOptions,
          required: false,
        ),
        FormStep(
          id: 'active',
          title: 'Publish this job?',
          inputType: FormInputType.choice,
          options: activeOptions,
        ),
      ],
      onComplete: (answers) async {
        if (user == null) {
          if (context.mounted) context.pop();
          return;
        }
        final location = ((answers['location'] as String?) ?? '').trim();
        final description =
            ((answers['description'] as String?) ?? '').trim();
        final tags = (answers['tags'] is List)
            ? List<String>.from(answers['tags'] as List)
            : <String>[];
        final saved = Job(
          id: job?.id ?? '',
          title: ((answers['title'] as String?) ?? '').trim(),
          employer: ((answers['employer'] as String?) ?? '').trim(),
          employerId: job?.employerId ?? user.id,
          location: location.isEmpty ? null : location,
          description: description.isEmpty ? null : description,
          postedAt: job?.postedAt,
          tags: tags,
          isActive: answers['active'] != 'hidden',
        );
        try {
          await ref.read(jobServiceProvider).saveEmployerJob(saved);
          ref.invalidate(employerJobsProvider);
          ref.invalidate(jobsProvider);
          if (!context.mounted) return;
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppStrings.employerJobSaved)),
          );
        } catch (_) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppStrings.employerJobSaveFailed)),
          );
        }
      },
    );
  }
}
