import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:easyhome/features/accommodations/domain/entities/accommodation.dart';
import 'package:easyhome/features/accommodations/domain/entities/accommodation_query.dart';
import 'package:easyhome/features/accommodations/domain/entities/accommodation_record.dart';
import 'package:easyhome/features/accommodations/domain/entities/deleted_accommodation.dart';
import 'package:easyhome/features/accommodations/domain/repositories/shared_accommodation_repository.dart';
import 'package:easyhome/features/accommodations/data/repositories/shared_accommodation_repository_impl.dart';

void main() {
  late _FailingMemoryPreferences preferencePlatform;
  late SharedPreferencesAccommodationRepository repository;
  final repositories = <SharedPreferencesAccommodationRepository>[];

  SharedPreferencesAccommodationRepository createRepository({
    Future<List<AccommodationRecord>> Function()? loadInitial,
    String storageKey = 'test.accommodations.v1',
  }) {
    final instance = SharedPreferencesAccommodationRepository(
      preferences: SharedPreferencesAsync(),
      loadInitialAccommodations: loadInitial ?? () async => _initialRecords,
      storageKey: storageKey,
    );
    repositories.add(instance);
    return instance;
  }

  setUp(() {
    preferencePlatform = _FailingMemoryPreferences();
    SharedPreferencesAsyncPlatform.instance = preferencePlatform;
    repositories.clear();
    repository = createRepository();
  });

  tearDown(() async {
    for (final instance in repositories) {
      await instance.dispose();
    }
  });

  test(
    'query combines type, department, university and ownership filters',
    () async {
      final catalog = await repository.query(
        const AccommodationQuery(
          type: AccommodationType.apartment,
          departmentId: 'guatemala',
          universityId: 'usac',
        ),
      );
      final owned = await repository.query(
        const AccommodationQuery(onlyOwned: true),
      );

      expect(catalog.map((record) => record.id), ['a', 'c', 'd']);
      expect(owned.map((record) => record.id), ['b']);
    },
  );

  test('record retains all fields and makes collection inputs immutable', () {
    final universities = ['usac'];
    final images = ['front.jpg'];
    final record = _record(
      'full',
      universityIds: universities,
      imageUrls: images,
      isOwned: true,
    );
    universities.add('another');
    images.clear();

    expect(record.universityIds, ['usac']);
    expect(record.imageUrls, ['front.jpg']);
    expect(record.description, 'Description full');
    expect(record.contactEmail, 'owner@example.com');
    expect(record.isOwned, isTrue);
    expect(() => record.universityIds.add('mutate'), throwsUnsupportedError);
  });

  test(
    'delete and restore preserve the complete record and identity',
    () async {
      final original = (await repository.query(const AccommodationQuery()))[1];
      final deleted = await repository.deleteById(original.id);

      expect(deleted.record, original);
      expect(deleted.sequence, 1);
      expect(
        (await repository.query(const AccommodationQuery())).map((r) => r.id),
        ['a', 'c', 'd'],
      );

      await repository.restore(deleted);
      final restored = await repository.query(const AccommodationQuery());
      expect(restored[1], original);
      expect(restored.map((r) => r.id), ['a', 'b', 'c', 'd']);
    },
  );

  test(
    'restoring consecutive deletions in reverse order preserves order',
    () async {
      final deletedB = await repository.deleteById('b');
      final deletedD = await repository.deleteById('d');

      await repository.restore(deletedD);
      await repository.restore(deletedB);

      expect(
        (await repository.query(const AccommodationQuery())).map((r) => r.id),
        ['a', 'b', 'c', 'd'],
      );
    },
  );

  test(
    'repeated add, delete and restore do not create duplicate records',
    () async {
      final record = _record('new');
      await repository.add(record);
      await expectLater(
        repository.add(record),
        throwsA(isA<DuplicateAccommodationException>()),
      );

      final deletion = await repository.deleteById('new');
      await expectLater(
        repository.deleteById('new'),
        throwsA(isA<AccommodationNotFoundException>()),
      );
      await repository.restore(deletion);
      await repository.restore(deletion);

      final results = await repository.query(const AccommodationQuery());
      expect(results.where((item) => item.id == 'new'), hasLength(1));
    },
  );

  test(
    'successful writes persist across repository recreation and seed once',
    () async {
      var initialLoads = 0;
      repository = createRepository(
        loadInitial: () async {
          initialLoads++;
          return _initialRecords;
        },
        storageKey: 'test.recreated.v1',
      );
      await repository.query(const AccommodationQuery());

      final created = _record('new');
      await repository.add(created);
      final deleted = await repository.deleteById('a');
      await repository.dispose();

      repository = createRepository(
        loadInitial: () async {
          initialLoads++;
          return _initialRecords;
        },
        storageKey: 'test.recreated.v1',
      );
      expect(
        (await repository.query(const AccommodationQuery())).map((r) => r.id),
        ['b', 'c', 'd', 'new'],
      );
      expect(initialLoads, 1);

      await repository.restore(deleted);
      await repository.restore(deleted);
      expect(
        (await repository.query(const AccommodationQuery())).map((r) => r.id),
        ['a', 'b', 'c', 'd', 'new'],
      );
      await repository.dispose();

      repository = createRepository(
        loadInitial: () async {
          initialLoads++;
          return _initialRecords;
        },
        storageKey: 'test.recreated.v1',
      );
      expect(
        (await repository.query(const AccommodationQuery())).map((r) => r.id),
        ['a', 'b', 'c', 'd', 'new'],
      );
      expect(initialLoads, 1);
    },
  );

  test(
    'file-backed preferences survive repository recreation and deletion',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'easyhome_shared_accommodations_',
      );
      addTearDown(() async {
        if (await directory.exists()) await directory.delete(recursive: true);
      });

      final persistentPlatform = _FileBackedPreferences(
        File('${directory.path}${Platform.pathSeparator}preferences.json'),
      );
      SharedPreferencesAsyncPlatform.instance = persistentPlatform;
      var initialLoads = 0;
      repository = createRepository(
        storageKey: 'test.file-backed.v1',
        loadInitial: () async {
          initialLoads++;
          return _initialRecords;
        },
      );
      await repository.query(const AccommodationQuery());
      await repository.add(_record('file-backed'));
      final deleted = await repository.deleteById('a');
      await repository.dispose();

      repository = createRepository(
        storageKey: 'test.file-backed.v1',
        loadInitial: () async {
          initialLoads++;
          return _initialRecords;
        },
      );
      expect(
        (await repository.query(const AccommodationQuery())).map((r) => r.id),
        ['b', 'c', 'd', 'file-backed'],
      );
      expect(initialLoads, 1);

      await repository.restore(deleted);
      await repository.dispose();
      repository = createRepository(
        storageKey: 'test.file-backed.v1',
        loadInitial: () async {
          initialLoads++;
          return _initialRecords;
        },
      );
      expect(
        (await repository.query(const AccommodationQuery())).map((r) => r.id),
        ['a', 'b', 'c', 'd', 'file-backed'],
      );
      expect(initialLoads, 1);
    },
  );

  test('a failed initial read can be retried by the same repository', () async {
    var initialLoads = 0;
    repository = createRepository(
      storageKey: 'test.initial-read.v1',
      loadInitial: () async {
        initialLoads++;
        return _initialRecords;
      },
    );
    final revisions = <int>[];
    final subscription = repository.changes.listen(revisions.add);
    addTearDown(subscription.cancel);

    preferencePlatform.failNextRead = true;
    await expectLater(
      repository.query(const AccommodationQuery()),
      throwsA(isA<StateError>()),
    );
    expect(initialLoads, 0);
    expect(revisions, isEmpty);

    final recovered = await repository.query(const AccommodationQuery());
    expect(recovered.map((record) => record.id), ['a', 'b', 'c', 'd']);
    expect(initialLoads, 1);
    expect(revisions, isEmpty);
  });

  test(
    'a failed initial seed write can be retried without exposing the seed',
    () async {
      const key = 'test.initial-write.v1';
      var initialLoads = 0;
      Future<List<AccommodationRecord>> loadInitial() async {
        initialLoads++;
        return _initialRecords;
      }

      repository = createRepository(storageKey: key, loadInitial: loadInitial);
      final revisions = <int>[];
      final subscription = repository.changes.listen(revisions.add);
      addTearDown(subscription.cancel);

      preferencePlatform.failNextWrite = true;
      await expectLater(
        repository.query(const AccommodationQuery()),
        throwsA(isA<StateError>()),
      );
      expect(await SharedPreferencesAsync().getString(key), isNull);
      expect(revisions, isEmpty);

      final recovered = await repository.query(const AccommodationQuery());
      expect(recovered.map((record) => record.id), ['a', 'b', 'c', 'd']);
      expect(initialLoads, 2);
      expect(revisions, isEmpty);

      await repository.dispose();
      repository = createRepository(storageKey: key, loadInitial: loadInitial);
      expect(
        (await repository.query(const AccommodationQuery())).map((r) => r.id),
        ['a', 'b', 'c', 'd'],
      );
      expect(initialLoads, 2);
    },
  );

  test('concurrent first queries share one initialization', () async {
    var initialLoads = 0;
    repository = createRepository(
      storageKey: 'test.concurrent-initialization.v1',
      loadInitial: () async {
        initialLoads++;
        await Future<void>.delayed(const Duration(milliseconds: 1));
        return _initialRecords;
      },
    );

    final results = await Future.wait([
      repository.query(const AccommodationQuery()),
      repository.query(const AccommodationQuery(onlyOwned: true)),
      repository.query(const AccommodationQuery()),
    ]);
    expect(initialLoads, 1);
    expect(results[0], hasLength(4));
    expect(results[1].map((record) => record.id), ['b']);
    expect(results[2], hasLength(4));
  });

  test(
    'errors and failed persistence leave memory and revisions unchanged',
    () async {
      final revisions = <int>[];
      final subscription = repository.changes.listen(revisions.add);
      addTearDown(subscription.cancel);
      await repository.query(const AccommodationQuery());

      await expectLater(
        repository.deleteById('missing'),
        throwsA(isA<AccommodationNotFoundException>()),
      );
      await expectLater(
        repository.restore(
          DeletedAccommodation(
            record: _record('unknown'),
            deletionToken: 'unknown-token',
            sequence: 99,
          ),
        ),
        throwsA(isA<DeletedAccommodationNotFoundException>()),
      );
      await expectLater(
        repository.add(
          (await repository.query(const AccommodationQuery())).first,
        ),
        throwsA(isA<DuplicateAccommodationException>()),
      );

      preferencePlatform.failNextWrite = true;
      await expectLater(
        repository.add(_record('unsaved')),
        throwsA(isA<StateError>()),
      );
      expect(
        (await repository.query(const AccommodationQuery())).map((r) => r.id),
        ['a', 'b', 'c', 'd'],
      );
      expect(revisions, isEmpty);

      await repository.add(_record('saved'));
      final deletion = await repository.deleteById('saved');
      preferencePlatform.failNextWrite = true;
      await expectLater(
        repository.restore(deletion),
        throwsA(isA<StateError>()),
      );
      expect(
        (await repository.query(const AccommodationQuery())).map((r) => r.id),
        ['a', 'b', 'c', 'd'],
      );
      expect(revisions, [1, 2]);
    },
  );

  test(
    'changes emits increasing revisions only after committed mutations',
    () async {
      await repository.query(const AccommodationQuery());
      final revisions = <int>[];
      final subscription = repository.changes.listen(revisions.add);
      addTearDown(subscription.cancel);

      await repository.add(_record('new'));
      final deleted = await repository.deleteById('new');
      await repository.restore(deleted);
      await repository.restore(deleted);

      expect(revisions, [1, 2, 3]);
    },
  );

  test('serializes concurrent writes and keeps call order stable', () async {
    await repository.query(const AccommodationQuery());
    await Future.wait([
      repository.add(_record('first')),
      repository.add(_record('second')),
      repository.add(_record('third')),
    ]);

    final records = await repository.query(const AccommodationQuery());
    expect(records.map((record) => record.id).toList().sublist(4), [
      'first',
      'second',
      'third',
    ]);
  });
}

