import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/accommodation.dart';
import '../../domain/entities/accommodation_query.dart';
import '../../domain/entities/accommodation_record.dart';
import '../../domain/entities/deleted_accommodation.dart';
import '../../domain/repositories/shared_accommodation_repository.dart';

typedef InitialAccommodationLoader =
    Future<List<AccommodationRecord>> Function();

/// Shared, versioned local repository for catalog and owner publications.
///
/// One JSON preference key contains active records, deletion snapshots, stable
/// order metadata, and the revision. Each operation serializes a complete next
/// state, waits for SharedPreferencesAsync, then swaps memory and emits change.
class SharedPreferencesAccommodationRepository
    implements SharedAccommodationRepository {
  SharedPreferencesAccommodationRepository({
    required SharedPreferencesAsync preferences,
    required InitialAccommodationLoader loadInitialAccommodations,
    this.storageKey = defaultStorageKey,
  }) : _preferences = preferences,
       _loadInitialAccommodations = loadInitialAccommodations {
    _ready = _loadOrSeed();
  }

  static const defaultStorageKey = 'easyhome.accommodations.v1';
  static const _schemaVersion = 1;

  final SharedPreferencesAsync _preferences;
  final InitialAccommodationLoader _loadInitialAccommodations;
  final String storageKey;
  final StreamController<int> _changes = StreamController<int>.broadcast();

  late final Future<void> _ready;
  late _RepositoryState _state;
  Future<void> _writeQueue = Future<void>.value();
  Future<void>? _disposeFuture;

  @override
  Stream<int> get changes => _changes.stream;

  @override
  Future<List<AccommodationRecord>> query(AccommodationQuery filter) async {
    await _ready;
    final state = _state;
    final matching =
        state.records.values
            .where((stored) => filter.matches(stored.record))
            .toList()
          ..sort((left, right) => left.sequence.compareTo(right.sequence));
    return List.unmodifiable(matching.map((stored) => stored.record));
  }

  @override
  Future<void> add(AccommodationRecord record) {
    return _enqueue(() async {
      await _ready;
      if (_state.records.containsKey(record.id) ||
          _state.deleted.values.any(
            (deleted) => deleted.record.id == record.id,
          )) {
        throw DuplicateAccommodationException(record.id);
      }

      final records = Map<String, _StoredAccommodation>.from(_state.records)
        ..[record.id] = _StoredAccommodation(
          record: record,
          sequence: _state.nextSequence,
        );
      final next = _state.copyWith(
        records: records,
        nextSequence: _state.nextSequence + 1,
        revision: _state.revision + 1,
      );
      await _persistAndPublish(next);
    });
  }

  @override
  Future<DeletedAccommodation> deleteById(String id) {
    return _enqueue(() async {
      await _ready;
      final stored = _state.records[id];
      if (stored == null) throw AccommodationNotFoundException(id);

      final deletion = DeletedAccommodation(
        record: stored.record,
        deletionToken: 'delete-${_state.nextDeletionToken}',
        sequence: stored.sequence,
      );
      final records = Map<String, _StoredAccommodation>.from(_state.records)
        ..remove(id);
      final deleted = Map<String, DeletedAccommodation>.from(_state.deleted)
        ..[deletion.deletionToken] = deletion;
      final next = _state.copyWith(
        records: records,
        deleted: deleted,
        nextDeletionToken: _state.nextDeletionToken + 1,
        revision: _state.revision + 1,
      );
      await _persistAndPublish(next);
      return deletion;
    });
  }

  @override
  Future<void> restore(DeletedAccommodation deleted) {
    return _enqueue(() async {
      await _ready;
      final storedDeletion = _state.deleted[deleted.deletionToken];
      if (storedDeletion == null) {
        final active = _state.records[deleted.record.id];
        if (active?.record == deleted.record &&
            active?.sequence == deleted.sequence) {
          return;
        }
        throw DeletedAccommodationNotFoundException(deleted.deletionToken);
      }
      if (storedDeletion != deleted) {
        throw DeletedAccommodationNotFoundException(deleted.deletionToken);
      }
      if (_state.records.containsKey(deleted.record.id)) {
        throw DuplicateAccommodationException(deleted.record.id);
      }

      final records = Map<String, _StoredAccommodation>.from(_state.records)
        ..[deleted.record.id] = _StoredAccommodation(
          record: deleted.record,
          sequence: deleted.sequence,
        );
      final deletions = Map<String, DeletedAccommodation>.from(_state.deleted)
        ..remove(deleted.deletionToken);
      final next = _state.copyWith(
        records: records,
        deleted: deletions,
        revision: _state.revision + 1,
      );
      await _persistAndPublish(next);
    });
  }

  Future<void> _loadOrSeed() async {
    final storedJson = await _preferences.getString(storageKey);
    if (storedJson != null) {
      _state = _RepositoryState.fromJson(_decodeMap(storedJson));
      return;
    }

    final initialRecords = await _loadInitialAccommodations();
    final records = <String, _StoredAccommodation>{};
    var sequence = 0;
    for (final record in initialRecords) {
      if (records.containsKey(record.id)) {
        throw DuplicateAccommodationException(record.id);
      }
      records[record.id] = _StoredAccommodation(
        record: record,
        sequence: sequence++,
      );
    }
    final initial = _RepositoryState(
      records: records,
      deleted: const {},
      nextSequence: sequence,
      nextDeletionToken: 0,
      revision: 0,
    );

    // The seed marker and seed records are written as one value. If this fails,
    // the repository stays uninitialized and never exposes an unsaved seed.
    await _preferences.setString(storageKey, jsonEncode(initial.toJson()));
    _state = initial;
  }

  Future<void> _persistAndPublish(_RepositoryState next) async {
    await _preferences.setString(storageKey, jsonEncode(next.toJson()));
    _state = next;
    _changes.add(next.revision);
  }

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final result = _writeQueue.then<T>((_) => operation());
    _writeQueue = result.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {},
    );
    return result;
  }

  Map<String, dynamic> _decodeMap(String value) {
    final decoded = jsonDecode(value);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'Accommodation storage must be a JSON object.',
      );
    }
    return decoded;
  }

  Future<void> dispose() =>
      _disposeFuture ??= _writeQueue.then((_) => _changes.close());
}

