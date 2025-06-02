// lib/models/expense.dart
import 'package:mess_meal_management_app/utils/date_helpers.dart'; // Import DateHelpers

/// Represents a single expense made by the mess.
class Expense {
  final int? id; // Primary key, nullable for new entries
  final DateTime expenseDate;
  final double amount;
  final String? description; // Optional description for the expense

  Expense({
    this.id,
    required this.expenseDate,
    required this.amount,
    this.description,
  });

  /// Converts an Expense object into a Map for database operations.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'expense_date': DateHelpers.formatDateToYYYYMMDD(expenseDate), // Fixed: Use formatDateToYYYYMMDD
      'amount': amount,
      'description': description,
    };
  }

  /// Creates an Expense object from a Map retrieved from the database.
  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      expenseDate: DateTime.parse(map['expense_date'] as String), // Fixed: Use DateTime.parse
      amount: (map['amount'] as num).toDouble(),
      description: map['description'] as String?,
    );
  }

  /// Creates a copy of this Expense object with optional new values.
  Expense copyWith({
    int? id,
    DateTime? expenseDate,
    double? amount,
    String? description,
  }) {
    return Expense(
      id: id ?? this.id,
      expenseDate: expenseDate ?? this.expenseDate,
      amount: amount ?? this.amount,
      description: description ?? this.description,
    );
  }

  @override
  String toString() {
    return 'Expense(id: $id, expenseDate: $expenseDate, amount: $amount, description: $description)';
  }
}
