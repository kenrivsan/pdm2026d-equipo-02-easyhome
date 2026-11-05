import 'package:easyhome/app/app.dart';
import 'package:easyhome/features/accommodations/data/datasources/accommodation_data_source.dart';
import 'package:easyhome/features/accommodations/data/repositories/shared_accommodation_repository_impl.dart';
import 'package:easyhome/features/accommodations/domain/entities/accommodation_query.dart';
import 'package:easyhome/features/accommodations/domain/entities/accommodation_record.dart';
import 'package:easyhome/features/accommodations/presentation/controllers/catalog_deletion_controller.dart';
import 'package:easyhome/features/accommodations/presentation/controllers/catalog_deletion_provider.dart';
import 'package:easyhome/features/accommodations/presentation/pages/results_page.dart';
import 'package:easyhome/features/accommodations/presentation/providers/shared_accommodation_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

base class _Preferences extends InMemorySharedPreferencesAsync {
  _Preferences() : super.empty();
  bool failWrite = false;
  @override
  Future<bool> setString(
    String key,
    String value,
    SharedPreferencesOptions options,
  ) async {
    if (failWrite) {
      failWrite = false;
      throw StateError('Fallo de escritura controlado');
    }
    return super.setString(key, value, options);
  }
}

void main() {
  late _Preferences preferences;
  final repositories = <SharedPreferencesAccommodationRepository>[];
  var seedLoads = 0;

  SharedPreferencesAccommodationRepository create() {
    final repository = SharedPreferencesAccommodationRepository(
      preferences: SharedPreferencesAsync(),
      storageKey: 'kenneth.integration.v1',
      loadInitialAccommodations: () async {
        seedLoads++;
        return (await InMemoryAccommodationDataSource().getAccommodations())
            .map(AccommodationRecord.fromAccommodation)
            .toList();
      },
    );
    repositories.add(repository);
    return repository;
  }

  setUp(() {
    preferences = _Preferences();
    SharedPreferencesAsyncPlatform.instance = preferences;
    repositories.clear();
    seedLoads = 0;
  });

  Future<void> mount(
    WidgetTester tester,
    SharedPreferencesAccommodationRepository repository,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedAccommodationRepositoryProvider.overrideWithValue(repository),
        ],
        child: const EasyHomeApp(),
      ),
    );
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 5),
    );
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'demo@ingenium.com');
    await tester.enterText(fields.at(1), 'EasyHome123');
    final login = find.widgetWithText(ElevatedButton, 'INICIAR SESIÓN');
    await tester.ensureVisible(login);
    await tester.tap(login);
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 5),
    );
    await tester.tap(find.text('Alojamientos'));
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 5),
    );
  }

  Future<void> swipe(WidgetTester tester, String id) async {
    final row = find.byWidgetPredicate(
      (widget) => widget is Dismissible && widget.key == ValueKey(id),
    );
    await tester.ensureVisible(row);
    await tester.drag(row, const Offset(-700, 0));
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 5),
    );
  }

  void appTest(String name, Future<void> Function(WidgetTester) body) {
    testWidgets(name, (tester) async {
      try {
        await body(tester);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        for (final repository in repositories) {
          await repository.dispose();
        }
      }
    });
  }

  appTest(
    'app usa el repositorio real para borrar, fallar al restaurar y reintentar',
    (tester) async {
      final repository = create();
      await mount(tester, repository);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(ResultsPage)),
      );
      expect(
        container.read(sharedAccommodationRepositoryProvider),
        same(repository),
      );
      final initial = await repository.query(const AccommodationQuery());
      final original = initial.firstWhere(
        (item) => item.id == 'apartment-quetzaltenango-1',
      );
      final deletionController =
          container.read(catalogDeletionControllerProvider)!;
      final events = <CatalogDeletionEvent<Object>>[];
      final subscription = deletionController.events.listen(events.add);
      addTearDown(subscription.cancel);
      await swipe(tester, original.id);
      expect(
        events.where((event) => event.kind == CatalogDeletionKind.deleted),
        hasLength(1),
      );
      final ticket =
          events
              .firstWhere((event) => event.kind == CatalogDeletionKind.deleted)
              .ticket!;
      expect(find.text(original.title), findsNothing);
      expect(
        (await repository.query(
          const AccommodationQuery(),
        )).any((item) => item.id == original.id),
        isFalse,
      );
      preferences.failWrite = true;
      await tester.tap(find.text('Deshacer'));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 5),
      );
      expect(find.text('No se pudo restaurar el alojamiento.'), findsOneWidget);
      expect(find.text(original.title), findsNothing);
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 5),
      );
      final restored = await repository.query(const AccommodationQuery());
      expect(
        restored,
        initial,
      ); // Igualdad de todos los campos y orden canónicos.
      expect(ticket.id, original.id);
      expect(find.text(original.title), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  appTest('escritura fallida desde el gesto no elimina la fila ni los datos', (
    tester,
  ) async {
    final repository = create();
    await mount(tester, repository);
    final before = await repository.query(const AccommodationQuery());
    preferences.failWrite = true;
    await swipe(tester, 'apartment-quetzaltenango-1');
    expect(find.text('No se pudo borrar el alojamiento.'), findsOneWidget);
    expect(find.text('Apartamento para estudiantes'), findsOneWidget);
    expect(await repository.query(const AccommodationQuery()), before);
  });

  appTest('app recreada conserva el borrado y no vuelve a sembrar', (
    tester,
  ) async {
    final first = create();
    await mount(tester, first);
    await swipe(tester, 'apartment-quetzaltenango-1');
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 5),
    );
    await first.dispose();
    final second = create();
    await mount(tester, second);
    expect(find.text('Apartamento para estudiantes'), findsNothing);
    expect(find.text('Pensionado cerca de la USAC'), findsOneWidget);
    expect(seedLoads, 1);
    expect(
      (await second.query(
        const AccommodationQuery(),
      )).any((item) => item.id == 'apartment-quetzaltenango-1'),
      isFalse,
    );
  });

  appTest(
    'alta confirmada en la fuente única aparece en catálogo y consulta onlyOwned',
    (tester) async {
      final repository = create();
      await mount(tester, repository);
      final template =
          (await repository.query(const AccommodationQuery())).first;
      final publication = AccommodationRecord(
        id: 'owner-real-1',
        title: 'Publicación compartida',
        type: template.type,
        location: template.location,
        departmentId: template.departmentId,
        universityIds: template.universityIds,
        monthlyPrice: template.monthlyPrice,
        description: 'Todos los datos originales',
        available: true,
        bathrooms: template.bathrooms,
        sizeSquareMeters: template.sizeSquareMeters,
        imageUrls: template.imageUrls,
        contactName: template.contactName,
        contactPhone: template.contactPhone,
        contactEmail: 'prueba@example.com',
        isOwned: true,
      );
      await repository.add(publication);
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 5),
      );
      expect(find.text(publication.title), findsOneWidget);
      expect(
        await repository.query(const AccommodationQuery(onlyOwned: true)),
        [publication],
      );
      expect(tester.takeException(), isNull);
    },
  );
}
