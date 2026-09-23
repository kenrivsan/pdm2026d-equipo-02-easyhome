
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:easyhome/features/accommodations/data/datasources/accommodation_data_source.dart';
import 'package:easyhome/features/accommodations/data/datasources/location_data_source.dart';
import 'package:easyhome/features/accommodations/data/repositories/accommodation_repository_impl.dart';
import 'package:easyhome/features/accommodations/data/repositories/location_repository_impl.dart';
import 'package:easyhome/features/accommodations/domain/entities/accommodation.dart';
import 'package:easyhome/features/accommodations/presentation/controllers/accommodation_search_controller.dart';
import 'package:easyhome/features/accommodations/presentation/pages/results_page.dart';

void main() {
  testWidgets(
    'muestra un mensaje cuando no hay alojamientos disponibles',
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

      controller.selectDepartment('guatemala');
      controller.selectUniversity('usac-central');
      controller.selectType(AccommodationType.apartment);

      expect(controller.filteredAccommodations, isEmpty);

      await tester.pumpWidget(
        ChangeNotifierProvider<AccommodationSearchController>.value(
          value: controller,
          child: const MaterialApp(
            home: ResultsPage(),
          ),
        ),
      );

      expect(
        find.text(
          'No se encontraron alojamientos disponibles para esta búsqueda.',
        ),
        findsOneWidget,
      );
    },
  );
}