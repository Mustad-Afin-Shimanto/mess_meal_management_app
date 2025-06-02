// lib/services/market_schedule_service.dart
import 'package:mess_meal_management_app/database/database_helper.dart';
import 'package:mess_meal_management_app/models/market_schedule.dart';
import 'package:mess_meal_management_app/utils/app_constants.dart';
import 'package:mess_meal_management_app/utils/date_helpers.dart';

/// Service class for managing market schedule data in the database.
class MarketScheduleService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Adds a new market schedule.
  Future<int> addMarketSchedule(MarketSchedule schedule) async {
    return await _dbHelper.insert(AppConstants.tableMarketSchedules, schedule.toMap());
  }

  /// Retrieves all market schedules.
  Future<List<MarketSchedule>> getAllMarketSchedules() async {
    final List<Map<String, dynamic>> maps = await _dbHelper.queryAll(AppConstants.tableMarketSchedules);
    return List.generate(maps.length, (i) => MarketSchedule.fromMap(maps[i]));
  }

  /// Retrieves upcoming market schedules (from today onwards).
  Future<List<MarketSchedule>> getUpcomingMarketSchedules() async {
    final String today = DateHelpers.formatDateToYYYYMMDD(DateTime.now());
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      AppConstants.tableMarketSchedules,
      where: '${AppConstants.columnMarketScheduleDate} >= ?',
      whereArgs: [today],
      orderBy: '${AppConstants.columnMarketScheduleDate} ASC',
    );
    return List.generate(maps.length, (i) => MarketSchedule.fromMap(maps[i]));
  }

  /// Updates an existing market schedule.
  Future<bool> updateMarketSchedule(MarketSchedule schedule) async {
    final int rowsAffected = await _dbHelper.update(
      AppConstants.tableMarketSchedules,
      schedule.toMap(),
      '${AppConstants.columnMarketScheduleId} = ?',
      [schedule.id],
    );
    return rowsAffected > 0;
  }

  /// Deletes a market schedule by its ID.
  Future<bool> deleteMarketSchedule(int id) async {
    final int rowsAffected = await _dbHelper.delete(
      AppConstants.tableMarketSchedules,
      '${AppConstants.columnMarketScheduleId} = ?',
      [id],
    );
    return rowsAffected > 0;
  }

  /// Retrieves market schedules for a specific member for a given month and year.
  Future<List<MarketSchedule>> getMarketSchedulesByMemberForMonth(int memberId, int month, int year) async {
    final String startOfMonth = DateHelpers.formatDateToYYYYMMDD(DateTime(year, month, 1));
    final String endOfMonth = DateHelpers.formatDateToYYYYMMDD(DateTime(year, month + 1, 0)); // Last day of the month

    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      AppConstants.tableMarketSchedules,
      where: '${AppConstants.columnMarketMemberId} = ? AND ${AppConstants.columnMarketScheduleDate} BETWEEN ? AND ?',
      whereArgs: [memberId, startOfMonth, endOfMonth],
      orderBy: '${AppConstants.columnMarketScheduleDate} ASC',
    );
    return List.generate(maps.length, (i) => MarketSchedule.fromMap(maps[i]));
  }
}
