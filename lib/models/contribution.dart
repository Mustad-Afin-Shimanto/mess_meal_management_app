// lib/models/contribution.dart
import 'package:mess_meal_management_app/utils/date_helpers.dart'; // Import DateHelpers

/// Represents a financial contribution made by a member.
class Contribution {
  final int? id; // Primary key, nullable for new entries
  final int memberId;
  final DateTime contributionDate;
  final double amount;

  Contribution({
    this.id,
    required this.memberId,
    required this.contributionDate,
    required this.amount,
  });

  /// Converts a Contribution object into a Map for database operations.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'member_id': memberId,
      'contribution_date': DateHelpers.formatDateToYYYYMMDD(contributionDate), // Fixed: Use formatDateToYYYYMMDD
      'amount': amount,
    };
  }

  /// Creates a Contribution object from a Map retrieved from the database.
  factory Contribution.fromMap(Map<String, dynamic> map) {
    return Contribution(
      id: map['id'] as int?,
      memberId: map['member_id'] as int,
      contributionDate: DateTime.parse(map['contribution_date'] as String), // Fixed: Use DateTime.parse
      amount: (map['amount'] as num).toDouble(),
    );
  }

  /// Creates a copy of this Contribution object with optional new values.
  Contribution copyWith({
    int? id,
    int? memberId,
    DateTime? contributionDate,
    double? amount,
  }) {
    return Contribution(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      contributionDate: contributionDate ?? this.contributionDate,
      amount: amount ?? this.amount,
    );
  }

  @override
  String toString() {
    return 'Contribution(id: $id, memberId: $memberId, contributionDate: $contributionDate, amount: $amount)';
  }
}
