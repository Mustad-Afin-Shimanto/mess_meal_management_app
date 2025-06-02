// lib/providers/meal_provider.dart
import 'package:flutter/material.dart';
import 'package:mess_meal_management_app/models/meal_entry.dart';
import 'package:mess_meal_management_app/services/meal_service.dart';
// import 'package:mess_meal_management_app/utils/date_helpers.dart'; // Removed: Unused import

/// Provider for managing meal-related data.
class MealProvider with ChangeNotifier {
  final MealService _mealService;

  List<MealEntry> _mealEntries = [];
  double _monthlyMessMeals = 0.0;

  MealProvider(this._mealService);

  List<MealEntry> get mealEntries => _mealEntries;
  double get monthlyMessMeals => _monthlyMessMeals;

  /// Fetches all meal entries from the database.
  Future<void> fetchAllMealEntries() async {
    _mealEntries = await _mealService.getAllMealEntries();
    notifyListeners();
  }

  /// Adds a new meal entry.
  Future<bool> addMealEntry(MealEntry mealEntry) async {
    final int id = await _mealService.addMealEntry(mealEntry);
    if (id > 0) {
      await fetchAllMealEntries(); // Refresh the full list
      await calculateMonthlyMeals(mealEntry.mealDate.month, mealEntry.mealDate.year); // Recalculate monthly totals
      return true;
    }
    return false;
  }

  /// Updates an existing meal entry.
  Future<bool> updateMealEntry(MealEntry mealEntry) async {
    final bool success = await _mealService.updateMealEntry(mealEntry);
    if (success) {
      await fetchAllMealEntries(); // Refresh the full list
      await calculateMonthlyMeals(mealEntry.mealDate.month, mealEntry.mealDate.year); // Recalculate monthly totals
    }
    return success;
  }

  /// Deletes a meal entry by its ID.
  /// Added `recalculateDate` parameter to ensure correct monthly total recalculation.
  Future<bool> deleteMealEntry(int id, [DateTime? recalculateDate]) async {
    final bool success = await _mealService.deleteMealEntry(id);
    if (success) {
      await fetchAllMealEntries(); // Refresh the full list
      if (recalculateDate != null) {
        await calculateMonthlyMeals(recalculateDate.month, recalculateDate.year);
      } else {
        // Fallback: recalculate for current month if no specific date is provided
        await calculateMonthlyMeals(DateTime.now().month, DateTime.now().year);
      }
    }
    return success;
  }

  /// Calculates the total meals for the entire mess for a given month and year.
  Future<void> calculateMonthlyMeals(int month, int year) async {
    _monthlyMessMeals = await _mealService.getMonthlyTotalMealsForMess(month, year);
    notifyListeners();
  }

  /// Retrieves the total meals for a specific member for a given month and year.
  Future<double> getMonthlyTotalMealsForMember(int memberId, int month, int year) async {
    return await _mealService.getMonthlyTotalMealsForMember(memberId, month, year);
  }

  /// Fetches all meal entries for a specific date.
  Future<List<MealEntry>> getMealEntriesForDate(DateTime date) async {
    return await _mealService.getMealEntriesForDate(date);
  }

  /// Fetches meal entries for a specific member for a given month and year.
  Future<List<MealEntry>> fetchMealEntriesByMember(int memberId, int month, int year) async {
    return await _mealService.getMealEntriesByMemberForMonth(memberId, month, year);
  }

  /// New: Retrieves a single meal entry by its ID.
  Future<MealEntry?> getMealEntryById(int id) async {
    return await _mealService.getMealEntryById(id);
  }
}
