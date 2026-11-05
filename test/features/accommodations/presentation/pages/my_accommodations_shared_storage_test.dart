import 'package:easyhome/features/accommodations/data/repositories/shared_accommodation_repository_impl.dart';
import 'package:easyhome/features/accommodations/domain/entities/accommodation_query.dart';
import 'package:easyhome/features/accommodations/presentation/pages/my_accommodations_page.dart';
import 'package:easyhome/features/accommodations/presentation/providers/shared_accommodation_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../support/fake_owner_shared_repository.dart';

void main() {
  testWidgets('alta, baja y Deshacer comparten datos con el catálogo real', (
    tester,
  ) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final first = ownerRecord('primero');
    final second = ownerRecord('segundo');
    final outsider = ownerRecord('catalogo', isOwned: false);
    final repository = SharedPreferencesAccommodationRepository(
      preferences: SharedPreferencesAsync(),
      storageKey: 'test.owner.integration.v1',
      loadInitialAccommodations: () async => [first, second, outsider],
    );
    try {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedAccommodationRepositoryProvider.overrideWithValue(repository),
          ],
          child: const MaterialApp(home: MyAccommodationsPage()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Casa primero'), findsOneWidget);
      expect(find.text('Casa segundo'), findsOneWidget);
      expect(find.text('Casa catalogo'), findsNothing);

      final added = ownerRecord('nuevo');
      await repository.add(added);
      await tester.pumpAndSettle();
      expect(find.text('Casa nuevo'), findsOneWidget);
      expect(
        (await repository.query(const AccommodationQuery())).map((r) => r.id),
        ['primero', 'segundo', 'catalogo', 'nuevo'],
      );

      final row = find.byWidgetPredicate(
        (widget) => widget is Dismissible && widget.key == ValueKey(second.id),
      );
      await tester.ensureVisible(row);
      await tester.drag(row, const Offset(-700, 0));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.text('Casa segundo'), findsNothing);
      expect(
        (await repository.query(
          const AccommodationQuery(onlyOwned: true),
        )).map((r) => r.id),
        ['primero', 'nuevo'],
      );
      await tester.tap(find.text('Deshacer'));
      await tester.pumpAndSettle();
      final restored = await repository.query(const AccommodationQuery());
      expect(restored.map((r) => r.id), [
        'primero',
        'segundo',
        'catalogo',
        'nuevo',
      ]);
      expect(restored[1], second);
      expect(find.text('Casa segundo'), findsOneWidget);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await repository.dispose();
    }
  });

  test(
    'eliminación y restauración sobreviven a recrear el repositorio',
    () async {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      final original = ownerRecord('persistente');
      var seedLoads = 0;
      SharedPreferencesAccommodationRepository create() =>
          SharedPreferencesAccommodationRepository(
            preferences: SharedPreferencesAsync(),
            storageKey: 'test.owner.recreated.v1',
            loadInitialAccommodations: () async {
              seedLoads++;
              return [original];
            },
          );

      var repository = create();
      final deleted = await repository.deleteById(original.id);
      await repository.dispose();
      repository = create();
      expect(
        await repository.query(const AccommodationQuery(onlyOwned: true)),
        isEmpty,
      );
      await repository.restore(deleted);
      await repository.dispose();
      repository = create();
      expect(
        (await repository.query(
          const AccommodationQuery(onlyOwned: true),
        )).single,
        original,
      );
      expect(seedLoads, 1);
      await repository.dispose();
    },
  );
}
