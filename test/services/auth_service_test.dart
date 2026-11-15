import 'package:flutter_test/flutter_test.dart';

import 'package:sync_accessibility/models/user_model.dart';
import 'package:sync_accessibility/services/auth_service.dart';

void main() {
  group('InMemoryAuthService', () {
    test('signUp creates and signs in a user, normalising the email',
        () async {
      final auth = InMemoryAuthService();

      final user = await auth.signUp(
        email: '  Arsema@Example.COM ',
        password: 'secret1',
        displayName: 'Arsema',
      );

      expect(user.email, 'arsema@example.com');
      expect(user.displayName, 'Arsema');
      expect(auth.currentUser, user);
    });

    test('signUp rejects a duplicate account with AuthFailure', () async {
      final auth = InMemoryAuthService();
      await auth.signUp(email: 'a@example.com', password: 'secret1');
      await auth.signOut();

      await expectLater(
        auth.signUp(email: 'A@example.com', password: 'secret2'),
        throwsA(isA<AuthFailure>()),
      );
      expect(auth.currentUser, isNull);
    });

    test('signUp rejects short passwords', () async {
      final auth = InMemoryAuthService();

      await expectLater(
        auth.signUp(email: 'a@example.com', password: 'abc'),
        throwsA(isA<AuthFailure>()),
      );
      expect(auth.currentUser, isNull);
    });

    test('signIn validates credentials', () async {
      final auth = InMemoryAuthService();
      await auth.signUp(email: 'a@example.com', password: 'secret1');
      await auth.signOut();

      await expectLater(
        auth.signIn(email: 'missing@example.com', password: 'secret1'),
        throwsA(isA<AuthFailure>()),
      );
      await expectLater(
        auth.signIn(email: 'a@example.com', password: 'wrong-pass'),
        throwsA(isA<AuthFailure>()),
      );
      expect(auth.currentUser, isNull);

      final user = await auth.signIn(
        email: 'a@example.com',
        password: 'secret1',
      );
      expect(auth.currentUser, user);
    });

    test('signOut clears the session and is safe to repeat', () async {
      final auth = InMemoryAuthService();
      await auth.signUp(email: 'a@example.com', password: 'secret1');

      await auth.signOut();
      expect(auth.currentUser, isNull);

      await auth.signOut();
      expect(auth.currentUser, isNull);
    });

    test('authStateChanges emits the current user then every change',
        () async {
      final auth = InMemoryAuthService();
      final events = <SyncUser?>[];
      final subscription = auth.authStateChanges.listen(events.add);
      await pumpEventQueue();

      // Immediate replay of the (initially null) session.
      expect(events, <SyncUser?>[null]);

      final user = await auth.signUp(
        email: 'a@example.com',
        password: 'secret1',
      );
      await pumpEventQueue();
      expect(events, <SyncUser?>[null, user]);

      await auth.signOut();
      await pumpEventQueue();
      expect(events, <SyncUser?>[null, user, null]);

      await subscription.cancel();
    });
  });
}
