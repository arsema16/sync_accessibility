import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../models/job_model.dart';
import '../../../shared/widgets/status_view.dart';

/// The signed-in employer's own job postings.
///
/// Reads `jobs` rows where `employer_id` matches the session user (RLS
/// guarantees they can only ever see/edit their own) and offers create, edit
/// and delete through [EmployerJobFormScreen].
class EmployerJobsScreen extends ConsumerWidget {
  const EmployerJobsScreen({super.key});

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Job job,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.employerJobDelete),
        content: const Text(AppStrings.employerJobDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              AppStrings.employerJobDelete,
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(jobServiceProvider).deleteJob(job.id);
      ref.invalidate(employerJobsProvider);
      ref.invalidate(jobsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.employerJobDeleted)),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.employerJobSaveFailed)),
      );
    }
  }

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
          AppStrings.employerJobsTitle,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
      ),
      floatingActionButton: user == null
          ? null
          : FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              onPressed: () => context.pushNamed(RouteNames.employerJobForm),
              icon: const Icon(Icons.add),
              label: const Text(AppStrings.employerPostJob),
            ),
      body: SafeArea(child: _buildBody(context, ref, user?.id)),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, String? userId) {
    if (userId == null) {
      return StatusView(
        icon: Icons.business_center_outlined,
        title: AppStrings.employerSignInTitle,
        body: AppStrings.employerSignInBody,
        actionLabel: AppStrings.signInAction,
        onAction: () => context.pushNamed(RouteNames.signIn),
      );
    }

    final jobsAsync = ref.watch(employerJobsProvider);
    return jobsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => StatusView(
        icon: Icons.cloud_off,
        title: AppStrings.jobsLoadFailed,
        actionLabel: AppStrings.tryAgain,
        onAction: () => ref.invalidate(employerJobsProvider),
      ),
      data: (jobs) {
        if (jobs.isEmpty) {
          return StatusView(
            icon: Icons.business_center_outlined,
            title: AppStrings.employerJobsEmptyTitle,
            body: AppStrings.employerJobsEmptyBody,
            actionLabel: AppStrings.employerPostJob,
            onAction: () => context.pushNamed(RouteNames.employerJobForm),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pagePadding,
            AppSpacing.sm,
            AppSpacing.pagePadding,
            88, // clearance for the FAB
          ),
          itemCount: jobs.length,
          separatorBuilder: (context, index) =>
              const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) => _EmployerJobCard(
            job: jobs[index],
            onEdit: () => context.pushNamed(
              RouteNames.employerJobForm,
              extra: jobs[index],
            ),
            onDelete: () => _confirmDelete(context, ref, jobs[index]),
          ),
        );
      },
    );
  }
}

class _EmployerJobCard extends StatelessWidget {
  const _EmployerJobCard({
    required this.job,
    required this.onEdit,
    required this.onDelete,
  });

  final Job job;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
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
                      job.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    if (job.location != null && job.location!.isNotEmpty)
                      Text(
                        job.location!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF757575),
                        ),
                      ),
                  ],
                ),
              ),
              // Status: icon + text, never colour alone.
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: job.isActive
                      ? AppColors.successContainer
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      job.isActive ? Icons.check_circle : Icons.pause_circle,
                      size: 14,
                      color: job.isActive
                          ? AppColors.success
                          : AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      job.isActive ? 'Live' : 'Hidden',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: job.isActive
                            ? AppColors.success
                            : AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (job.tags.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: job.tags
                  .map(
                    (tag) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(color: AppColors.primary),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: onEdit,
                child: const Text(AppStrings.edit),
              ),
              TextButton(
                onPressed: onDelete,
                child: const Text(
                  AppStrings.employerJobDelete,
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
