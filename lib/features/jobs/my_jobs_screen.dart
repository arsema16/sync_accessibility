import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../models/job_application_model.dart';
import '../../../shared/widgets/status_view.dart';

/// The signed-in user's job applications, read from the `job_applications`
/// table. Shows a sign-in prompt when there is no session yet.
class MyJobsScreen extends ConsumerWidget {
  const MyJobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Color(0xFF1A1A1A)),
          tooltip: AppStrings.goBack,
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'My Jobs',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
      ),
      body: SafeArea(child: _buildBody(context, ref, user?.id)),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, String? userId) {
    if (userId == null) {
      return StatusView(
        icon: Icons.lock_outline,
        title: AppStrings.signInToSeeApplications,
        body: AppStrings.myJobsEmptyBody,
        actionLabel: AppStrings.signInAction,
        onAction: () => context.pushNamed(RouteNames.signIn),
      );
    }

    final applicationsAsync = ref.watch(jobApplicationsProvider);
    return applicationsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => StatusView(
        icon: Icons.cloud_off,
        title: AppStrings.jobsLoadFailed,
        actionLabel: AppStrings.tryAgain,
        onAction: () => ref.invalidate(jobApplicationsProvider),
      ),
      data: (applications) {
        if (applications.isEmpty) {
          return const StatusView(
            icon: Icons.bookmark_border,
            title: AppStrings.myJobsEmptyTitle,
            body: AppStrings.myJobsEmptyBody,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          itemCount: applications.length,
          separatorBuilder: (context, index) =>
              const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) =>
              _ApplicationCard(application: applications[index]),
        );
      },
    );
  }
}

class _ApplicationCard extends ConsumerStatefulWidget {
  const _ApplicationCard({required this.application});

  final JobApplication application;

  @override
  ConsumerState<_ApplicationCard> createState() => _ApplicationCardState();
}

class _ApplicationCardState extends ConsumerState<_ApplicationCard> {
  bool _busy = false;

  Future<void> _withdraw() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(jobServiceProvider).removeApplication(
            widget.application.id,
          );
      ref.invalidate(jobApplicationsProvider);
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.applicationWithdrawn)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.applicationFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final application = widget.application;
    final job = application.job;
    final title = job?.title ?? AppStrings.notProvided;
    final subtitle = [
      if (job != null) job.employer,
      if (job != null && job.location != null && job.location!.isNotEmpty)
        job.location!,
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                child: const Icon(Icons.work, color: Colors.white, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF757575),
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    _StatusChip(status: application.status),
                    if (application.coverNote != null &&
                        application.coverNote!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              AppStrings.myAnswerLabel,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              application.coverNote!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _busy ? null : _withdraw,
              child: _busy
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      AppStrings.withdraw,
                      style: TextStyle(color: AppColors.error),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Status label for an application — always text + colour, never colour alone.
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final applied = status == JobApplication.statusApplied;
    final color = applied ? AppColors.success : AppColors.onSurfaceVariant;
    final label = applied ? AppStrings.applied : status;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: applied ? AppColors.successContainer : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            applied ? Icons.check_circle : Icons.schedule,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
