// lib/providers/expense_provider.dart
import 'package:flutter/material.dart';
import 'package:mess_meal_management_app/models/expense.dart';
import 'package:mess_meal_management_app/models/contribution.dart';
import 'package:mess_meal_management_app/services/expense_service.dart';
import 'package:mess_meal_management_app/services/contribution_service.dart'; // Assuming contributions have their own service now
// Import DateHelpers for date manipulation

/// Represents a monthly expense summary for the ExpenseAnalysisScreen.
class MonthlyExpenseSummary {
  final int month;
  final int year;
  final double amount;
  final bool isPredicted;

  MonthlyExpenseSummary({
    required this.month,
    required this.year,
    required this.amount,
    this.isPredicted = false,
  });
}

/// Provider for managing Expense and Contribution data.
class ExpenseProvider with ChangeNotifier {
  final ExpenseService _expenseService;
  final ContributionService _contributionService; // Use a dedicated service for contributions

  List<Expense> _expenses = [];
  List<Contribution> _contributions = [];
  double _monthlyTotalExpenses = 0.0;
  double _monthlyTotalContributions = 0.0;
  double _currentMessBalance = 0.0;
  double _predictedNextMonthExpenses = 0.0; // Predicted expenses for the upcoming month (single value for dashboards)

  // New: For ExpenseAnalysisScreen
  List<MonthlyExpenseSummary> _expenseHistoryAndPrediction = [];

  ExpenseProvider(this._expenseService, this._contributionService);

  List<Expense> get expenses => _expenses;
  List<Contribution> get contributions => _contributions;
  double get monthlyTotalExpenses => _monthlyTotalExpenses;
  double get monthlyTotalContributions => _monthlyTotalContributions;
  double get currentMessBalance => _currentMessBalance;
  double get predictedNextMonthExpenses => _predictedNextMonthExpenses;
  List<MonthlyExpenseSummary> get expenseHistoryAndPrediction => _expenseHistoryAndPrediction; // New getter

  /// Fetches all expenses from the database.
  Future<List<Expense>> fetchAllExpenses() async {
    _expenses = await _expenseService.getAllExpenses();
    notifyListeners();
    return _expenses;
  }

  /// Adds a new expense.
  Future<bool> addExpense(Expense expense) async {
    final int id = await _expenseService.addExpense(expense);
    if (id > 0) {
      await fetchAllExpenses(); // Refresh list
      await calculateMonthlyFinancials(expense.expenseDate.month, expense.expenseDate.year); // Recalculate financials
      await calculatePredictedNextMonthExpenses(); // Recalculate prediction for dashboard
      await fetchExpenseHistoryAndPredictions(); // New: Recalculate for analysis screen
      return true;
    }
    return false;
  }

  /// Updates an existing expense.
  Future<bool> updateExpense(Expense expense) async {
    final bool success = await _expenseService.updateExpense(expense);
    if (success) {
      await fetchAllExpenses(); // Refresh list
      await calculateMonthlyFinancials(expense.expenseDate.month, expense.expenseDate.year); // Recalculate financials
      await calculatePredictedNextMonthExpenses(); // Recalculate prediction for dashboard
      await fetchExpenseHistoryAndPredictions(); // New: Recalculate for analysis screen
    }
    return success;
  }

  /// Deletes an expense.
  Future<bool> deleteExpense(int id) async {
    final bool success = await _expenseService.deleteExpense(id);
    if (success) {
      // Re-fetch all expenses to get the latest list and then recalculate financials
      await fetchAllExpenses();
      // Since we don't have the date of the deleted expense directly,
      // recalculate for the current month or the month of the last known expense.
      // A more robust solution might pass the month/year of the deleted expense.
      // For now, we'll recalculate for the current month.
      await calculateMonthlyFinancials(DateTime.now().month, DateTime.now().year);
      await calculatePredictedNextMonthExpenses(); // Recalculate prediction for dashboard
      await fetchExpenseHistoryAndPredictions(); // New: Recalculate for analysis screen
    }
    return success;
  }

  /// Fetches all contributions from the database.
  Future<List<Contribution>> fetchAllContributions() async {
    _contributions = await _contributionService.getAllContributions();
    notifyListeners();
    return _contributions;
  }

