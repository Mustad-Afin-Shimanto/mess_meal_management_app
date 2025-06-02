// lib/widgets/dashboard_card.dart

import 'package:flutter/material.dart';
import 'package:mess_meal_management_app/utils/app_constants.dart';

/// A reusable card widget for displaying information on dashboards.
class DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? color;

  const DashboardCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      color: color ?? Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 30,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: AppConstants.paddingSmall),
                Expanded( // Use Expanded to give the Text widget available horizontal space
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                    overflow: TextOverflow.visible, // Allow text to wrap
                    softWrap: true, // Enable soft wrapping
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingSmall),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
              overflow: TextOverflow.visible, // Allow text to wrap
              softWrap: true, // Enable soft wrapping
            ),
          ],
        ),
      ),
    );
  }
}
