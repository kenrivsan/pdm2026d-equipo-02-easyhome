import 'package:flutter_test/flutter_test.dart';

import 'package:easyhome/features/accommodations/data/datasources/accommodation_data_source.dart';
import 'package:easyhome/features/accommodations/data/datasources/location_data_source.dart';
import 'package:easyhome/features/accommodations/data/repositories/accommodation_repository_impl.dart';
import 'package:easyhome/features/accommodations/data/repositories/location_repository_impl.dart';
import 'package:easyhome/features/accommodations/domain/entities/accommodation.dart';
import 'package:easyhome/features/accommodations/presentation/controllers/accommodation_search_controller.dart';

void main() {
  late AccommodationSearchController controller;

  setUp(() {
    controller = AccommodationSearchController(
      accommodationRepository: AccommodationRepositoryImpl(
        InMemoryAccommodationDataSource(),
      ),
      locationRepository: LocationRepositoryImpl(InMemoryLocationDataSource()),
    );
  });

  tearDown(() => controller.dispose());

  test(
    'carga catálogos y muestra únicamente alojamientos disponibles',
    () async {
      await controller.loadData();

      expect(controller.departments, hasLength(2));
      expect(controller.universities, hasLength(2));
      expect(controller.filteredAccommodations, hasLength(2));
      expect(controller.errorMessage, isNull);
      expect(controller.isLoading, isFalse);
    },
  );

  test('combina filtros de departamento, universidad y tipo', () async {
    await controller.loadData();

    controller.selectDepartment('quetzaltenango');
    controller.selectUniversity('mesoamericana-quetzaltenango');
    controller.selectType(AccommodationType.apartment);

    expect(controller.filteredAccommodations, hasLength(1));
    expect(
      controller.filteredAccommodations.single.id,
      'apartment-quetzaltenango-1',
    );
  });

  test('limpia la universidad cuando cambia a otro departamento', () async {
    await controller.loadData();

    controller.selectUniversity('mesoamericana-quetzaltenango');
    controller.selectDepartment('guatemala');

    expect(controller.selectedDepartmentId, 'guatemala');
    expect(controller.selectedUniversityId, isNull);
  });

  test(
    'encuentra el alojamiento por ID para la navegación a detalle',
    () async {
      await controller.loadData();

      final accommodation = controller.findAccommodationById(
        'room-guatemala-1',
      );

      expect(accommodation?.title, 'Pensionado cerca de la USAC');
    },
  );
}
