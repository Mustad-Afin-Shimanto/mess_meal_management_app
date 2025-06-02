// lib/models/market_duty.dart
// This model is kept for consistency with the project description,
// but its functionality is largely merged into MarketSchedule.
// It can be used if a more granular distinction between a 'duty' and a 'schedule entry' is needed.

/// Data model for a specific market duty (e.g., "Buy vegetables").
/// This is a conceptual model and might be integrated into MarketSchedule.
class MarketDuty {
  int? id;
  String description;

  MarketDuty({
    this.id,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
    };
  }

  factory MarketDuty.fromMap(Map<String, dynamic> map) {
    return MarketDuty(
      id: map['id'],
      description: map['description'],
    );
  }

  @override
  String toString() {
    return 'MarketDuty{id: $id, description: $description}';
  }
}
