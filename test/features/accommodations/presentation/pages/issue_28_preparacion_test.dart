import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:easyhome/features/accommodations/presentation/controllers/catalog_providers.dart';
import 'package:easyhome/features/accommodations/domain/entities/catalog_filter.dart';
import '../../support/catalog_test_scope.dart';

import 'package:easyhome/features/accommodations/data/datasources/accommodation_data_source.dart';
import 'package:easyhome/features/accommodations/data/datasources/location_data_source.dart';
import 'package:easyhome/features/accommodations/data/repositories/location_repository_impl.dart';
import 'package:easyhome/features/accommodations/domain/entities/accommodation.dart';
import 'package:easyhome/features/accommodations/domain/repositories/accommodation_repository.dart';
import 'package:easyhome/features/accommodations/presentation/controllers/accommodation_search_controller.dart';
import 'package:easyhome/features/accommodations/presentation/pages/results_page.dart';

/// Pruebas de Víctor adaptadas al catálogo reactivo del issue #28.
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
    expect(_filter(tester).type, AccommodationType.apartment);
    expect(find.text('Apartamento para estudiantes'), findsOneWidget);
    expect(find.text('Pensionado cerca de la USAC'), findsNothing);

    await _selectType(tester, 'Pensionado');
    expect(_filter(tester).type, AccommodationType.boardingHouse);
    expect(find.text('Pensionado cerca de la USAC'), findsOneWidget);
    expect(find.text('Apartamento para estudiantes'), findsNothing);

    await _selectType(tester, 'Todos');
    expect(_filter(tester).type, isNull);
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

    expect(
      ProviderScope.containerOf(
        tester.element(find.byType(ResultsPage)),
      ).read(catalogResultsProvider).requireValue,
      isEmpty,
    );
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
    expect(
      repository.calls,
      2,
    ); // Carga previa del MVP y consulta del catálogo.
    await _selectType(tester, 'Apartamento');
    expect(repository.calls, 3);
    await _showResults(tester, controller);
    expect(repository.calls, 3);

    await _selectType(tester, 'Apartamento');
    await tester.pumpAndSettle();
    expect(repository.calls, 3);
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
      child: CatalogTestScope(
        controller: controller,
        child: const MaterialApp(home: ResultsPage()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

CatalogFilter _filter(WidgetTester tester) => ProviderScope.containerOf(
  tester.element(find.byType(ResultsPage)),
).read(catalogFilterProvider);

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