  /// Adds a new contribution.
  Future<bool> addContribution(Contribution contribution) async {
    final int id = await _contributionService.addContribution(contribution);
    if (id > 0) {
      await fetchAllContributions(); // Refresh list
      await calculateMonthlyFinancials(contribution.contributionDate.month, contribution.contributionDate.year); // Recalculate financials
      return true;
    }
    return false;
  }

  /// Updates an existing contribution.
  Future<bool> updateContribution(Contribution contribution) async {
    final bool success = await _contributionService.updateContribution(contribution);
    if (success) {
      await fetchAllContributions(); // Refresh list
      await calculateMonthlyFinancials(contribution.contributionDate.month, contribution.contributionDate.year); // Recalculate financials
    }
    return success;
  }

  /// Deletes a contribution.
  Future<bool> deleteContribution(int id) async {
    final bool success = await _contributionService.deleteContribution(id);
    if (success) {
      // Re-fetch all contributions to get the latest list and then recalculate financials
      await fetchAllContributions();
      // Recalculate for the current month or the month of the last known contribution.
      await calculateMonthlyFinancials(DateTime.now().month, DateTime.now().year);
    }
    return success;
  }

  /// Fetches contributions made by a specific member.
  Future<List<Contribution>> fetchContributionsByMember(int memberId) async {
    return await _contributionService.getContributionsByMember(memberId);
  }

  /// Calculates monthly total expenses and contributions for the mess.
  Future<void> calculateMonthlyFinancials(int month, int year) async {
    _monthlyTotalExpenses = await _expenseService.getMonthlyTotalExpensesForMess(month, year);
    _monthlyTotalContributions = await _contributionService.getMonthlyTotalContributionsForMess(month, year);
    _currentMessBalance = _monthlyTotalContributions - _monthlyTotalExpenses;
    notifyListeners();
  }

  /// Calculates the predicted expenses for the upcoming month (single value for dashboards).
  /// Uses a weighted average of previous Julys and the last 3 months.
  Future<void> calculatePredictedNextMonthExpenses() async {
    final DateTime now = DateTime.now();
    final DateTime nextMonth = DateTime(now.year, now.month + 1, 1);
    final int targetMonth = nextMonth.month;
    final int targetYear = nextMonth.year;

    List<double> historicalSeasonalExpenses = [];
    List<double> recentMonthsExpenses = [];

    // --- Gather Historical Seasonal Data (up to 5 previous years for the target month) ---
    for (int i = 1; i <= 5; i++) { // Look back up to 5 years
      final int pastYear = now.year - i;
      final List<Expense> expenses = await _expenseService.getExpensesForMonth(targetMonth, pastYear);
      if (expenses.isNotEmpty) {
        final double total = expenses.fold(0.0, (sum, expense) => sum + expense.amount);
        historicalSeasonalExpenses.add(total);
      }
    }

    // --- Gather Recent Months Data (last 3 months) ---
    for (int i = 1; i <= 3; i++) {
      final DateTime pastMonthDate = DateTime(now.year, now.month - i + 1, 1);
      final List<Expense> expenses = await _expenseService.getExpensesForMonth(pastMonthDate.month, pastMonthDate.year);
      if (expenses.isNotEmpty) {
        final double totalMonth = expenses.fold(0.0, (sum, expense) => sum + expense.amount);
        recentMonthsExpenses.add(totalMonth);
      }
    }

    double historicalSeasonalAverage = 0.0;
    if (historicalSeasonalExpenses.isNotEmpty) {
      historicalSeasonalAverage = historicalSeasonalExpenses.reduce((a, b) => a + b) / historicalSeasonalExpenses.length;
    }

    double recentMonthsAverage = 0.0;
    if (recentMonthsExpenses.isNotEmpty) {
      recentMonthsAverage = recentMonthsExpenses.reduce((a, b) => a + b) / recentMonthsExpenses.length;
    }

    // Apply weighted average (60% recent, 40% historical seasonal)
    if (recentMonthsExpenses.isNotEmpty && historicalSeasonalExpenses.isNotEmpty) {
      _predictedNextMonthExpenses = (recentMonthsAverage * 0.60) + (historicalSeasonalAverage * 0.40);
    } else if (recentMonthsExpenses.isNotEmpty) {
      _predictedNextMonthExpenses = recentMonthsAverage; // Fallback to only recent if no historical seasonal
    } else if (historicalSeasonalExpenses.isNotEmpty) {
      _predictedNextMonthExpenses = historicalSeasonalAverage; // Fallback to only historical seasonal if no recent
    } else {
      _predictedNextMonthExpenses = 0.0; // No data to predict
    }

    notifyListeners();
  }

