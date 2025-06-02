// lib/providers/market_schedule_provider.dart
import 'package:flutter/material.dart';
import 'package:mess_meal_management_app/models/market_schedule.dart';
import 'package:mess_meal_management_app/services/market_schedule_service.dart';

/// Provider for managing market schedule data.
class MarketScheduleProvider with ChangeNotifier {
  final MarketScheduleService _marketScheduleService;

  List<MarketSchedule> _upcomingMarketSchedules = [];
  List<MarketSchedule> _allMarketSchedules = []; // To hold all schedules for broader use

  MarketScheduleProvider(this._marketScheduleService);

  List<MarketSchedule> get upcomingMarketSchedules => _upcomingMarketSchedules;
  List<MarketSchedule> get allMarketSchedules => _allMarketSchedules;

  /// Fetches all upcoming market schedules (from today onwards).
  Future<void> fetchUpcomingMarketSchedules() async {
    _upcomingMarketSchedules = await _marketScheduleService.getUpcomingMarketSchedules();
    notifyListeners();
  }

  /// Fetches all market schedules.
  Future<void> fetchAllMarketSchedules() async {
    _allMarketSchedules = await _marketScheduleService.getAllMarketSchedules();
    notifyListeners();
  }

  /// Adds a new market schedule.
  Future<bool> addMarketSchedule(MarketSchedule schedule) async {
    final int id = await _marketScheduleService.addMarketSchedule(schedule);
    if (id > 0) {
      await fetchUpcomingMarketSchedules(); // Refresh upcoming list
      await fetchAllMarketSchedules(); // Refresh all list
      return true;
    }
    return false;
  }

  /// Updates an existing market schedule.
  Future<bool> updateMarketSchedule(MarketSchedule schedule) async {
    final bool success = await _marketScheduleService.updateMarketSchedule(schedule);
    if (success) {
      await fetchUpcomingMarketSchedules(); // Refresh upcoming list
      await fetchAllMarketSchedules(); // Refresh all list
    }
    return success;
  }

  /// Deletes a market schedule by its ID.
  Future<bool> deleteMarketSchedule(int id) async {
    final bool success = await _marketScheduleService.deleteMarketSchedule(id);
    if (success) {
      await fetchUpcomingMarketSchedules(); // Refresh upcoming list
      await fetchAllMarketSchedules(); // Refresh all list
    }
    return success;
  }

  /// Retrieves market schedules for a specific member for a given month and year.
  Future<List<MarketSchedule>> getMarketSchedulesByMemberForMonth(int memberId, int month, int year) async {
    return await _marketScheduleService.getMarketSchedulesByMemberForMonth(memberId, month, year);
  }
}
