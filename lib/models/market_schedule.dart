// lib/models/market_schedule.dart
import 'package:mess_meal_management_app/utils/date_helpers.dart'; // Import DateHelpers

/// Represents a market duty schedule for a member.
class MarketSchedule {
  final int? id; // Primary key, nullable for new entries
  final int memberId;
  final DateTime scheduleDate;
  final String dutyTitle; // New: Title for the duty (e.g., "Morning Market", "Evening Groceries")
  final String? description; // Optional description for the duty

  MarketSchedule({
    this.id,
    required this.memberId,
    required this.scheduleDate,
    required this.dutyTitle,
    this.description,
  });

  /// Converts a MarketSchedule object into a Map for database operations.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'member_id': memberId,
      'schedule_date': DateHelpers.formatDateToYYYYMMDD(scheduleDate), // Fixed: Use formatDateToYYYYMMDD
      'duty_title': dutyTitle,
      'description': description,
    };
  }

  /// Creates a MarketSchedule object from a Map retrieved from the database.
  factory MarketSchedule.fromMap(Map<String, dynamic> map) {
    return MarketSchedule(
      id: map['id'] as int?,
      memberId: map['member_id'] as int,
      scheduleDate: DateTime.parse(map['schedule_date'] as String), // Fixed: Use DateTime.parse
      dutyTitle: map['duty_title'] as String,
      description: map['description'] as String?,
    );
  }

  /// Creates a copy of this MarketSchedule object with optional new values.
  MarketSchedule copyWith({
    int? id,
    int? memberId,
    DateTime? scheduleDate,
    String? dutyTitle,
    String? description,
  }) {
    return MarketSchedule(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      scheduleDate: scheduleDate ?? this.scheduleDate,
      dutyTitle: dutyTitle ?? this.dutyTitle,
      description: description ?? this.description,
    );
  }

  @override
  String toString() {
    return 'MarketSchedule(id: $id, memberId: $memberId, scheduleDate: $scheduleDate, dutyTitle: $dutyTitle, description: $description)';
  }
}
