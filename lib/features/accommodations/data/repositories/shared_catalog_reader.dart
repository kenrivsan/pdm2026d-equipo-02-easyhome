import '../../domain/entities/accommodation.dart';
import '../../domain/entities/accommodation_query.dart';
import '../../domain/entities/catalog_filter.dart';
import '../../domain/repositories/catalog_reader.dart';
import '../../domain/repositories/shared_accommodation_repository.dart';

/// Proyección de lectura del catálogo sobre la fuente canónica compartida.
class SharedCatalogReader implements CatalogReader {
  const SharedCatalogReader(this.repository);

  final SharedAccommodationRepository repository;

  @override
  Stream<int> get changes => repository.changes;

  @override
  Future<List<Accommodation>> query(CatalogFilter filter) async {
    final records = await repository.query(
      AccommodationQuery(
        type: filter.type,
        departmentId: filter.departmentId,
        universityId: filter.universityId,
      ),
    );
    return List.unmodifiable(
      records
          .where((record) => record.available)
          .map((record) => record.toAccommodation()),
    );
  }
}
