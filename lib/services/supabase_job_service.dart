import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/supabase_config.dart';
import '../models/job_application_model.dart';
import '../models/job_model.dart';
import 'job_service.dart';
import 'profile_service.dart';

/// Reads a `jobs` row into a [Job].
///
/// Top-level (rather than private) so tests can cover the mapping without a
/// live client.
Job jobFromRow(Map<String, dynamic> row) => Job(
      id: row['id'] as String,
      title: row['title'] as String,
      employer: row['employer'] as String,
      employerId: row['employer_id'] as String?,
      location: row['location'] as String?,
      description: row['description'] as String?,
      postedAt: row['posted_at'] is String
          ? DateTime.tryParse(row['posted_at'] as String)
          : null,
      tags: _stringList(row['tags']),
      isActive: row['is_active'] as bool? ?? true,
    );

/// Reads a `job_applications` row (with `job:jobs(*)` embedded) into a
/// [JobApplication].
JobApplication applicationFromRow(Map<String, dynamic> row) {
  final jobRaw = row['job'];
  return JobApplication(
    id: row['id'] as String,
    jobId: row['job_id'] as String,
    userId: row['user_id'] as String,
    status: (row['status'] as String?) ?? JobApplication.statusApplied,
    coverNote: row['cover_note'] as String?,
    createdAt: row['created_at'] is String
        ? DateTime.tryParse(row['created_at'] as String)
        : null,
    job: jobRaw is Map<String, dynamic> ? jobFromRow(jobRaw) : null,
  );
}

List<String> _stringList(Object? raw) {
  if (raw is List) {
    return raw.map((item) => item.toString()).toList();
  }
  return const <String>[];
}

/// Supabase-backed [JobService] over the `jobs` and `job_applications` tables.
///
/// Job listings are public read; applications are protected by row-level
/// security so users only ever see their own.
class SupabaseJobService implements JobService {
  SupabaseJobService({SupabaseClient? client})
      : _client = client ?? SupabaseBootstrap.client;

  final SupabaseClient _client;

  @override
  Future<List<Job>> listJobs() async {
    try {
      final rows = await _client
          .from('jobs')
          .select()
          .eq('is_active', true)
          .order('posted_at', ascending: false);
      return rows.map(jobFromRow).toList(growable: false);
    } on PostgrestException catch (error) {
      debugPrint('Supabase listJobs failed: $error');
      rethrow;
    }
  }

  @override
  Future<Job?> getJob(String id) async {
    final row =
        await _client.from('jobs').select().eq('id', id).maybeSingle();
    return row == null ? null : jobFromRow(row);
  }

  @override
  Future<List<Job>> listJobsForEmployer(String employerId) async {
    try {
      final rows = await _client
          .from('jobs')
          .select()
          .eq('employer_id', employerId)
          .order('posted_at', ascending: false);
      return rows.map(jobFromRow).toList(growable: false);
    } on PostgrestException catch (error) {
      debugPrint('Supabase listJobsForEmployer failed: $error');
      rethrow;
    }
  }

  @override
  Future<Job> saveEmployerJob(Job job) async {
    // The RLS policies (jobs_insert_own / jobs_update_own) guarantee the row
    // is written under the signed-in user's employer_id regardless of what
    // the client sends; we still pass it explicitly for the insert path.
    final payload = <String, Object?>{
      'title': job.title,
      'employer': job.employer,
      'employer_id': job.employerId,
      'location': job.location,
      'description': job.description,
      'tags': job.tags,
      'is_active': job.isActive,
    };
    try {
      final row = job.id.isEmpty
          ? await _client.from('jobs').insert(payload).select().single()
          : await _client
              .from('jobs')
              .update(payload)
              .eq('id', job.id)
              .select()
              .single();
      return jobFromRow(row);
    } on PostgrestException catch (error) {
      debugPrint('Supabase saveEmployerJob failed: $error');
      if (error.code == '42501' ||
          error.message.contains('row-level security')) {
        throw const ProfileException(
          'You can only edit job postings you created.',
        );
      }
      rethrow;
    }
  }

  @override
  Future<void> deleteJob(String jobId) async {
    try {
      await _client.from('jobs').delete().eq('id', jobId);
    } on PostgrestException catch (error) {
      debugPrint('Supabase deleteJob failed: $error');
      rethrow;
    }
  }

  @override
  Future<List<JobApplication>> listApplications(String userId) async {
    final rows = await _client
        .from('job_applications')
        .select('*, job:jobs(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return rows.map(applicationFromRow).toList(growable: false);
  }

  @override
  Future<JobApplication> applyToJob({
    required String jobId,
    required String userId,
    String? coverNote,
  }) async {
    try {
      final row = await _client
          .from('job_applications')
          .upsert(
            <String, Object?>{
              'user_id': userId,
              'job_id': jobId,
              'status': JobApplication.statusApplied,
              'cover_note': coverNote,
            },
            onConflict: 'user_id,job_id',
          )
          .select('*, job:jobs(*)')
          .single();
      return applicationFromRow(row);
    } on PostgrestException catch (error) {
      debugPrint('Supabase applyToJob failed: $error');
      if (error.code == '42501' ||
          error.message.contains('row-level security')) {
        throw const ProfileException('Sign in to apply for this job.');
      }
      rethrow;
    }
  }

  @override
  Future<void> removeApplication(String applicationId) async {
    await _client
        .from('job_applications')
        .delete()
        .eq('id', applicationId);
  }
}
