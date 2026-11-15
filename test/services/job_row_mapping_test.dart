import 'package:flutter_test/flutter_test.dart';

import 'package:sync_accessibility/models/job_application_model.dart';
import 'package:sync_accessibility/services/supabase_job_service.dart';

void main() {
  group('jobFromRow', () {
    test('maps a full jobs row', () {
      final job = jobFromRow(<String, dynamic>{
        'id': 'j1',
        'title': 'Warehouse assistant',
        'employer': 'Sunrise Logistics',
        'location': 'Addis Ababa',
        'description': 'Packing and loading.',
        'posted_at': '2026-01-05T08:00:00.000Z',
        'tags': <String>['Step-free Access', 'Flexible Hours'],
        'is_active': true,
      });

      expect(job.id, 'j1');
      expect(job.title, 'Warehouse assistant');
      expect(job.employer, 'Sunrise Logistics');
      expect(job.employerId, isNull);
      expect(job.location, 'Addis Ababa');
      expect(job.description, 'Packing and loading.');
      expect(job.postedAt, isNotNull);
      expect(job.tags, <String>['Step-free Access', 'Flexible Hours']);
      expect(job.isActive, isTrue);
    });

    test('maps employer_id and a hidden listing', () {
      final job = jobFromRow(<String, dynamic>{
        'id': 'j3',
        'title': 'Kitchen porter',
        'employer': 'Horn Cafe',
        'employer_id': 'user-42',
        'is_active': false,
      });

      expect(job.employerId, 'user-42');
      expect(job.isActive, isFalse);
    });

    test('tolerates nulls and a missing tag list', () {
      final job = jobFromRow(<String, dynamic>{
        'id': 'j2',
        'title': 'Data entry clerk',
        'employer': 'FinServe Group',
        'location': null,
        'description': null,
        'posted_at': null,
      });

      expect(job.location, isNull);
      expect(job.description, isNull);
      expect(job.postedAt, isNull);
      expect(job.tags, isEmpty);
    });
  });

  group('applicationFromRow', () {
    test('maps the row with the embedded job', () {
      final application = applicationFromRow(<String, dynamic>{
        'id': 'a1',
        'job_id': 'j1',
        'user_id': 'u1',
        'status': JobApplication.statusApplied,
        'cover_note': 'I am reliable and hard-working.',
        'created_at': '2026-01-06T09:00:00.000Z',
        'job': <String, dynamic>{
          'id': 'j1',
          'title': 'Retail assistant',
          'employer': 'GreenMart',
          'tags': <String>['With Support'],
        },
      });

      expect(application.id, 'a1');
      expect(application.jobId, 'j1');
      expect(application.userId, 'u1');
      expect(application.status, JobApplication.statusApplied);
      expect(application.coverNote, 'I am reliable and hard-working.');
      expect(application.createdAt, isNotNull);
      expect(application.job, isNotNull);
      expect(application.job!.title, 'Retail assistant');
      expect(application.job!.employer, 'GreenMart');
    });

    test('tolerates a missing embed and status', () {
      final application = applicationFromRow(<String, dynamic>{
        'id': 'a2',
        'job_id': 'j2',
        'user_id': 'u2',
        'job': null,
      });

      expect(application.status, JobApplication.statusApplied);
      expect(application.createdAt, isNull);
      expect(application.job, isNull);
    });
  });
}
