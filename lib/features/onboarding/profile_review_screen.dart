import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../models/applicant_profile_model.dart';
import '../../../services/profile_service.dart';
import '../../../shared/widgets/auth_form.dart';

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

List<String> _supportSummary(PrivateSupport? s) {
  if (s == null) {
    return const <String>[];
  }
  final list = <String>[];
  if (s.stepFreeLocation) list.add('Step-free interview location');
  if (s.writtenInstructions) list.add(AppStrings.supportWrittenInstructions);
  if (s.extraInterviewTime) list.add(AppStrings.supportExtraTime);
  if (s.remoteInterview) list.add(AppStrings.supportRemote);
  if (s.accessibleTransportation) list.add('Accessible transportation');
  if (s.other != null && s.other!.isNotEmpty) {
    list.add(s.other!);
  }
  return list;
}

/// Shows everything the user entered, grouped by section, with an Edit link per
/// section. "Save profile" persists via the profile service and shows a
/// completion state. If nobody is signed in yet, an account prompt appears
/// first so the profile has an owner on the backend.
class ProfileReviewScreen extends ConsumerStatefulWidget {
  const ProfileReviewScreen({super.key});

  @override
  ConsumerState<ProfileReviewScreen> createState() =>
      _ProfileReviewScreenState();
}

