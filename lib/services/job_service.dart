import '../models/job_model.dart';

/// Job listings contract. Stub only — fleshed out in Phase 2.
abstract class JobService {
  /// Returns all open job listings.
  Future<List<Job>> listJobs();

  /// Returns a single job by id, or `null`.
  Future<Job?> getJob(String id);
}

/// Local in-memory implementation of [JobService].
///
/// Returns a small fixed set of sample jobs so the stub job screen has
/// something to render in Phase 1.
///
// TODO(arsema-tewodros): replace InMemoryJobService with Supabase implementation.
class InMemoryJobService implements JobService {
  final List<Job> _jobs = <Job>[
    const Job(
      id: 'job-1',
      title: 'Warehouse assistant',
      employer: 'Sunrise Logistics',
      location: 'Addis Ababa',
      description: 'Packing, sorting and loading. Full training provided.',
    ),
    const Job(
      id: 'job-2',
      title: 'Retail assistant',
      employer: 'Mercato Stores',
      location: 'Addis Ababa',
      description: 'Helping customers and stocking shelves.',
    ),
    const Job(
      id: 'job-3',
      title: 'Farm worker',
      employer: 'Green Valley Co-op',
      location: 'Debre Zeit',
      description: 'Planting and harvesting. Seasonal role.',
    ),
  ];

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
}
