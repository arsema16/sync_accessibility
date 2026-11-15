import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../models/applicant_profile_model.dart';
import '../../../shared/widgets/status_view.dart';

/// The signed-in user's stored profile.
///
/// Reads the `profiles` row through [savedProfileProvider]; when none exists
/// yet it offers to start onboarding, and "Edit profile" loads the saved row
/// back into the onboarding draft so it can be changed and re-submitted.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _editProfile(
    BuildContext context,
    WidgetRef ref,
    ApplicantProfile profile,
  ) async {
    // Restore the saved answers into the live draft and access passport so
    // the review screen round-trips exactly what is stored.
    ref.read(onboardingDraftProvider.notifier).replace(profile);
    final passport = profile.accessPassport;
    final access = ref.read(accessPreferencesNotifierProvider.notifier);
    access
      ..setAnswerMode(passport.answerMode)
      ..setReadAloud(passport.readAloud)
      ..setSimplerWording(passport.simplerWording)
      ..setLargerText(passport.largerText)
      ..setStrongerContrast(passport.strongerContrast)
      ..setExtraTime(passport.extraTime);

    if (!context.mounted) return;
    context.pushNamed(RouteNames.profileReview);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.sectionName)),
        body: SafeArea(
          child: StatusView(
            icon: Icons.person_outline,
            title: AppStrings.signInToContinue,
            body: AppStrings.profileEmptyBody,
            actionLabel: AppStrings.signInAction,
            onAction: () => context.pushNamed(RouteNames.signIn),
          ),
        ),
      );
    }

    final profileAsync = ref.watch(savedProfileProvider(user.id));

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.sectionName)),
      body: SafeArea(
        child: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => StatusView(
            icon: Icons.cloud_off,
            title: AppStrings.profileLoadFailed,
            actionLabel: AppStrings.tryAgain,
            onAction: () => ref.invalidate(savedProfileProvider(user.id)),
          ),
          data: (profile) {
            if (profile == null) {
              return StatusView(
                icon: Icons.person_outline,
                title: AppStrings.profileEmptyTitle,
                body: AppStrings.profileEmptyBody,
                actionLabel: AppStrings.startProfile,
                onAction: () =>
                    context.pushNamed(RouteNames.profileReview),
              );
            }
            return _ProfileDetails(
              profile: profile,
              onEdit: () => _editProfile(context, ref, profile),
            );
          },
        ),
      ),
    );
  }
}

class _ProfileDetails extends StatelessWidget {
  const _ProfileDetails({required this.profile, required this.onEdit});

  final ApplicantProfile profile;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final contact = profile.contact;
    final skills = profile.skills;
    final passport = profile.accessPassport;
    final support = profile.privateSupport;
    final contactLine = <String>[
      if (contact.email != null && contact.email!.isNotEmpty) contact.email!,
      if (contact.phone.isNotEmpty) contact.phone,
    ].join(' · ');

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      children: [
        // Header: name + contact
        Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.fullName.isEmpty
                        ? AppStrings.notProvided
                        : contact.fullName,
                    style: theme.textTheme.titleLarge,
                  ),
                  Text(
                    contactLine.isEmpty
                        ? AppStrings.notProvided
                        : contactLine,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        _Section(
          title: AppStrings.sectionSkills,
          rows: <String, String>{
            AppStrings.occupationQuestion: skills.occupation.isEmpty
                ? AppStrings.notProvided
                : skills.occupation,
            AppStrings.educationQuestion: _educationLabel(
              skills.educationLevel,
            ),
            AppStrings.keySkillsQuestion: skills.keySkills.isEmpty
                ? AppStrings.notProvided
                : skills.keySkills.join(', '),
            AppStrings.languagesQuestion: skills.languages.isEmpty
                ? AppStrings.notProvided
                : skills.languages.join(', '),
          },
        ),
        _Section(
          title: AppStrings.sectionAccessPreferences,
          rows: <String, String>{
            AppStrings.answerModeQuestion: _answerModeLabel(
              passport.answerMode,
            ),
            AppStrings.readAloudPref: _yesNo(passport.readAloud),
            AppStrings.largerText: _yesNo(passport.largerText),
            AppStrings.strongerContrast: _yesNo(passport.strongerContrast),
            AppStrings.extraTime: _yesNo(passport.extraTime),
          },
        ),
        if (support != null)
          _Section(
            title: AppStrings.sectionSupport,
            rows: <String, String>{
              AppStrings.supportWrittenInstructions:
                  _yesNo(support.writtenInstructions),
              AppStrings.supportExtraTime: _yesNo(support.extraInterviewTime),
              AppStrings.supportRemote: _yesNo(support.remoteInterview),
              if (support.other != null && support.other!.isNotEmpty)
                AppStrings.supportOther: support.other!,
            },
          ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(AppSpacing.minTapTarget),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(50)),
            ),
          ),
          onPressed: onEdit,
          child: const Text(
            AppStrings.editProfile,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  static String _yesNo(bool value) =>
      value ? AppStrings.yes : AppStrings.no;

  static String _educationLabel(EducationLevel level) {
    switch (level) {
      case EducationLevel.primary:
        return AppStrings.educationPrimary;
      case EducationLevel.secondary:
        return AppStrings.educationSecondary;
      case EducationLevel.vocational:
        return AppStrings.educationVocational;
      case EducationLevel.university:
        return AppStrings.educationUniversity;
      case EducationLevel.noneOrOther:
        return AppStrings.educationNoneOrOther;
    }
  }

  static String _answerModeLabel(AnswerMode mode) {
    switch (mode) {
      case AnswerMode.voice:
        return AppStrings.answerVoice;
      case AnswerMode.typed:
        return AppStrings.answerTyped;
      case AnswerMode.either:
        return AppStrings.answerEither;
    }
  }
}

/// A titled group of label/value rows.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.rows});

  final String title;
  final Map<String, String> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Color(0xFFE0E0E0)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final entry in rows.entries) ...[
                Text(
                  entry.key,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF757575),
                  ),
                ),
                Text(
                  entry.value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
