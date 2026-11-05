import '../../domain/entities/accommodation_query.dart';
import '../../domain/entities/accommodation_record.dart';
import '../../domain/entities/owner_accommodation_filter.dart';
import '../../domain/repositories/shared_accommodation_repository.dart';

/// Owner view over the same persisted records used by the student catalog.
class SharedOwnerAccommodationReader {
  const SharedOwnerAccommodationReader(this.repository);

  final SharedAccommodationRepository repository;

  Future<List<AccommodationRecord>> query(OwnerAccommodationFilter filter) =>
      repository.query(AccommodationQuery(type: filter.type, onlyOwned: true));
}
