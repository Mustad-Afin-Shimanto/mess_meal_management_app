// lib/screens/member/personal_expense_history_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mess_meal_management_app/models/expense.dart';
import 'package:mess_meal_management_app/providers/expense_provider.dart';
import 'package:mess_meal_management_app/utils/app_constants.dart';
import 'package:mess_meal_management_app/utils/date_helpers.dart';

/// Screen for a member to view the mess's expense history (accessible by members).
class PersonalExpenseHistoryScreen extends StatefulWidget {
  const PersonalExpenseHistoryScreen({super.key}); // Fixed: super.key

  @override
  State<PersonalExpenseHistoryScreen> createState() => _PersonalExpenseHistoryScreenState();
}

class _PersonalExpenseHistoryScreenState extends State<PersonalExpenseHistoryScreen> {
  DateTime _selectedMonth = DateTime.now();
  List<Expense> _expenses = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchExpensesForMonth();
  }

  /// Fetches expenses for the selected month.
  Future<void> _fetchExpensesForMonth() async {
    setState(() {
      _isLoading = true;
      _expenses = [];
    });

    final expenseService = Provider.of<ExpenseProvider>(context, listen: false);

    try {
      // Assuming ExpenseProvider has a method to get expenses for a specific month
      // If not, we'd need to add one to ExpenseService and ExpenseProvider.
      // For now, let's filter the general list by month.
      // A more efficient approach would be to add a dedicated service method.
      final allExpenses = await expenseService.fetchAllExpenses(); // Fetch all and filter
      if (!mounted) return; // Fixed: BuildContext across async gaps

      setState(() {
        _expenses = allExpenses.where((expense) =>
        expense.expenseDate.month == _selectedMonth.month &&
            expense.expenseDate.year == _selectedMonth.year
        ).toList();
      });
    } catch (e) {
      debugPrint('Error fetching expenses for month: $e'); // Fixed: Use debugPrint
      if (!mounted) return; // Fixed: BuildContext across async gaps
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load expenses: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Allows the user to select a different month for the history.
  Future<void> _selectMonth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogTheme: const DialogThemeData( // Fixed: Use DialogThemeData
              backgroundColor: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedMonth) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month, 1);
      });
      _fetchExpensesForMonth(); // Re-fetch data for the new month
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.personalExpenseHistory),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectMonth(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _expenses.isEmpty
          ? Center(child: Text('No expenses recorded for ${DateHelpers.formatMonthYear(_selectedMonth)}.'))
          : ListView.builder(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        itemCount: _expenses.length,
        itemBuilder: (context, index) {
          final expense = _expenses[index];
          return Card(
            margin: const EdgeInsets.only(bottom: AppConstants.paddingSmall),
            elevation: 2,
            child: ListTile(
              title: Text(
                '৳${expense.amount.toStringAsFixed(2)} - ${expense.description ?? 'No Description'}', // Fixed: Handle nullable description
                style: Theme.of(context).textTheme.titleMedium,
              ),
              subtitle: Text(DateHelpers.formatDate(expense.expenseDate)),
            ),
          );
        },
      ),
    );
  }
}
