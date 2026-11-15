import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/supabase_config.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

/// Maps a Supabase [User] onto the app's [SyncUser].
///
/// Top-level (rather than private) so tests can cover the mapping without a
/// live client.
SyncUser syncUserFromAuthUser(User user) {
  final metadata = user.userMetadata ?? const <String, dynamic>{};
  final displayName = metadata['display_name'] as String? ??
      metadata['full_name'] as String? ??
      user.email;
  return SyncUser(
    id: user.id,
    email: user.email ?? user.phone ?? '',
    displayName: displayName,
    createdAt: DateTime.tryParse(user.createdAt),
  );
}

/// Supabase-backed [AuthService] using `supabase_flutter`'s auth (GoTrue).
///
/// Errors are surfaced as [AuthFailure] with a message that is safe to show
/// directly in the UI.
class SupabaseAuthService implements AuthService {
  SupabaseAuthService({SupabaseClient? client})
      : _client = client ?? SupabaseBootstrap.client;

  final SupabaseClient _client;

  @override
  Future<SyncUser> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: displayName == null || displayName.isEmpty
            ? null
            : <String, dynamic>{'display_name': displayName},
      );
      final user = response.user;
      if (user == null) {
        throw const AuthFailure(
          'Could not create your account. Please try again.',
        );
      }
      return syncUserFromAuthUser(user);
    } on AuthFailure {
      rethrow;
    } on AuthException catch (error) {
      throw AuthFailure(
        _friendlyAuthMessage(error),
        code: error.code ?? error.statusCode,
      );
    } catch (error) {
      debugPrint('Supabase signUp failed: $error');
      throw const AuthFailure(
        'Could not reach SYNC. Check your connection and try again.',
      );
    }
  }

  @override
  Future<SyncUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      final user = response.user;
      if (user == null) {
        throw const AuthFailure('Email or password is incorrect.');
      }
      return syncUserFromAuthUser(user);
    } on AuthFailure {
      rethrow;
    } on AuthException catch (error) {
      throw AuthFailure(
        _friendlyAuthMessage(error),
        code: error.code ?? error.statusCode,
      );
    } catch (error) {
      debugPrint('Supabase signIn failed: $error');
      throw const AuthFailure(
        'Could not reach SYNC. Check your connection and try again.',
      );
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (error) {
      // Signing out must always succeed locally: the session is cleared on
      // the device either way, so a failed server-side revoke is not fatal.
      debugPrint('Supabase signOut warning: $error');
    }
  }

  @override
  SyncUser? get currentUser {
    final user = _client.auth.currentUser;
    return user == null ? null : syncUserFromAuthUser(user);
  }

  @override
  Stream<SyncUser?> get authStateChanges async* {
    // Emit the session that already exists so listeners never wait for the
    // first auth event to render the signed-in state.
    yield currentUser;
    yield* _client.auth.onAuthStateChange.map((state) {
      final user = state.session?.user;
      return user == null ? null : syncUserFromAuthUser(user);
    });
  }

  /// Turns a Supabase [AuthException] into copy a person can act on.
  static String _friendlyAuthMessage(AuthException error) {
    switch (error.code ?? error.statusCode) {
      case 'invalid_credentials':
      case 'invalid_grant':
        return 'Email or password is incorrect.';
      case 'email_not_confirmed':
        return 'Confirm your email address first — open the link in the '
            'SYNC email (look in your spam folder).';
      case 'user_already_exists':
      case 'email_exists':
        return 'An account with that email already exists.';
      case 'weak_password':
        return 'Please choose a password of at least 6 characters.';
      case 'validation_failed':
        return 'Please enter a valid email address and password.';
      case 'over_email_send_rate_limit':
      case 'over_request_rate_limit':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'signup_disabled':
        return 'Creating accounts is currently disabled.';
      default:
        // Supabase messages are already plain English; fall back to them.
        return error.message.isEmpty
            ? 'Something went wrong. Please try again.'
            : error.message;
    }
  }
}
