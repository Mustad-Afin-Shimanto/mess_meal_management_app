// lib/screens/manager/manage_contributions_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mess_meal_management_app/models/contribution.dart';
import 'package:mess_meal_management_app/models/member.dart';
import 'package:mess_meal_management_app/providers/expense_provider.dart'; // Handles contributions
import 'package:mess_meal_management_app/providers/member_provider.dart';
import 'package:mess_meal_management_app/utils/app_constants.dart';
import 'package:mess_meal_management_app/utils/date_helpers.dart';
import 'package:mess_meal_management_app/widgets/custom_button.dart';

/// Screen for managers to record and manage member contributions.
class ManageContributionsScreen extends StatefulWidget {
  const ManageContributionsScreen({super.key});

  @override
  State<ManageContributionsScreen> createState() => _ManageContributionsScreenState();
}

class _ManageContributionsScreenState extends State<ManageContributionsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  Member? _selectedMember;
  bool _isLoading = false;
  List<Contribution> _contributions = [];
  Contribution? _editingContribution;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  /// Fetches all contributions and active members.
  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
      final memberProvider = Provider.of<MemberProvider>(context, listen: false);

      await expenseProvider.fetchAllContributions();
      _contributions = expenseProvider.contributions;

      await memberProvider.fetchActiveMembers();
      if (memberProvider.activeMembers.isNotEmpty && _selectedMember == null) {
        _selectedMember = memberProvider.activeMembers.first;
      }
    } catch (e) {
      print('Error fetching contribution data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load contribution data: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Allows the user to select a date for the contribution.
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
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
        _selectedDate = picked;
      });
    }
  }

  /// Handles adding or updating a contribution.
  Future<void> _saveContribution() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedMember == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a member.')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);

      final contribution = Contribution(
        id: _editingContribution?.id,
        memberId: _selectedMember!.id!,
        amount: double.parse(_amountController.text),
        contributionDate: _selectedDate,
      );

      bool success;
      if (_editingContribution == null) {
        success = await expenseProvider.addContribution(contribution);
      } else {
        success = await expenseProvider.updateContribution(contribution);
      }

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_editingContribution == null ? 'Contribution added successfully!' : 'Contribution updated successfully!')),
        );
        _clearForm();
        await _fetchData(); // Refresh list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_editingContribution == null ? 'Failed to add contribution.' : 'Failed to update contribution.')),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Sets the form fields for editing an existing contribution.
  void _editContribution(Contribution contribution) {
    setState(() {
      _editingContribution = contribution;
      _amountController.text = contribution.amount.toString();
      _selectedDate = contribution.contributionDate;
      _selectedMember = Provider.of<MemberProvider>(context, listen: false).getMemberById(contribution.memberId);
    });
  }

  /// Deletes a contribution.
  Future<void> _deleteContribution(int id) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete Contribution'),
          content: const Text('Are you sure you want to delete this contribution?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });
      final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
      final bool success = await expenseProvider.deleteContribution(id);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contribution deleted successfully!')),
        );
        _clearForm();
        await _fetchData(); // Refresh list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete contribution.')),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Clears the form fields and resets editing state.
  void _clearForm() {
    _amountController.clear();
    setState(() {
      _selectedDate = DateTime.now();
      _editingContribution = null;
      // Reset selected member to the first active member if available
      final memberProvider = Provider.of<MemberProvider>(context, listen: false);
      if (memberProvider.activeMembers.isNotEmpty) {
        _selectedMember = memberProvider.activeMembers.first;
      } else {
        _selectedMember = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.manageContributions),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Amount (৳)', // Changed from $ to ৳
                      prefixIcon: Icon(Icons.money),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an amount';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  ListTile(
                    title: Text('Date: ${DateHelpers.formatDate(_selectedDate)}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => _selectDate(context),
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  Consumer<MemberProvider>(
                    builder: (context, memberProvider, child) {
                      return DropdownButtonFormField<Member>(
                        value: _selectedMember,
                        decoration: const InputDecoration(
                          labelText: 'Member Who Contributed',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        items: memberProvider.activeMembers.map((member) {
                          return DropdownMenuItem<Member>(
                            value: member,
                            child: Text(member.name),
                          );
                        }).toList(),
                        onChanged: (Member? newValue) {
                          setState(() {
                            _selectedMember = newValue;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a member';
                          }
                          return null;
                        },
                      );
                    },
                  ),
                  const SizedBox(height: AppConstants.paddingLarge),
                  CustomButton(
                    text: _editingContribution == null ? 'Add Contribution' : 'Update Contribution',
                    onPressed: _saveContribution,
                  ),
                  if (_editingContribution != null)
                    Padding(
                      padding: const EdgeInsets.only(top: AppConstants.paddingSmall),
                      child: CustomButton(
                        text: 'Cancel Edit',
                        onPressed: _clearForm,
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const Divider(),
          Expanded(
            child: _contributions.isEmpty
                ? const Center(child: Text('No contributions recorded yet.'))
                : ListView.builder(
              itemCount: _contributions.length,
              itemBuilder: (context, index) {
                final contribution = _contributions[index];
                final memberName = Provider.of<MemberProvider>(context, listen: false)
                    .getMemberById(contribution.memberId)
                    ?.name ?? 'Unknown';
                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingMedium,
                      vertical: AppConstants.paddingSmall),
                  elevation: 1,
                  child: ListTile(
                    title: Text('$memberName contributed ৳${contribution.amount.toStringAsFixed(2)}'), // Changed from $ to ৳
                    subtitle: Text('Date: ${DateHelpers.formatDate(contribution.contributionDate)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _editContribution(contribution),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteContribution(contribution.id!),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
