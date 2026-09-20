import 'package:flutter_test/flutter_test.dart';
import 'package:easyhome/features/accommodations/data/datasources/accommodation_data_source.dart';
import 'package:easyhome/features/accommodations/domain/entities/accommodation.dart';
void main() {
  group('InMemoryAccommodationDataSource', () {
    late InMemoryAccommodationDataSource dataSource;

    setUp(() {
      dataSource = InMemoryAccommodationDataSource();
    });

    test('devuelve alojamientos de prueba', () async {
      final accommodations = await dataSource.getAccommodations();

      expect(accommodations, isNotEmpty);
    });

    test('incluye apartamentos y pensionados', () async {
      final accommodations = await dataSource.getAccommodations();

      expect(
        accommodations.any(
          (accommodation) =>
              accommodation.type == AccommodationType.apartment,
        ),
        isTrue,
      );

      expect(
        accommodations.any(
          (accommodation) =>
              accommodation.type == AccommodationType.boardingHouse,
        ),
        isTrue,
      );
    });

    test('incluye alojamientos de diferentes departamentos', () async {
      final accommodations = await dataSource.getAccommodations();

      final departmentIds = accommodations
          .map((accommodation) => accommodation.departmentId)
          .toSet();

      expect(departmentIds.length, greaterThan(1));
    });

    test('incluye registros disponibles y no disponibles', () async {
      final accommodations = await dataSource.getAccommodations();

      expect(
        accommodations.any((accommodation) => accommodation.available),
        isTrue,
      );

      expect(
        accommodations.any((accommodation) => !accommodation.available),
        isTrue,
      );
    });
  });
}