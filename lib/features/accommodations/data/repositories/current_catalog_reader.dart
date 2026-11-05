import 'dart:async';

import '../../domain/entities/accommodation.dart';
import '../../domain/entities/catalog_filter.dart';
import '../../domain/repositories/accommodation_repository.dart';
import '../../domain/repositories/catalog_reader.dart';
import '../owner_accommodation_store.dart';

/// Adaptador de lectura del MVP existente, sin almacenamiento adicional.
/// Se sustituirá por el adaptador de la fuente compartida cuando se publique.
class CurrentCatalogReader implements CatalogReader {
  CurrentCatalogReader(this.repository, this.ownerStore) {
    ownerStore.addListener(_onOwnerChanged);
  }

  final AccommodationRepository repository;
  final OwnerAccommodationStore ownerStore;
  final _changes = StreamController<int>.broadcast();
  int _revision = 0;

  @override
  Stream<int> get changes => _changes.stream;

  void _onOwnerChanged() => _changes.add(++_revision);

  @override
  Future<List<Accommodation>> query(CatalogFilter filter) async {
    final original = await repository.getAccommodations();
    final byId = <String, Accommodation>{
      for (final item in original) item.id: item,
      for (final item in ownerStore.catalogItems) item.id: item,
    };
    return List.unmodifiable(
      byId.values.where((item) {
        return item.available &&
            (filter.type == null || item.type == filter.type) &&
            (filter.departmentId == null ||
                item.departmentId == filter.departmentId) &&
            (filter.universityId == null ||
                item.universityIds.contains(filter.universityId));
      }),
    );
  }

  void dispose() {
    ownerStore.removeListener(_onOwnerChanged);
    unawaited(_changes.close());
  }
}
