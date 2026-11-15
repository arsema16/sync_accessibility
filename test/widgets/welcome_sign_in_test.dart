import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sync_accessibility/core/constants/app_strings.dart';
import 'package:sync_accessibility/core/providers/app_providers.dart';
import 'package:sync_accessibility/features/onboarding/sign_in_screen.dart';
import 'package:sync_accessibility/features/onboarding/welcome_screen.dart';
import 'package:sync_accessibility/main.dart';

// The first screen must give returning users an obvious way in: a Sign In
// button (not the old "Accessibility Options" text link that quietly
// pointed at the same route).
void main() {
  testWidgets('the welcome screen offers a sign-in button that opens sign in',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const SyncApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(WelcomeScreen), findsOneWidget);

    final signIn = find.widgetWithText(
      OutlinedButton,
      AppStrings.signInAction,
    );
    expect(signIn, findsOneWidget);
    // The misleading label is gone for good.
    expect(find.text('Accessibility Options'), findsNothing);

    await tester.ensureVisible(signIn);
    await tester.tap(signIn);
    await tester.pumpAndSettle();

    expect(find.byType(SignInScreen), findsOneWidget);
  });
}
