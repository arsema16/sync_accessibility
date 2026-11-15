import 'package:flutter_test/flutter_test.dart';

import 'package:sync_accessibility/services/job_service.dart';

void main() {
  group('InMemoryJobService', () {
    test('listJobs returns listings and getJob finds one by id', () async {
      final service = InMemoryJobService();

      final jobs = await service.listJobs();
      expect(jobs, isNotEmpty);

      final first = jobs.first;
      expect(await service.getJob(first.id), first);
      expect(await service.getJob('does-not-exist'), isNull);
    });

    test('listJobs returns an unmodifiable copy', () async {
      final service = InMemoryJobService();
      final jobs = await service.listJobs();

      expect(() => jobs.clear(), throwsUnsupportedError);
      expect((await service.listJobs()).length, jobs.length);
    });

    test('applyToJob stores an application and embeds the job', () async {
      final service = InMemoryJobService();
      final job = (await service.listJobs()).first;

      final application = await service.applyToJob(
        jobId: job.id,
        userId: 'u1',
      );

      expect(application.id, isNotNull);
      expect(application.jobId, job.id);
      expect(application.userId, 'u1');
      expect(application.job, job);

      final mine = await service.listApplications('u1');
      expect(mine, hasLength(1));
      expect(await service.listApplications('u2'), isEmpty);
    });

    test('applyToJob does not create duplicates for the same user and job',
        () async {
      final service = InMemoryJobService();
      final job = (await service.listJobs()).first;

      final first = await service.applyToJob(jobId: job.id, userId: 'u1');
      final second = await service.applyToJob(jobId: job.id, userId: 'u1');

      expect(second.id, first.id);
      expect(await service.listApplications('u1'), hasLength(1));
    });

    test('removeApplication withdraws the application', () async {
      final service = InMemoryJobService();
      final job = (await service.listJobs()).first;
      final application = await service.applyToJob(
        jobId: job.id,
        userId: 'u1',
      );

      await service.removeApplication(application.id);

      expect(await service.listApplications('u1'), isEmpty);
    });

    test('listApplications returns newest first', () async {
      final service = InMemoryJobService();
      final jobs = await service.listJobs();

      await service.applyToJob(jobId: jobs[0].id, userId: 'u1');
      // Ensure a distinct timestamp on platforms with coarse clock resolution.
      await Future<void>.delayed(const Duration(milliseconds: 30));
      await service.applyToJob(jobId: jobs[1].id, userId: 'u1');

      final applications = await service.listApplications('u1');
      expect(applications.first.jobId, jobs[1].id);
      expect(applications.last.jobId, jobs[0].id);
    });
  });
}
