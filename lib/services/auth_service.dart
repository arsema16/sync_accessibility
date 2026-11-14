import '../models/user_model.dart';

/// Authentication contract.
///
/// The in-memory implementation below is a local stand-in so the onboarding
/// flow can run end to end without a backend. It is intentionally simple and
/// stores everything in process memory.
abstract class AuthService {
  /// Creates a new account and signs the user in.
  ///
  /// Returns the signed-in user on success, or `null` if the account already
  /// exists (the real backend will surface a typed error instead).
  Future<SyncUser?> signUp({
    required String email,
    required String password,
    String? displayName,
  });

  /// Signs an existing user in.
  ///
  /// Returns the user on success, or `null` if the credentials do not match.
  Future<SyncUser?> signIn({
    required String email,
    required String password,
  });

  /// Signs the current user out, clearing any in-memory session.
  Future<void> signOut();

  /// The currently signed-in user, or `null`.
  SyncUser? get currentUser;
}

/// Local in-memory implementation of [AuthService].
///
// TODO(arsema-tewodros): replace InMemoryAuthService with Supabase implementation.
class InMemoryAuthService implements AuthService {
  final Map<String, _Account> _accountsByEmail = <String, _Account>{};
  SyncUser? _currentUser;
  int _nextId = 0;

  @override
  Future<SyncUser?> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    if (_accountsByEmail.containsKey(email)) {
      return null;
    }
    final user = SyncUser(
      id: 'user-${_nextId++}',
      email: email,
      displayName: displayName,
      createdAt: DateTime.now(),
    );
    _accountsByEmail[email] = _Account(user: user, password: password);
    _currentUser = user;
    return user;
  }

  @override
  Future<SyncUser?> signIn({
    required String email,
    required String password,
  }) async {
    final account = _accountsByEmail[email];
    if (account == null || account.password != password) {
      return null;
    }
    _currentUser = account.user;
    return account.user;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
  }

  @override
  SyncUser? get currentUser => _currentUser;
}

class _Account {
  const _Account({required this.user, required this.password});

  final SyncUser user;
  final String password;
}