base class _FailingMemoryPreferences extends InMemorySharedPreferencesAsync {
  _FailingMemoryPreferences() : super.empty();

  bool failNextWrite = false;
  bool failNextRead = false;

  @override
  Future<String?> getString(
    String key,
    SharedPreferencesOptions options,
  ) async {
    if (failNextRead) {
      failNextRead = false;
      throw StateError('simulated preference read failure');
    }
    return super.getString(key, options);
  }

  @override
  Future<bool> setString(
    String key,
    String value,
    SharedPreferencesOptions options,
  ) async {
    if (failNextWrite) {
      failNextWrite = false;
      throw StateError('simulated preference write failure');
    }
    return super.setString(key, value, options);
  }
}

final _initialRecords = [
  _record('a'),
  _record(
    'b',
    type: AccommodationType.boardingHouse,
    departmentId: 'xela',
    universityIds: const ['usac-xela'],
    available: false,
    isOwned: true,
  ),
  _record('c'),
  _record('d'),
];

base class _FileBackedPreferences extends InMemorySharedPreferencesAsync {
  _FileBackedPreferences(this.file) : super.empty();

  final File file;

  @override
  Future<String?> getString(
    String key,
    SharedPreferencesOptions options,
  ) async {
    if (!await file.exists()) return null;
    final values = Map<String, dynamic>.from(
      jsonDecode(await file.readAsString()) as Map,
    );
    return values[key] as String?;
  }

  @override
  Future<bool> setString(
    String key,
    String value,
    SharedPreferencesOptions options,
  ) async {
    final values = <String, String>{};
    if (await file.exists()) {
      values.addAll(
        Map<String, String>.from(jsonDecode(await file.readAsString()) as Map),
      );
    }
    values[key] = value;
    await file.writeAsString(jsonEncode(values), flush: true);
    return true;
  }
}

AccommodationRecord _record(
  String id, {
  AccommodationType type = AccommodationType.apartment,
  String departmentId = 'guatemala',
  List<String> universityIds = const ['usac'],
  bool available = true,
  bool isOwned = false,
  List<String> imageUrls = const ['front.jpg'],
}) {
  return AccommodationRecord(
    id: id,
    title: 'Accommodation $id',
    type: type,
    location: 'Location $id',
    departmentId: departmentId,
    universityIds: universityIds,
    monthlyPrice: 1000,
    description: 'Description $id',
    available: available,
    bathrooms: 2,
    sizeSquareMeters: 45,
    imageUrls: imageUrls,
    contactName: 'Contact $id',
    contactPhone: '555-0100',
    contactEmail: 'owner@example.com',
    isOwned: isOwned,
  );
}
