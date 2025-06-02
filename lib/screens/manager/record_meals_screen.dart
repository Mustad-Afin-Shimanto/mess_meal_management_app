// lib/screens/manager/record_meals_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mess_meal_management_app/models/meal_entry.dart';
import 'package:mess_meal_management_app/models/member.dart';
import 'package:mess_meal_management_app/providers/meal_provider.dart';
import 'package:mess_meal_management_app/providers/member_provider.dart';
import 'package:mess_meal_management_app/utils/app_constants.dart';
import 'package:mess_meal_management_app/utils/date_helpers.dart';
import 'package:mess_meal_management_app/screens/manager/daily_meal_entries_screen.dart'; // Import the new screen

/// Screen for managers to record daily meal entries for members.
class RecordMealsScreen extends StatefulWidget {
  const RecordMealsScreen({super.key});

  @override
  State<RecordMealsScreen> createState() => _RecordMealsScreenState();
}

class _RecordMealsScreenState extends State<RecordMealsScreen> {
  DateTime _selectedDate = DateTime.now();
  Member? _selectedMember;
  final TextEditingController _breakfastController = TextEditingController(text: '0.5');
  final TextEditingController _lunchController = TextEditingController(text: '1.0');
  final TextEditingController _dinnerController = TextEditingController(text: '1.0');
  final TextEditingController _guestController = TextEditingController(text: '0.0');

  List<MealEntry> _mealEntriesForSelectedDate = []; // To hold entries for the selected date

  @override
  void initState() {
    super.initState();
    _fetchMembersAndEntries();
  }

  @override
  void dispose() {
    _breakfastController.dispose();
    _lunchController.dispose();
    _dinnerController.dispose();
    _guestController.dispose();
    super.dispose();
  }

  /// Fetches all members and meal entries for the selected date.
  Future<void> _fetchMembersAndEntries() async {
    final memberProvider = Provider.of<MemberProvider>(context, listen: false);

    await memberProvider.fetchAllMembers(); // Ensure members are loaded

    // Fetch meal entries for the currently selected date
    await _fetchMealEntriesForDate(_selectedDate);
  }

  /// Fetches and updates the list of meal entries for a specific date.
  Future<void> _fetchMealEntriesForDate(DateTime date) async {
    final mealProvider = Provider.of<MealProvider>(context, listen: false);
    final entries = await mealProvider.getMealEntriesForDate(date);
    if (!mounted) return;
    setState(() {
      _mealEntriesForSelectedDate = entries;
    });
  }

