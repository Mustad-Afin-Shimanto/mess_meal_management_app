// lib/models/meal_entry.dart
import 'package:mess_meal_management_app/utils/date_helpers.dart'; // Import DateHelpers

/// Represents a single meal entry for a member on a specific date.
class MealEntry {
  final int? id; // Primary key, nullable for new entries
  final int memberId;
  final DateTime mealDate;
  final double breakfastMeals;
  final double lunchMeals;
  final double dinnerMeals;
  final double guestMeals;

  MealEntry({
    this.id,
    required this.memberId,
    required this.mealDate,
    this.breakfastMeals = 0.0,
    this.lunchMeals = 0.0,
    this.dinnerMeals = 0.0,
    this.guestMeals = 0.0,
  });

  /// Calculates the total meals for this entry.
  double get totalMeals => breakfastMeals + lunchMeals + dinnerMeals + guestMeals;

  /// Converts a MealEntry object into a Map for database operations.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'member_id': memberId,
      'meal_date': DateHelpers.formatDateToYYYYMMDD(mealDate), // Fixed: Store as YYYY-MM-DD
      'breakfast_meals': breakfastMeals,
      'lunch_meals': lunchMeals,
      'dinner_meals': dinnerMeals,
      'guest_meals': guestMeals,
    };
  }

  /// Creates a MealEntry object from a Map retrieved from the database.
  factory MealEntry.fromMap(Map<String, dynamic> map) {
    return MealEntry(
      id: map['id'] as int?,
      memberId: map['member_id'] as int,
      mealDate: DateTime.parse(map['meal_date'] as String), // Parse from YYYY-MM-DD string
      breakfastMeals: (map['breakfast_meals'] as num).toDouble(),
      lunchMeals: (map['lunch_meals'] as num).toDouble(),
      dinnerMeals: (map['dinner_meals'] as num).toDouble(),
      guestMeals: (map['guest_meals'] as num).toDouble(),
    );
  }

  /// Creates a copy of this MealEntry object with optional new values.
  MealEntry copyWith({
    int? id,
    int? memberId,
    DateTime? mealDate,
    double? breakfastMeals,
    double? lunchMeals,
    double? dinnerMeals,
    double? guestMeals,
  }) {
    return MealEntry(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      mealDate: mealDate ?? this.mealDate,
      breakfastMeals: breakfastMeals ?? this.breakfastMeals,
      lunchMeals: lunchMeals ?? this.lunchMeals,
      dinnerMeals: dinnerMeals ?? this.dinnerMeals,
      guestMeals: guestMeals ?? this.guestMeals,
    );
  }

  @override
  String toString() {
    return 'MealEntry(id: $id, memberId: $memberId, mealDate: $mealDate, '
        'breakfastMeals: $breakfastMeals, lunchMeals: $lunchMeals, '
        'dinnerMeals: $dinnerMeals, guestMeals: $guestMeals)';
  }
}
