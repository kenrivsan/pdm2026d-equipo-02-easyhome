import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:easyhome/features/accommodations/data/datasources/accommodation_data_source.dart';
import 'package:easyhome/features/accommodations/data/datasources/location_data_source.dart';
import 'package:easyhome/features/accommodations/data/repositories/location_repository_impl.dart';
import 'package:easyhome/features/accommodations/domain/entities/accommodation.dart';
import 'package:easyhome/features/accommodations/domain/repositories/accommodation_repository.dart';
import 'package:easyhome/features/accommodations/presentation/controllers/accommodation_search_controller.dart';
import 'package:easyhome/features/accommodations/presentation/pages/results_page.dart';

/// Pruebas preliminares para el issue #28.
/// Estas verifican solo lo disponible en main tras integrar PR #30.
/// No sustituyen las pruebas de Dismissible, Deshacer o persistencia.
void main() {
  late _CountingAccommodationRepository repository;
  late AccommodationSearchController controller;

  setUp(() {
    repository = _CountingAccommodationRepository();
    controller = _makeController(repository);
  });

  tearDown(() => controller.dispose());

  testWidgets('filtro Todos, Apartamento y Pensionado cambia las tarjetas', (
    tester,
  ) async {
    await controller.loadData();
    await _showResults(tester, controller);

    expect(find.text('Apartamento para estudiantes'), findsOneWidget);
    expect(find.text('Pensionado cerca de la USAC'), findsOneWidget);

    await _selectType(tester, 'Apartamento');
    expect(controller.selectedType, AccommodationType.apartment);
    expect(find.text('Apartamento para estudiantes'), findsOneWidget);
    expect(find.text('Pensionado cerca de la USAC'), findsNothing);

    await _selectType(tester, 'Pensionado');
    expect(controller.selectedType, AccommodationType.boardingHouse);
    expect(find.text('Pensionado cerca de la USAC'), findsOneWidget);
    expect(find.text('Apartamento para estudiantes'), findsNothing);

    await _selectType(tester, 'Todos');
    expect(controller.selectedType, isNull);
    expect(find.text('Apartamento para estudiantes'), findsOneWidget);
    expect(find.text('Pensionado cerca de la USAC'), findsOneWidget);
  });

  testWidgets('combinacion de filtros sin coincidencias muestra estado vacio', (
    tester,
  ) async {
    await controller.loadData();
    controller.selectDepartment('guatemala');
    controller.selectUniversity('usac-central');
    await _showResults(tester, controller);

    await _selectType(tester, 'Apartamento');

    expect(controller.filteredAccommodations, isEmpty);
    expect(
      find.text(
        'No se encontraron alojamientos disponibles para esta búsqueda.',
      ),
      findsOneWidget,
    );
  });

  test('carga fallida se recupera al reintentar en el controlador', () async {
    final failedOnce = _FailOnceAccommodationRepository();
    final retryController = _makeController(failedOnce);
    addTearDown(retryController.dispose);

    await retryController.loadData();
    expect(retryController.errorMessage, isNotNull);
    expect(retryController.isLoading, isFalse);
    expect(retryController.filteredAccommodations, isEmpty);

    await retryController.loadData();
    expect(retryController.errorMessage, isNull);
    expect(retryController.isLoading, isFalse);
    expect(retryController.filteredAccommodations, hasLength(2));
    expect(failedOnce.calls, 2);
  });

  testWidgets('reconstruir la pantalla y repetir filtro no hace carga extra', (
    tester,
  ) async {
    await controller.loadData();
    expect(repository.calls, 1);

    await _showResults(tester, controller);
    await tester.pumpWidget(const SizedBox.shrink());
    await _showResults(tester, controller);
    expect(repository.calls, 1);

    controller.selectType(AccommodationType.apartment);
    controller.selectType(AccommodationType.apartment);
    await tester.pumpAndSettle();
    expect(repository.calls, 1);
  });
}

AccommodationSearchController _makeController(
  AccommodationRepository repository,
) {
  return AccommodationSearchController(
    accommodationRepository: repository,
    locationRepository: LocationRepositoryImpl(InMemoryLocationDataSource()),
  );
}

Future<void> _showResults(
  WidgetTester tester,
  AccommodationSearchController controller,
) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<AccommodationSearchController>.value(
      value: controller,
      child: const MaterialApp(home: ResultsPage()),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _selectType(WidgetTester tester, String label) async {
  final dropdown = find.byType(DropdownButtonFormField<AccommodationType?>);
  await tester.ensureVisible(dropdown);
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

class _CountingAccommodationRepository implements AccommodationRepository {
  final InMemoryAccommodationDataSource _source =
      InMemoryAccommodationDataSource();
  int calls = 0;

  @override
  Future<List<Accommodation>> getAccommodations() async {
    calls++;
    return _source.getAccommodations();
  }
}

class _FailOnceAccommodationRepository implements AccommodationRepository {
  final InMemoryAccommodationDataSource _source =
      InMemoryAccommodationDataSource();
  int calls = 0;

  @override
  Future<List<Accommodation>> getAccommodations() async {
    calls++;
    if (calls == 1) {
      throw StateError('Fallo simulado de conexion');
    }
    return _source.getAccommodations();
  }
}
