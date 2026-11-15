import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sync_accessibility/core/constants/app_strings.dart';
import 'package:sync_accessibility/core/providers/app_providers.dart';
import 'package:sync_accessibility/features/onboarding/sign_in_screen.dart';
import 'package:sync_accessibility/models/user_model.dart';
import 'package:sync_accessibility/services/auth_service.dart';
import 'package:sync_accessibility/services/service_locator.dart';
import 'package:sync_accessibility/shared/widgets/auth_form.dart';

/// An [AuthService] stub that reproduces the backend quirks the form has to
/// tell apart: a sign-up that opens no session, and a sign-in probe that
/// then explains why (or succeeds).
class _FakeAuth implements AuthService {
  _FakeAuth({this.signUpFailure, this.signInFailure});

  /// Thrown by [signUp] — e.g. "already exists" when auto-confirm is on.
  final AuthFailure? signUpFailure;

  /// Thrown by the [signIn] probe; `null` means sign-in succeeds.
  final AuthFailure? signInFailure;

  static const SyncUser _user = SyncUser(
    id: 'user-fake',
    email: 'person@example.com',
    displayName: 'Person',
  );

  SyncUser? _current;

  @override
  Future<SyncUser> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    if (signUpFailure != null) throw signUpFailure!;
    return _user;
  }

  @override
  Future<SyncUser> signIn({
    required String email,
    required String password,
  }) async {
    if (signInFailure != null) throw signInFailure!;
    _current = _user;
    return _user;
  }

  @override
  Future<void> signOut() async {
    _current = null;
  }

  @override
  SyncUser? get currentUser => _current;

  @override
  Stream<SyncUser?> get authStateChanges async* {
    yield _current;
  }
}

Future<void> pumpForm(
  WidgetTester tester,
  AuthService auth, {
  required List<SyncUser> completed,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[authServiceProvider.overrideWithValue(auth)],
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AuthForm(onCompleted: completed.add),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> fillAndSubmit(
  WidgetTester tester, {
  required String email,
  required bool signUp,
}) async {
  await tester.enterText(find.byType(TextFormField).at(0), email);
  await tester.enterText(find.byType(TextFormField).at(1), 'secret123');
  if (signUp) {
    final toggle = find.widgetWithText(TextButton, AppStrings.switchToSignUp);
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
  }
  final submit = find.widgetWithText(
    FilledButton,
    signUp ? AppStrings.createAccountAction : AppStrings.signInAction,
  );
  await tester.ensureVisible(submit);
  await tester.tap(submit);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
      'creating an account that already exists hands off to sign in',
      (tester) async {
    // The real fallback service: its duplicate sign-up carries the
    // "already exists" code the form keys its hand-off on.
    final auth = ServiceLocator.instance.auth;
    await auth.signOut();
    await auth.signUp(email: 'taken@example.com', password: 'secret123');
    await auth.signOut();

    final completed = <SyncUser>[];
    await pumpForm(tester, auth, completed: completed);

    await fillAndSubmit(tester, email: 'taken@example.com', signUp: true);

    // Back in sign-in mode with the address kept and the password cleared,
    // so only the password is left to type.
    expect(
      find.widgetWithText(FilledButton, AppStrings.signInAction),
      findsOneWidget,
    );
    expect(find.text(AppStrings.accountExistsSignIn), findsOneWidget);
    expect(
      find.widgetWithText(TextFormField, 'taken@example.com'),
      findsOneWidget,
    );
    expect(find.widgetWithText(TextFormField, 'secret123'), findsNothing);
    expect(completed, isEmpty);
  });

  testWidgets('a sign-up that still needs email confirmation says so',
      (tester) async {
    final completed = <SyncUser>[];
    final auth = _FakeAuth(
      signInFailure: const AuthFailure(
        'Email not confirmed',
        code: 'email_not_confirmed',
      ),
    );
    await pumpForm(tester, auth, completed: completed);

    await fillAndSubmit(tester, email: 'person@example.com', signUp: true);

    expect(
      find.text(AppStrings.confirmationSent('person@example.com')),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(FilledButton, AppStrings.signInAction),
      findsOneWidget,
    );
    expect(completed, isEmpty);
  });

  testWidgets(
      'a sign-up over an account with another password points at sign in',
      (tester) async {
    final completed = <SyncUser>[];
    final auth = _FakeAuth(
      signInFailure: const AuthFailure(
        'Email or password is incorrect.',
        code: 'invalid_credentials',
      ),
    );
    await pumpForm(tester, auth, completed: completed);

    await fillAndSubmit(tester, email: 'person@example.com', signUp: true);

    expect(find.text(AppStrings.accountExistsSignIn), findsOneWidget);
    expect(
      find.widgetWithText(FilledButton, AppStrings.signInAction),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(TextFormField, 'person@example.com'),
      findsOneWidget,
    );
    expect(completed, isEmpty);
  });

  testWidgets(
      'a sign-up over an account with the same password signs straight in',
      (tester) async {
    final completed = <SyncUser>[];
    // Sign-up opens no session, but the sign-in probe succeeds: the account
    // is theirs, so they end up signed in either way.
    await pumpForm(tester, _FakeAuth(), completed: completed);

    await fillAndSubmit(tester, email: 'person@example.com', signUp: true);

    expect(completed, hasLength(1));
  });

  testWidgets('a backend "already exists" rejection hands off to sign in',
      (tester) async {
    final completed = <SyncUser>[];
    final auth = _FakeAuth(
      signUpFailure: const AuthFailure(
        'An account with that email already exists.',
        code: 'user_already_exists',
      ),
    );
    await pumpForm(tester, auth, completed: completed);

    await fillAndSubmit(tester, email: 'person@example.com', signUp: true);

    expect(find.text(AppStrings.accountExistsSignIn), findsOneWidget);
    expect(
      find.widgetWithText(FilledButton, AppStrings.signInAction),
      findsOneWidget,
    );
    expect(completed, isEmpty);
  });

  testWidgets('the sign-in screen announces when it runs without Supabase',
      (tester) async {
    // The real fallback service, signed out so the form (and its banner)
    // is on screen — a mis-built APK shows the same notice.
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final auth = ServiceLocator.instance.auth;
    await auth.signOut();

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
          authServiceProvider.overrideWithValue(auth),
        ],
        child: const MaterialApp(home: SignInScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.localAuthModeNotice), findsOneWidget);
    expect(find.byType(AuthForm), findsOneWidget);
  });
}
