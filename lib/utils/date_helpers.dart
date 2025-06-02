// lib/utils/date_helpers.dart
import 'package:intl/intl.dart';

/// A utility class for date and time related helper functions.
class DateHelpers {
  /// Formats a DateTime object to 'YYYY-MM-DD' string.
  static String formatDateToYYYYMMDD(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// Formats a DateTime object to a more readable 'Mon DD, YYYY' string.
  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  /// Formats a DateTime object to 'Month YYYY' string.
  static String formatMonthYear(DateTime date) {
    return DateFormat('MMMM yyyy').format(date);
  }

  /// Checks if two DateTime objects represent the same day (ignoring time).
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Returns the first day of the month for a given date.
  static DateTime firstDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// Returns the last day of the month for a given date.
  static DateTime lastDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0); // Day 0 of next month is last day of current month
  }
}
