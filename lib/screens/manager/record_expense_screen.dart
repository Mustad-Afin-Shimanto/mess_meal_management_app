// lib/screens/manager/record_expense_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mess_meal_management_app/models/expense.dart';
import 'package:mess_meal_management_app/providers/expense_provider.dart';
import 'package:mess_meal_management_app/utils/app_constants.dart';
import 'package:mess_meal_management_app/utils/date_helpers.dart';

/// Screen for managers to record daily expenses for the mess.
class RecordExpenseScreen extends StatefulWidget {
  const RecordExpenseScreen({super.key}); // Fixed: super.key

  @override
  State<RecordExpenseScreen> createState() => _RecordExpenseScreenState();
}

class _RecordExpenseScreenState extends State<RecordExpenseScreen> {
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  Expense? _editingExpense; // To hold the expense being edited

  @override
  void initState() {
    super.initState();
    _fetchExpenses();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Fetches all expenses to update the list.
  Future<void> _fetchExpenses() async {
    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
    await expenseProvider.fetchAllExpenses();
  }

  /// Allows the user to select a different date for the expense.
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
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

    if (picked != null && picked != _selectedDate) {
      if (!mounted) return; // Fixed: BuildContext across async gaps
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  /// Sets the form fields for editing an existing expense.
  void _setForEdit(Expense expense) {
    setState(() {
      _editingExpense = expense;
      _selectedDate = expense.expenseDate;
      _amountController.text = expense.amount.toStringAsFixed(2);
      _descriptionController.text = expense.description ?? ''; // Fixed: Handle nullable description
    });
  }

  /// Saves or updates an expense.
  Future<void> _saveExpense() async {
    if (_amountController.text.isEmpty || double.tryParse(_amountController.text) == null) {
      if (!mounted) return; // Fixed: BuildContext across async gaps
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount.')),
      );
      return;
    }

    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);

    final double amount = double.parse(_amountController.text);
    final String? description = _descriptionController.text.isEmpty ? null : _descriptionController.text;

    final Expense newExpense = Expense(
      id: _editingExpense?.id, // Use existing ID if editing
      expenseDate: _selectedDate,
      amount: amount,
      description: description,
    );

    bool success = false;
    if (_editingExpense == null) {
      success = await expenseProvider.addExpense(newExpense);
    } else {
      success = await expenseProvider.updateExpense(newExpense);
    }

    if (!mounted) return; // Fixed: BuildContext across async gaps
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Expense ${ _editingExpense == null ? 'added' : 'updated'} successfully!')),
      );
      _clearForm(); // Clear form after successful save
      await _fetchExpenses(); // Refresh list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save expense.')),
      );
    }
  }

  /// Deletes an expense.
  Future<void> _deleteExpense(int id) async {
    final bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: const Text('Are you sure you want to delete this expense?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false); // Fixed: BuildContext across async gaps
      final success = await expenseProvider.deleteExpense(id);
      if (!mounted) return; // Fixed: BuildContext across async gaps
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense deleted successfully!')),
        );
        _clearForm(); // Clear form as the edited item might be deleted
        await _fetchExpenses(); // Refresh list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete expense.')),
        );
      }
    }
  }

  /// Clears the form fields and resets editing state.
  void _clearForm() {
    setState(() {
      _selectedDate = DateTime.now();
      _amountController.clear();
      _descriptionController.clear();
      _editingExpense = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.recordExpense),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchExpenses,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recording Expense for: ${DateHelpers.formatDate(_selectedDate)}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount (৳)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppConstants.paddingSmall),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: AppConstants.paddingLarge),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saveExpense,
                    icon: Icon(_editingExpense == null ? Icons.add : Icons.save),
                    label: Text(_editingExpense == null ? 'Add Expense' : 'Update Expense'),
                  ),
                ),
                if (_editingExpense != null) ...[
                  const SizedBox(width: AppConstants.paddingMedium),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _clearForm,
                      icon: const Icon(Icons.cancel),
                      label: const Text('Cancel Edit'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppConstants.paddingLarge),
            Text(
              'Recent Expenses:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            Consumer<ExpenseProvider>(
              builder: (context, expenseProvider, child) {
                if (expenseProvider.expenses.isEmpty) {
                  return const Center(child: Text('No expenses recorded yet.'));
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: expenseProvider.expenses.length,
                  itemBuilder: (context, index) {
                    final expense = expenseProvider.expenses[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: AppConstants.paddingSmall),
                      elevation: 2,
                      child: ListTile(
                        title: Text(
                          '৳${expense.amount.toStringAsFixed(2)} - ${expense.description ?? 'No Description'}', // Fixed: Handle nullable description
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        subtitle: Text(DateHelpers.formatDate(expense.expenseDate)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: Theme.of(context).primaryColor),
                              onPressed: () => _setForEdit(expense),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteExpense(expense.id!),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
