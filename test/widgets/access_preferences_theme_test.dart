import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sync_accessibility/core/providers/app_providers.dart';
import 'package:sync_accessibility/core/theme/app_colors.dart';
import 'package:sync_accessibility/core/theme/app_spacing.dart';
import 'package:sync_accessibility/features/onboarding/welcome_screen.dart';
import 'package:sync_accessibility/main.dart';

// Covers the review finding "Behavioral paths untested" for the larger-text and
// stronger-contrast Access Passport preferences, which are applied app-wide in
// SyncApp (text scaler clamp + high-contrast theme variant).
void main() {
  testWidgets('larger text preference raises the app text scaler',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const SyncApp(),
      ),
    );
    await tester.pumpAndSettle();

    final element = tester.element(find.byType(WelcomeScreen));
    // Default: no scaling applied.
    expect(MediaQuery.of(element).textScaler.scale(14), closeTo(14.0, 0.01));

    ProviderScope.containerOf(element)
        .read(accessPreferencesNotifierProvider.notifier)
        .setLargerText(true);
    await tester.pumpAndSettle();

    // The scaler floor is raised to the large-text scale factor.
    expect(
      MediaQuery.of(element).textScaler.scale(14),
      closeTo(14.0 * AppSpacing.largeTextScale, 0.1),
    );
  });

  testWidgets('stronger contrast preference switches to the high-contrast theme',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const SyncApp(),
      ),
    );
    await tester.pumpAndSettle();

    final element = tester.element(find.byType(WelcomeScreen));
    final surfaceBefore = Theme.of(element).colorScheme.surface;

    ProviderScope.containerOf(element)
        .read(accessPreferencesNotifierProvider.notifier)
        .setStrongerContrast(true);
    await tester.pumpAndSettle();

    final surfaceAfter = Theme.of(element).colorScheme.surface;
    // The active theme surface changed (the theme variant switched).
    expect(surfaceAfter, isNot(surfaceBefore));
    // And it is the high-contrast surface for the current brightness.
    final isLight = Theme.of(element).brightness == Brightness.light;
    expect(
      surfaceAfter,
      isLight ? AppColors.surfaceHighContrast : AppColors.surfaceDarkHighContrast,
    );
  });
}
