// lib/screens/manager/market_schedule_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mess_meal_management_app/models/market_schedule.dart';
import 'package:mess_meal_management_app/models/member.dart';
import 'package:mess_meal_management_app/providers/market_schedule_provider.dart';
import 'package:mess_meal_management_app/providers/member_provider.dart';
import 'package:mess_meal_management_app/utils/app_constants.dart';
import 'package:mess_meal_management_app/utils/date_helpers.dart';

/// Screen for managers to manage market schedules (assigning duties to members).
class MarketScheduleScreen extends StatefulWidget {
  const MarketScheduleScreen({super.key}); // Fixed: super.key

  @override
  State<MarketScheduleScreen> createState() => _MarketScheduleScreenState();
}

class _MarketScheduleScreenState extends State<MarketScheduleScreen> {
  DateTime _selectedDate = DateTime.now();
  Member? _selectedMember;
  final TextEditingController _dutyTitleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  MarketSchedule? _editingSchedule; // To hold the schedule being edited

  @override
  void initState() {
    super.initState();
    _fetchMembersAndSchedules();
  }

  @override
  void dispose() {
    _dutyTitleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Fetches all members and market schedules.
  Future<void> _fetchMembersAndSchedules() async {
    final memberProvider = Provider.of<MemberProvider>(context, listen: false);
    final marketScheduleProvider = Provider.of<MarketScheduleProvider>(context, listen: false);

    await memberProvider.fetchAllMembers();
    await marketScheduleProvider.fetchUpcomingMarketSchedules(); // Refresh schedules
  }

  /// Allows the user to select a different date for the schedule.
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
      setState(() {
        _selectedDate = picked;
        _selectedMember = null; // Reset member selection for new date
        _dutyTitleController.clear();
        _descriptionController.clear();
        _editingSchedule = null; // Clear editing state
      });
      // Optionally, fetch schedules for the new date if needed for display
      // For now, we only fetch upcoming, so no specific date fetch is needed here.
    }
  }

  /// Sets the form fields for editing an existing schedule.
  void _setForEdit(MarketSchedule schedule) {
    setState(() {
      _editingSchedule = schedule;
      _selectedDate = schedule.scheduleDate;
      _dutyTitleController.text = schedule.dutyTitle;
      _descriptionController.text = schedule.description ?? ''; // Fixed: Handle nullable description
      // Find the member object from the provider's list
      _selectedMember = Provider.of<MemberProvider>(context, listen: false)
          .getMemberById(schedule.memberId);
    });
  }

  /// Saves or updates a market schedule.
  Future<void> _saveSchedule() async {
    if (_selectedMember == null || _dutyTitleController.text.isEmpty) {
      if (!mounted) return; // Fixed: BuildContext across async gaps
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a member and enter a duty title.')),
      );
      return;
    }

    final marketScheduleProvider = Provider.of<MarketScheduleProvider>(context, listen: false);

    final MarketSchedule newSchedule = MarketSchedule(
      id: _editingSchedule?.id, // Use existing ID if editing
      memberId: _selectedMember!.id!,
      scheduleDate: _selectedDate,
      dutyTitle: _dutyTitleController.text,
      description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
    );

    bool success = false;
    if (_editingSchedule == null) {
      success = await marketScheduleProvider.addMarketSchedule(newSchedule);
    } else {
      success = await marketScheduleProvider.updateMarketSchedule(newSchedule);
    }

    if (!mounted) return; // Fixed: BuildContext across async gaps
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Market schedule ${ _editingSchedule == null ? 'added' : 'updated'} successfully!')),
      );
      _clearForm(); // Clear form after successful save
      await marketScheduleProvider.fetchUpcomingMarketSchedules(); // Refresh list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save market schedule.')),
      );
    }
  }

  /// Deletes a market schedule.
  Future<void> _deleteSchedule(int id) async {
    final bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Schedule'),
        content: const Text('Are you sure you want to delete this market schedule?'),
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
      final marketScheduleProvider = Provider.of<MarketScheduleProvider>(context, listen: false); // Fixed: BuildContext across async gaps
      final success = await marketScheduleProvider.deleteMarketSchedule(id);
      if (!mounted) return; // Fixed: BuildContext across async gaps
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Market schedule deleted successfully!')),
        );
        _clearForm(); // Clear form as the edited item might be deleted
        await marketScheduleProvider.fetchUpcomingMarketSchedules(); // Refresh list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete market schedule.')),
        );
      }
    }
  }

  /// Clears the form fields and resets editing state.
  void _clearForm() {
    setState(() {
      _selectedMember = null;
      _selectedDate = DateTime.now();
      _dutyTitleController.clear();
      _descriptionController.clear();
      _editingSchedule = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.marketSchedule),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchMembersAndSchedules,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Schedule Duty for: ${DateHelpers.formatDate(_selectedDate)}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            Consumer<MemberProvider>(
              builder: (context, memberProvider, child) {
                if (memberProvider.members.isEmpty) {
                  return const Center(child: Text('No members found. Please add members first.'));
                }
                return DropdownButtonFormField<Member>(
                  decoration: const InputDecoration(
                    labelText: 'Select Member',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedMember,
                  hint: const Text('Choose a member'),
                  onChanged: (Member? newValue) {
                    setState(() {
                      _selectedMember = newValue;
                    });
                  },
                  items: memberProvider.members.map((Member member) {
                    return DropdownMenuItem<Member>(
                      value: member,
                      child: Text(member.name),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            TextField(
              controller: _dutyTitleController,
              decoration: const InputDecoration(
                labelText: 'Duty Title',
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
                    onPressed: _saveSchedule,
                    icon: Icon(_editingSchedule == null ? Icons.add : Icons.save),
                    label: Text(_editingSchedule == null ? 'Add Schedule' : 'Update Schedule'),
                  ),
                ),
                if (_editingSchedule != null) ...[
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
              'Upcoming Market Schedules:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            Consumer<MarketScheduleProvider>(
              builder: (context, marketScheduleProvider, child) {
                if (marketScheduleProvider.upcomingMarketSchedules.isEmpty) {
                  return const Center(child: Text('No upcoming market schedules.'));
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: marketScheduleProvider.upcomingMarketSchedules.length,
                  itemBuilder: (context, index) {
                    final schedule = marketScheduleProvider.upcomingMarketSchedules[index];
                    final assignedMember = Provider.of<MemberProvider>(context, listen: false)
                        .getMemberById(schedule.memberId);
                    return Card(
                      margin: const EdgeInsets.only(bottom: AppConstants.paddingSmall),
                      elevation: 2,
                      child: ListTile(
                        title: Text(
                          '${schedule.dutyTitle} - ${assignedMember?.name ?? 'Unknown Member'}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        subtitle: Text(
                          'Date: ${DateHelpers.formatDate(schedule.scheduleDate)}\n'
                              'Description: ${schedule.description ?? 'N/A'}', // Fixed: Handle nullable description
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: Theme.of(context).primaryColor),
                              onPressed: () => _setForEdit(schedule),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteSchedule(schedule.id!),
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