class _RepositoryState {
  const _RepositoryState({
    required this.records,
    required this.deleted,
    required this.nextSequence,
    required this.nextDeletionToken,
    required this.revision,
  });

  final Map<String, _StoredAccommodation> records;
  final Map<String, DeletedAccommodation> deleted;
  final int nextSequence;
  final int nextDeletionToken;
  final int revision;

  _RepositoryState copyWith({
    Map<String, _StoredAccommodation>? records,
    Map<String, DeletedAccommodation>? deleted,
    int? nextSequence,
    int? nextDeletionToken,
    int? revision,
  }) {
    return _RepositoryState(
      records: records ?? this.records,
      deleted: deleted ?? this.deleted,
      nextSequence: nextSequence ?? this.nextSequence,
      nextDeletionToken: nextDeletionToken ?? this.nextDeletionToken,
      revision: revision ?? this.revision,
    );
  }

  Map<String, Object?> toJson() => {
    'version': SharedPreferencesAccommodationRepository._schemaVersion,
    'revision': revision,
    'nextSequence': nextSequence,
    'nextDeletionToken': nextDeletionToken,
    'records':
        records.values
            .map(
              (stored) => {
                'sequence': stored.sequence,
                'record': _recordToJson(stored.record),
              },
            )
            .toList(),
    'deleted':
        deleted.values
            .map(
              (item) => {
                'deletionToken': item.deletionToken,
                'sequence': item.sequence,
                'record': _recordToJson(item.record),
              },
            )
            .toList(),
  };

  factory _RepositoryState.fromJson(Map<String, dynamic> json) {
    final version = json['version'];
    if (version != SharedPreferencesAccommodationRepository._schemaVersion) {
      throw FormatException(
        'Unsupported accommodation storage version: $version',
      );
    }

    final records = <String, _StoredAccommodation>{};
    for (final value in json['records'] as List<dynamic>) {
      final entry = Map<String, dynamic>.from(value as Map);
      final record = _recordFromJson(
        Map<String, dynamic>.from(entry['record'] as Map),
      );
      if (records.containsKey(record.id)) {
        throw DuplicateAccommodationException(record.id);
      }
      records[record.id] = _StoredAccommodation(
        record: record,
        sequence: entry['sequence'] as int,
      );
    }

    final deleted = <String, DeletedAccommodation>{};
    for (final value in json['deleted'] as List<dynamic>) {
      final entry = Map<String, dynamic>.from(value as Map);
      final item = DeletedAccommodation(
        record: _recordFromJson(
          Map<String, dynamic>.from(entry['record'] as Map),
        ),
        deletionToken: entry['deletionToken'] as String,
        sequence: entry['sequence'] as int,
      );
      if (deleted.containsKey(item.deletionToken) ||
          records.containsKey(item.record.id) ||
          deleted.values.any((other) => other.record.id == item.record.id)) {
        throw FormatException(
          'Duplicate accommodation state for ${item.record.id}.',
        );
      }
      deleted[item.deletionToken] = item;
    }

    return _RepositoryState(
      records: records,
      deleted: deleted,
      nextSequence: json['nextSequence'] as int,
      nextDeletionToken: json['nextDeletionToken'] as int,
      revision: json['revision'] as int,
    );
  }
}

class _StoredAccommodation {
  const _StoredAccommodation({required this.record, required this.sequence});

  final AccommodationRecord record;
  final int sequence;
}

Map<String, Object?> _recordToJson(AccommodationRecord record) => {
  'id': record.id,
  'title': record.title,
  'type': record.type.name,
  'location': record.location,
  'departmentId': record.departmentId,
  'universityIds': record.universityIds,
  'monthlyPrice': record.monthlyPrice,
  'description': record.description,
  'available': record.available,
  'bathrooms': record.bathrooms,
  'sizeSquareMeters': record.sizeSquareMeters,
  'imageUrls': record.imageUrls,
  'contactName': record.contactName,
  'contactPhone': record.contactPhone,
  'contactEmail': record.contactEmail,
  'isOwned': record.isOwned,
};

AccommodationRecord _recordFromJson(Map<String, dynamic> json) {
  return AccommodationRecord(
    id: json['id'] as String,
    title: json['title'] as String,
    type: AccommodationType.values.byName(json['type'] as String),
    location: json['location'] as String,
    departmentId: json['departmentId'] as String,
    universityIds: List<String>.from(json['universityIds'] as List),
    monthlyPrice: (json['monthlyPrice'] as num).toDouble(),
    description: json['description'] as String? ?? '',
    available: json['available'] as bool? ?? true,
    bathrooms: json['bathrooms'] as int,
    sizeSquareMeters: (json['sizeSquareMeters'] as num).toDouble(),
    imageUrls: List<String>.from(json['imageUrls'] as List),
    contactName: json['contactName'] as String,
    contactPhone: json['contactPhone'] as String,
    contactEmail: json['contactEmail'] as String?,
    isOwned: json['isOwned'] as bool? ?? false,
  );
}
