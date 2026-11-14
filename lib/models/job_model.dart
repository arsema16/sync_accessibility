import 'package:equatable/equatable.dart';

/// Stub job model.
///
/// This is intentionally minimal: the job and application flow is fleshed out in
/// Phase 2. Fields are included so the in-memory [JobService] stub can return
/// something realistic, but no UI depends on them yet beyond the stub screen.
class Job extends Equatable {
  const Job({
    required this.id,
    required this.title,
    required this.employer,
    this.location,
    this.description,
    this.postedAt,
  });

  final String id;
  final String title;
  final String employer;
  final String? location;
  final String? description;
  final DateTime? postedAt;

  @override
  List<Object?> get props => [id, title, employer, location, description, postedAt];
}
