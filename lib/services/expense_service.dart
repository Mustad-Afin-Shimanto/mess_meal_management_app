// lib/services/expense_service.dart
import 'package:mess_meal_management_app/database/database_helper.dart';
import 'package:mess_meal_management_app/models/expense.dart';
import 'package:mess_meal_management_app/models/contribution.dart'; // Ensure Contribution model is imported
import 'package:mess_meal_management_app/utils/app_constants.dart';
import 'package:mess_meal_management_app/utils/date_helpers.dart';

/// Service class for managing expense-related data in the database.
class ExpenseService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Adds a new expense.
  Future<int> addExpense(Expense expense) async {
    return await _dbHelper.insert(AppConstants.tableExpenses, expense.toMap());
  }

  /// Retrieves all expenses.
  Future<List<Expense>> getAllExpenses() async {
    final List<Map<String, dynamic>> maps = await _dbHelper.queryAll(AppConstants.tableExpenses);
    return List.generate(maps.length, (i) => Expense.fromMap(maps[i]));
  }

  // NOTE: getExpensesByMember has been removed as per the requirement that
  // expenses are not tied to individual members.

  /// Updates an existing expense.
  Future<bool> updateExpense(Expense expense) async {
    final int rowsAffected = await _dbHelper.update(
      AppConstants.tableExpenses,
      expense.toMap(),
      '${AppConstants.columnExpenseId} = ?',
      [expense.id],
    );
    return rowsAffected > 0;
  }

  /// Deletes an expense by its ID.
  Future<bool> deleteExpense(int id) async {
    final int rowsAffected = await _dbHelper.delete(
      AppConstants.tableExpenses,
      '${AppConstants.columnExpenseId} = ?',
      [id],
    );
    return rowsAffected > 0;
  }

  /// Calculates the total expenses for the entire mess for a given month and year.
  Future<double> getMonthlyTotalExpensesForMess(int month, int year) async {
    final String startOfMonth = DateHelpers.formatDateToYYYYMMDD(DateTime(year, month, 1));
    final String endOfMonth = DateHelpers.formatDateToYYYYMMDD(DateTime(year, month + 1, 0));

    final List<Map<String, dynamic>> result = await _dbHelper.rawQuery('''
      SELECT SUM(${AppConstants.columnExpenseAmount}) as total_amount
      FROM ${AppConstants.tableExpenses}
      WHERE ${AppConstants.columnExpenseDate} BETWEEN ? AND ?
    ''', [startOfMonth, endOfMonth]);

    if (result.isNotEmpty && result.first['total_amount'] != null) {
      return (result.first['total_amount'] as num).toDouble();
    }
    return 0.0;
  }

  // Contributions related methods (assuming they are still handled by ExpenseService)

  /// Adds a new contribution.
  Future<int> addContribution(Contribution contribution) async {
    return await _dbHelper.insert(AppConstants.tableContributions, contribution.toMap());
  }

  /// Retrieves all contributions.
  Future<List<Contribution>> getAllContributions() async {
    final List<Map<String, dynamic>> maps = await _dbHelper.queryAll(AppConstants.tableContributions);
    return List.generate(maps.length, (i) => Contribution.fromMap(maps[i]));
  }

  /// Retrieves contributions by a specific member.
  Future<List<Contribution>> getContributionsByMember(int memberId) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      AppConstants.tableContributions,
      where: '${AppConstants.columnContributionMemberId} = ?',
      whereArgs: [memberId],
      orderBy: '${AppConstants.columnContributionDate} DESC',
    );
    return List.generate(maps.length, (i) => Contribution.fromMap(maps[i]));
  }

  /// Updates an existing contribution.
  Future<bool> updateContribution(Contribution contribution) async {
    final int rowsAffected = await _dbHelper.update(
      AppConstants.tableContributions,
      contribution.toMap(),
      '${AppConstants.columnContributionId} = ?',
      [contribution.id],
    );
    return rowsAffected > 0;
  }

  /// Deletes a contribution by its ID.
  Future<bool> deleteContribution(int id) async {
    final int rowsAffected = await _dbHelper.delete(
      AppConstants.tableContributions,
      '${AppConstants.columnContributionId} = ?',
      [id],
    );
    return rowsAffected > 0;
  }

  /// Calculates the total contributions for the entire mess for a given month and year.
  Future<double> getMonthlyTotalContributionsForMess(int month, int year) async {
    final String startOfMonth = DateHelpers.formatDateToYYYYMMDD(DateTime(year, month, 1));
    final String endOfMonth = DateHelpers.formatDateToYYYYMMDD(DateTime(year, month + 1, 0));

    final List<Map<String, dynamic>> result = await _dbHelper.rawQuery('''
      SELECT SUM(${AppConstants.columnContributionAmount}) as total_amount
      FROM ${AppConstants.tableContributions}
      WHERE ${AppConstants.columnContributionDate} BETWEEN ? AND ?
    ''', [startOfMonth, endOfMonth]);

    if (result.isNotEmpty && result.first['total_amount'] != null) {
      return (result.first['total_amount'] as num).toDouble();
    }
    return 0.0;
  }

  /// Fetches expenses for a specific month and year.
  /// This method is crucial for gathering historical data for prediction.
  Future<List<Expense>> getExpensesForMonth(int month, int year) async {
    final String startOfMonth = DateHelpers.formatDateToYYYYMMDD(DateTime(year, month, 1));
    final String endOfMonth = DateHelpers.formatDateToYYYYMMDD(DateHelpers.lastDayOfMonth(DateTime(year, month, 1)));

    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      AppConstants.tableExpenses,
      where: '${AppConstants.columnExpenseDate} BETWEEN ? AND ?',
      whereArgs: [startOfMonth, endOfMonth],
      orderBy: '${AppConstants.columnExpenseDate} ASC',
    );
    return List.generate(maps.length, (i) => Expense.fromMap(maps[i]));
  }
}
