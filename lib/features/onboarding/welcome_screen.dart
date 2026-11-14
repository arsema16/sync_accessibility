import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_spacing.dart';

/// The SYNC entry point. Two primary actions plus a read-aloud helper.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xl),
              Semantics(
                label: AppStrings.appName,
                child: Container(
                  width: 80,
                  height: 80,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.accessibility_new,
                    size: 40,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Semantics(
                header: true,
                child: Text(AppStrings.welcomeHeading, style: theme.textTheme.displayLarge),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(AppStrings.appTagline, style: theme.textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.xl),
              Text(AppStrings.welcomeBody, style: theme.textTheme.bodyLarge),
              const SizedBox(height: AppSpacing.xxl),
              FilledButton(
                onPressed: () {
                  ref.read(onboardingDraftProvider.notifier).reset();
                  context.pushNamed(RouteNames.accessPreferences);
                },
                child: Text(AppStrings.getStarted),
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(
                onPressed: () => context.pushNamed(RouteNames.signIn),
                child: Text(AppStrings.iHaveAnAccount),
              ),
              const SizedBox(height: AppSpacing.lg),
              Semantics(
                label: AppStrings.readAloud,
                hint: AppStrings.readAloudHint,
                button: true,
                child: TextButton.icon(
                  onPressed: () {
                    final readAloud = ref.read(readAloudProvider);
                    readAloud(
                      '${AppStrings.welcomeHeading}. '
                      '${AppStrings.appTagline}. '
                      '${AppStrings.welcomeBody}',
                    );
                  },
                  icon: const Icon(Icons.volume_up),
                  label: Text(AppStrings.readAloud),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
