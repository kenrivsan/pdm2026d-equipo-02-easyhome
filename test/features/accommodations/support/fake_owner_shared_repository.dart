import 'dart:async';

import 'package:easyhome/features/accommodations/domain/entities/accommodation.dart';
import 'package:easyhome/features/accommodations/domain/entities/accommodation_query.dart';
import 'package:easyhome/features/accommodations/domain/entities/accommodation_record.dart';
import 'package:easyhome/features/accommodations/domain/entities/deleted_accommodation.dart';
import 'package:easyhome/features/accommodations/domain/repositories/shared_accommodation_repository.dart';

class FakeOwnerSharedRepository implements SharedAccommodationRepository {
  FakeOwnerSharedRepository({List<AccommodationRecord>? records})
    : records = [...?records];

  final List<AccommodationRecord> records;
  final requestedQueries = <AccommodationQuery>[];
  final changesController = StreamController<int>.broadcast();
  Future<List<AccommodationRecord>> Function(AccommodationQuery)? onQuery;
  bool failNextQuery = false;
  bool failNextDelete = false;
  bool failNextRestore = false;
  Completer<void>? deleteGate;
  int revision = 0;
  int deleteCalls = 0;
  final restoredSnapshots = <DeletedAccommodation>[];

  @override
  Stream<int> get changes => changesController.stream;

  @override
  Future<List<AccommodationRecord>> query(AccommodationQuery filter) async {
    requestedQueries.add(filter);
    if (failNextQuery) {
      failNextQuery = false;
      throw StateError('simulated query failure');
    }
    if (onQuery != null) return onQuery!(filter);
    return List.unmodifiable(records.where(filter.matches));
  }

  @override
  Future<void> add(AccommodationRecord record) async {
    records.add(record);
    changesController.add(++revision);
  }

  @override
  Future<DeletedAccommodation> deleteById(String id) async {
    deleteCalls++;
    if (deleteGate != null) await deleteGate!.future;
    if (failNextDelete) {
      failNextDelete = false;
      throw StateError('simulated delete failure');
    }
    final index = records.indexWhere((record) => record.id == id);
    if (index < 0) throw AccommodationNotFoundException(id);
    final record = records.removeAt(index);
    changesController.add(++revision);
    return DeletedAccommodation(
      record: record,
      deletionToken: 'delete-$revision',
      sequence: index,
    );
  }

  @override
  Future<void> restore(DeletedAccommodation deleted) async {
    restoredSnapshots.add(deleted);
    if (failNextRestore) {
      failNextRestore = false;
      throw StateError('simulated restore failure');
    }
    if (records.any((record) => record.id == deleted.record.id)) return;
    records.insert(deleted.sequence.clamp(0, records.length), deleted.record);
    changesController.add(++revision);
  }

  Future<void> close() => changesController.close();
}

AccommodationRecord ownerRecord(
  String id, {
  AccommodationType type = AccommodationType.apartment,
  bool isOwned = true,
}) => AccommodationRecord(
  id: id,
  title: 'Casa $id',
  type: type,
  location: 'Dirección $id',
  departmentId: 'guatemala',
  universityIds: const ['usac'],
  monthlyPrice: 1200,
  description: 'Descripción $id',
  available: true,
  bathrooms: 1,
  sizeSquareMeters: 35,
  imageUrls: const ['front.jpg'],
  contactName: 'Contacto $id',
  contactPhone: '555-0100',
  contactEmail: 'owner@example.com',
  isOwned: isOwned,
);
