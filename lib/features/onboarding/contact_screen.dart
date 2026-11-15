import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/providers/app_providers.dart';
import '../../../models/applicant_profile_model.dart';
import '../../../shared/widgets/form_step.dart';
import '../../../shared/widgets/question_screen.dart';

/// Collects full name, phone and (optional) email, one question per screen.
///
/// When [editMode] is true the screen was pushed from Profile Review to edit
/// this section; completing it pops back to review instead of advancing to the
/// identity route.
class ContactScreen extends ConsumerWidget {
  const ContactScreen({super.key, this.editMode = false});

  final bool editMode;

  String? _phoneValidator(String value) {
    if (value.isEmpty) {
      return AppStrings.requiredError;
    }
    final digits = value.replaceAll(RegExp(r'[\s\-()]'), '');
    final ok = RegExp(r'^\+?[0-9]{6,}$').hasMatch(digits);
    return ok ? null : AppStrings.invalidPhoneError;
  }

  String? _emailValidator(String value) {
    if (value.isEmpty) {
      return null;
    }
    final ok = RegExp(r'^[\w.+-]+@[\w-]+\.[A-Za-z]{2,}$').hasMatch(value);
    return ok ? null : AppStrings.invalidEmailError;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(onboardingDraftProvider);
    final contact = draft.contact;
    return QuestionScreen(
      flowTitle: AppStrings.contactFlowTitle,
      finalStepLabel: AppStrings.continueLabel,
      initialAnswers: <String, Object>{
        if (contact.fullName.isNotEmpty) 'fullName': contact.fullName,
        if (contact.phone.isNotEmpty) 'phone': contact.phone,
        if (contact.email != null && contact.email!.isNotEmpty)
          'email': contact.email!,
      },
      steps: <FormStep>[
        FormStep(
          id: 'fullName',
          title: AppStrings.fullNameQuestion,
          hint: AppStrings.fullNameHint,
          simpleTitle: AppStrings.fullNameQuestionSimple,
          simpleHint: AppStrings.fullNameHintSimple,
          inputType: FormInputType.text,
        ),
        FormStep(
          id: 'phone',
          title: AppStrings.phoneQuestion,
          hint: AppStrings.phoneHint,
          simpleTitle: AppStrings.phoneQuestionSimple,
          simpleHint: AppStrings.phoneHintSimple,
          inputType: FormInputType.text,
          keyboardType: TextInputType.phone,
          validator: _phoneValidator,
        ),
        FormStep(
          id: 'email',
          title: AppStrings.emailQuestion,
          hint: AppStrings.emailHint,
          simpleTitle: AppStrings.emailQuestionSimple,
          simpleHint: AppStrings.emailHintSimple,
          inputType: FormInputType.text,
          keyboardType: TextInputType.emailAddress,
          required: false,
          validator: _emailValidator,
        ),
      ],
      onComplete: (answers) {
        final email = (answers['email'] as String?) ?? '';
        final updated = PersonalContact(
          fullName: (answers['fullName'] as String?) ?? '',
          phone: (answers['phone'] as String?) ?? '',
          email: email.isEmpty ? null : email,
        );
        ref.read(onboardingDraftProvider.notifier).setContact(updated);
        if (editMode) {
          context.pop();
        } else {
          context.pushNamed(RouteNames.identity);
        }
      },
    );
  }
}
