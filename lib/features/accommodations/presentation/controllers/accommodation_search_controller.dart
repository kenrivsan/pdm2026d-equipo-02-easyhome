import 'package:flutter/foundation.dart';

import '../../domain/entities/accommodation.dart';
import '../../domain/entities/department.dart';
import '../../domain/entities/university.dart';
import '../../domain/repositories/accommodation_repository.dart';
import '../../domain/repositories/location_repository.dart';

class AccommodationSearchController extends ChangeNotifier {
  AccommodationSearchController({
    required AccommodationRepository accommodationRepository,
    required LocationRepository locationRepository,
  }) : _accommodationRepository = accommodationRepository,
       _locationRepository = locationRepository;

  final AccommodationRepository _accommodationRepository;
  final LocationRepository _locationRepository;

  List<Accommodation> _accommodations = const [];
  List<Department> _departments = const [];
  List<University> _universities = const [];
  String? _selectedDepartmentId;
  String? _selectedUniversityId;
  AccommodationType? _selectedType;
  bool _isLoading = false;
  String? _errorMessage;

  List<Department> get departments => List.unmodifiable(_departments);
  List<University> get universities => List.unmodifiable(_universities);
  String? get selectedDepartmentId => _selectedDepartmentId;
  String? get selectedUniversityId => _selectedUniversityId;
  AccommodationType? get selectedType => _selectedType;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<University> get availableUniversities {
    final departmentId = _selectedDepartmentId;
    if (departmentId == null) return List.unmodifiable(_universities);

    return List.unmodifiable(
      _universities.where(
        (university) => university.departmentId == departmentId,
      ),
    );
  }

  List<Accommodation> get filteredAccommodations {
    return List.unmodifiable(
      _accommodations.where((accommodation) {
        final matchesDepartment =
            _selectedDepartmentId == null ||
            accommodation.departmentId == _selectedDepartmentId;
        final matchesUniversity =
            _selectedUniversityId == null ||
            accommodation.universityIds.contains(_selectedUniversityId);
        final matchesType =
            _selectedType == null || accommodation.type == _selectedType;

        return accommodation.available &&
            matchesDepartment &&
            matchesUniversity &&
            matchesType;
      }),
    );
  }

  Future<void> loadData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _departments = await _locationRepository.getDepartments();
      _universities = await _locationRepository.getUniversities();
      _accommodations = await _accommodationRepository.getAccommodations();
    } catch (_) {
      _errorMessage = 'No fue posible cargar los alojamientos.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectDepartment(String? departmentId) {
    if (_selectedDepartmentId == departmentId) return;

    _selectedDepartmentId = departmentId;
    final selectedUniversity = _findUniversity(_selectedUniversityId);
    if (selectedUniversity != null &&
        selectedUniversity.departmentId != departmentId) {
      _selectedUniversityId = null;
    }
    notifyListeners();
  }

  void selectUniversity(String? universityId) {
    if (_selectedUniversityId == universityId) return;

    _selectedUniversityId = universityId;
    final university = _findUniversity(universityId);
    if (university != null) {
      _selectedDepartmentId = university.departmentId;
    }
    notifyListeners();
  }

  void selectType(AccommodationType? type) {
    if (_selectedType == type) return;
    _selectedType = type;
    notifyListeners();
  }

  void clearFilters() {
    _selectedDepartmentId = null;
    _selectedUniversityId = null;
    _selectedType = null;
    notifyListeners();
  }

  Accommodation? findAccommodationById(String id) {
    for (final accommodation in _accommodations) {
      if (accommodation.id == id) return accommodation;
    }
    return null;
  }

  University? _findUniversity(String? id) {
    if (id == null) return null;
    for (final university in _universities) {
      if (university.id == id) return university;
    }
    return null;
  }
}
