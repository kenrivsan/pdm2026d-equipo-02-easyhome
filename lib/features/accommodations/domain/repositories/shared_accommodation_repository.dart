import '../entities/accommodation_query.dart';
import '../entities/accommodation_record.dart';
import '../entities/deleted_accommodation.dart';

/// Domain contract for the one source of truth used by owners and students.
///
/// Implementations must emit events only after durable changes. Queries return
/// records in their stable insertion order, independent of filters. Delete
/// returns a complete snapshot and its original order metadata. Adding an
/// existing id and deleting an absent id fail without changing stored data.
/// Restore is idempotent for the same deletion token and preserves the original
/// order and every publication field.
abstract interface class SharedAccommodationRepository {
  /// Monotonically increasing revisions emitted after successful writes only.
  Stream<int> get changes;

  /// Returns all matching records in stable insertion order.
  Future<List<AccommodationRecord>> query(AccommodationQuery filter);

  /// Adds a publication. Existing IDs fail with [DuplicateAccommodationException].
  Future<void> add(AccommodationRecord record);

  /// Deletes an active publication or throws [AccommodationNotFoundException].
  Future<DeletedAccommodation> deleteById(String id);

  /// Restores the snapshot once; repeating the same token is a no-op.
  /// Unknown or stale tokens fail with [DeletedAccommodationNotFoundException].
  Future<void> restore(DeletedAccommodation deleted);
}

final class AccommodationNotFoundException implements Exception {
  const AccommodationNotFoundException(this.id);

  final String id;

  @override
  String toString() => 'Accommodation not found: $id';
}

final class DuplicateAccommodationException implements Exception {
  const DuplicateAccommodationException(this.id);

  final String id;

  @override
  String toString() => 'Accommodation already exists: $id';
}

final class DeletedAccommodationNotFoundException implements Exception {
  const DeletedAccommodationNotFoundException(this.deletionToken);

  final String deletionToken;

  @override
  String toString() => 'Deleted accommodation not found: $deletionToken';
}
