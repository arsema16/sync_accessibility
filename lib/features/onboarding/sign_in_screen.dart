import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/auth_form.dart';

/// Email + password sign in / account creation.
///
/// Reached from "I already have an account" on Welcome and from More. When a
/// session already exists the screen shows the account with options to
/// continue or sign out instead of the form.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  bool _signingOut = false;

  @override
  void initState() {
    super.initState();
    // Read the heading aloud on arrival when read-aloud is on.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final access = ref.read(accessPreferencesNotifierProvider);
      if (access.readAloud) {
        ref.read(readAloudProvider)(AppStrings.signInHeading);
      }
    });
  }

  Future<void> _signOut() async {
    setState(() => _signingOut = true);
    await ref.read(authServiceProvider).signOut();
    if (!mounted) return;
    setState(() => _signingOut = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.signedOutMessage)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
          AppStrings.signInHeading,
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
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              AppSpacing.sm,
              AppSpacing.pagePadding,
              AppSpacing.lg,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(36)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadowSoft,
                        blurRadius: 30,
                        offset: Offset(0, 15),
                      ),
                    ],
                  ),
                  child: user == null
                      ? _buildForm(theme)
                      : _buildSignedIn(theme, user.email),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.heroStart, AppColors.heroEnd],
            ),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.lock_outline,
            size: 34,
            color: AppColors.onHero,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Semantics(
          header: true,
          child: Text(
            AppStrings.signInHeading,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: AppColors.cardInk,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          AppStrings.signInSubtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            height: 1.45,
            color: AppColors.cardInkMuted,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        AuthForm(
          onCompleted: (user) {
            // A fresh session goes straight to the job listings; the rest of
            // the app is reachable from the bottom navigation.
            context.goNamed(RouteNames.jobs);
          },
        ),
      ],
    );
  }

  Widget _buildSignedIn(ThemeData theme, String email) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xl),
        Center(
          child: Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.heroStart, AppColors.heroEnd],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              size: 44,
              color: AppColors.onHero,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Semantics(
          header: true,
          child: Text(
            AppStrings.signedInAs(email),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.cardInk,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(AppSpacing.minTapTarget),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(50)),
            ),
          ),
          onPressed: () => context.goNamed(RouteNames.jobs),
          child: const Text(AppStrings.continueToJobs),
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(AppSpacing.minTapTarget),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(50)),
            ),
          ),
          onPressed: _signingOut ? null : _signOut,
          child: _signingOut
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text(AppStrings.signOut),
        ),
      ],
    );
  }
}
