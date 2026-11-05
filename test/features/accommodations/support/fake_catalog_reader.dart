import 'dart:async';

import 'package:easyhome/features/accommodations/domain/entities/accommodation.dart';
import 'package:easyhome/features/accommodations/domain/entities/catalog_filter.dart';
import 'package:easyhome/features/accommodations/domain/repositories/catalog_reader.dart';

class FakeCatalogReader implements CatalogReader {
  final changesController = StreamController<int>.broadcast();
  final queries = <CatalogFilter>[];
  Future<List<Accommodation>> Function(CatalogFilter)? respond;

  @override
  Stream<int> get changes => changesController.stream;

  @override
  Future<List<Accommodation>> query(CatalogFilter filter) async {
    queries.add(filter);
    if (respond != null) return respond!(filter);
    return fixtures.where((item) {
      return item.available &&
          (filter.type == null || item.type == filter.type) &&
          (filter.departmentId == null ||
              item.departmentId == filter.departmentId) &&
          (filter.universityId == null ||
              item.universityIds.contains(filter.universityId));
    }).toList();
  }

  Future<void> close() => changesController.close();

  static const fixtures = [
    Accommodation(
      id: 'apartment-1',
      title: 'Apartamento de prueba',
      type: AccommodationType.apartment,
      location: 'Zona 3',
      departmentId: 'quetzaltenango',
      universityIds: ['meso'],
      monthlyPrice: 1800,
      bathrooms: 1,
      sizeSquareMeters: 35,
      imageUrls: [],
      contactName: 'Contacto uno',
      contactPhone: '1111',
    ),
    Accommodation(
      id: 'boarding-1',
      title: 'Pensionado de prueba',
      type: AccommodationType.boardingHouse,
      location: 'Zona 12',
      departmentId: 'guatemala',
      universityIds: ['usac'],
      monthlyPrice: 1200,
      bathrooms: 2,
      sizeSquareMeters: 15,
      imageUrls: [],
      contactName: 'Contacto dos',
      contactPhone: '2222',
    ),
  ];
}
