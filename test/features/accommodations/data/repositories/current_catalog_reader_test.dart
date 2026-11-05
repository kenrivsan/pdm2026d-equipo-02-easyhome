import 'package:easyhome/features/accommodations/data/datasources/accommodation_data_source.dart';
import 'package:easyhome/features/accommodations/data/owner_accommodation_store.dart';
import 'package:easyhome/features/accommodations/data/repositories/accommodation_repository_impl.dart';
import 'package:easyhome/features/accommodations/data/repositories/current_catalog_reader.dart';
import 'package:easyhome/features/accommodations/domain/entities/accommodation.dart';
import 'package:easyhome/features/accommodations/domain/entities/catalog_filter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

class _OwnerSource extends ChangeNotifier implements OwnerAccommodationStore {
  final List<OwnerAccommodation> _items = [];

  @override
  List<OwnerAccommodation> get items => List.unmodifiable(_items);

  @override
  List<Accommodation> get catalogItems =>
      _items.map((item) => item.toAccommodation()).toList();

  @override
  void add(OwnerAccommodation item) {
    _items.add(item);
    notifyListeners();
  }
}

void main() {
  late _OwnerSource owner;
  late CurrentCatalogReader reader;

  setUp(() {
    owner = _OwnerSource();
    reader = CurrentCatalogReader(
      AccommodationRepositoryImpl(InMemoryAccommodationDataSource()),
      owner,
    );
  });
  tearDown(() {
    reader.dispose();
    owner.dispose();
  });

  test(
    'combina tipo y ubicación y omite los alojamientos no disponibles',
    () async {
      final all = await reader.query(const CatalogFilter());
      expect(all, hasLength(2));
      expect(all.every((item) => item.available), isTrue);
      final selected = await reader.query(
        const CatalogFilter(
          type: AccommodationType.apartment,
          departmentId: 'quetzaltenango',
          universityId: 'mesoamericana-quetzaltenango',
        ),
      );
      expect(selected.single.id, 'apartment-quetzaltenango-1');
      expect(
        await reader.query(
          const CatalogFilter(
            type: AccommodationType.apartment,
            departmentId: 'guatemala',
          ),
        ),
        isEmpty,
      );
    },
  );

  test(
    'publicación del propietario emite revisión y aparece sin otra copia persistente',
    () async {
      final event = reader.changes.first;
      owner.add(
        const OwnerAccommodation(
          id: 'owner-1',
          name: 'Publicación nueva',
          type: 'Apartamento',
          address: 'Zona 1',
          departmentId: 'quetzaltenango',
          universityIds: ['mesoamericana-quetzaltenango'],
          monthlyPrice: 1600,
          description: 'Descripción original',
          bathrooms: 1,
          sizeSquareMeters: 30,
          contactName: 'Propietario',
          contactPhone: '5555',
        ),
      );
      expect(await event, 1);
      final results = await reader.query(const CatalogFilter());
      final publication = results.singleWhere((item) => item.id == 'owner-1');
      expect(publication.title, 'Publicación nueva');
      expect(publication.monthlyPrice, 1600);
      expect(owner.items, hasLength(1));
      expect(
        await reader.query(
          const CatalogFilter(type: AccommodationType.boardingHouse),
        ),
        hasLength(1),
      );
    },
  );
}
