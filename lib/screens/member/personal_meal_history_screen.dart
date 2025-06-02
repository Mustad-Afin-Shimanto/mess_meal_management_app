// lib/screens/member/personal_meal_history_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mess_meal_management_app/models/meal_entry.dart';
import 'package:mess_meal_management_app/providers/meal_provider.dart';
import 'package:mess_meal_management_app/providers/user_provider.dart';
import 'package:mess_meal_management_app/utils/app_constants.dart';
import 'package:mess_meal_management_app/utils/date_helpers.dart';

/// Screen for a member to view their personal meal history.
class PersonalMealHistoryScreen extends StatefulWidget {
  const PersonalMealHistoryScreen({super.key});

  @override
  State<PersonalMealHistoryScreen> createState() => _PersonalMealHistoryScreenState();
}

class _PersonalMealHistoryScreenState extends State<PersonalMealHistoryScreen> {
  DateTime _selectedMonth = DateTime.now();
  List<MealEntry> _personalMealEntries = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchPersonalMealHistory();
  }

  /// Fetches the personal meal history for the currently logged-in member.
  Future<void> _fetchPersonalMealHistory() async {
    setState(() {
      _isLoading = true;
      _personalMealEntries = [];
    });

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final mealProvider = Provider.of<MealProvider>(context, listen: false);

    final int? memberId = userProvider.currentMember?.id;

    if (memberId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not retrieve member ID.')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final entries = await mealProvider.fetchMealEntriesByMember(
        memberId,
        _selectedMonth.month,
        _selectedMonth.year,
      );
      if (!mounted) return;
      setState(() {
        _personalMealEntries = entries;
      });
    } catch (e) {
      debugPrint('Error fetching personal meal history: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load personal meal history: $e')),
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
            dialogTheme: const DialogThemeData(
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
      _fetchPersonalMealHistory(); // Re-fetch data for the new month
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.personalMealHistory),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectMonth(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _personalMealEntries.isEmpty
          ? Center(child: Text('No meal entries for ${DateHelpers.formatMonthYear(_selectedMonth)}.'))
          : ListView.builder(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        itemCount: _personalMealEntries.length,
        itemBuilder: (context, index) {
          final entry = _personalMealEntries[index];
          return Card(
            margin: const EdgeInsets.only(bottom: AppConstants.paddingSmall),
            elevation: 2,
            child: ListTile(
              title: Text(
                'Date: ${DateHelpers.formatDate(entry.mealDate)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                // Fixed: Display as doubles with one decimal place
                'Breakfast: ${entry.breakfastMeals.toStringAsFixed(1)}, '
                    'Lunch: ${entry.lunchMeals.toStringAsFixed(1)}, '
                    'Dinner: ${entry.dinnerMeals.toStringAsFixed(1)}, '
                    'Guest: ${entry.guestMeals.toStringAsFixed(1)}\n'
                    'Total Meals: ${entry.totalMeals.toStringAsFixed(1)}',
              ),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }
}