class _ProfileReviewScreenState extends ConsumerState<ProfileReviewScreen> {
  bool _saving = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    // Read the heading aloud on arrival when read-aloud is on.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final access = ref.read(accessPreferencesNotifierProvider);
      if (access.readAloud) {
        ref.read(readAloudProvider)('Review Your Application');
      }
    });
  }

  Future<void> _saveProfile() async {
    // Resolve the account first (prompting if needed) so the button only
    // shows "saving" while a save is genuinely in flight.
    final auth = ref.read(authServiceProvider);
    var user = auth.currentUser;
    if (user == null) {
      final draftEmail = ref.read(onboardingDraftProvider).contact.email;
      final signedIn = await showAuthPrompt(
        context,
        initialEmail: draftEmail,
        notice: AppStrings.authPromptForSubmit,
      );
      if (!mounted) return;
      user = auth.currentUser;
      if (!signedIn || user == null) {
        // Dismissed, or the account still needs email confirmation.
        return;
      }
    }

    setState(() => _saving = true);

    final draft = ref.read(onboardingDraftProvider);
    final access = ref.read(accessPreferencesNotifierProvider);
    final profile = draft.copyWith(accessPassport: access, userId: user.id);

    try {
      final saved =
          await ref.read(profileServiceProvider).saveProfile(profile);
      if (!mounted) return;
      // Keep the draft aligned with the stored row (id, updatedAt) so a
      // later edit from the Profile screen round-trips cleanly.
      ref.read(onboardingDraftProvider.notifier).replace(saved);
      setState(() {
        _saving = false;
        _saved = true;
      });
    } on ProfileException catch (failure) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.profileSubmitFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_saved) {
      return _buildCompletion(context);
    }

    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final draft = ref.watch(onboardingDraftProvider);
    final contact = draft.contact;
    final skills = draft.skills;
    final support = draft.privateSupport;

    final supportItems = _supportSummary(support);

    return Scaffold(
      backgroundColor: AppColors.pageGradientEnd,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: AppColors.cardInk),
          tooltip: AppStrings.goBack,
          onPressed: () => context.pop(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.pageGradientStart, AppColors.pageGradientEnd],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              // Progress bar: 5 of 5 (100%)
              Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: const LinearProgressIndicator(
                      value: 1.0,
                      minHeight: 6,
                      backgroundColor: AppColors.cardTrack,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.pagePadding,
                      AppSpacing.sm,
                      AppSpacing.pagePadding,
                      AppSpacing.xs,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '5 of 5',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.cardInkMuted,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.pagePadding,
                    vertical: AppSpacing.sm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Review Your Application',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: AppColors.cardInk,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      const Text(
                        'Please check your information before submitting.',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.45,
                          color: AppColors.cardInkMuted,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    _InfoRow(
                      icon: Icons.person,
                      title: AppStrings.sectionName,
                      value: _valueOrPlaceholder(contact.fullName),
                      onEdit: () =>
                          context.pushNamed(RouteNames.contact, extra: true),
                    ),
                    _InfoRow(
                      icon: Icons.email,
                      title: AppStrings.sectionContact,
                      value: _valueOrPlaceholder(
                        [
                          if (contact.phone.isNotEmpty) contact.phone,
                          if (contact.email != null && contact.email!.isNotEmpty)
                            contact.email!,
                        ].join(' · '),
                        fallback: AppStrings.notProvided,
                      ),
                      onEdit: () =>
                          context.pushNamed(RouteNames.contact, extra: true),
                    ),
                    _InfoRow(
                      icon: Icons.work,
                      title: AppStrings.sectionIdentity,
                      value: _valueOrPlaceholder(
                        draft.identityRoute == null
                            ? AppStrings.notProvided
                            : _identityLabel(draft.identityRoute!),
                      ),
                      onEdit: () =>
                          context.pushNamed(RouteNames.identity, extra: true),
                    ),
                    _InfoRow(
                      icon: Icons.build_outlined,
                      title: AppStrings.sectionSkills,
                      value: _valueOrPlaceholder(
                        [
                          if (skills.occupation.isNotEmpty) skills.occupation,
                          _educationLabel(skills.educationLevel),
                          if (skills.keySkills.isNotEmpty)
                            skills.keySkills.join(', '),
                        ].join(' · '),
                      ),
                      onEdit: () =>
                          context.pushNamed(RouteNames.skills, extra: true),
                    ),
                    _InfoRow(
                      icon: Icons.translate,
                      title: AppStrings.sectionLanguages,
                      value: skills.languages.isEmpty
                          ? AppStrings.notProvided
                          : skills.languages.join(', '),
                      onEdit: () =>
                          context.pushNamed(RouteNames.skills, extra: true),
                    ),
                    _InfoRow(
                      icon: Icons.favorite_border,
                      title: AppStrings.sectionSupport,
                      value: supportItems.isEmpty
                          ? AppStrings.notProvided
                          : supportItems.join(', '),
                      onEdit: () =>
                          context.pushNamed(RouteNames.support, extra: true),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadding,
                0,
                AppSpacing.pagePadding,
                AppSpacing.lg,
              ),
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(AppSpacing.minTapTarget),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(50)),
                  ),
                ),
                onPressed: _saving ? null : _saveProfile,
                child: _saving
                    ? Semantics(
                        liveRegion: true,
                        label: AppStrings.saving,
                        child: disableAnimations
                            ? SizedBox(
                                height: 24,
                                width: 24,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                      )
                    : const Text(
                        'Submit Application →',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildCompletion(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageGradientEnd,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.pageGradientStart, AppColors.pageGradientEnd],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.xxl),
                  // Confetti dots + check circle
                  Center(
                    child: SizedBox(
                      width: 180,
                      height: 180,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Scatter colored dots
                          ..._confettiDots(),
                          // Large teal circle with check
                          Container(
                            width: 100,
                            height: 100,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [AppColors.heroStart, AppColors.heroEnd],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: AppColors.onHero,
                              size: 56,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Semantics(
                    header: true,
                    liveRegion: true,
                    child: const Text(
                      'Application Submitted!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: AppColors.cardInk,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    "You'll be notified about the status of your application soon.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.45,
                      color: AppColors.cardInkMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  // Thank-you banner
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.cardAqua,
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.star, color: AppColors.primary, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Thank you for being part of a more inclusive workforce.',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: AppColors.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize:
                          const Size.fromHeight(AppSpacing.minTapTarget),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(50)),
                      ),
                    ),
                    onPressed: () => context.pushNamed(RouteNames.jobs),
                    child: const Text(
                      'Back to Jobs',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _confettiDots() {
    const dots = [
      _DotSpec(dx: -70, dy: -50, color: Colors.amber),
      _DotSpec(dx: 70, dy: -50, color: Colors.pink),
      _DotSpec(dx: -60, dy: 60, color: Colors.blue),
      _DotSpec(dx: 60, dy: 60, color: Colors.green),
      _DotSpec(dx: 0, dy: -75, color: Colors.orange),
      _DotSpec(dx: -80, dy: 0, color: Colors.purple),
      _DotSpec(dx: 80, dy: 0, color: Colors.red),
      _DotSpec(dx: 0, dy: 75, color: Colors.teal),
    ];
    return dots
        .map(
          (d) => Positioned(
            left: 90 + d.dx - 4,
            top: 90 + d.dy - 4,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: d.color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        )
        .toList();
  }

  String _valueOrPlaceholder(String value, {String? fallback}) {
    final isEmpty = value.trim().isEmpty;
    return isEmpty ? (fallback ?? AppStrings.notProvided) : value;
  }
}

@immutable
class _DotSpec {
  const _DotSpec({required this.dx, required this.dy, required this.color});
  final double dx;
  final double dy;
  final Color color;
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onEdit,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.cardBorder, width: 1.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.cardAqua,
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.cardInkMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.cardInk,
                      ),
                    ),
                  ],
                ),
              ),
              Semantics(
                label: AppStrings.edit,
                hint: AppStrings.editSectionHint(title),
                button: true,
                child: TextButton(
                  onPressed: onEdit,
                  child: const Text(
                    AppStrings.edit,
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
