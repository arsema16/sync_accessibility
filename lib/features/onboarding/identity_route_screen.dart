import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/providers/app_providers.dart';
import '../../../models/applicant_profile_model.dart';
import '../../../shared/widgets/form_step.dart';
import '../../../shared/widgets/question_screen.dart';

/// Lets the user pick how they will verify their identity (single choice).
///
/// When [editMode] is true the screen was pushed from Profile Review to edit
/// this section; completing it pops back to review instead of advancing to the
/// skills screen.
class IdentityRouteScreen extends ConsumerWidget {
  const IdentityRouteScreen({super.key, this.editMode = false});

  final bool editMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(onboardingDraftProvider);
    return QuestionScreen(
      flowTitle: AppStrings.identityHeading,
      finalStepLabel: AppStrings.continueLabel,
      initialAnswers: <String, Object>{
        if (draft.identityRoute != null) 'identityRoute': draft.identityRoute!.name,
      },
      steps: <FormStep>[
        FormStep(
          id: 'identityRoute',
          title: AppStrings.identityHeading,
          hint: AppStrings.identityHint,
          inputType: FormInputType.choice,
          options: const <FormOption>[
            FormOption(
              id: 'nationalId',
              label: AppStrings.identityNationalId,
              description: AppStrings.identityNationalIdDesc,
            ),
            FormOption(
              id: 'refugeeId',
              label: AppStrings.identityRefugeeId,
              description: AppStrings.identityRefugeeIdDesc,
            ),
            FormOption(
              id: 'otherDocument',
              label: AppStrings.identityOtherDoc,
              description: AppStrings.identityOtherDocDesc,
            ),
            FormOption(
              id: 'partnerReferral',
              label: AppStrings.identityPartner,
              description: AppStrings.identityPartnerDesc,
            ),
          ],
        ),
      ],
      onComplete: (answers) {
        final selected = answers['identityRoute'] as String?;
        final route = IdentityRoute.values.firstWhere(
          (r) => r.name == selected,
          orElse: () => IdentityRoute.nationalId,
        );
        ref.read(onboardingDraftProvider.notifier).setIdentityRoute(route);
        if (editMode) {
          context.pop();
        } else {
          context.pushNamed(RouteNames.skills);
        }
      },
    );
  }
}
