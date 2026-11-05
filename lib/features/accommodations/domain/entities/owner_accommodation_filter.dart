import 'accommodation.dart';

/// Immutable filter for the owner's accommodation list.
final class OwnerAccommodationFilter {
  const OwnerAccommodationFilter({this.type});

  final AccommodationType? type;

  OwnerAccommodationFilter copyWith({
    AccommodationType? type,
    bool clearType = false,
  }) {
    return OwnerAccommodationFilter(type: clearType ? null : type ?? this.type);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OwnerAccommodationFilter && other.type == type;

  @override
  int get hashCode => type.hashCode;
}
