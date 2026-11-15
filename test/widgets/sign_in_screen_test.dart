import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sync_accessibility/core/constants/app_strings.dart';
import 'package:sync_accessibility/core/constants/route_names.dart';
import 'package:sync_accessibility/core/providers/app_providers.dart';
import 'package:sync_accessibility/core/router/app_router.dart';
import 'package:sync_accessibility/features/jobs/jobs_screen.dart';
import 'package:sync_accessibility/features/onboarding/sign_in_screen.dart';
import 'package:sync_accessibility/services/service_locator.dart';

Future<void> _pumpSignIn(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final prefs = await SharedPreferences.getInstance();
  final router = GoRouter(
    initialLocation: AppRoutes.signIn,
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
}

Finder _field(int index) => find.byType(TextFormField).at(index);

void main() {
  testWidgets('bad credentials show a typed error instead of failing silently',
      (tester) async {
    await _pumpSignIn(tester);
    expect(find.byType(SignInScreen), findsOneWidget);

    await tester.enterText(_field(0), 'nobody@example.com');
    await tester.enterText(_field(1), 'password');

    final submit = find.widgetWithText(FilledButton, AppStrings.signInAction);
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(find.text('Email or password is incorrect.'), findsOneWidget);
    expect(find.byType(SignInScreen), findsOneWidget);
  });

  testWidgets('creating an account signs in and lands on the job listings',
      (tester) async {
    await _pumpSignIn(tester);

    await tester.enterText(_field(0), 'new.user@example.com');
    await tester.enterText(_field(1), 'secret123');

    final switchToSignUp = find.widgetWithText(
      TextButton,
      AppStrings.switchToSignUp,
    );
    await tester.ensureVisible(switchToSignUp);
    await tester.tap(switchToSignUp);
    await tester.pumpAndSettle();

    final submit = find.widgetWithText(
      FilledButton,
      AppStrings.createAccountAction,
    );
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    // The session exists, so the router moved on to the job listings —
    // which are loaded through the service layer (in-memory in tests).
    expect(find.byType(SignInScreen), findsNothing);
    expect(find.byType(JobsScreen), findsOneWidget);
    expect(find.text('Warehouse assistant'), findsOneWidget);
    expect(find.text(AppStrings.apply), findsWidgets);
  });

  testWidgets('a signed-in user sees their account and can sign out',
      (tester) async {
    // Start from a known signed-in state, independent of earlier tests.
    final auth = ServiceLocator.instance.auth;
    await auth.signOut();
    await auth.signUp(
      email: 'signed.in@example.com',
      password: 'secret123',
      displayName: 'Signed In',
    );

    await _pumpSignIn(tester);

    expect(find.text(AppStrings.signedInAs('signed.in@example.com')),
        findsOneWidget);
    expect(find.widgetWithText(FilledButton, AppStrings.continueToJobs),
        findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);

    final signOut = find.widgetWithText(OutlinedButton, AppStrings.signOut);
    await tester.ensureVisible(signOut);
    await tester.tap(signOut);
    await tester.pumpAndSettle();

    // Signed out: the form is back and the snackbar confirms it.
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text(AppStrings.signedOutMessage), findsOneWidget);

    // Let the snackbar dismissal timer fire so no timer is left pending.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });
}