  /// Allows the user to select a different date for recording meals.
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
            dialogTheme: const DialogThemeData(
              backgroundColor: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      if (!mounted) return;
      setState(() {
        _selectedDate = picked;
        _selectedMember = null; // Reset selected member when date changes
        _resetControllers(); // Reset meal counts to defaults for new date
      });
      await _fetchMealEntriesForDate(_selectedDate); // Fetch entries for the new date
    }
  }

  /// Resets meal count controllers to default values.
  void _resetControllers() {
    _breakfastController.text = '0.5';
    _lunchController.text = '1.0';
    _dinnerController.text = '1.0';
    _guestController.text = '0.0';
  }

  /// Loads an existing meal entry's data into the controllers if one exists for the selected member and date.
  /// Otherwise, it resets controllers to default values.
  void _loadExistingEntry() {
    if (_selectedMember != null) {
      final existingEntry = _mealEntriesForSelectedDate.firstWhere(
            (entry) => entry.memberId == _selectedMember!.id,
        orElse: () => MealEntry( // If no existing entry, create a dummy one with default values
          id: null,
          memberId: _selectedMember!.id!,
          mealDate: _selectedDate,
          breakfastMeals: 0.5, // Default for new entry
          lunchMeals: 1.0,     // Default for new entry
          dinnerMeals: 1.0,    // Default for new entry
          guestMeals: 0.0,     // Default for new entry
        ),
      );

      // Load values from existing entry or the dummy default entry
      _breakfastController.text = existingEntry.breakfastMeals.toStringAsFixed(1);
      _lunchController.text = existingEntry.lunchMeals.toStringAsFixed(1);
      _dinnerController.text = existingEntry.dinnerMeals.toStringAsFixed(1);
      _guestController.text = existingEntry.guestMeals.toStringAsFixed(1);
    } else {
      _resetControllers(); // If no member selected, reset to default app values
    }
  }

  /// Saves or updates a meal entry.
  Future<void> _saveMealEntry() async {
    if (_selectedMember == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a member.')),
      );
      return;
    }

    final mealProvider = Provider.of<MealProvider>(context, listen: false);
    final memberId = _selectedMember!.id!;

    // Fixed: Use double.tryParse to get the value, but don't force format here
    final double breakfast = double.tryParse(_breakfastController.text) ?? 0.0;
    final double lunch = double.tryParse(_lunchController.text) ?? 0.0;
    final double dinner = double.tryParse(_dinnerController.text) ?? 0.0;
    final double guest = double.tryParse(_guestController.text) ?? 0.0;

    // Check if an entry for this member and date already exists
    final existingEntry = _mealEntriesForSelectedDate.firstWhere(
          (entry) => entry.memberId == memberId && DateHelpers.isSameDay(entry.mealDate, _selectedDate),
      orElse: () => MealEntry(
        id: null, // Indicate no existing ID, use null for new entry
        memberId: memberId,
        mealDate: _selectedDate,
        breakfastMeals: 0.0,
        lunchMeals: 0.0,
        dinnerMeals: 0.0,
        guestMeals: 0.0,
      ),
    );

    bool success = false;
    if (existingEntry.id != null) {
      // Update existing entry
      final updatedEntry = existingEntry.copyWith(
        breakfastMeals: breakfast,
        lunchMeals: lunch,
        dinnerMeals: dinner,
        guestMeals: guest,
      );
      success = await mealProvider.updateMealEntry(updatedEntry);
    } else {
      // Add new entry
      final newEntry = MealEntry(
        memberId: memberId,
        mealDate: _selectedDate,
        breakfastMeals: breakfast,
        lunchMeals: lunch,
        dinnerMeals: dinner,
        guestMeals: guest,
      );
      success = await mealProvider.addMealEntry(newEntry);
    }

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meal entry saved successfully!')),
      );
      // After saving, refresh the list for the current date
      await _fetchMealEntriesForDate(_selectedDate);
      // Reload the selected member's data to ensure the input fields reflect the saved state
      _loadExistingEntry();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save meal entry.')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.recordMeals),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recording Meals for: ${DateHelpers.formatDate(_selectedDate)}',
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
                      _loadExistingEntry(); // Load existing data or set defaults when member changes
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
            _buildMealInput('Breakfast Meals', _breakfastController),
            const SizedBox(height: AppConstants.paddingSmall),
            _buildMealInput('Lunch Meals', _lunchController),
            const SizedBox(height: AppConstants.paddingSmall),
            _buildMealInput('Dinner Meals', _dinnerController),
            const SizedBox(height: AppConstants.paddingSmall),
            _buildMealInput('Guest Meals', _guestController),
            const SizedBox(height: AppConstants.paddingLarge),
            ElevatedButton.icon(
              onPressed: _saveMealEntry,
              icon: const Icon(Icons.save),
              label: const Text(AppConstants.saveButton),
            ),
            const SizedBox(height: AppConstants.paddingLarge),

            // New button to view/edit daily meal entries on a separate screen
            ElevatedButton.icon(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => DailyMealEntriesScreen(selectedDate: _selectedDate),
                  ),
                );
                // Refresh entries for the current date when returning from the detail screen
                _fetchMealEntriesForDate(_selectedDate);
                // Also, reload the current member's meal entry to update the input fields
                _loadExistingEntry();
              },
              icon: const Icon(Icons.list_alt),
              label: const Text(AppConstants.viewDailyMeals),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary, // Use accent color
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealInput(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true), // Allow decimal input
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove),
              onPressed: () {
                double currentValue = double.tryParse(controller.text) ?? 0.0;
                if (currentValue > 0) {
                  controller.text = (currentValue - 0.5).toStringAsFixed(1);
                } else {
                  controller.text = '0.0'; // Ensure it doesn't go below 0
                }
                controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));
              },
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                double currentValue = double.tryParse(controller.text) ?? 0.0;
                controller.text = (currentValue + 0.5).toStringAsFixed(1);
                controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));
              },
            ),
          ],
        ),
      ),
      onChanged: (value) {
        // Allow empty string temporarily for backspace
        if (value.isEmpty) {
          return; // Do nothing, let the controller become empty
        }

        // Allow partial input like "2." or ".5"
        if (value == '.' || (value.endsWith('.') && value.length > 1 && value.indexOf('.') == value.lastIndexOf('.'))) {
          return; // Do nothing, allow partial decimal input
        }

        // Try to parse the value as a double.
        double? parsedValue = double.tryParse(value);

        if (parsedValue != null) {
          // If it's a valid number, we don't need to force format here.
          // The formatting will happen when the value is loaded or saved.
          // Just ensure the controller reflects the valid parsed value.
          // This prevents aggressive reformatting during typing.
          // Only update if the parsed value is different from what's currently displayed
          // and the current text isn't a partial number (like "2.")
          if (parsedValue.toStringAsFixed(1) != controller.text && !value.endsWith('.')) {
            // This line was causing the issue. Removing it to allow free typing.
            // controller.text = parsedValue.toStringAsFixed(1);
            // controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));
          }
        } else {
          // If the input is not a valid number, revert to the last valid number or '0.0'.
          // This is a common pattern to prevent invalid input.
          // However, if the user is in the middle of typing, this can be annoying.
          // A better approach is to only validate on submission.
          // For now, we'll keep it simple: if it's completely unparseable, reset.
          if (value != controller.text) { // Only reset if the input is genuinely invalid
            controller.text = '0.0';
            controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));
          }
        }
      },
    );
  }
}
