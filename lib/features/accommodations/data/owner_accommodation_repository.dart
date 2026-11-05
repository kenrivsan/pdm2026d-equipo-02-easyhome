import '../domain/entities/accommodation.dart';
import 'owner_accommodation_store.dart';

/// Typed storage contract to coordinate owner listings with the student catalog.
///
/// Proposed for agreement in issue #27 before changing the shared store.
/// The same record and id must back both listings. Deletion must be durable
/// before its future completes; restore must preserve every field, be
/// idempotent for an already restored id, and make the record visible in the
/// student catalog through that same source of truth.
abstract interface class OwnerAccommodationRepository {
  Future<List<OwnerAccommodation>> getOwnerAccommodations({
    AccommodationType? type,
  });

  /// Completes only after the record is durably deleted.
  Future<void> deleteOwnerAccommodation(String id);

  /// Restores the complete record under its original id; must not duplicate it.
  Future<void> restoreOwnerAccommodation(OwnerAccommodation accommodation);
}
