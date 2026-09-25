import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:easyhome/features/accommodations/data/datasources/accommodation_data_source.dart';
import 'package:easyhome/features/accommodations/data/datasources/location_data_source.dart';
import 'package:easyhome/features/accommodations/data/repositories/accommodation_repository_impl.dart';
import 'package:easyhome/features/accommodations/data/repositories/location_repository_impl.dart';
import 'package:easyhome/features/accommodations/domain/entities/accommodation.dart';
import 'package:easyhome/features/accommodations/presentation/controllers/accommodation_search_controller.dart';
import 'package:easyhome/features/accommodations/presentation/pages/search_page.dart';

void main() {
  testWidgets(
    'completa el flujo principal del MVP de Easy Home',
    (WidgetTester tester) async {
      final controller = AccommodationSearchController(
        accommodationRepository: AccommodationRepositoryImpl(
          InMemoryAccommodationDataSource(),
        ),
        locationRepository: LocationRepositoryImpl(
          InMemoryLocationDataSource(),
        ),
      );

      addTearDown(controller.dispose);

      await controller.loadData();

      await tester.pumpWidget(
        ChangeNotifierProvider<AccommodationSearchController>.value(
          value: controller,
          child: const MaterialApp(
            home: SearchPage(),
          ),
        ),
      );

      // 1. Pantalla de búsqueda.
      expect(
        find.text('Buscar alojamiento'),
        findsOneWidget,
      );

      // 2. Seleccionar departamento.
      final searchDropdowns =
          find.byType(DropdownButtonFormField<String>);

      expect(searchDropdowns, findsNWidgets(2));

      await tester.tap(searchDropdowns.at(0));
      await tester.pumpAndSettle();

      await tester.tap(
        find.text('Quetzaltenango').last,
      );

      await tester.pumpAndSettle();

      // 3. Seleccionar universidad.
      await tester.tap(searchDropdowns.at(1));
      await tester.pumpAndSettle();

      await tester.tap(
        find.text('Universidad Mesoamericana').last,
      );

      await tester.pumpAndSettle();

      expect(
        controller.selectedDepartmentId,
        'quetzaltenango',
      );

      expect(
        controller.selectedUniversityId,
        'mesoamericana-quetzaltenango',
      );

      // 4. Abrir resultados.
      await tester.tap(
        find.text('Ver resultados'),
      );

      await tester.pumpAndSettle();

      expect(
        find.text('Resultados de búsqueda'),
        findsOneWidget,
      );

      expect(
        find.text('Apartamento para estudiantes'),
        findsOneWidget,
      );

      // 5. Aplicar filtro de tipo.
      final typeDropdown =
          find.byType(
            DropdownButtonFormField<AccommodationType?>,
          );

      await tester.tap(typeDropdown);
      await tester.pumpAndSettle();

      await tester.tap(
        find.text('Apartamento').last,
      );

      await tester.pumpAndSettle();

      expect(
        controller.selectedType,
        AccommodationType.apartment,
      );

      expect(
        find.text('Apartamento para estudiantes'),
        findsOneWidget,
      );

      // 6. Seleccionar alojamiento.
      await tester.tap(
        find.text('Apartamento para estudiantes'),
      );

      await tester.pumpAndSettle();

      // 7. Comprobar pantalla de detalle.
      expect(
        find.text('Detalle del alojamiento'),
        findsOneWidget,
      );

      expect(
        find.text('Zona 3, Quetzaltenango'),
        findsOneWidget,
      );

      expect(
        find.text('Disponible'),
        findsOneWidget,
      );

      expect(
        find.text('45 m²'),
        findsOneWidget,
      );

      expect(
        find.text('Persona anfitriona de ejemplo'),
        findsOneWidget,
      );

      expect(
        find.text('5555-0102'),
        findsOneWidget,
      );
    },
  );
}