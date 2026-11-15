import 'package:equatable/equatable.dart';

import 'job_model.dart';

/// A user's application to (or save of) a job posting.
///
/// Backed by the `job_applications` table. [job] is filled in when the row is
/// fetched with the job embedded (`job:jobs(*)`), and stays `null` otherwise.
class JobApplication extends Equatable {
  const JobApplication({
    required this.id,
    required this.jobId,
    required this.userId,
    this.status = statusApplied,
    this.coverNote,
    this.createdAt,
    this.job,
  });

  static const String statusApplied = 'applied';
  static const String statusSaved = 'saved';
  static const String statusWithdrawn = 'withdrawn';

  final String id;
  final String jobId;
  final String userId;

  /// One of [statusApplied], [statusSaved], [statusWithdrawn].
  final String status;

  /// The applicant's voice/typed answers for this application
  /// (`job_applications.cover_note`). Read by the employer with the
  /// application; never shared anywhere else.
  final String? coverNote;

  final DateTime? createdAt;

  /// The job this application refers to, when fetched with the embed.
  final Job? job;

  @override
  List<Object?> get props =>
      [id, jobId, userId, status, coverNote, createdAt, job];
}
