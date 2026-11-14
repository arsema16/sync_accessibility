import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../models/applicant_profile_model.dart';

String _identityLabel(IdentityRoute route) {
  switch (route) {
    case IdentityRoute.nationalId:
      return AppStrings.identityNationalId;
    case IdentityRoute.refugeeId:
      return AppStrings.identityRefugeeId;
    case IdentityRoute.otherDocument:
      return AppStrings.identityOtherDoc;
    case IdentityRoute.partnerReferral:
      return AppStrings.identityPartner;
  }
}

String _educationLabel(EducationLevel level) {
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

List<String> _accessSummary(AccessPassport a) {
  final list = <String>[];
  switch (a.answerMode) {
    case AnswerMode.voice:
      list.add(AppStrings.answerVoice);
    case AnswerMode.typed:
      list.add(AppStrings.answerTyped);
    case AnswerMode.either:
      list.add(AppStrings.answerEither);
  }
  if (a.readAloud) {
    list.add(AppStrings.readAloudPref);
  }
  if (a.simplerWording) {
    list.add(AppStrings.simplerWording);
  }
  if (a.largerText) {
    list.add(AppStrings.largerText);
  }
  if (a.strongerContrast) {
    list.add(AppStrings.strongerContrast);
  }
  if (a.extraTime) {
    list.add(AppStrings.extraTime);
  }
  return list;
}

List<String> _supportSummary(PrivateSupport? s) {
  if (s == null) {
    return const <String>[];
  }
  final list = <String>[];
  if (s.writtenInstructions) {
    list.add(AppStrings.supportWrittenInstructions);
  }
  if (s.extraInterviewTime) {
    list.add(AppStrings.supportExtraTime);
  }
  if (s.remoteInterview) {
    list.add(AppStrings.supportRemote);
  }
  if (s.other != null && s.other!.isNotEmpty) {
    list.add(s.other!);
  }
  return list;
}

/// Shows everything the user entered, grouped by section, with an Edit link per
/// section. "Save profile" persists via the profile service stub and shows a
/// completion state.
class ProfileReviewScreen extends ConsumerStatefulWidget {
  const ProfileReviewScreen({super.key});

  @override
  ConsumerState<ProfileReviewScreen> createState() =>
      _ProfileReviewScreenState();
}

class _ProfileReviewScreenState extends ConsumerState<ProfileReviewScreen> {
  bool _saving = false;
  bool _saved = false;

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    final draft = ref.read(onboardingDraftProvider);
    final access = ref.read(accessPreferencesNotifierProvider);
    final profile = draft.copyWith(accessPassport: access);
    await ref.read(profileServiceProvider).saveProfile(profile);
    if (!mounted) {
      return;
    }
    setState(() {
      _saving = false;
      _saved = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_saved) {
      return _buildCompletion(context, theme);
    }

    final draft = ref.watch(onboardingDraftProvider);
    final access = ref.watch(accessPreferencesNotifierProvider);
    final contact = draft.contact;
    final skills = draft.skills;
    final support = draft.privateSupport;

    final accessItems = _accessSummary(access);
    final supportItems = _supportSummary(support);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.profileReviewHeading)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.pagePadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(AppStrings.profileReviewHint, style: theme.textTheme.bodyLarge),
                    const SizedBox(height: AppSpacing.lg),
                    _ReviewSection(
                      title: AppStrings.sectionName,
                      onEdit: () => context.goNamed(RouteNames.contact),
                      children: [
                        _valueOrPlaceholder(contact.fullName),
                      ],
                    ),
                    _ReviewSection(
                      title: AppStrings.sectionContact,
                      onEdit: () => context.goNamed(RouteNames.contact),
                      children: [
                        _valueOrPlaceholder(contact.phone, fallback: AppStrings.notProvided),
                        if (contact.email != null && contact.email!.isNotEmpty)
                          _valueOrPlaceholder(contact.email!),
                      ],
                    ),
                    _ReviewSection(
                      title: AppStrings.sectionIdentity,
                      onEdit: () => context.goNamed(RouteNames.identity),
                      children: [
                        _valueOrPlaceholder(
                          draft.identityRoute == null
                              ? AppStrings.notProvided
                              : _identityLabel(draft.identityRoute!),
                        ),
                      ],
                    ),
                    _ReviewSection(
                      title: AppStrings.sectionSkills,
                      onEdit: () => context.goNamed(RouteNames.skills),
                      children: [
                        _valueOrPlaceholder(skills.occupation, fallback: AppStrings.notProvided),
                        const SizedBox(height: AppSpacing.xs),
                        _valueOrPlaceholder(_educationLabel(skills.educationLevel)),
                      ],
                    ),
                    _ReviewSection(
                      title: AppStrings.sectionLanguages,
                      onEdit: () => context.goNamed(RouteNames.skills),
                      children: [
                        _valueOrPlaceholder(
                          skills.languages.isEmpty
                              ? AppStrings.notProvided
                              : skills.languages.join(', '),
                        ),
                      ],
                    ),
                    _ReviewSection(
                      title: AppStrings.sectionAccessPreferences,
                      onEdit: () => context.goNamed(RouteNames.accessPreferences),
                      children: [
                        for (final item in accessItems)
                          Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                            child: Text(item, style: theme.textTheme.bodyLarge),
                          ),
                      ],
                    ),
                    _ReviewSection(
                      title: AppStrings.sectionSupport,
                      onEdit: () => context.goNamed(RouteNames.support),
                      children: [
                        if (supportItems.isEmpty)
                          _valueOrPlaceholder(AppStrings.notProvided)
                        else
                          for (final item in supportItems)
                            Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                              child: Text(item, style: theme.textTheme.bodyLarge),
                            ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              child: FilledButton(
                onPressed: _saving ? null : _saveProfile,
                child: _saving
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(AppStrings.saveProfile),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletion(BuildContext context, ThemeData theme) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.profileReviewHeading)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.check_circle,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: AppSpacing.lg),
                Semantics(
                  header: true,
                  liveRegion: true,
                  child: Text(
                    AppStrings.profileSavedTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  AppStrings.profileSavedBody,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.xxl),
                FilledButton(
                  onPressed: () => context.pushNamed(RouteNames.jobs),
                  child: const Text(AppStrings.exploreJobs),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _valueOrPlaceholder(String value, {String? fallback}) {
    final theme = Theme.of(context);
    final isEmpty = value.trim().isEmpty;
    final display = isEmpty ? (fallback ?? AppStrings.notProvided) : value;
    final isPlaceholder = isEmpty || value == AppStrings.notProvided;
    return Text(
      display,
      style: isPlaceholder
          ? theme.textTheme.bodyMedium!.copyWith(color: theme.colorScheme.onSurfaceVariant)
          : theme.textTheme.bodyLarge,
    );
  }
}

class _ReviewSection extends StatelessWidget {
  const _ReviewSection({
    required this.title,
    required this.onEdit,
    required this.children,
  });

  final String title;
  final VoidCallback onEdit;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(title, style: theme.textTheme.titleLarge),
                    ),
                  ),
                  Semantics(
                    label: AppStrings.edit,
                    hint: AppStrings.editSectionHint(title),
                    button: true,
                    child: TextButton(
                      onPressed: onEdit,
                      child: Text(AppStrings.edit),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}
