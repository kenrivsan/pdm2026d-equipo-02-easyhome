import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'dart:async';

import 'package:easyhome/app/app.dart';
import 'package:easyhome/app/navigation/app_shell.dart';
import 'package:easyhome/features/accommodations/data/datasources/accommodation_data_source.dart';
import 'package:easyhome/features/accommodations/data/datasources/location_data_source.dart';
import 'package:easyhome/features/accommodations/data/repositories/location_repository_impl.dart';
import 'package:easyhome/features/accommodations/domain/entities/accommodation.dart';
import 'package:easyhome/features/accommodations/domain/repositories/accommodation_repository.dart';
import 'package:easyhome/features/accommodations/presentation/controllers/accommodation_search_controller.dart';
import 'package:easyhome/features/accommodations/presentation/controllers/catalog_providers.dart';
import 'package:easyhome/features/accommodations/presentation/pages/results_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../support/catalog_test_scope.dart';

class _ControlledRepository implements AccommodationRepository {
  int calls = 0;
  bool failNext = false;
  Completer<List<Accommodation>>? pending;

  @override
  Future<List<Accommodation>> getAccommodations() async {
    calls++;
    if (failNext) {
      failNext = false;
      throw Exception('Fallo controlado');
    }
    return pending?.future ??
        InMemoryAccommodationDataSource().getAccommodations();
  }
}

void main() {
  late _ControlledRepository repository;
  late AccommodationSearchController controller;

  setUp(() async {
    repository = _ControlledRepository();
    controller = AccommodationSearchController(
      accommodationRepository: repository,
      locationRepository: LocationRepositoryImpl(InMemoryLocationDataSource()),
    );
    await controller.loadData();
  });
  tearDown(() => controller.dispose());

  Future<void> mount(WidgetTester tester, {bool shell = false}) async {
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: controller,
        child: CatalogTestScope(
          controller: controller,
          child: MaterialApp(
            home: shell ? const AppShell() : const ResultsPage(),
          ),
        ),
      ),
    );
  }

  testWidgets(
    'ResultsPage muestra carga y datos al completarse el repositorio',
    (tester) async {
      final pending = Completer<List<Accommodation>>();
      repository.pending = pending;
      await mount(tester);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      pending.complete(
        await InMemoryAccommodationDataSource().getAccommodations(),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Apartamento para estudiantes'), findsOneWidget);
      expect(find.text('Pensionado cerca de la USAC'), findsOneWidget);
    },
  );

  testWidgets('ResultsPage reintenta un error sin consultar automáticamente', (
    tester,
  ) async {
    repository.failNext = true;
    await mount(tester);
    await tester.pumpAndSettle();
    expect(
      find.text('No fue posible cargar los alojamientos.'),
      findsOneWidget,
    );
    final calls = repository.calls;
    await tester.pump(const Duration(seconds: 2));
    expect(repository.calls, calls);
    await tester.ensureVisible(find.text('Reintentar'));
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('Apartamento para estudiantes'), findsOneWidget);
    expect(find.text('Reintentar'), findsNothing);
    expect(repository.calls, calls + 1);
  });

  testWidgets('cambiar departamento limpia universidad y mantiene tipo', (
    tester,
  ) async {
    controller.selectUniversity('mesoamericana-quetzaltenango');
    controller.selectType(AccommodationType.apartment);
    await mount(tester);
    await tester.pumpAndSettle();
    final department = find.byKey(
      const ValueKey('catalog-department-quetzaltenango'),
    );
    await tester.ensureVisible(department);
    await tester.tap(department);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guatemala').last);
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ResultsPage)),
    );
    final filter = container.read(catalogFilterProvider);
    expect(filter.universityId, isNull);
    expect(filter.departmentId, 'guatemala');
    expect(filter.type, AccommodationType.apartment);
    expect(controller.selectedUniversityId, isNull);
    expect(
      find.text(
        'No se encontraron alojamientos disponibles para esta búsqueda.',
      ),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text('Limpiar filtros'));
    await tester.tap(find.text('Limpiar filtros'));
    await tester.pumpAndSettle();
    expect(container.read(catalogFilterProvider).isEmpty, isTrue);
    expect(controller.selectedDepartmentId, isNull);
    expect(find.text('Apartamento para estudiantes'), findsOneWidget);
  });

  testWidgets(
    'Buscar entrega departamento y universidad al catálogo sin recargas extra por pestaña',
    (tester) async {
      await mount(tester, shell: true);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Buscar'));
      await tester.pumpAndSettle();
      controller.selectUniversity('mesoamericana-quetzaltenango');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ver resultados'));
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(ResultsPage)),
      );
      expect(
        container.read(catalogFilterProvider).universityId,
        'mesoamericana-quetzaltenango',
      );
      expect(find.text('Apartamento para estudiantes'), findsOneWidget);
      expect(find.text('Pensionado cerca de la USAC'), findsNothing);
      final calls = repository.calls;
      await tester.tap(find.text('Ajustes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Alojamientos'));
      await tester.pumpAndSettle();
      expect(repository.calls, calls);
    },
  );

  testWidgets('la composición real permite entrar y consultar el catálogo', (
    tester,
  ) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    await tester.pumpWidget(const EasyHomeApp());
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'demo@ingenium.com');
    await tester.enterText(fields.at(1), 'EasyHome123');
    final loginButton = find.widgetWithText(ElevatedButton, 'INICIAR SESIÓN');
    await tester.ensureVisible(loginButton);
    await tester.tap(loginButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alojamientos'));
    await tester.pumpAndSettle();
    expect(find.text('Apartamento para estudiantes'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
