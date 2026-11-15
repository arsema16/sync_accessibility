import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../models/applicant_profile_model.dart';
import '../../../models/job_application_model.dart';
import '../../../models/job_model.dart';
import '../../../shared/widgets/auth_form.dart';
import '../../../shared/widgets/status_view.dart';
import '../../../shared/widgets/sync_bottom_nav.dart';

/// Job listings screen with teal header, search, filters, and job cards.
///
/// Listings come from the `jobs` table through [jobsProvider]; applying for a
/// job opens the voice-answer flow ([ApplyJobScreen] via [RouteNames.applyJob])
/// and writes a row to `job_applications` (sign-in is prompted on demand).
///
/// The "My support" filter matches the user's *private* support preferences
/// against job accommodations entirely on-device — the preference payload is
/// never sent anywhere for matching.
class JobsScreen extends ConsumerStatefulWidget {
  const JobsScreen({super.key});

  @override
  ConsumerState<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends ConsumerState<JobsScreen> {
  int _selectedFilter = 0;
  String _query = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  static const _filters = [
    'All',
    'Remote',
    'Step-free',
    'With Support',
    AppStrings.filterMySupport,
  ];

  /// Index of the private support-needs filter in [_filters].
  static const _supportFilterIndex = 4;

  /// The hero "accessibility tip" card. [tipSpoken] is what the read-aloud
  /// button announces — it matches the visible copy word for word.
  static const String tipTitle = 'Apply with your voice';
  static const String tipBody = 'Speak your answers instead of typing.';
  static const String tipSpoken =
      'Accessibility tip. Apply with your voice. '
      'Speak your answers instead of typing. '
      'Tap the mic on any question.';

  @override
  void initState() {
    super.initState();
    // Read the screen heading aloud on arrival when read-aloud is on.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final access = ref.read(accessPreferencesNotifierProvider);
      if (access.readAloud) {
        ref.read(readAloudProvider)(
          'Good morning! Discover jobs that fit your needs.',
        );
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  bool _matchesFilter(Job job) {
    bool hasTag(String needle) =>
        job.tags.any((tag) => tag.toLowerCase().contains(needle));
    switch (_selectedFilter) {
      case 1:
        return hasTag('remote');
      case 2:
        return hasTag('step-free');
      case 3:
        return hasTag('support');
      default:
        return true;
    }
  }

  bool _matchesSupport(Job job, List<String> requiredTags) =>
      jobMatchesSupport(job, requiredTags);

  bool _matchesQuery(Job job) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return true;
    return job.title.toLowerCase().contains(query) ||
        job.employer.toLowerCase().contains(query) ||
        (job.location?.toLowerCase().contains(query) ?? false) ||
        job.tags.any((tag) => tag.toLowerCase().contains(query));
  }

  /// Ensures a session exists (prompting sign-in if not) and returns the user
  /// id, or `null` when the user is not ready to apply.
  Future<String?> _ensureSignedIn(String jobTitle) async {
    final auth = ref.read(authServiceProvider);
    var user = auth.currentUser;
    if (user == null) {
      final signedIn = await showAuthPrompt(
        context,
        notice: AppStrings.signInToApply(jobTitle),
      );
      if (!mounted || !signedIn) return null;
      user = auth.currentUser;
      // Null when the account still needs email confirmation.
      if (user == null) return null;
    }
    return user.id;
  }

  Future<void> _apply(Job job) async {
    final userId = await _ensureSignedIn(job.title);
    if (userId == null || !mounted) return;
    // The apply screen collects the voice answers, then submits with them.
    context.pushNamed(RouteNames.applyJob, extra: job);
  }

  @override
  Widget build(BuildContext context) {
    final jobsAsync = ref.watch(jobsProvider);
    final applications =
        ref.watch(jobApplicationsProvider).valueOrNull ?? const <JobApplication>[];
    final appliedJobIds = <String>{
      for (final application in applications) application.jobId,
    };
    final user = ref.watch(currentUserProvider);
    // The private support filter needs the saved profile; only fetch it when
    // that filter is on so the common path stays a single query.
    final supportFilterOn = _selectedFilter == _supportFilterIndex;
    final profileAsync = supportFilterOn && user != null
        ? ref.watch(savedProfileProvider(user.id))
        : null;

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
        child: Column(
          children: [
            // Greeting header (no AppBar)
            _buildHeader(),
            // Hero accessibility tip with a built-in read-aloud action
            _buildTipCard(),
            // Search bar
            _buildSearchBar(),
            // Filter chips
            _buildFilterRow(),
            // Job cards list (or the support-filter guidance states)
            Expanded(
              child: supportFilterOn
                  ? _buildSupportFilterBody(
                      context,
                      jobsAsync,
                      profileAsync,
                      user != null,
                    )
                  : _buildJobsBody(jobsAsync, appliedJobIds),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const SyncBottomNav(currentIndex: 0),
    );
  }

  /// Standard listings + search + tag filters.
  Widget _buildJobsBody(
    AsyncValue<List<Job>> jobsAsync,
    Set<String> appliedJobIds,
  ) {
    return jobsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stackTrace) => StatusView(
        icon: Icons.cloud_off,
        title: AppStrings.jobsLoadFailed,
        actionLabel: AppStrings.tryAgain,
        onAction: () => ref.invalidate(jobsProvider),
      ),
      data: (jobs) {
        final visible = jobs
            .where((job) => _matchesFilter(job) && _matchesQuery(job))
            .toList();
        if (visible.isEmpty) {
          return StatusView(
            icon: Icons.search_off,
            title: AppStrings.jobsEmptyTitle,
            body: AppStrings.jobsEmptyBody,
            actionLabel: AppStrings.tryAgain,
            onAction: () {
              setState(() {
                _selectedFilter = 0;
                _query = '';
                _searchController.clear();
              });
            },
          );
        }
        return _JobListView(
          jobs: visible,
          appliedJobIds: appliedJobIds,
          onApply: _apply,
        );
      },
    );
  }

  /// The private "support I need" filter: guides the user when no profile or
  /// preferences are available, otherwise matches jobs on-device.
  Widget _buildSupportFilterBody(
    BuildContext context,
    AsyncValue<List<Job>> jobsAsync,
    AsyncValue<ApplicantProfile?>? profileAsync,
    bool signedIn,
  ) {
    if (!signedIn) {
      return StatusView(
        icon: Icons.lock_outline,
        title: AppStrings.supportFilterUnavailableTitle,
        body: AppStrings.supportFilterUnavailableBody,
        actionLabel: AppStrings.signInAction,
        onAction: () => context.pushNamed(RouteNames.signIn),
      );
    }
    return profileAsync!.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stackTrace) => StatusView(
        icon: Icons.cloud_off,
        title: AppStrings.profileLoadFailed,
        actionLabel: AppStrings.tryAgain,
        onAction: () => ref.invalidate(
          savedProfileProvider(ref.read(currentUserProvider)!.id),
        ),
      ),
      data: (profile) {
        final support = profile?.privateSupport;
        if (support == null) {
          return StatusView(
            icon: Icons.lock_outline,
            title: AppStrings.supportFilterNoPrefsTitle,
            body: AppStrings.supportFilterNoPrefsBody,
            actionLabel: AppStrings.supportFilterEditPrefs,
            onAction: () => context.pushNamed(
              RouteNames.support,
              extra: true, // editMode: returns here after saving
            ),
          );
        }
        final requiredTags = requiredTagsFor(support);        return jobsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stackTrace) => StatusView(
            icon: Icons.cloud_off,
            title: AppStrings.jobsLoadFailed,
            actionLabel: AppStrings.tryAgain,
            onAction: () => ref.invalidate(jobsProvider),
          ),
          data: (jobs) {
            final visible = jobs
                .where(
                  (job) =>
                      _matchesSupport(job, requiredTags) && _matchesQuery(job),
                )
                .toList();
            if (visible.isEmpty) {
              return StatusView(
                icon: Icons.search_off,
                title: AppStrings.supportFilterEmptyTitle,
                body: AppStrings.supportFilterEmptyBody,
                actionLabel: AppStrings.tryAgain,
                onAction: () {
                  setState(() {
                    _selectedFilter = 0;
                    _query = '';
                    _searchController.clear();
                  });
                },
              );
            }
            final applications = ref.watch(jobApplicationsProvider).valueOrNull ??
                const <JobApplication>[];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.pagePadding,
                    AppSpacing.xs,
                    AppSpacing.pagePadding,
                    0,
                  ),
                  child: Text(
                    AppStrings.supportFilterMatchedHint,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.cardInkMuted,
                    ),
                  ),
                ),
                Expanded(
                  child: _JobListView(
                    jobs: visible,
                    appliedJobIds: {
                      for (final application in applications)
                        application.jobId,
                    },
                    onApply: _apply,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Greeting header: SYNC monogram, greeting copy and a search shortcut —
  /// the same rhythm as the app's reference design, in SYNC teal.
  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + AppSpacing.md,
        left: AppSpacing.pagePadding,
        right: AppSpacing.pagePadding,
        bottom: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.heroStart, AppColors.heroEnd],
              ),
              border: Border.fromBorderSide(BorderSide(color: Colors.white, width: 2)),
            ),
            child: const Text(
              'S',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.onHero,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good morning!',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: AppColors.cardInk,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Discover jobs that fit your needs.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.cardInkMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Round search shortcut that jumps into the search field below.
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.cardBorder, width: 1.2),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              tooltip: AppStrings.jobsSearchHint,
              onPressed: () => FocusScope.of(context).requestFocus(
                _searchFocusNode,
              ),
              icon: const Icon(
                Icons.search_rounded,
                size: 22,
                color: AppColors.cardInk,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Hero card: a rotating accessibility tip with read-aloud built in.
  Widget _buildTipCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.xs,
        AppSpacing.pagePadding,
        AppSpacing.sm,
      ),
      child: Container(
        // Sized by its content so the card grows with the user's text scale
        // instead of clipping (the app clamps scaling at 1.3x).
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(28)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.heroStart, AppColors.heroEnd],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowHero,
              blurRadius: 22,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(right: -16, top: -20, child: _buildTipShapes()),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xB3FFFFFF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Accessibility tip',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onHero,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        tipTitle,
                        style: TextStyle(
                          fontSize: 22,
                          height: 1.1,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: AppColors.onHero,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        tipBody,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.onHero,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.onHero,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      minimumSize: const Size(0, 40),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(50)),
                      ),
                    ),
                    onPressed: () =>
                        ref.read(readAloudProvider)(tipSpoken),
                    icon: const Icon(Icons.volume_up, size: 18),
                    label: const Text(
                      AppStrings.readAloud,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
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

  /// Decorative teal shapes echoing the reference card artwork. They are
  /// purely ornamental, so they carry no semantics of their own.
  Widget _buildTipShapes() {
    return SizedBox(
      width: 132,
      height: 156,
      child: Stack(
        children: [
          Positioned(
            top: 8,
            right: 22,
            child: Transform.rotate(
              angle: 0.45,
              child: Container(
                width: 44,
                height: 62,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(22)),
                  gradient: LinearGradient(
                    colors: [AppColors.cardDeep, Color(0xFF0A4A43)],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 46,
            right: 66,
            child: Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: Color(0xE6FFFFFF),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 14,
            right: 12,
            child: Container(
              width: 52,
              height: 44,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(18)),
                gradient: LinearGradient(
                  colors: [AppColors.cardAqua, Color(0xFF9ED9CE)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.md,
        AppSpacing.pagePadding,
        AppSpacing.sm,
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        onChanged: (value) => setState(() => _query = value),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: AppStrings.jobsSearchHint,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                  icon: const Icon(Icons.close),
                ),
          fillColor: Colors.white,
          filled: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50),
            borderSide: const BorderSide(color: AppColors.cardBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50),
            borderSide: const BorderSide(color: AppColors.cardBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pagePadding,
          vertical: AppSpacing.sm,
        ),
        itemCount: _filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final selected = _selectedFilter == index;
          return Semantics(
            button: true,
            selected: selected,
            label: _filters[index],
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: selected ? AppColors.navBar : Colors.white,
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: selected
                        ? AppColors.navBar
                        : AppColors.cardBorder,
                    width: 1.2,
                  ),
                ),
                child: Text(
                  _filters[index],
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.cardInk,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A scrollable list of [JobCard]s shared by the standard and support-filter
/// views.
class _JobListView extends StatelessWidget {
  const _JobListView({
    required this.jobs,
    required this.appliedJobIds,
    required this.onApply,
  });

  final List<Job> jobs;
  final Set<String> appliedJobIds;
  final ValueChanged<Job> onApply;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pagePadding,
        vertical: AppSpacing.sm,
      ),
      itemCount: jobs.length,
      itemBuilder: (context, index) {
        final job = jobs[index];
        return _JobCard(
          job: job,
          applied: appliedJobIds.contains(job.id),
          onApply: () => onApply(job),
        );
      },
    );
  }
}

/// A single job listing with tag chips and an Apply action.
class _JobCard extends StatelessWidget {
  const _JobCard({
    required this.job,
    required this.applied,
    required this.onApply,
  });

  final Job job;
  final bool applied;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: teal rounded-square icon
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                ),
                child: const Icon(Icons.work, color: Colors.white, size: 24),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15.5,
                        color: AppColors.cardInk,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [
                        job.employer,
                        if (job.location != null &&
                            job.location!.isNotEmpty)
                          job.location!,
                      ].join(' · '),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.cardInkMuted,
                      ),
                    ),
                    if (job.tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children:
                            job.tags.map((tag) => _TagChip(label: tag)).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (applied)
                const _AppliedBadge()
              else
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(112, AppSpacing.minTapTarget),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(50)),
                    ),
                  ),
                  onPressed: onApply,
                  child: const Text(AppStrings.apply),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Confirmation that an application already exists for this job.
class _AppliedBadge extends StatelessWidget {
  const _AppliedBadge();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: AppStrings.applied,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.successContainer,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: AppColors.success),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 18),
            SizedBox(width: 6),
            Text(
              AppStrings.applied,
              style: TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: const BoxDecoration(
        color: AppColors.cardAqua,
        borderRadius: BorderRadius.all(Radius.circular(50)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Maps the user's private support preferences onto job accommodation tags.
///
/// Only flags with a real job-tag equivalent are included; preferences with
/// no listing-side representation (extra interview time, transport, other)
/// are deliberately not matched rather than faked. Matching runs on-device —
/// the preferences themselves never leave the phone for this.
List<String> requiredTagsFor(PrivateSupport support) => <String>[
      if (support.stepFreeLocation) 'step-free',
      if (support.writtenInstructions) 'written',
      if (support.remoteInterview) 'remote',
    ];

/// Whether [job] offers every accommodation in [requiredTags] (tag matching is
/// case-insensitive substring, e.g. `written` matches `Written Instructions`).
bool jobMatchesSupport(Job job, List<String> requiredTags) {
  final tags =
      job.tags.map((tag) => tag.toLowerCase()).toList(growable: false);
  return requiredTags.every(
    (needle) => tags.any((tag) => tag.contains(needle)),
  );
}
