import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sync_accessibility/core/constants/app_strings.dart';
import 'package:sync_accessibility/core/constants/route_names.dart';
import 'package:sync_accessibility/core/providers/app_providers.dart';
import 'package:sync_accessibility/core/router/app_router.dart';
import 'package:sync_accessibility/features/onboarding/profile_review_screen.dart';
import 'package:sync_accessibility/services/service_locator.dart';
import 'package:sync_accessibility/shared/widgets/auth_form.dart';

void main() {
  testWidgets(
      'submitting while signed out prompts for an account, then completes',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final router = GoRouter(
      initialLocation: AppRoutes.profileReview,
      routes: appRouteList,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ProfileReviewScreen), findsOneWidget);

    // Submit triggers the account prompt instead of failing against RLS.
    final submit = find.widgetWithText(FilledButton, 'Submit Application →');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(find.byType(AuthForm), findsOneWidget);
    expect(find.text(AppStrings.authPromptTitle), findsOneWidget);

    // Create the account from inside the dialog.
    final switchToSignUp = find.widgetWithText(
      TextButton,
      AppStrings.switchToSignUp,
    );
    await tester.ensureVisible(switchToSignUp);
    await tester.tap(switchToSignUp);
    await tester.pumpAndSettle();

    final dialogForm = find.byType(AuthForm);
    await tester.enterText(
      find.descendant(of: dialogForm, matching: find.byType(TextFormField)).first,
      'applicant@example.com',
    );
    await tester.enterText(
      find.descendant(of: dialogForm, matching: find.byType(TextFormField)).at(1),
      'secret123',
    );

    final createAccount = find.descendant(
      of: dialogForm,
      matching: find.widgetWithText(FilledButton, AppStrings.createAccountAction),
    );
    await tester.ensureVisible(createAccount);
    await tester.tap(createAccount);
    await tester.pumpAndSettle();

    // Account created + profile stored: the completion state is shown.
    expect(find.byType(AuthForm), findsNothing);
    expect(find.text('Application Submitted!'), findsOneWidget);

    // The stored profile is attached to the signed-in user.
    final user = ServiceLocator.instance.auth.currentUser;
    expect(user, isNotNull);
    final stored =
        await ServiceLocator.instance.profile.getProfile(user!.id);
    expect(stored, isNotNull);
    expect(stored!.userId, user.id);
  });
}
