import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/sync_bottom_nav.dart';

/// "More" screen — account, settings, accessibility options, sign out.
///
/// The account tile reflects the live session from [currentUserProvider] and
/// swaps between Sign In and Sign Out.
class MoreScreen extends ConsumerStatefulWidget {
  const MoreScreen({super.key});

  @override
  ConsumerState<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends ConsumerState<MoreScreen> {
  @override
  void initState() {
    super.initState();
    // Read the screen heading aloud on arrival when read-aloud is on.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final access = ref.read(accessPreferencesNotifierProvider);
      if (access.readAloud) {
        ref.read(readAloudProvider)('More');
      }
    });
  }

  Future<void> _signOut() async {
    await ref.read(authServiceProvider).signOut();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.signedOutMessage)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

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
        title: const Text(
          'More',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: AppColors.cardInk,
          ),
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
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pagePadding,
            AppSpacing.sm,
            AppSpacing.pagePadding,
            AppSpacing.lg,
          ),
          children: [
            if (user != null) _AccountTile(email: user.email),
            if (user == null)
              _MoreTile(
                icon: Icons.login,
                label: AppStrings.signInHeading,
                subtitle: AppStrings.notSignedIn,
                onTap: () => context.pushNamed(RouteNames.signIn),
              )
            else
              _MoreTile(
                icon: Icons.logout,
                label: AppStrings.signOut,
                onTap: () => _signOut(),
              ),
            _MoreTile(
              icon: Icons.tune,
              label: 'Accessibility Settings',
              onTap: () => context.pushNamed(
                RouteNames.accessPreferences,
                extra: true, // editMode
              ),
            ),
            _MoreTile(
              icon: Icons.person_outline,
              label: 'My Profile',
              onTap: () => context.pushNamed(RouteNames.profile),
            ),
            _MoreTile(
              icon: Icons.business_center_outlined,
              label: AppStrings.employerJobsTitle,
              subtitle: 'Post jobs and manage your listings',
              onTap: () => context.pushNamed(RouteNames.employerJobs),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const SyncBottomNav(currentIndex: 3),
    );
  }
}

/// Read-only row showing which account is signed in.
class _AccountTile extends StatelessWidget {
  const _AccountTile({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
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
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.cardAqua,
              borderRadius: BorderRadius.all(Radius.circular(14)),
            ),
            child: const Icon(
              Icons.account_circle_outlined,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Account',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.cardInkMuted,
                  ),
                ),
                Text(
                  email.isEmpty ? AppStrings.notSignedIn : email,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.cardInk,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.lg,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.cardAqua,
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.cardInk,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.cardInkMuted,
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.cardInkMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
