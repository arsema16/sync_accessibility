import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../models/applicant_profile_model.dart';
import '../../../shared/widgets/sync_info_banner.dart';
import '../../../shared/widgets/sync_option_card.dart';

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
  late bool _stepFreeLocation;
  late bool _accessibleTransportation;
  late final TextEditingController _otherController;

  @override
  void initState() {
    super.initState();
    final support = ref.read(onboardingDraftProvider).privateSupport;
    _writtenInstructions = support?.writtenInstructions ?? false;
    _extraInterviewTime = support?.extraInterviewTime ?? false;
    _remoteInterview = support?.remoteInterview ?? false;
    _stepFreeLocation = support?.stepFreeLocation ?? false;
    _accessibleTransportation = support?.accessibleTransportation ?? false;
    _otherController = TextEditingController(text: support?.other ?? '');

    // Read the step heading aloud on arrival when read-aloud is on.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final access = ref.read(accessPreferencesNotifierProvider);
      if (access.readAloud) {
        ref.read(readAloudProvider)(
          access.simplerWording
              ? AppStrings.supportHeadingSimple
              : 'What support would you like?',
        );
      }
    });
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
    final userOther = _otherController.text.trim();
    final support = PrivateSupport(
      writtenInstructions: _writtenInstructions,
      extraInterviewTime: _extraInterviewTime,
      remoteInterview: _remoteInterview,
      stepFreeLocation: _stepFreeLocation,
      accessibleTransportation: _accessibleTransportation,
      other: userOther.isEmpty ? null : userOther,
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
    final simpler = ref.watch(accessPreferencesNotifierProvider).simplerWording;
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
              // Progress indicator at top
              Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: const LinearProgressIndicator(
                      value: 0.60,
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
                        '3 of 5',
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
                      Text(
                        simpler
                            ? AppStrings.supportHeadingSimple
                            : 'What support would you like?',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: AppColors.cardInk,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        simpler
                            ? AppStrings.supportSubtitleSimple
                            : AppStrings.supportSubtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.45,
                          color: AppColors.cardInkMuted,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    SyncOptionCard(
                      icon: Icons.accessible_forward,
                      label: 'Step-free interview location',
                      description: 'Venue accessible without stairs',
                      selected: _stepFreeLocation,
                      multi: true,
                      onTap: () => setState(
                        () => _stepFreeLocation = !_stepFreeLocation,
                      ),
                    ),
                    SyncOptionCard(
                      icon: Icons.timer_outlined,
                      label: 'Extra time for assessments',
                      description: AppStrings.supportExtraTime,
                      selected: _extraInterviewTime,
                      multi: true,
                      onTap: () => setState(
                        () => _extraInterviewTime = !_extraInterviewTime,
                      ),
                    ),
                    SyncOptionCard(
                      icon: Icons.videocam_outlined,
                      label: 'Remote interview',
                      description: AppStrings.supportRemote,
                      selected: _remoteInterview,
                      multi: true,
                      onTap: () => setState(
                        () => _remoteInterview = !_remoteInterview,
                      ),
                    ),
                    SyncOptionCard(
                      icon: Icons.description_outlined,
                      label: 'Written instructions',
                      description: AppStrings.supportWrittenInstructions,
                      selected: _writtenInstructions,
                      multi: true,
                      onTap: () => setState(
                        () => _writtenInstructions = !_writtenInstructions,
                      ),
                    ),
                    SyncOptionCard(
                      icon: Icons.directions_bus_outlined,
                      label: 'Accessible transportation',
                      description: 'Transport assistance to reach the venue',
                      selected: _accessibleTransportation,
                      multi: true,
                      onTap: () => setState(
                        () => _accessibleTransportation = !_accessibleTransportation,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const SyncInfoBanner(
                      icon: Icons.lock_outline,
                      message:
                          'Your preferences stay private and are not shared with employers.',
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              child: Row(
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(80, AppSpacing.minTapTarget),
                    ),
                    onPressed: _skip,
                    child: const Text(AppStrings.skip),
                  ),
                  const Spacer(),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(120, AppSpacing.minTapTarget),
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(50)),
                      ),
                    ),
                    onPressed: _save,
                    child: const Text(
                      'Continue →',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
