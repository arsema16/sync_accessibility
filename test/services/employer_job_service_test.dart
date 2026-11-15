import 'package:flutter_test/flutter_test.dart';

import 'package:sync_accessibility/models/job_model.dart';
import 'package:sync_accessibility/services/job_service.dart';

void main() {
  group('InMemoryJobService employer postings', () {
    test('saveEmployerJob creates, then updates, then deletes', () async {
      final service = InMemoryJobService();

      final created = await service.saveEmployerJob(
        const Job(
          id: '',
          title: 'Kitchen porter',
          employer: 'Horn Cafe',
          employerId: 'employer-1',
          location: 'Addis Ababa',
          tags: <String>['Step-free Access'],
        ),
      );

      expect(created.id, isNotEmpty);
      expect(created.employerId, 'employer-1');
      expect(created.isActive, isTrue);
      expect(await service.getJob(created.id), created);

      // The public feed includes it too.
      expect(
        (await service.listJobs()).map((job) => job.id),
        contains(created.id),
      );

      // Update: rename, hide, and change the accommodations.
      final updated = await service.saveEmployerJob(
        Job(
          id: created.id,
          title: 'Kitchen porter (nights)',
          employer: 'Horn Cafe',
          employerId: 'employer-1',
          tags: <String>['Flexible Hours'],
          isActive: false,
        ),
      );
      expect(updated.title, 'Kitchen porter (nights)');
      expect(updated.isActive, isFalse);
      expect(updated.tags, <String>['Flexible Hours']);

      await service.deleteJob(created.id);
      expect(await service.getJob(created.id), isNull);
    });

    test('listJobsForEmployer only returns that employer\'s rows', () async {
      final service = InMemoryJobService();
      await service.saveEmployerJob(
        const Job(
          id: '',
          title: 'Job A',
          employer: 'A Corp',
          employerId: 'employer-a',
        ),
      );
      await service.saveEmployerJob(
        const Job(
          id: '',
          title: 'Job B',
          employer: 'B Corp',
          employerId: 'employer-b',
        ),
      );

      final mine = await service.listJobsForEmployer('employer-a');
      expect(mine, hasLength(1));
      expect(mine.single.title, 'Job A');
      expect(await service.listJobsForEmployer('nobody'), isEmpty);
    });

    test('seed jobs (no employer) belong to no employer', () async {
      final service = InMemoryJobService();
      expect(await service.listJobsForEmployer('employer-a'), isEmpty);
    });
  });

  group('InMemoryJobService cover notes', () {
    test('applyToJob stores the cover note', () async {
      final service = InMemoryJobService();
      final job = (await service.listJobs()).first;

      final application = await service.applyToJob(
        jobId: job.id,
        userId: 'u1',
        coverNote: 'I am reliable.\nTwo years in warehouses.',
      );

      expect(application.coverNote, 'I am reliable.\nTwo years in warehouses.');
      expect(
        (await service.listApplications('u1')).single.coverNote,
        'I am reliable.\nTwo years in warehouses.',
      );
    });

    test('re-applying updates the note instead of duplicating', () async {
      final service = InMemoryJobService();
      final job = (await service.listJobs()).first;

      await service.applyToJob(jobId: job.id, userId: 'u1', coverNote: 'first');
      final second = await service.applyToJob(
        jobId: job.id,
        userId: 'u1',
        coverNote: 'second',
      );

      expect(second.coverNote, 'second');
      final mine = await service.listApplications('u1');
      expect(mine, hasLength(1));
      expect(mine.single.coverNote, 'second');
    });

    test('re-applying without a note keeps the previous one', () async {
      final service = InMemoryJobService();
      final job = (await service.listJobs()).first;

      await service.applyToJob(jobId: job.id, userId: 'u1', coverNote: 'keep');
      final second = await service.applyToJob(jobId: job.id, userId: 'u1');

      expect(second.coverNote, 'keep');
    });
  });
}
