import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../models/applicant_profile_model.dart';

/// Optional support preferences. These stay private and are never shared with
/// employers. The user can always skip this step.
///
/// When [editMode] is true the screen was pushed from Profile Review to edit
/// this section; saving or skipping pops back to review instead of advancing
/// to the profile review screen.
class SupportPreferencesScreen extends ConsumerStatefulWidget {
  const SupportPreferencesScreen({super.key, this.editMode = false});

  final bool editMode;

  @override
  ConsumerState<SupportPreferencesScreen> createState() =>
      _SupportPreferencesScreenState();
}

class _SupportPreferencesScreenState extends ConsumerState<SupportPreferencesScreen> {
  late bool _writtenInstructions;
  late bool _extraInterviewTime;
  late bool _remoteInterview;
  late final TextEditingController _otherController;

  @override
  void initState() {
    super.initState();
    final support = ref.read(onboardingDraftProvider).privateSupport;
    _writtenInstructions = support?.writtenInstructions ?? false;
    _extraInterviewTime = support?.extraInterviewTime ?? false;
    _remoteInterview = support?.remoteInterview ?? false;
    _otherController = TextEditingController(text: support?.other ?? '');
  }

  @override
  void dispose() {
    _otherController.dispose();
    super.dispose();
  }

  void _goToReview() {
    if (widget.editMode) {
      context.pop();
    } else {
      context.pushNamed(RouteNames.profileReview);
    }
  }

  void _save() {
    final support = PrivateSupport(
      writtenInstructions: _writtenInstructions,
      extraInterviewTime: _extraInterviewTime,
      remoteInterview: _remoteInterview,
      other: _otherController.text.trim().isEmpty ? null : _otherController.text.trim(),
    );
    ref.read(onboardingDraftProvider.notifier).setPrivateSupport(support);
    _goToReview();
  }

  void _skip() {
    ref.read(onboardingDraftProvider.notifier).setPrivateSupport(null);
    _goToReview();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.supportHeading)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.pagePadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Privacy notice: icon + text, never colour alone.
                    Semantics(
                      container: true,
                      label: AppStrings.supportPrivacy,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.lock, color: theme.colorScheme.primary),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Text(
                                  AppStrings.supportPrivacy,
                                  style: theme.textTheme.bodyLarge,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    CheckboxListTile(
                      title: Text(AppStrings.supportWrittenInstructions),
                      value: _writtenInstructions,
                      onChanged: (v) =>
                          setState(() => _writtenInstructions = v ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 0,
                      ),
                    ),
                    CheckboxListTile(
                      title: Text(AppStrings.supportExtraTime),
                      value: _extraInterviewTime,
                      onChanged: (v) =>
                          setState(() => _extraInterviewTime = v ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 0,
                      ),
                    ),
                    CheckboxListTile(
                      title: Text(AppStrings.supportRemote),
                      value: _remoteInterview,
                      onChanged: (v) =>
                          setState(() => _remoteInterview = v ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 0,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: _otherController,
                      decoration: const InputDecoration(
                        labelText: AppStrings.supportOther,
                        hintText: AppStrings.supportOtherHint,
                      ),
                      minLines: 1,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              child: Row(
                children: [
                  OutlinedButton(
                    onPressed: _skip,
                    child: const Text(AppStrings.skip),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _save,
                    child: const Text(AppStrings.saveAndContinue),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
