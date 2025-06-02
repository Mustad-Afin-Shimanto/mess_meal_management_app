// lib/screens/shared/financial_report_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mess_meal_management_app/models/monthly_summary.dart';
import 'package:mess_meal_management_app/providers/meal_provider.dart';
import 'package:mess_meal_management_app/providers/expense_provider.dart';
import 'package:mess_meal_management_app/providers/member_provider.dart';
import 'package:mess_meal_management_app/utils/app_constants.dart';
import 'package:mess_meal_management_app/utils/date_helpers.dart';
import 'package:mess_meal_management_app/models/member.dart';

/// Screen for viewing comprehensive monthly financial reports.
class FinancialReportScreen extends StatefulWidget {
  const FinancialReportScreen({super.key});

  @override
  State<FinancialReportScreen> createState() => _FinancialReportScreenState();
}

class _FinancialReportScreenState extends State<FinancialReportScreen> {
  DateTime _selectedDate = DateTime.now();
  MonthlySummary? _monthlySummary;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _generateReport();
  }

  /// Generates the financial report for the selected month.
  Future<void> _generateReport() async {
    setState(() {
      _isLoading = true;
      _monthlySummary = null;
    });

    final mealProvider = Provider.of<MealProvider>(context, listen: false);
    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
    final memberProvider = Provider.of<MemberProvider>(context, listen: false);

    try {
      // Ensure all necessary data is fetched
      await memberProvider.fetchAllMembers();
      await mealProvider.calculateMonthlyMeals(_selectedDate.month, _selectedDate.year);
      await expenseProvider.calculateMonthlyFinancials(_selectedDate.month, _selectedDate.year);

      final List<Member> allMembers = memberProvider.members;
      final double totalMessMeals = mealProvider.monthlyMessMeals;
      final double totalMessExpenses = expenseProvider.monthlyTotalExpenses;
      final double totalMessContributions = expenseProvider.monthlyTotalContributions;

      double mealRate = 0.0;
      if (totalMessMeals > 0) {
        mealRate = totalMessExpenses / totalMessMeals;
      }

      List<MemberBalance> memberBalances = [];
      for (Member member in allMembers) {
        // personalMeals now includes regular meals + guest meals recorded by this member
        final personalMeals = await mealProvider.getMonthlyTotalMealsForMember(
            member.id!, _selectedDate.month, _selectedDate.year);
        final personalContributions = await expenseProvider.fetchContributionsByMember(member.id!)
            .then((list) => list.where((c) => DateHelpers.isSameDay(DateHelpers.firstDayOfMonth(_selectedDate), DateHelpers.firstDayOfMonth(c.contributionDate))).fold(0.0, (sum, item) => sum + item.amount));

        // Calculate individual share of expenses and balance for the FINAL monthly report
        final shareOfExpenses = personalMeals * mealRate;
        final balance = personalContributions - shareOfExpenses;

        memberBalances.add(MemberBalance(
          memberId: member.id!,
          memberName: member.name,
          personalMeals: personalMeals,
          personalContributions: personalContributions,
          shareOfExpenses: shareOfExpenses,
          balance: balance,
        ));
      }

      setState(() {
        _monthlySummary = MonthlySummary(
          month: _selectedDate.month,
          year: _selectedDate.year,
          totalMessMeals: totalMessMeals,
          totalMessExpenses: totalMessExpenses,
          totalMessContributions: totalMessContributions,
          mealRate: mealRate,
          memberBalances: memberBalances,
        );
      });
    } catch (e) {
      print('Error generating financial report: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate report: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Allows the user to select a different month for the report.
  Future<void> _selectMonth(BuildContext context) async {
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
            ), dialogTheme: DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month, 1);
      });
      _generateReport();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.financialReport),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectMonth(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _monthlySummary == null
          ? const Center(child: Text('No data available for this month.'))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                'Report for ${DateHelpers.formatMonthYear(_selectedDate)}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            const SizedBox(height: AppConstants.paddingLarge),
            _buildSummaryCard(
              'Overall Mess Summary',
              [
                'Total Meals: ${_monthlySummary!.totalMessMeals.toStringAsFixed(2)}',
                'Total Expenses: ৳${_monthlySummary!.totalMessExpenses.toStringAsFixed(2)}',
                'Total Contributions: ৳${_monthlySummary!.totalMessContributions.toStringAsFixed(2)}',
                'Current Mess Balance: ৳${Provider.of<ExpenseProvider>(context).currentMessBalance.toStringAsFixed(2)}',
                'Final Meal Rate: ৳${_monthlySummary!.mealRate.toStringAsFixed(2)} / meal',
              ],
              Icons.summarize,
              Theme.of(context).primaryColor.withOpacity(0.1),
            ),
            const SizedBox(height: AppConstants.paddingLarge),
            Text(
              'Individual Member Details:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _monthlySummary!.memberBalances.length,
              itemBuilder: (context, index) {
                final memberBalance = _monthlySummary!.memberBalances[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingMedium),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          memberBalance.memberName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        const Divider(),
                        _buildDetailRow('Personal Meals', '${memberBalance.personalMeals.toStringAsFixed(2)} meals'),
                        _buildDetailRow('Personal Contributions', '৳${memberBalance.personalContributions.toStringAsFixed(2)}'),
                        _buildDetailRow('Share of Expenses', '৳${memberBalance.shareOfExpenses.toStringAsFixed(2)}'),
                        _buildDetailRow(
                          'Balance',
                          memberBalance.balance >= 0
                              ? 'Owed: ৳${memberBalance.balance.toStringAsFixed(2)}'
                              : 'Owed: ৳${(memberBalance.balance * -1).toStringAsFixed(2)}',
                          isBalance: true,
                          balanceColor: memberBalance.balance >= 0 ? Colors.green : Colors.red,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, List<String> details, IconData icon, Color cardColor) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 30, color: Theme.of(context).primaryColor),
                const SizedBox(width: AppConstants.paddingSmall),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            const Divider(),
            ...details.map((detail) => Padding(
              padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingSmall / 2),
              child: Text(
                detail,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBalance = false, Color? balanceColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingSmall / 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: isBalance ? FontWeight.bold : FontWeight.normal,
              color: isBalance ? balanceColor : null,
            ),
          ),
        ],
      ),
    );
  }
}
