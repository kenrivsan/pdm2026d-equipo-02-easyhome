import '../models/department_model.dart';
import '../models/university_model.dart';

abstract interface class LocationDataSource {
  Future<List<DepartmentModel>> getDepartments();

  Future<List<UniversityModel>> getUniversities();
}

/// Catálogo temporal para M1. Se reemplazará sin afectar presentación o dominio.
class InMemoryLocationDataSource implements LocationDataSource {
  static const _departments = <DepartmentModel>[
    DepartmentModel(id: 'guatemala', name: 'Guatemala'),
    DepartmentModel(id: 'quetzaltenango', name: 'Quetzaltenango'),
  ];

  static const _universities = <UniversityModel>[
    UniversityModel(
      id: 'usac-central',
      name: 'Universidad de San Carlos de Guatemala',
      departmentId: 'guatemala',
    ),
    UniversityModel(
      id: 'mesoamericana-quetzaltenango',
      name: 'Universidad Mesoamericana',
      departmentId: 'quetzaltenango',
    ),
  ];

  @override
  Future<List<DepartmentModel>> getDepartments() async =>
      List.unmodifiable(_departments);

  @override
  Future<List<UniversityModel>> getUniversities() async =>
      List.unmodifiable(_universities);
}
