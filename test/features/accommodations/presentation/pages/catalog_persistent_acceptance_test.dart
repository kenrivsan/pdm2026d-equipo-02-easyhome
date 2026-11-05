import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:easyhome/app/app.dart';
import 'package:easyhome/features/accommodations/data/repositories/shared_accommodation_repository_impl.dart';
import 'package:easyhome/features/accommodations/data/repositories/shared_catalog_reader.dart';
import 'package:easyhome/features/accommodations/domain/entities/accommodation.dart';
import 'package:easyhome/features/accommodations/domain/entities/accommodation_query.dart';
import 'package:easyhome/features/accommodations/domain/entities/accommodation_record.dart';
import 'package:easyhome/features/accommodations/domain/entities/deleted_accommodation.dart';
import 'package:easyhome/features/accommodations/domain/entities/catalog_filter.dart';
import 'package:easyhome/features/accommodations/presentation/controllers/catalog_deletion_controller.dart';
import 'package:easyhome/features/accommodations/presentation/controllers/catalog_deletion_provider.dart';
import 'package:easyhome/features/accommodations/presentation/controllers/catalog_providers.dart';
import 'package:easyhome/features/accommodations/presentation/pages/accommodation_detail_page.dart';
import 'package:easyhome/features/accommodations/presentation/pages/results_page.dart';
import 'package:easyhome/features/accommodations/presentation/providers/shared_accommodation_providers.dart';
import 'package:easyhome/features/accommodations/presentation/widgets/catalog_undo_host.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// Complementa QA01..QA07 de Víctor sin sustituir sus fuentes falsas.
/// EasyHomeApp usa sus providers/controller/reader productivos. Las escrituras,
/// tokens, secuencias y JSON son del repositorio real. Solo se controlan el
/// backend de preferencias y tiempos/fallos de consulta en la subclase observada.
/// El último caso usa archivo; ninguno equivale a cerrar un navegador real.
void main() {
  late _Preferences preferences;
  late _ObservedRepository repository;
  SharedPreferencesAsyncPlatform? previousPlatform;
  final repositories = <_ObservedRepository>[];
  var seedLoads = 0;

  _ObservedRepository create() {
    final instance = _ObservedRepository(() async {
      seedLoads++;
      return _records;
    });
    repositories.add(instance);
    return instance;
  }

  setUp(() {
    previousPlatform = SharedPreferencesAsyncPlatform.instance;
    preferences = _Preferences();
    SharedPreferencesAsyncPlatform.instance = preferences;
    seedLoads = 0;
    repositories.clear();
  });

  Future<void> settle(WidgetTester tester) => tester.pumpAndSettle(
    const Duration(milliseconds: 100),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 5),
  );

  void appTest(String name, Future<void> Function(WidgetTester) body) {
    testWidgets(name, (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      // Crear la cola asíncrona dentro de la zona de testWidgets, no en setUp.
      repository = create();
      try {
        await body(tester);
      } finally {
        // Desmontar providers antes de cerrar sus streams evita un cierre
        // pendiente por listeners activos; también cubre aserciones fallidas.
        preferences.writeGate?.completeIfPending();
        for (final instance in repositories) {
          instance.queryGate?.completeIfPending();
        }
        await tester.pumpWidget(const SizedBox.shrink());
        await settle(tester);
        for (final instance in repositories) {
          await instance.dispose();
        }
        SharedPreferencesAsyncPlatform.instance = previousPlatform;
      }
    });
  }

  Future<void> mount(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedAccommodationRepositoryProvider.overrideWithValue(repository),
        ],
        child: const EasyHomeApp(),
      ),
    );
    await settle(tester);
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'demo@ingenium.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'EasyHome123');
    final login = find.widgetWithText(ElevatedButton, 'INICIAR SESIÓN');
    await tester.ensureVisible(login);
    await tester.tap(login);
    await settle(tester);
    await tester.tap(find.text('Alojamientos'));
    await settle(tester);
  }

  ProviderContainer container(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(ResultsPage)));

  CatalogDeletionController<Object> deletion(WidgetTester tester) =>
      container(tester).read(catalogDeletionControllerProvider)!;

  State host(WidgetTester tester) =>
      tester.state(find.byType(CatalogUndoHost<Object>));

  List<String> ids(WidgetTester tester) =>
      tester
          .widgetList<Dismissible>(find.byType(Dismissible))
          .where((widget) => widget.key is ValueKey<String>)
          .map((widget) => (widget.key! as ValueKey<String>).value)
          .toList();

  Future<void> swipe(WidgetTester tester, String id) async {
    final row = find.byWidgetPredicate(
      (widget) => widget is Dismissible && widget.key == ValueKey(id),
    );
    await tester.ensureVisible(row);
    await tester.drag(row, const Offset(-700, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
  }

  appTest('REAL01 filtros combinados y reconstruccion sin consultas extra', (
    tester,
  ) async {
    await mount(tester);
    expect(ids(tester), ['a', 'b', 'c', 'd', 'e']);
    expect(
      container(tester).read(sharedAccommodationRepositoryProvider),
      same(repository),
    );
    final originalController = deletion(tester);
    final originalHost = host(tester);
    const combined = CatalogFilter(
      type: AccommodationType.apartment,
      departmentId: 'quetzaltenango',
      universityId: 'mesoamericana-quetzaltenango',
    );
    final filter = container(tester).read(catalogFilterProvider.notifier);
    filter.setFilter(combined);
    await settle(tester);
    expect(ids(tester), ['a', 'c', 'e']);
    final calls = repository.queries.length;
    filter.setFilter(combined);
    tester.element(find.byType(ResultsPage)).markNeedsBuild();
    await settle(tester);
    await tester.tap(find.text('Ajustes'));
    await settle(tester);
    await tester.tap(find.text('Alojamientos'));
    await settle(tester);
    expect(repository.queries, hasLength(calls));
    expect(deletion(tester), same(originalController));
    expect(host(tester), same(originalHost));
    expect(seedLoads, 1);
  });

  appTest('REAL02 detalle y scroll conservados sobre la fuente compartida', (
    tester,
  ) async {
    await mount(tester);
    final scroll =
        find
            .descendant(
              of: find.byType(ResultsPage),
              matching: find.byType(Scrollable),
            )
            .first;
    final position = tester.state<ScrollableState>(scroll).position;
    await tester.drag(scroll, const Offset(0, -400));
    await settle(tester);
    final offset = position.pixels;
    expect(offset, greaterThan(0));
    await tester.tap(find.text('Ajustes'));
    await settle(tester);
    await tester.tap(find.text('Alojamientos'));
    await settle(tester);
    expect(tester.state<ScrollableState>(scroll).position, same(position));
    expect(position.pixels, offset);
    await tester.ensureVisible(find.text('Aceptación a'));
    await tester.tap(find.text('Aceptación a'));
    await settle(tester);
    final detail = tester.widget<AccommodationDetailPage>(
      find.byType(AccommodationDetailPage),
    );
    final original = (await repository.committed()).first;
    expect(
      AccommodationRecord.fromAccommodation(detail.accommodation),
      original,
    );
    await tester.pageBack();
    await settle(tester);
    expect(find.byType(ResultsPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  appTest('REAL03 QA01/04/06 borrados filtrados, snapshots y orden global', (
    tester,
  ) async {
    await mount(tester);
    final before = await repository.committed();
    container(tester)
        .read(catalogFilterProvider.notifier)
        .selectType(AccommodationType.apartment);
    await settle(tester);
    expect(ids(tester), ['a', 'c', 'e']);
    await swipe(tester, 'c');
    await settle(tester);
    await swipe(tester, 'a');
    await settle(tester);
    await deletion(tester).deleteById('c');
    expect(repository.deleteRequests, ['c', 'a']);
    expect(ids(tester), ['e']);
    expect(repository.snapshots.map((s) => s.sequence), [2, 0]);
    await tester.tap(find.text('Deshacer'));
    await settle(tester);
    await tester.tap(find.text('Deshacer'));
    await settle(tester);
    expect(await repository.committed(), before);
    expect(ids(tester), ['a', 'c', 'e']);
    expect(repository.restores, hasLength(2));
    for (var i = 0; i < 2; i++) {
      expect(repository.restores[i], same(repository.snapshots[i]));
      expect(repository.restores[i].record, before[i == 0 ? 2 : 0]);
    }
  });

  appTest(
    'REAL04 QA02/07 escritura lenta, doble gesto y filtro durante commit',
    (tester) async {
      await mount(tester);
      final originalController = deletion(tester);
      final originalHost = host(tester);
      preferences.writeGate = Completer<void>();
      final row = find.byWidgetPredicate(
        (widget) => widget is Dismissible && widget.key == const ValueKey('a'),
      );
      await tester.ensureVisible(row);
      final gesturePosition = tester.getCenter(row);
      await swipe(tester, 'a');
      // Repetir el gesto en la misma posición mientras la fila está bloqueada.
      await tester.dragFrom(gesturePosition, const Offset(-700, 0));
      await tester.pump(const Duration(milliseconds: 400));
      expect(repository.deleteRequests, ['a']);
      expect(ids(tester), contains('a'));
      expect((await repository.committed()).any((r) => r.id == 'a'), isTrue);
      expect(find.text('Deshacer'), findsNothing);
      container(tester)
          .read(catalogFilterProvider.notifier)
          .selectType(AccommodationType.boardingHouse);
      await settle(tester);
      expect(ids(tester), ['b', 'd']);
      preferences.writeGate!.complete();
      await settle(tester);
      expect(host(tester), same(originalHost));
      expect(deletion(tester), same(originalController));
      expect((await repository.committed()).any((r) => r.id == 'a'), isFalse);
      await tester.tap(find.text('Deshacer'));
      await settle(tester);
      expect(ids(tester), ['b', 'd']);
      expect(await repository.committed(), _records);
    },
  );

  appTest('REAL05 QA03/05 falla escritura y Reintentar usa snapshot original', (
    tester,
  ) async {
    await mount(tester);
    final before = await repository.committed();
    preferences.failWrite = true;
    await swipe(tester, 'c');
    await settle(tester);
    expect(find.text('No se pudo borrar el alojamiento.'), findsOneWidget);
    expect(await repository.committed(), before);
    expect(ids(tester), contains('c'));
    await tester.pump(const Duration(seconds: 6));
    await settle(tester);
    await swipe(tester, 'c');
    await settle(tester);
    preferences.failWrite = true;
    await tester.tap(find.text('Deshacer'));
    await settle(tester);
    expect(find.text('No se pudo restaurar el alojamiento.'), findsOneWidget);
    expect(find.text('Alojamiento restaurado.'), findsNothing);
    expect(ids(tester), isNot(contains('c')));
    await tester.tap(find.text('Reintentar'));
    await settle(tester);
    expect(repository.restores, hasLength(2));
    expect(repository.restores.first, same(repository.snapshots.single));
    expect(repository.restores.last, same(repository.snapshots.single));
    expect(await repository.committed(), before);
    expect(deletion(tester).isLocked('c'), isFalse);
  });

  appTest('REAL06 host conserva su identidad en carga, error, vacio y datos', (
    tester,
  ) async {
    await mount(tester);
    await swipe(tester, 'c');
    await settle(tester);
    final originalHost = host(tester);
    final originalController = deletion(tester);
    final scope = container(tester);
    repository.queryGate = Completer<void>();
    scope.invalidate(catalogResultsProvider);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(host(tester), same(originalHost));
    repository.queryGate!.completeError(
      StateError('Consulta controlada fallida'),
    );
    await settle(tester);
    expect(
      find.text('No fue posible cargar los alojamientos.'),
      findsOneWidget,
    );
    expect(host(tester), same(originalHost));
    repository.queryGate = null;
    final retry = find.widgetWithText(FilledButton, 'Reintentar');
    await tester.ensureVisible(retry);
    await tester.tap(retry);
    await settle(tester);
    expect(ids(tester), contains('a'));
    scope
        .read(catalogFilterProvider.notifier)
        .setFilter(
          const CatalogFilter(
            type: AccommodationType.apartment,
            departmentId: 'guatemala',
            universityId: 'usac-central',
          ),
        );
    await settle(tester);
    expect(ids(tester), isEmpty);
    expect(find.text('Limpiar filtros'), findsOneWidget);
    expect(find.text('Deshacer'), findsOneWidget);
    expect(host(tester), same(originalHost));
    await tester.tap(find.text('Deshacer'));
    await settle(tester);
    expect(ids(tester), isEmpty);
    expect(deletion(tester), same(originalController));
    await tester.ensureVisible(find.text('Limpiar filtros'));
    await tester.tap(find.text('Limpiar filtros'));
    await settle(tester);
    expect(ids(tester), ['a', 'b', 'c', 'd', 'e']);
    expect(host(tester), same(originalHost));
  });

  appTest(
    'REAL07 expiracion y desmontaje con escritura pendiente no duplican',
    (tester) async {
      await mount(tester);
      final oldController = deletion(tester);
      await swipe(tester, 'a');
      await settle(tester);
      await tester.pump(const Duration(seconds: 6));
      await settle(tester);
      expect(oldController.isLocked('a'), isFalse);
      expect(repository.restores, isEmpty);
      preferences.writeGate = Completer<void>();
      await swipe(tester, 'c');
      await tester.pumpWidget(const SizedBox.shrink());
      preferences.writeGate!.complete();
      await settle(tester);
      expect(repository.deleteRequests, ['a', 'c']);
      await mount(tester);
      expect(deletion(tester), isNot(same(oldController)));
      expect(ids(tester), ['b', 'd', 'e']);
      expect(seedLoads, 1);
      expect(tester.takeException(), isNull);
    },
  );

  // E/S real en una prueba asíncrona normal: no mezclar la zona de reloj falso
  // de testWidgets con archivos del SO. La interacción de UI se prueba arriba.
  test(
    'REAL08 archivo: controller y lector conservan datos tras recreacion',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'easyhome-acceptance-',
      );
      final file = File('${directory.path}/preferences.json');
      SharedPreferencesAsyncPlatform.instance = _FilePreferences(file);
      repository = create();
      final controller = CatalogDeletionController<DeletedAccommodation>(
        deleteById: repository.deleteById,
        restore: repository.restore,
      );
      final events = <CatalogDeletionEvent<DeletedAccommodation>>[];
      final subscription = controller.events.listen(events.add);
      var controllerDisposed = false;
      try {
        final reader = SharedCatalogReader(repository);
        final before = await repository.committed();
        await controller.deleteById('c');
        await Future<void>.delayed(Duration.zero);
        await controller.undo(events.single.ticket!);
        expect(repository.restores.single, same(repository.snapshots.single));
        expect(await repository.committed(), before);
        await controller.deleteById('a');
        expect((await reader.query(const CatalogFilter())).map((r) => r.id), [
          'b',
          'c',
          'd',
          'e',
        ]);
        controller.dispose();
        controllerDisposed = true;
        await subscription.cancel();
        await repository.dispose();
        SharedPreferencesAsyncPlatform.instance = _FilePreferences(file);
        repository = create();
        final reopenedReader = SharedCatalogReader(repository);
        expect(
          await repository.committed(),
          _records.where((r) => r.id != 'a').toList(),
        );
        expect(
          (await reopenedReader.query(const CatalogFilter())).map((r) => r.id),
          ['b', 'c', 'd', 'e'],
        );
        expect(seedLoads, 1);
        expect(await file.readAsString(), contains('description'));
      } finally {
        if (!controllerDisposed) controller.dispose();
        await subscription.cancel();
        for (final instance in repositories) {
          await instance.dispose();
        }
        SharedPreferencesAsyncPlatform.instance = previousPlatform;
        await directory.delete(recursive: true);
      }
    },
  );
}

/// Instrumentación: todas las operaciones normales delegan a la implementación
/// productiva. La compuerta de query solo inyecta carga/error para probar la UI.
class _ObservedRepository extends SharedPreferencesAccommodationRepository {
  _ObservedRepository(InitialAccommodationLoader load)
    : super(
        preferences: SharedPreferencesAsync(),
        loadInitialAccommodations: load,
        storageKey: 'acceptance.catalog.real.v1',
      );

  final queries = <AccommodationQuery>[];
  final deleteRequests = <String>[];
  final snapshots = <DeletedAccommodation>[];
  final restores = <DeletedAccommodation>[];
  Completer<void>? queryGate;

  Future<List<AccommodationRecord>> committed() =>
      super.query(const AccommodationQuery());

  @override
  Future<List<AccommodationRecord>> query(AccommodationQuery filter) async {
    queries.add(filter);
    if (queryGate != null) await queryGate!.future;
    return super.query(filter);
  }

  @override
  Future<DeletedAccommodation> deleteById(String id) async {
    deleteRequests.add(id);
    final snapshot = await super.deleteById(id);
    snapshots.add(snapshot);
    return snapshot;
  }

  @override
  Future<void> restore(DeletedAccommodation snapshot) {
    restores.add(snapshot);
    return super.restore(snapshot);
  }
}

base class _Preferences extends InMemorySharedPreferencesAsync {
  _Preferences() : super.empty();
  Completer<void>? writeGate;
  bool failWrite = false;

  @override
  Future<bool> setString(
    String key,
    String value,
    SharedPreferencesOptions options,
  ) async {
    if (writeGate != null) await writeGate!.future;
    if (failWrite) {
      failWrite = false;
      throw StateError('Escritura de preferencias controlada fallida');
    }
    return super.setString(key, value, options);
  }
}

/// Backend de prueba en disco; no modifica el almacenamiento de producción.
base class _FilePreferences extends InMemorySharedPreferencesAsync {
  _FilePreferences(this.file) : super.empty();
  final File file;

  @override
  Future<String?> getString(
    String key,
    SharedPreferencesOptions options,
  ) async {
    if (!await file.exists()) return null;
    return (jsonDecode(await file.readAsString()) as Map<String, dynamic>)[key]
        as String?;
  }

  @override
  Future<bool> setString(
    String key,
    String value,
    SharedPreferencesOptions options,
  ) async {
    final values =
        await file.exists()
            ? Map<String, dynamic>.from(
              jsonDecode(await file.readAsString()) as Map,
            )
            : <String, dynamic>{};
    values[key] = value;
    await file.writeAsString(jsonEncode(values), flush: true);
    return true;
  }
}

extension on Completer<void> {
  void completeIfPending() {
    if (!isCompleted) complete();
  }
}

final _records = [
  _record('a'),
  _record('b', type: AccommodationType.boardingHouse, owned: true),
  _record(
    'c',
    images: const [
      'https://example.test/c-1.png',
      'https://example.test/c-2.png',
    ],
  ),
  _record('d', type: AccommodationType.boardingHouse, guatemala: true),
  _record('e'),
  _record('hidden', available: false),
];

AccommodationRecord _record(
  String id, {
  AccommodationType type = AccommodationType.apartment,
  bool owned = false,
  bool available = true,
  bool guatemala = false,
  List<String> images = const [],
}) => AccommodationRecord(
  id: id,
  title: 'Aceptación $id',
  type: type,
  location: 'Dirección $id',
  departmentId: guatemala ? 'guatemala' : 'quetzaltenango',
  universityIds: [guatemala ? 'usac-central' : 'mesoamericana-quetzaltenango'],
  monthlyPrice: 1234.50,
  description: 'Descripción completa $id',
  available: available,
  bathrooms: 2,
  sizeSquareMeters: 53.5,
  imageUrls: images,
  contactName: 'Contacto $id',
  contactPhone: '5555-1234',
  contactEmail: '$id@example.test',
  isOwned: owned,
);
