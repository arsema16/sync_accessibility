import 'package:flutter_test/flutter_test.dart';

import 'package:sync_accessibility/models/applicant_profile_model.dart';

void main() {
  group('ApplicantProfile.copyWith', () {
    final withSupport = ApplicantProfile.empty().copyWith(
      privateSupport: const PrivateSupport(
        writtenInstructions: true,
        extraInterviewTime: false,
        remoteInterview: false,
      ),
    );

    test('skipping (passing null explicitly) clears privateSupport', () {
      // This is the bug the copyWith sentinel fixes: previously, null was
      // swallowed by `?? this.privateSupport`, so Skip never cleared the field.
      final skipped = withSupport.copyWith(privateSupport: null);
      expect(skipped.privateSupport, isNull);
    });

    test('omitting privateSupport leaves the existing value unchanged', () {
      // The sentinel must not break the normal "no-change" behaviour.
      final unchanged = withSupport.copyWith(contact: PersonalContact.empty());
      expect(unchanged.privateSupport, equals(withSupport.privateSupport));
    });

    test('setting a new PrivateSupport replaces the existing one', () {
      const replacement = PrivateSupport(
        writtenInstructions: false,
        extraInterviewTime: true,
        remoteInterview: true,
      );
      final updated = withSupport.copyWith(privateSupport: replacement);
      expect(updated.privateSupport, equals(replacement));
    });
  });
}
