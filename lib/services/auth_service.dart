import 'dart:async';

import '../models/user_model.dart';

/// Authentication contract.
///
/// The Supabase implementation (`SupabaseAuthService`) is the production
/// backend; `InMemoryAuthService` remains as a local fallback so the app and
/// the test suite keep working when no Supabase credentials are supplied.
abstract class AuthService {
  /// Creates a new account and signs the user in.
  ///
  /// Throws [AuthFailure] when the account cannot be created (for example the
  /// email is already registered or the password is too weak).
  ///
  /// If the Supabase project requires email confirmation the account is
  /// created but no session is opened yet — check [currentUser] afterwards to
  /// tell the two outcomes apart.
  Future<SyncUser> signUp({
    required String email,
    required String password,
    String? displayName,
  });

  /// Signs an existing user in.
  ///
  /// Throws [AuthFailure] when the credentials do not match or the account
  /// still needs email confirmation.
  Future<SyncUser> signIn({
    required String email,
    required String password,
  });

  /// Signs the current user out. Safe to call when nobody is signed in.
  Future<void> signOut();

  /// The currently signed-in user, or `null`.
  SyncUser? get currentUser;

  /// Emits the current user immediately, then every sign-in / sign-out.
  ///
  /// Used by the riverpod `authStateChangesProvider` so the UI rebuilds when
  /// the session changes.
  Stream<SyncUser?> get authStateChanges;
}

/// A typed authentication failure with a message safe to show to the user.
class AuthFailure implements Exception {
  const AuthFailure(this.message, {this.code});

  /// Human-readable reason, already suitable for display.
  final String message;

  /// Optional backend error code (e.g. an HTTP status or Supabase code).
  final String? code;

  @override
  String toString() => message;
}

/// Local in-memory implementation of [AuthService].
///
/// Used when Supabase is not configured (unit tests, `flutter analyze`, or a
/// first run without `config.json`). Behaviour mirrors the Supabase service:
/// duplicate sign-ups and bad credentials throw [AuthFailure], and
/// [authStateChanges] emits on every change.
class InMemoryAuthService implements AuthService {
  final Map<String, _Account> _accountsByEmail = <String, _Account>{};
  final StreamController<SyncUser?> _changes =
      StreamController<SyncUser?>.broadcast();
  SyncUser? _currentUser;
  int _nextId = 0;

  @override
  Future<SyncUser> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final key = _normalise(email);
    if (_accountsByEmail.containsKey(key)) {
      throw const AuthFailure('An account with that email already exists.');
    }
    if (password.length < 6) {
      throw const AuthFailure(
        'Please choose a password of at least 6 characters.',
      );
    }
    final user = SyncUser(
      id: 'user-${_nextId++}',
      email: key,
      displayName: displayName,
      createdAt: DateTime.now(),
    );
    _accountsByEmail[key] = _Account(user: user, password: password);
    _setCurrentUser(user);
    return user;
  }

  @override
  Future<SyncUser> signIn({
    required String email,
    required String password,
  }) async {
    final account = _accountsByEmail[_normalise(email)];
    if (account == null || account.password != password) {
      throw const AuthFailure('Email or password is incorrect.');
    }
    _setCurrentUser(account.user);
    return account.user;
  }

  @override
  Future<void> signOut() async {
    _setCurrentUser(null);
  }

  @override
  SyncUser? get currentUser => _currentUser;

  @override
  Stream<SyncUser?> get authStateChanges async* {
    yield _currentUser;
    yield* _changes.stream;
  }

  void _setCurrentUser(SyncUser? user) {
    _currentUser = user;
    if (!_changes.isClosed) {
      _changes.add(user);
    }
  }

  static String _normalise(String email) => email.trim().toLowerCase();

  /// Releases the broadcast controller — only needed by long-lived tests.
  void dispose() {
    _changes.close();
  }
}

class _Account {
  const _Account({required this.user, required this.password});

  final SyncUser user;
  final String password;
}
