import 'package:equatable/equatable.dart';

/// A job listing, read from the `jobs` table (or the in-memory fallback).
class Job extends Equatable {
  const Job({
    required this.id,
    required this.title,
    required this.employer,
    this.employerId,
    this.location,
    this.description,
    this.postedAt,
    this.tags = const <String>[],
    this.isActive = true,
  });

  final String id;
  final String title;
  final String employer;

  /// Auth user id of the employer who posted this listing (`jobs.employer_id`).
  ///
  /// `null` for seed / service-role listings. Employers can only edit rows
  /// whose `employer_id` matches their own (enforced by RLS).
  final String? employerId;

  final String? location;
  final String? description;
  final DateTime? postedAt;

  /// Accessibility / working-pattern labels shown as chips and used by the
  /// job-list filters, e.g. `Remote OK`, `Step-free Access`.
  final List<String> tags;

  /// Whether the listing is visible in the public feed (`jobs.is_active`).
  final bool isActive;

  @override
  List<Object?> get props =>
      [id, title, employer, employerId, location, description, postedAt, tags, isActive];
}
