import '../../domain/entities/accommodation.dart';

class AccommodationModel extends Accommodation {
  const AccommodationModel({
    required super.id,
    required super.title,
    required super.type,
    required super.location,
    required super.monthlyPrice,
    super.available,
  });

  factory AccommodationModel.fromJson(Map<String, dynamic> json) {
    return AccommodationModel(
      id: json['id'] as String,
      title: json['title'] as String,
      type: AccommodationType.values.byName(json['type'] as String),
      location: json['location'] as String,
      monthlyPrice: (json['monthlyPrice'] as num).toDouble(),
      available: json['available'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'type': type.name,
        'location': location,
        'monthlyPrice': monthlyPrice,
        'available': available,
      };
}
