import 'package:flutter/foundation.dart';

import '../domain/entities/accommodation.dart';

class OwnerAccommodation {
  const OwnerAccommodation({
    required this.id,
    required this.name,
    required this.type,
    required this.address,
    required this.departmentId,
    required this.universityIds,
    required this.monthlyPrice,
    required this.description,
    required this.bathrooms,
    required this.sizeSquareMeters,
    required this.contactName,
    required this.contactPhone,
  });

  final String id;
  final String name;
  final String type;
  final String address;
  final String departmentId;
  final List<String> universityIds;
  final double monthlyPrice;
  final String description;
  final int bathrooms;
  final double sizeSquareMeters;
  final String contactName;
  final String contactPhone;

  Accommodation toAccommodation() {
    return Accommodation(
      id: id,
      title: name,
      type:
          type == 'Apartamento'
              ? AccommodationType.apartment
              : AccommodationType.boardingHouse,
      location: address,
      departmentId: departmentId,
      universityIds: universityIds,
      monthlyPrice: monthlyPrice,
      bathrooms: bathrooms,
      sizeSquareMeters: sizeSquareMeters,
      imageUrls: const [],
      contactName: contactName,
      contactPhone: contactPhone,
    );
  }
}

class OwnerAccommodationStore extends ChangeNotifier {
  OwnerAccommodationStore._();

  static final OwnerAccommodationStore instance = OwnerAccommodationStore._();

  final List<OwnerAccommodation> _items = [];

  List<OwnerAccommodation> get items => List.unmodifiable(_items);

  List<Accommodation> get catalogItems =>
      List.unmodifiable(_items.map((item) => item.toAccommodation()));

  void add(OwnerAccommodation accommodation) {
    _items.add(accommodation);
    notifyListeners();
  }
}
