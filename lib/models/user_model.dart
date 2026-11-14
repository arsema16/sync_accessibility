import 'package:equatable/equatable.dart';

/// A SYNC account holder.
///
/// The auth service stub produces these. The [id] is a local identifier until
/// the real backend is wired up.
class SyncUser extends Equatable {
  const SyncUser({
    required this.id,
    required this.email,
    this.displayName,
    this.createdAt,
  });

  final String id;
  final String email;
  final String? displayName;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [id, email, displayName, createdAt];
}
