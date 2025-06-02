// lib/screens/member/personal_contribution_history_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mess_meal_management_app/models/contribution.dart';
import 'package:mess_meal_management_app/providers/expense_provider.dart'; // Manages contributions
import 'package:mess_meal_management_app/providers/user_provider.dart';
import 'package:mess_meal_management_app/utils/app_constants.dart';
import 'package:mess_meal_management_app/utils/date_helpers.dart';

/// Screen for members to view their personal contribution history.
class PersonalContributionHistoryScreen extends StatefulWidget {
  const PersonalContributionHistoryScreen({super.key});

  @override
  State<PersonalContributionHistoryScreen> createState() => _PersonalContributionHistoryScreenState();
}

class _PersonalContributionHistoryScreenState extends State<PersonalContributionHistoryScreen> {
  List<Contribution> _contributionHistory = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchPersonalContributionHistory();
  }

  /// Fetches the contribution history for the current logged-in member.
  Future<void> _fetchPersonalContributionHistory() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);

      final int? memberId = userProvider.currentMember?.id;
      if (memberId != null) {
        _contributionHistory = await expenseProvider.fetchContributionsByMember(memberId);
      } else {
        _contributionHistory = [];
      }
    } catch (e) {
      print('Error fetching personal contribution history: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load contribution history: $e')),
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
        title: const Text(AppConstants.personalContributionHistory),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _contributionHistory.isEmpty
          ? const Center(child: Text('No contribution entries found for you.'))
          : ListView.builder(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        itemCount: _contributionHistory.length,
        itemBuilder: (context, index) {
          final contribution = _contributionHistory[index];
          return Card(
            margin: const EdgeInsets.only(bottom: AppConstants.paddingSmall),
            elevation: 2,
            child: ListTile(
              title: Text('Amount: \$${contribution.amount.toStringAsFixed(2)}'),
              subtitle: Text('Date: ${DateHelpers.formatDate(contribution.contributionDate)}'),
              leading: Icon(Icons.money, color: Theme.of(context).primaryColor),
            ),
          );
        },
      ),
    );
  }
}
