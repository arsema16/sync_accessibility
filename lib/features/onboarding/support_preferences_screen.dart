import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/providers/app_providers.dart';
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

  static const Color _teal = Color(0xFF1B7A6E);

  @override
  void initState() {
    super.initState();
    final support = ref.read(onboardingDraftProvider).privateSupport;
    _writtenInstructions = support?.writtenInstructions ?? false;
    _extraInterviewTime = support?.extraInterviewTime ?? false;
    _remoteInterview = support?.remoteInterview ?? false;
    // Restore new fields from the other field if present
    final other = support?.other ?? '';
    _stepFreeLocation = other.contains('stepFreeLocation');
    _accessibleTransportation = other.contains('accessibleTransportation');
    _otherController = TextEditingController(
      text: _cleanOtherText(other),
    );
  }

  /// Strip the internal tags from the other field for display.
  String _cleanOtherText(String raw) {
    return raw
        .replaceAll('stepFreeLocation', '')
        .replaceAll('accessibleTransportation', '')
        .replaceAll(RegExp(r',\s*,'), ',')
        .replaceAll(RegExp(r'^,\s*'), '')
        .replaceAll(RegExp(r',\s*$'), '')
        .trim();
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
    final extras = <String>[];
    if (_stepFreeLocation) extras.add('stepFreeLocation');
    if (_accessibleTransportation) extras.add('accessibleTransportation');
    final userOther = _otherController.text.trim();
    final allOther = [...extras, if (userOther.isNotEmpty) userOther].join(', ');

    final support = PrivateSupport(
      writtenInstructions: _writtenInstructions,
      extraInterviewTime: _extraInterviewTime,
      remoteInterview: _remoteInterview,
      other: allOther.isEmpty ? null : allOther,
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Color(0xFF1A1A1A)),
          tooltip: AppStrings.goBack,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator at top
            Column(
              children: [
                LinearProgressIndicator(
                  value: 0.60,
                  minHeight: 6,
                  backgroundColor: const Color(0xFFE0E0E0),
                  valueColor: const AlwaysStoppedAnimation<Color>(_teal),
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
                        color: Color(0xFF757575),
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
                      'What support would help you?',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Text(
                      'Select any options that make applying or interviewing easier.',
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF757575),
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
                    onPressed: _skip,
                    child: const Text(AppStrings.skip),
                  ),
                  const Spacer(),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _teal,
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
    );
  }
}
