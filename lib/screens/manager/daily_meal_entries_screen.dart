// lib/screens/manager/daily_meal_entries_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mess_meal_management_app/models/meal_entry.dart';
import 'package:mess_meal_management_app/models/member.dart';
import 'package:mess_meal_management_app/providers/meal_provider.dart';
import 'package:mess_meal_management_app/providers/member_provider.dart';
import 'package:mess_meal_management_app/utils/app_constants.dart';
import 'package:mess_meal_management_app/utils/date_helpers.dart';

/// A screen to display and manage meal entries for a specific date in detail.
class DailyMealEntriesScreen extends StatefulWidget {
  final DateTime selectedDate;

  const DailyMealEntriesScreen({super.key, required this.selectedDate});

  @override
  State<DailyMealEntriesScreen> createState() => _DailyMealEntriesScreenState();
}

class _DailyMealEntriesScreenState extends State<DailyMealEntriesScreen> {
  List<MealEntry> _mealEntries = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchDailyMealEntries();
  }

  /// Fetches meal entries for the date passed to this screen.
  Future<void> _fetchDailyMealEntries() async {
    setState(() {
      _isLoading = true;
      _mealEntries = []; // Clear existing entries before fetching new ones
    });
    try {
      final mealProvider = Provider.of<MealProvider>(context, listen: false);
      final entries = await mealProvider.getMealEntriesForDate(widget.selectedDate);
      if (!mounted) return;
      setState(() {
        _mealEntries = entries;
      });
    } catch (e) {
      debugPrint('Error fetching daily meal entries: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load meal entries: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Shows a dialog to edit a meal entry.
  Future<void> _editMealEntry(int entryId) async {
    final mealProvider = Provider.of<MealProvider>(context, listen: false);
    final MemberProvider memberProvider = Provider.of<MemberProvider>(context, listen: false);

    final MealEntry? entry = await mealProvider.getMealEntryById(entryId);

    if (entry == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meal entry not found for editing.')),
      );
      return;
    }

    final Member? member = memberProvider.getMemberById(entry.memberId);

    if (member == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Member not found for this meal entry.')),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (dialogContext) { // Use dialogContext to avoid confusion with widget's context
        // Use StatefulBuilder to manage the controllers' lifecycle within the dialog
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            // Controllers are now managed by this StatefulBuilder's state
            final TextEditingController bController = TextEditingController(text: entry.breakfastMeals.toStringAsFixed(1));
            final TextEditingController lController = TextEditingController(text: entry.lunchMeals.toStringAsFixed(1));
            final TextEditingController dController = TextEditingController(text: entry.dinnerMeals.toStringAsFixed(1));
            final TextEditingController gController = TextEditingController(text: entry.guestMeals.toStringAsFixed(1));

            // Dispose controllers when the StatefulBuilder's state is disposed
            // This is the key to preventing the _dependents.isEmpty error
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (dialogContext.findRenderObject() == null) {
                // This means the dialog is no longer in the tree, so dispose controllers
                bController.dispose();
                lController.dispose();
                dController.dispose();
                gController.dispose();
              }
            });


            return AlertDialog(
              title: Text('Edit Meals for ${member.name}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildMealInput('Breakfast', bController),
                    _buildMealInput('Lunch', lController),
                    _buildMealInput('Dinner', dController),
                    _buildMealInput('Guest', gController),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Dismiss dialog
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Parse values from controllers. If empty, treat as 0.0.
                    final double breakfast = double.tryParse(bController.text.isEmpty ? '0.0' : bController.text) ?? 0.0;
                    final double lunch = double.tryParse(lController.text.isEmpty ? '0.0' : lController.text) ?? 0.0;
                    final double dinner = double.tryParse(dController.text.isEmpty ? '0.0' : dController.text) ?? 0.0;
                    final double guest = double.tryParse(gController.text.isEmpty ? '0.0' : gController.text) ?? 0.0;

                    final MealEntry updatedEntry = entry.copyWith( // Use the fetched 'entry' for copyWith
                      breakfastMeals: breakfast,
                      lunchMeals: lunch,
                      dinnerMeals: dinner,
                      guestMeals: guest,
                    );

                    final bool success = await mealProvider.updateMealEntry(updatedEntry);

                    if (!mounted) return; // Check if the parent widget is still mounted
                    if (success) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar( // Use dialogContext for SnackBar
                        const SnackBar(content: Text('Meal entry updated successfully!')),
                      );
                      Navigator.of(dialogContext).pop(); // Close dialog on success
                      _fetchDailyMealEntries(); // Refresh the list after update
                    } else {
                      ScaffoldMessenger.of(dialogContext).showSnackBar( // Use dialogContext for SnackBar
                        const SnackBar(content: Text('Failed to update meal entry.')),
                      );
                    }
                  },
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
    // Removed explicit dispose calls here as they are now handled by StatefulBuilder
  }

  /// Shows a confirmation dialog to delete a meal entry.
  Future<void> _confirmDeleteMealEntry(int entryId) async {
    final bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Meal Entry'),
        content: const Text('Are you sure you want to delete this meal entry?'),
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
      final mealProvider = Provider.of<MealProvider>(context, listen: false);
      final success = await mealProvider.deleteMealEntry(entryId, widget.selectedDate);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Meal entry deleted successfully!')),
        );
        _fetchDailyMealEntries(); // Refresh the list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete meal entry.')),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final String formattedDate = DateHelpers.formatDate(widget.selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: Text('${AppConstants.dailyMealEntries} ($formattedDate)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchDailyMealEntries,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _mealEntries.isEmpty
          ? Center(child: Text('No meal entries for $formattedDate.'))
          : ListView.builder(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        itemCount: _mealEntries.length,
        itemBuilder: (context, index) {
          final entry = _mealEntries[index];
          final memberProvider = Provider.of<MemberProvider>(context, listen: false);
          final Member? member = memberProvider.getMemberById(entry.memberId);

          if (member == null) {
            return const SizedBox.shrink(); // Hide if member not found
          }

          return Card(
            margin: const EdgeInsets.only(bottom: AppConstants.paddingSmall),
            elevation: 2,
            child: ListTile(
              title: Text(
                member.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'B: ${entry.breakfastMeals.toStringAsFixed(1)}, L: ${entry.lunchMeals.toStringAsFixed(1)}, D: ${entry.dinnerMeals.toStringAsFixed(1)}, G: ${entry.guestMeals.toStringAsFixed(1)}\n'
                    'Total: ${entry.totalMeals.toStringAsFixed(1)} meals',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: Theme.of(context).primaryColor),
                    onPressed: () => _editMealEntry(entry.id!),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmDeleteMealEntry(entry.id!),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Helper widget for meal input in dialog
  Widget _buildMealInput(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingSmall / 2),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true), // Allow decimal input
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingSmall, vertical: AppConstants.paddingSmall),
        ),
        onChanged: (value) {
          // Rule 1: Allow empty string. If empty, do nothing.
          if (value.isEmpty) {
            return;
          }

          // Rule 2: Allow partial input like "2." or ".5"
          // Check for single decimal point, and ensure it's not at the very beginning unless it's just "."
          if (value == '.' || (value.contains('.') && value.indexOf('.') == value.lastIndexOf('.') && value.length > 1)) {
            return;
          }

          // Rule 3: If it's not empty and not a partial decimal, try to parse.
          double? parsedValue = double.tryParse(value);

          if (parsedValue == null) {
            // Rule 4: If parsing fails (e.g., "abc"), revert to the last valid state or "0.0".
            if (controller.text.isEmpty || double.tryParse(controller.text) == null) {
              controller.text = '0.0'; // Revert to a safe default
              controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));
            }
          }
          // IMPORTANT: No programmatic controller.text = ... or controller.selection = ... here for formatting.
          // Let the TextField manage its own text and cursor based on user input.
          // Formatting (like .0 for whole numbers) will be handled when the value is initially loaded
          // or when it's read for saving.
        },
      ),
    );
  }
}
