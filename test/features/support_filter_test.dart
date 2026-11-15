import 'package:flutter_test/flutter_test.dart';

import 'package:sync_accessibility/features/jobs/jobs_screen.dart';
import 'package:sync_accessibility/models/applicant_profile_model.dart';
import 'package:sync_accessibility/models/job_model.dart';

void main() {
  group('requiredTagsFor', () {
    test('maps only support flags that have a job-tag equivalent', () {
      const support = PrivateSupport(
        writtenInstructions: true,
        extraInterviewTime: true,
        remoteInterview: false,
        stepFreeLocation: true,
        accessibleTransportation: true,
        other: 'sign language interpreter',
      );

      // Extra interview time / transport / free-text "other" have no listing
      // tag, so they must not be faked into the match.
      expect(
        requiredTagsFor(support),
        <String>['step-free', 'written'],
      );
    });

    test('returns an empty list when nothing maps', () {
      const support = PrivateSupport(
        writtenInstructions: false,
        extraInterviewTime: true,
        remoteInterview: false,
      );

      expect(requiredTagsFor(support), isEmpty);
    });
  });

  group('jobMatchesSupport', () {
    const stepFreeJob = Job(
      id: 'j1',
      title: 'Warehouse assistant',
      employer: 'Sunrise Logistics',
      tags: <String>['Step-free Access', 'Flexible Hours'],
    );
    const remoteJob = Job(
      id: 'j2',
      title: 'Data entry clerk',
      employer: 'FinServe Group',
      tags: <String>['Remote OK', 'Written Instructions'],
    );

    test('matches a single requirement case-insensitively', () {
      expect(jobMatchesSupport(stepFreeJob, <String>['step-free']), isTrue);
      expect(jobMatchesSupport(remoteJob, <String>['step-free']), isFalse);
    });

    test('requires every listed accommodation', () {
      expect(
        jobMatchesSupport(remoteJob, <String>['written', 'remote']),
        isTrue,
      );
      expect(
        jobMatchesSupport(remoteJob, <String>['written', 'step-free']),
        isFalse,
      );
    });

    test('a job with no tags never matches a real requirement', () {
      const bare = Job(id: 'j3', title: 'Farm worker', employer: 'Green Valley');
      expect(jobMatchesSupport(bare, <String>['remote']), isFalse);
    });
  });
}
