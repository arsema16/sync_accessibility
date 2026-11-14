import 'package:flutter_test/flutter_test.dart';

import 'package:sync_accessibility/models/applicant_profile_model.dart';
import 'package:sync_accessibility/services/profile_service.dart';

void main() {
  test('saveProfile persists and returns a profile with id and updatedAt',
      () async {
    final service = InMemoryProfileService();
    final input = ApplicantProfile.empty().copyWith(
      userId: 'u1',
      contact: const PersonalContact(
        fullName: 'Arsema',
        phone: '0912345678',
      ),
    );

    final saved = await service.saveProfile(input);

    expect(saved.id, isNotNull);
    expect(saved.updatedAt, isNotNull);

    final fetched = await service.getProfile('u1');
    expect(fetched, isNotNull);
    expect(fetched!.contact.fullName, 'Arsema');
    expect(fetched.contact.phone, '0912345678');
  });

  test('getProfile returns null when nothing is stored', () async {
    final service = InMemoryProfileService();
    expect(await service.getProfile('unknown'), isNull);
  });

  test('updateProfile replaces an existing profile', () async {
    final service = InMemoryProfileService();
    final first = await service.saveProfile(
      ApplicantProfile.empty().copyWith(userId: 'u2'),
    );
    final updated = await service.updateProfile(
      first.copyWith(contact: const PersonalContact(fullName: 'New', phone: '1')),
    );
    expect(updated.id, first.id);
    expect(updated.contact.fullName, 'New');
    expect((await service.getProfile('u2'))!.contact.fullName, 'New');
  });
}
