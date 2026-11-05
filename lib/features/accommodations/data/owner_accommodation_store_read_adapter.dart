import '../domain/entities/accommodation.dart';
import 'owner_accommodation_repository.dart';
import 'owner_accommodation_store.dart';

/// Read-only bridge that keeps the owner list usable while the shared
/// repository contract is being coordinated in issue #27.
class OwnerAccommodationStoreReadAdapter
    implements OwnerAccommodationRepository {
  const OwnerAccommodationStoreReadAdapter(this.store);

  final OwnerAccommodationStore store;

  @override
  Future<List<OwnerAccommodation>> getOwnerAccommodations({
    AccommodationType? type,
  }) async {
    return List.unmodifiable(
      store.items.where(
        (item) => type == null || item.toAccommodation().type == type,
      ),
    );
  }

  @override
  Future<void> deleteOwnerAccommodation(String id) =>
      Future.error(UnsupportedError('Deletion awaits the shared contract.'));

  @override
  Future<void> restoreOwnerAccommodation(OwnerAccommodation accommodation) =>
      Future.error(UnsupportedError('Restoration awaits the shared contract.'));
}
