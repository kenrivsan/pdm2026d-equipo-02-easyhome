import '../../domain/entities/accommodation.dart';
import '../../domain/repositories/accommodation_repository.dart';
import '../datasources/accommodation_data_source.dart';

class AccommodationRepositoryImpl implements AccommodationRepository {
  const AccommodationRepositoryImpl(this.dataSource);

  final AccommodationDataSource dataSource;

  @override
  Future<List<Accommodation>> getAccommodations() =>
      dataSource.getAccommodations();
}
