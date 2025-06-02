// lib/screens/shared/expense_analysis_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mess_meal_management_app/providers/expense_provider.dart';
import 'package:mess_meal_management_app/utils/app_constants.dart';
import 'package:mess_meal_management_app/utils/date_helpers.dart';

/// A screen to display historical and predicted monthly expenses.
class ExpenseAnalysisScreen extends StatefulWidget {
  const ExpenseAnalysisScreen({super.key});

  @override
  State<ExpenseAnalysisScreen> createState() => _ExpenseAnalysisScreenState();
}

class _ExpenseAnalysisScreenState extends State<ExpenseAnalysisScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  /// Fetches historical and predicted expense data.
  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
      // Fetch 6 past months and 3 future months for analysis
      await expenseProvider.fetchExpenseHistoryAndPredictions(pastMonths: 6, futureMonths: 3);
    } catch (e) {
      print('Error fetching expense analysis data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load expense analysis: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.expenseAnalysis),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<ExpenseProvider>(
        builder: (context, expenseProvider, child) {
          if (expenseProvider.expenseHistoryAndPrediction.isEmpty) {
            return const Center(child: Text('No expense data available for analysis.'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Monthly Expense Overview',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppConstants.paddingLarge),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: expenseProvider.expenseHistoryAndPrediction.length,
                  itemBuilder: (context, index) {
                    final summary = expenseProvider.expenseHistoryAndPrediction[index];
                    final monthYear = DateHelpers.formatMonthYear(DateTime(summary.year, summary.month));
                    final isCurrentMonth = summary.month == DateTime.now().month && summary.year == DateTime.now().year;

                    return Card(
                      margin: const EdgeInsets.only(bottom: AppConstants.paddingSmall),
                      elevation: 2,
                      color: summary.isPredicted
                          ? Colors.blue.shade50 // Light blue for predicted
                          : isCurrentMonth
                          ? Colors.green.shade50 // Light green for current month
                          : Colors.white, // White for past actuals
                      child: Padding(
                        padding: const EdgeInsets.all(AppConstants.paddingMedium),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  monthYear,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: summary.isPredicted ? Theme.of(context).colorScheme.primary : Colors.black87,
                                  ),
                                ),
                                Text(
                                  summary.isPredicted ? 'Predicted' : 'Actual',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontStyle: FontStyle.italic,
                                    color: summary.isPredicted ? Theme.of(context).colorScheme.primary : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '৳${summary.amount.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: summary.isPredicted ? Colors.blue.shade700 : Colors.teal.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppConstants.paddingLarge),
                Text(
                  'Note: Predicted values are estimates based on historical data.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
