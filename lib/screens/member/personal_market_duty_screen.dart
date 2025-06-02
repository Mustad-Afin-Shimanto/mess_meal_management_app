// lib/screens/member/personal_market_duty_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mess_meal_management_app/models/market_schedule.dart';
import 'package:mess_meal_management_app/providers/market_schedule_provider.dart';
import 'package:mess_meal_management_app/providers/user_provider.dart';
import 'package:mess_meal_management_app/utils/app_constants.dart';
import 'package:mess_meal_management_app/utils/date_helpers.dart';
import 'package:mess_meal_management_app/providers/member_provider.dart'; // Import MemberProvider

/// Screen for a member to view their personal market duty history.
class PersonalMarketDutyScreen extends StatefulWidget {
  const PersonalMarketDutyScreen({super.key}); // Fixed: super.key

  @override
  State<PersonalMarketDutyScreen> createState() => _PersonalMarketDutyScreenState();
}

class _PersonalMarketDutyScreenState extends State<PersonalMarketDutyScreen> {
  DateTime _selectedMonth = DateTime.now();
  List<MarketSchedule> _personalMarketDuties = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchPersonalMarketDuties();
  }

  /// Fetches the personal market duties for the currently logged-in member.
  Future<void> _fetchPersonalMarketDuties() async {
    setState(() {
      _isLoading = true;
      _personalMarketDuties = [];
    });

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final marketScheduleProvider = Provider.of<MarketScheduleProvider>(context, listen: false);

    final int? memberId = userProvider.currentMember?.id;

    if (memberId == null) {
      if (!mounted) return; // Fixed: BuildContext across async gaps
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not retrieve member ID.')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final duties = await marketScheduleProvider.getMarketSchedulesByMemberForMonth(
        memberId,
        _selectedMonth.month,
        _selectedMonth.year,
      );
      if (!mounted) return; // Fixed: BuildContext across async gaps
      setState(() {
        _personalMarketDuties = duties;
      });
    } catch (e) {
      debugPrint('Error fetching personal market duties: $e'); // Fixed: Use debugPrint
      if (!mounted) return; // Fixed: BuildContext across async gaps
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load personal market duties: $e')),
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
      _fetchPersonalMarketDuties(); // Re-fetch data for the new month
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.personalMarketDuty),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectMonth(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _personalMarketDuties.isEmpty
          ? Center(child: Text('No market duties for ${DateHelpers.formatMonthYear(_selectedMonth)}.'))
          : ListView.builder(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        itemCount: _personalMarketDuties.length,
        itemBuilder: (context, index) {
          final duty = _personalMarketDuties[index];
          final memberProvider = Provider.of<MemberProvider>(context, listen: false);
          final assignedMember = memberProvider.getMemberById(duty.memberId); // Get member details

          return Card(
            margin: const EdgeInsets.only(bottom: AppConstants.paddingSmall),
            elevation: 2,
            child: ListTile(
              title: Text(
                duty.dutyTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'Date: ${DateHelpers.formatDate(duty.scheduleDate)}\n'
                    'Assigned To: ${assignedMember?.name ?? 'Unknown Member'}\n' // Display assigned member
                    'Description: ${duty.description ?? 'N/A'}', // Fixed: Handle nullable description
              ),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }
}
