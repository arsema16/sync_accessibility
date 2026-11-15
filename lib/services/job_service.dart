import '../models/job_application_model.dart';
import '../models/job_model.dart';

/// Job listings and applications contract.
///
/// The Supabase implementation (`SupabaseJobService`) reads the `jobs` and
/// `job_applications` tables; `InMemoryJobService` remains as a local fallback
/// for tests and unconfigured builds.
abstract class JobService {
  /// Returns all open job listings, newest first.
  Future<List<Job>> listJobs();

  /// Returns a single job by id, or `null`.
  Future<Job?> getJob(String id);

  /// Returns the listings posted by [employerId] (own row only), newest first.
  Future<List<Job>> listJobsForEmployer(String employerId);

  /// Creates or updates the employer's job posting.
  ///
  /// When [job.id] is empty a new listing is created and returned with its id
  /// set; otherwise the existing row is updated. Implementations must only be
  /// able to write rows owned by the signed-in employer (enforced by RLS on
  /// Supabase).
  Future<Job> saveEmployerJob(Job job);

  /// Deletes (or deactivates) the job posting with [jobId].
  Future<void> deleteJob(String jobId);

  /// Returns every application [userId] has made, newest first, with the
  /// referenced job embedded where available.
  Future<List<JobApplication>> listApplications(String userId);

  /// Applies for [jobId] on behalf of [userId], attaching [coverNote] — the
  /// applicant's voice/typed answers — when provided.
  ///
  /// Re-applying for the same job updates the existing row instead of
  /// creating a duplicate. Returns the stored application with its id set.
  Future<JobApplication> applyToJob({
    required String jobId,
    required String userId,
    String? coverNote,
  });

  /// Withdraws (deletes) the application with [applicationId].
  Future<void> removeApplication(String applicationId);
}

/// Local in-memory implementation of [JobService].
///
/// Returns a small fixed set of sample jobs so the job screens have something
/// to render without a backend.
class InMemoryJobService implements JobService {
  final List<Job> _jobs = <Job>[
    const Job(
      id: 'job-1',
      title: 'Warehouse assistant',
      employer: 'Sunrise Logistics',
      location: 'Addis Ababa',
      description: 'Packing, sorting and loading. Full training provided.',
      tags: <String>['Step-free Access', 'Flexible Hours'],
    ),
    const Job(
      id: 'job-2',
      title: 'Retail assistant',
      employer: 'Mercato Stores',
      location: 'Addis Ababa',
      description: 'Helping customers and stocking shelves.',
      tags: <String>['With Support', 'Step-free Access'],
    ),
    const Job(
      id: 'job-3',
      title: 'Farm worker',
      employer: 'Green Valley Co-op',
      location: 'Debre Zeit',
      description: 'Planting and harvesting. Seasonal role.',
      tags: <String>['Flexible Hours'],
    ),
    const Job(
      id: 'job-4',
      title: 'Data entry clerk',
      employer: 'FinServe Group',
      location: 'Remote',
      description: 'Recording information into internal systems.',
      tags: <String>['Remote OK', 'Written Instructions'],
    ),
  ];

  final List<JobApplication> _applications = <JobApplication>[];
  int _nextId = 0;
  int _nextApplicationId = 0;

  @override
  Future<List<Job>> listJobs() async => List<Job>.unmodifiable(_jobs);

  @override
  Future<Job?> getJob(String id) async {
    for (final job in _jobs) {
      if (job.id == id) {
        return job;
      }
    }
    return null;
  }

  @override
  Future<List<Job>> listJobsForEmployer(String employerId) async {
    final mine = _jobs
        .where((job) => job.employerId == employerId)
        .toList()
      ..sort((a, b) => (b.postedAt ?? DateTime(0))
          .compareTo(a.postedAt ?? DateTime(0)));
    return List<Job>.unmodifiable(mine);
  }

  @override
  Future<Job> saveEmployerJob(Job job) async {
    if (job.id.isEmpty) {
      final created = Job(
        id: 'job-${_nextId++}',
        title: job.title,
        employer: job.employer,
        employerId: job.employerId,
        location: job.location,
        description: job.description,
        postedAt: DateTime.now(),
        tags: job.tags,
        isActive: job.isActive,
      );
      _jobs.insert(0, created);
      return created;
    }
    final index = _jobs.indexWhere((existing) => existing.id == job.id);
    if (index >= 0) {
      _jobs[index] = job;
      return job;
    }
    // Editing an unknown id behaves like a create so the UI never loses work.
    final created = Job(
      id: job.id,
      title: job.title,
      employer: job.employer,
      employerId: job.employerId,
      location: job.location,
      description: job.description,
      postedAt: job.postedAt ?? DateTime.now(),
      tags: job.tags,
      isActive: job.isActive,
    );
    _jobs.insert(0, created);
    return created;
  }

  @override
  Future<void> deleteJob(String jobId) async {
    _jobs.removeWhere((job) => job.id == jobId);
  }

  @override
  Future<List<JobApplication>> listApplications(String userId) async {
    final mine = _applications
        .where((application) => application.userId == userId)
        .toList()
      ..sort((a, b) => (b.createdAt ?? DateTime(0))
          .compareTo(a.createdAt ?? DateTime(0)));
    return List<JobApplication>.unmodifiable(mine);
  }

  @override
  Future<JobApplication> applyToJob({
    required String jobId,
    required String userId,
    String? coverNote,
  }) async {
    final existing = _applications.indexWhere(
      (application) =>
          application.userId == userId && application.jobId == jobId,
    );
    if (existing >= 0) {
      final previous = _applications[existing];
      final updated = JobApplication(
        id: previous.id,
        jobId: previous.jobId,
        userId: previous.userId,
        status: previous.status,
        coverNote: coverNote ?? previous.coverNote,
        createdAt: previous.createdAt,
        job: previous.job,
      );
      _applications[existing] = updated;
      return updated;
    }
    final application = JobApplication(
      id: 'application-${_nextApplicationId++}',
      jobId: jobId,
      userId: userId,
      coverNote: coverNote,
      createdAt: DateTime.now(),
      job: _jobs.firstWhere(
        (job) => job.id == jobId,
        orElse: () => _jobs.first,
      ),
    );
    _applications.add(application);
    return application;
  }

  @override
  Future<void> removeApplication(String applicationId) async {
    _applications.removeWhere(
      (application) => application.id == applicationId,
    );
  }
}
