// lib/services/meal_service.dart
import 'package:mess_meal_management_app/database/database_helper.dart';
import 'package:mess_meal_management_app/models/meal_entry.dart';
import 'package:mess_meal_management_app/utils/app_constants.dart';
import 'package:mess_meal_management_app/utils/date_helpers.dart'; // Import for date formatting

/// Service class for managing meal-related data in the database.
class MealService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Adds a new meal entry.
  Future<int> addMealEntry(MealEntry mealEntry) async {
    return await _dbHelper.insert(AppConstants.tableMealEntries, mealEntry.toMap());
  }

  /// Retrieves all meal entries.
  Future<List<MealEntry>> getAllMealEntries() async {
    final List<Map<String, dynamic>> maps = await _dbHelper.queryAll(AppConstants.tableMealEntries);
    return List.generate(maps.length, (i) => MealEntry.fromMap(maps[i]));
  }

  /// Retrieves meal entries for a specific date.
  Future<List<MealEntry>> getMealEntriesForDate(DateTime date) async {
    final String formattedDate = DateHelpers.formatDateToYYYYMMDD(date);
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      AppConstants.tableMealEntries,
      where: '${AppConstants.columnMealDate} = ?',
      whereArgs: [formattedDate],
      orderBy: '${AppConstants.columnMealMemberId} ASC', // Order by member for consistency
    );
    return List.generate(maps.length, (i) => MealEntry.fromMap(maps[i]));
  }

  /// Retrieves meal entries for a specific member for a given month and year.
  Future<List<MealEntry>> getMealEntriesByMemberForMonth(int memberId, int month, int year) async {
    final String startOfMonth = DateHelpers.formatDateToYYYYMMDD(DateTime(year, month, 1));
    final String endOfMonth = DateHelpers.formatDateToYYYYMMDD(DateTime(year, month + 1, 0)); // Last day of the month

    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      AppConstants.tableMealEntries,
      where: '${AppConstants.columnMealMemberId} = ? AND ${AppConstants.columnMealDate} BETWEEN ? AND ?',
      whereArgs: [memberId, startOfMonth, endOfMonth],
      orderBy: '${AppConstants.columnMealDate} ASC',
    );
    return List.generate(maps.length, (i) => MealEntry.fromMap(maps[i]));
  }

  /// Retrieves a single meal entry by its ID.
  Future<MealEntry?> getMealEntryById(int id) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      AppConstants.tableMealEntries,
      where: '${AppConstants.columnMealEntryId} = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return MealEntry.fromMap(maps.first);
    }
    return null;
  }


  /// Updates an existing meal entry.
  Future<bool> updateMealEntry(MealEntry mealEntry) async {
    final int rowsAffected = await _dbHelper.update(
      AppConstants.tableMealEntries,
      mealEntry.toMap(),
      '${AppConstants.columnMealEntryId} = ?',
      [mealEntry.id],
    );
    return rowsAffected > 0;
  }

  /// Deletes a meal entry by its ID.
  Future<bool> deleteMealEntry(int id) async {
    final int rowsAffected = await _dbHelper.delete(
      AppConstants.tableMealEntries,
      '${AppConstants.columnMealEntryId} = ?',
      [id],
    );
    return rowsAffected > 0;
  }

  /// Calculates the total meals for the entire mess for a given month and year.
  Future<double> getMonthlyTotalMealsForMess(int month, int year) async {
    final String startOfMonth = DateHelpers.formatDateToYYYYMMDD(DateTime(year, month, 1));
    final String endOfMonth = DateHelpers.formatDateToYYYYMMDD(DateTime(year, month + 1, 0)); // Last day of the month

    final List<Map<String, dynamic>> result = await _dbHelper.rawQuery('''
      SELECT SUM(${AppConstants.columnBreakfastMeals}) +
             SUM(${AppConstants.columnLunchMeals}) +
             SUM(${AppConstants.columnDinnerMeals}) +
             SUM(${AppConstants.columnGuestMeals}) as total_meals
      FROM ${AppConstants.tableMealEntries}
      WHERE ${AppConstants.columnMealDate} BETWEEN ? AND ?
    ''', [startOfMonth, endOfMonth]);

    if (result.isNotEmpty && result.first['total_meals'] != null) {
      return (result.first['total_meals'] as num).toDouble();
    }
    return 0.0;
  }

  /// Retrieves the total meals for a specific member for a given month and year.
  Future<double> getMonthlyTotalMealsForMember(int memberId, int month, int year) async {
    final String startOfMonth = DateHelpers.formatDateToYYYYMMDD(DateTime(year, month, 1));
    final String endOfMonth = DateHelpers.formatDateToYYYYMMDD(DateTime(year, month + 1, 0)); // Last day of the month

    final List<Map<String, dynamic>> result = await _dbHelper.rawQuery('''
      SELECT SUM(${AppConstants.columnBreakfastMeals}) +
             SUM(${AppConstants.columnLunchMeals}) +
             SUM(${AppConstants.columnDinnerMeals}) +
             SUM(${AppConstants.columnGuestMeals}) as total_meals
      FROM ${AppConstants.tableMealEntries}
      WHERE ${AppConstants.columnMealMemberId} = ? AND ${AppConstants.columnMealDate} BETWEEN ? AND ?
    ''', [memberId, startOfMonth, endOfMonth]);

    if (result.isNotEmpty && result.first['total_meals'] != null) {
      return (result.first['total_meals'] as num).toDouble();
    }
    return 0.0;
  }
}
