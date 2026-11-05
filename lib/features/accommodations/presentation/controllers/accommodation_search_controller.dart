import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/entities/accommodation.dart';
import '../../domain/entities/accommodation_query.dart';
import '../../domain/entities/accommodation_record.dart';
import '../../domain/entities/department.dart';
import '../../domain/entities/university.dart';
import '../../domain/repositories/accommodation_repository.dart';
import '../../domain/repositories/location_repository.dart';
import '../../domain/repositories/shared_accommodation_repository.dart';

class AccommodationSearchController extends ChangeNotifier {
  AccommodationSearchController({
    AccommodationRepository? accommodationRepository,
    SharedAccommodationRepository? sharedAccommodationRepository,
    required LocationRepository locationRepository,
  }) : assert(
         accommodationRepository != null ||
             sharedAccommodationRepository != null,
         'Provide the shared repository (or the legacy repository in tests).',
       ),
       _accommodationRepository = accommodationRepository,
       _sharedAccommodationRepository = sharedAccommodationRepository,
       _locationRepository = locationRepository {
    if (sharedAccommodationRepository != null) {
      _changesSubscription = sharedAccommodationRepository.changes.listen(
        (_) => unawaited(refreshAccommodations()),
      );
    }
  }

  final AccommodationRepository? _accommodationRepository;
  final SharedAccommodationRepository? _sharedAccommodationRepository;
  final LocationRepository _locationRepository;
  StreamSubscription<int>? _changesSubscription;

  /// Permite componer lectores de la misma fuente, sin crear otro repositorio.
  AccommodationRepository get accommodationRepository {
    final repository = _accommodationRepository;
    if (repository == null) {
      throw StateError(
        'El controlador usa el repositorio compartido; no tiene fuente legada.',
      );
    }
    return repository;
  }

  List<Accommodation> _accommodations = const [];
  List<Department> _departments = const [];
  List<University> _universities = const [];
  String? _selectedDepartmentId;
  String? _selectedUniversityId;
  AccommodationType? _selectedType;
  bool _isLoading = false;
  String? _errorMessage;
  int _accommodationRequest = 0;
  bool _disposed = false;

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

  List<Accommodation> get allAccommodations =>
      List.unmodifiable(_accommodations);

  List<Accommodation> get filteredAccommodations {
    return List.unmodifiable(
      allAccommodations.where((accommodation) {
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
      await _loadAccommodations(notify: false);
    } catch (_) {
      _errorMessage = 'No fue posible cargar los alojamientos.';
    } finally {
      _isLoading = false;
      if (!_disposed) notifyListeners();
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
    for (final accommodation in allAccommodations) {
      if (accommodation.id == id) return accommodation;
    }
    return null;
  }

  Future<void> refreshAccommodations() => _loadAccommodations();

  Future<void> _loadAccommodations({bool notify = true}) async {
    final request = ++_accommodationRequest;
    try {
      final shared = _sharedAccommodationRepository;
      final accommodations =
          shared == null
              ? await _accommodationRepository!.getAccommodations()
              : (await shared.query(
                const AccommodationQuery(),
              )).map(_toAccommodation).toList(growable: false);
      if (_disposed || request != _accommodationRequest) return;
      _accommodations = accommodations;
      _errorMessage = null;
    } catch (_) {
      if (_disposed || request != _accommodationRequest) return;
      _errorMessage = 'No fue posible cargar los alojamientos.';
    }
    if (notify && !_disposed) notifyListeners();
  }

  Accommodation _toAccommodation(AccommodationRecord record) =>
      record.toAccommodation();

  University? _findUniversity(String? id) {
    if (id == null) return null;
    for (final university in _universities) {
      if (university.id == id) return university;
    }
    return null;
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_changesSubscription?.cancel());
    super.dispose();
  }
}