  /// New: Fetches historical monthly expenses and calculates predictions for future months.
  /// Populates _expenseHistoryAndPrediction for the ExpenseAnalysisScreen.
  Future<void> fetchExpenseHistoryAndPredictions({int pastMonths = 6, int futureMonths = 3}) async {
    _expenseHistoryAndPrediction = [];
    final DateTime now = DateTime.now();

    // --- Fetch Historical Data ---
    for (int i = pastMonths - 1; i >= 0; i--) {
      final DateTime monthDate = DateTime(now.year, now.month - i, 1);
      final double totalExpenses = await _expenseService.getMonthlyTotalExpensesForMess(monthDate.month, monthDate.year);
      _expenseHistoryAndPrediction.add(MonthlyExpenseSummary(
        month: monthDate.month,
        year: monthDate.year,
        amount: totalExpenses,
        isPredicted: false,
      ));
    }

    // --- Calculate Future Predictions ---
    for (int i = 1; i <= futureMonths; i++) {
      final DateTime targetMonthDate = DateTime(now.year, now.month + i, 1);
      final int targetMonth = targetMonthDate.month;
      final int targetYear = targetMonthDate.year;

      List<double> historicalSeasonalExpenses = [];
      List<double> recentMonthsForPrediction = [];

      // Gather Historical Seasonal Data for the target month
      for (int j = 1; j <= 5; j++) { // Look back up to 5 years for seasonal data
        final int pastYear = targetYear - j;
        final List<Expense> expenses = await _expenseService.getExpensesForMonth(targetMonth, pastYear);
        if (expenses.isNotEmpty) {
          final double total = expenses.fold(0.0, (sum, expense) => sum + expense.amount);
          historicalSeasonalExpenses.add(total);
        }
      }

      // Gather Recent Months Data leading up to the target month
      // This needs to be dynamic based on the targetMonthDate
      for (int j = 1; j <= 3; j++) {
        final DateTime recentMonthDate = DateTime(targetMonthDate.year, targetMonthDate.month - j, 1);
        final List<Expense> expenses = await _expenseService.getExpensesForMonth(recentMonthDate.month, recentMonthDate.year);
        if (expenses.isNotEmpty) {
          final double total = expenses.fold(0.0, (sum, expense) => sum + expense.amount);
          recentMonthsForPrediction.add(total);
        }
      }

      double historicalSeasonalAverage = 0.0;
      if (historicalSeasonalExpenses.isNotEmpty) {
        historicalSeasonalAverage = historicalSeasonalExpenses.reduce((a, b) => a + b) / historicalSeasonalExpenses.length;
      }

      double recentMonthsAverage = 0.0;
      if (recentMonthsForPrediction.isNotEmpty) {
        recentMonthsAverage = recentMonthsForPrediction.reduce((a, b) => a + b) / recentMonthsForPrediction.length;
      }

      double predictedAmount = 0.0;
      if (recentMonthsForPrediction.isNotEmpty && historicalSeasonalExpenses.isNotEmpty) {
        predictedAmount = (recentMonthsAverage * 0.60) + (historicalSeasonalAverage * 0.40);
      } else if (recentMonthsForPrediction.isNotEmpty) {
        predictedAmount = recentMonthsAverage;
      } else if (historicalSeasonalExpenses.isNotEmpty) {
        predictedAmount = historicalSeasonalAverage;
      } else {
        predictedAmount = 0.0;
      }

      _expenseHistoryAndPrediction.add(MonthlyExpenseSummary(
        month: targetMonthDate.month,
        year: targetMonthDate.year,
        amount: predictedAmount,
        isPredicted: true,
      ));
    }

    notifyListeners();
  }
}
