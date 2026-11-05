import 'accommodation_record.dart';

/// Exact publication snapshot and token required to undo one deletion.
final class DeletedAccommodation {
  const DeletedAccommodation({
    required this.record,
    required this.deletionToken,
    required this.sequence,
  });

  final AccommodationRecord record;

  /// Unique per deletion, so a stale undo cannot reverse a later deletion.
  final String deletionToken;

  /// Stable insertion sequence captured at deletion, never a filtered index.
  final int sequence;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeletedAccommodation &&
          other.record == record &&
          other.deletionToken == deletionToken &&
          other.sequence == sequence;

  @override
  int get hashCode => Object.hash(record, deletionToken, sequence);
}
