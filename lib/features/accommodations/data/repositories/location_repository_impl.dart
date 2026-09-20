import '../../domain/entities/department.dart';
import '../../domain/entities/university.dart';
import '../../domain/repositories/location_repository.dart';
import '../datasources/location_data_source.dart';

class LocationRepositoryImpl implements LocationRepository {
  const LocationRepositoryImpl(this.dataSource);

  final LocationDataSource dataSource;

  @override
  Future<List<Department>> getDepartments() => dataSource.getDepartments();

  @override
  Future<List<University>> getUniversities() => dataSource.getUniversities();
}
