import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../models/applicant_profile_model.dart';

/// Lets the user pick the interaction preferences that form their Access
/// Passport. These preferences also drive the app-wide text scale and theme
/// variant.
///
/// When [editMode] is true the screen was pushed from Profile Review to edit
/// this section; "Save and continue" pops back to review instead of advancing
/// to the contact screen.
class AccessPreferencesScreen extends ConsumerWidget {
  const AccessPreferencesScreen({super.key, this.editMode = false});

  final bool editMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final access = ref.watch(accessPreferencesNotifierProvider);
    final notifier = ref.read(accessPreferencesNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.accessPreferencesHeading)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.pagePadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      AppStrings.accessPreferencesHint,
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Semantics(
                      header: true,
                      child: Text(
                        AppStrings.answerModeQuestion,
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        _AnswerModeChip(
                          label: AppStrings.answerVoice,
                          selected: access.answerMode == AnswerMode.voice,
                          onSelected: (_) => notifier.setAnswerMode(AnswerMode.voice),
                        ),
                        _AnswerModeChip(
                          label: AppStrings.answerTyped,
                          selected: access.answerMode == AnswerMode.typed,
                          onSelected: (_) => notifier.setAnswerMode(AnswerMode.typed),
                        ),
                        _AnswerModeChip(
                          label: AppStrings.answerEither,
                          selected: access.answerMode == AnswerMode.either,
                          onSelected: (_) => notifier.setAnswerMode(AnswerMode.either),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const Divider(),
                    const SizedBox(height: AppSpacing.md),
                    _TogglePreference(
                      label: AppStrings.readAloudPref,
                      selected: access.readAloud,
                      onToggle: notifier.setReadAloud,
                    ),
                    _TogglePreference(
                      label: AppStrings.simplerWording,
                      selected: access.simplerWording,
                      onToggle: notifier.setSimplerWording,
                    ),
                    _TogglePreference(
                      label: AppStrings.largerText,
                      helper: AppStrings.largerTextHint,
                      selected: access.largerText,
                      onToggle: notifier.setLargerText,
                    ),
                    _TogglePreference(
                      label: AppStrings.strongerContrast,
                      helper: AppStrings.strongerContrastHint,
                      selected: access.strongerContrast,
                      onToggle: notifier.setStrongerContrast,
                    ),
                    _TogglePreference(
                      label: AppStrings.extraTime,
                      helper: AppStrings.extraTimeHint,
                      selected: access.extraTime,
                      onToggle: notifier.setExtraTime,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              child: FilledButton(
                onPressed: () {
                  if (editMode) {
                    context.pop();
                  } else {
                    context.pushNamed(RouteNames.contact);
                  }
                },
                child: const Text(AppStrings.saveAndContinue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnswerModeChip extends StatelessWidget {
  const _AnswerModeChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
  }
}

class _TogglePreference extends StatelessWidget {
  const _TogglePreference({
    required this.label,
    required this.selected,
    required this.onToggle,
    this.helper,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onToggle;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FilterChip(
            label: Text(label),
            selected: selected,
            onSelected: onToggle,
            materialTapTargetSize: MaterialTapTargetSize.padded,
          ),
          if (helper != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(helper!, style: theme.textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}
