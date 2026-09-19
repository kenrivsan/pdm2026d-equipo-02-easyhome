import '../entities/department.dart';
import '../entities/university.dart';

abstract interface class LocationRepository {
  Future<List<Department>> getDepartments();

  Future<List<University>> getUniversities();
}
