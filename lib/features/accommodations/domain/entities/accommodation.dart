enum AccommodationType { apartment, boardingHouse }

class Accommodation {
  const Accommodation({
    required this.id,
    required this.title,
    required this.type,
    required this.location,
    required this.monthlyPrice,
    this.available = true,
  });

  final String id;
  final String title;
  final AccommodationType type;
  final String location;
  final double monthlyPrice;
  final bool available;
}
