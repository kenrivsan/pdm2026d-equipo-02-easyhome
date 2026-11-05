import 'package:easyhome/app/navigation/app_navigation.dart';
import 'package:easyhome/app/navigation/app_shell.dart';
import 'package:easyhome/features/accommodations/data/datasources/accommodation_data_source.dart';
import 'package:easyhome/features/accommodations/data/datasources/location_data_source.dart';
import 'package:easyhome/features/accommodations/data/repositories/accommodation_repository_impl.dart';
import 'package:easyhome/features/accommodations/data/repositories/location_repository_impl.dart';
import 'package:easyhome/features/accommodations/presentation/controllers/accommodation_search_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import '../features/accommodations/support/catalog_test_scope.dart';

Future<void> mountApp(WidgetTester tester) async {
  final controller = AccommodationSearchController(
    accommodationRepository: AccommodationRepositoryImpl(
      InMemoryAccommodationDataSource(),
    ),
    locationRepository: LocationRepositoryImpl(InMemoryLocationDataSource()),
  );
  addTearDown(controller.dispose);
  await controller.loadData();
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: controller,
      child: CatalogTestScope(
        controller: controller,
        child: const MaterialApp(home: AppShell()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('cada destino cambia la pestaña activa en el Notifier', (
    tester,
  ) async {
    await mountApp(tester);
    const destinations = [
      'Inicio',
      'Buscar',
      'Alojamientos',
      'Propietario',
      'Ajustes',
    ];
    const titles = [
      'Easy Home',
      'Buscar alojamiento',
      'Resultados de búsqueda',
      'Panel del propietario',
      'Ajustes: Próximamente',
    ];
    final container = riverpod.ProviderScope.containerOf(
      tester.element(find.byType(AppShell)),
    );
    for (var index = 0; index < destinations.length; index++) {
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(destinations[index]),
        ),
      );
      await tester.pumpAndSettle();
      expect(container.read(appNavigationProvider), AppTab.values[index]);
      expect(find.text(titles[index]), findsWidgets);
    }
  });

  testWidgets('Ver todos navega por provider sin agregar una ruta', (
    tester,
  ) async {
    await mountApp(tester);
    final button = find.text('Ver todos los alojamientos');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.text('Resultados de búsqueda'), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      2,
    );
    expect(
      Navigator.of(tester.element(find.byType(AppShell))).canPop(),
      isFalse,
    );
  });

  testWidgets('conserva el scroll del listado al cambiar de pestaña', (
    tester,
  ) async {
    await mountApp(tester);
    await tester.tap(find.text('Alojamientos'));
    await tester.pumpAndSettle();
    final scrollable = find.byType(Scrollable).first;
    final position = tester.state<ScrollableState>(scrollable).position;
    await tester.drag(scrollable, const Offset(0, -350));
    await tester.pumpAndSettle();
    final offset = position.pixels;
    expect(offset, greaterThan(0));
    await tester.tap(find.text('Ajustes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alojamientos'));
    await tester.pumpAndSettle();
    expect(
      tester.state<ScrollableState>(find.byType(Scrollable).first).position,
      same(position),
    );
    expect(position.pixels, offset);
  });
}
