import 'dart:async';

import 'package:easyhome/app/accommodation_deletion_providers.dart';
import 'package:easyhome/app/app.dart';
import 'package:easyhome/features/accommodations/data/datasources/accommodation_data_source.dart';
import 'package:easyhome/features/accommodations/data/repositories/shared_accommodation_repository_impl.dart';
import 'package:easyhome/features/accommodations/domain/entities/accommodation_query.dart';
import 'package:easyhome/features/accommodations/domain/entities/accommodation_record.dart';
import 'package:easyhome/features/accommodations/domain/entities/catalog_filter.dart';
import 'package:easyhome/features/accommodations/domain/entities/deleted_accommodation.dart';
import 'package:easyhome/features/accommodations/presentation/controllers/catalog_deletion_controller.dart';
import 'package:easyhome/features/accommodations/presentation/controllers/catalog_deletion_provider.dart';
import 'package:easyhome/features/accommodations/presentation/controllers/catalog_providers.dart';
import 'package:easyhome/features/accommodations/presentation/providers/shared_accommodation_providers.dart';
import 'package:easyhome/features/auth/presentation/pages/login_page.dart';
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
  ) {
    if (failWrite) {
      failWrite = false;
      throw StateError('Fallo controlado de escritura');
    }
    return super.setString(key, value, options);
  }
}

void main() {
  late _Preferences preferences;
  late SharedPreferencesAccommodationRepository repository;
  late List<AccommodationRecord> initial;

  Future<void> initialize() async {
    preferences = _Preferences();
    SharedPreferencesAsyncPlatform.instance = preferences;
    final seed = await InMemoryAccommodationDataSource().getAccommodations();
    initial =
        seed
            .map(
              (item) =>
                  AccommodationRecord.fromAccommodation(item, isOwned: true),
            )
            .toList();
    repository = SharedPreferencesAccommodationRepository(
      preferences: SharedPreferencesAsync(),
      storageKey: 'kenneth.composition.v1',
      loadInitialAccommodations: () async => initial,
    );
    await repository.query(const AccommodationQuery());
  }

  Future<void> mount(WidgetTester tester) async {
    await initialize();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedAccommodationRepositoryProvider.overrideWithValue(repository),
        ],
        child: const EasyHomeApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> cleanup(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await repository.dispose();
  }

  testWidgets(
    'composicion real separa hosts y conserva la fuente y snapshot al deshacer',
    (tester) async {
      try {
        await mount(tester);
        final container = ProviderScope.containerOf(
          tester.element(find.byType(LoginPage)),
        );
        final owner =
            container.read(ownerAccommodationDeletionControllerProvider)!;
        final catalog = container.read(catalogDeletionControllerProvider)!;
        expect(owner, isNot(same(catalog)));
        expect(
          container.read(sharedAccommodationRepositoryProvider),
          same(repository),
        );
        expect(
          container.read(ownerAccommodationDeletionControllerProvider),
          same(owner),
        );
        final ownerEvents = <CatalogDeletionEvent<Object>>[];
        final catalogEvents = <CatalogDeletionEvent<Object>>[];
        final ownerSubscription = owner.events.listen(ownerEvents.add);
        final catalogSubscription = catalog.events.listen(catalogEvents.add);
        try {
          final original = initial.first;
          await owner.deleteById(original.id);
          await tester.pump();
          final ticket = ownerEvents.single.ticket!;
          expect(ticket.snapshot, isA<DeletedAccommodation>());
          expect((ticket.snapshot as DeletedAccommodation).record, original);
          expect((ticket.snapshot as DeletedAccommodation).sequence, 0);
          expect(owner.isLocked(original.id), isTrue);
          expect(catalog.isLocked(original.id), isFalse);
          expect(catalogEvents, isEmpty);
          expect(
            await repository.query(const AccommodationQuery(onlyOwned: true)),
            isNot(contains(original)),
          );
          final reader = container.read(catalogReaderProvider);
          expect(
            (await reader.query(const CatalogFilter())).map((item) => item.id),
            isNot(contains(original.id)),
          );
          // Otra pantalla puede operar sobre otro ID sin consumir el ticket del propietario.
          await catalog.deleteById(initial[1].id);
          await tester.pump();
          final catalogTicket = catalogEvents.single.ticket!;
          expect(ownerEvents, hasLength(1));
          await owner.undo(ticket);
          expect(await repository.query(const AccommodationQuery()), [
            initial[0],
            initial[2],
          ]);
          expect(owner.isLocked(original.id), isFalse);
          expect(catalog.isLocked(initial[1].id), isTrue);
          await catalog.undo(catalogTicket);
          expect(await repository.query(const AccommodationQuery()), initial);
          expect(
            (await reader.query(const CatalogFilter())).first.id,
            original.id,
          );
        } finally {
          unawaited(ownerSubscription.cancel());
          unawaited(catalogSubscription.cancel());
        }
      } finally {
        await cleanup(tester);
      }
    },
  );

  testWidgets(
    'escritura fallida no diverge y reintento conserva snapshot original',
    (tester) async {
      try {
        await mount(tester);
        final container = ProviderScope.containerOf(
          tester.element(find.byType(LoginPage)),
        );
        final owner =
            container.read(ownerAccommodationDeletionControllerProvider)!;
        final events = <CatalogDeletionEvent<Object>>[];
        final revisions = <int>[];
        final subscription = owner.events.listen(events.add);
        final changes = repository.changes.listen(revisions.add);
        try {
          preferences.failWrite = true;
          await owner.deleteById(initial.first.id);
          await tester.pump();
          expect(events.single.kind, CatalogDeletionKind.deleteFailed);
          expect(await repository.query(const AccommodationQuery()), initial);
          expect(revisions, isEmpty);
          expect(owner.isLocked(initial.first.id), isFalse);
          await owner.deleteById(initial.first.id);
          await tester.pump();
          final ticket = events.last.ticket!;
          final originalSnapshot = ticket.snapshot;
          preferences.failWrite = true;
          await owner.undo(ticket);
          await tester.pump();
          expect(events.last.kind, CatalogDeletionKind.restoreFailed);
          expect(events.last.ticket!.snapshot, same(originalSnapshot));
          expect(
            await repository.query(const AccommodationQuery()),
            initial.skip(1).toList(),
          );
          expect(revisions, [1]);
          await owner.undo(ticket);
          await owner.undo(ticket);
          await tester.pump();
          expect(await repository.query(const AccommodationQuery()), initial);
          expect(revisions, [1, 2]);
          expect(owner.isLocked(initial.first.id), isFalse);
        } finally {
          unawaited(subscription.cancel());
          unawaited(changes.cancel());
        }
      } finally {
        await cleanup(tester);
      }
    },
  );
}
