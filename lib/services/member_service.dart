// lib/services/member_service.dart

import 'package:mess_meal_management_app/database/database_helper.dart';
import 'package:mess_meal_management_app/models/member.dart';
import 'package:mess_meal_management_app/utils/app_constants.dart';

/// Service class for managing member data in the database.
class MemberService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Adds a new member.
  Future<int> addMember(Member member) async {
    return await _dbHelper.insert(AppConstants.tableMembers, member.toMap());
  }

  /// Retrieves all members.
  Future<List<Member>> getAllMembers() async {
    final List<Map<String, dynamic>> maps = await _dbHelper.queryAll(AppConstants.tableMembers);
    return List.generate(maps.length, (i) => Member.fromMap(maps[i]));
  }

  /// Retrieves a single member by ID.
  Future<Member?> getMemberById(int id) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      AppConstants.tableMembers,
      where: '${AppConstants.columnMemberIdPk} = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Member.fromMap(maps.first);
    }
    return null;
  }

  /// Updates an existing member.
  Future<bool> updateMember(Member member) async {
    final int rowsAffected = await _dbHelper.update(
      AppConstants.tableMembers,
      member.toMap(),
      '${AppConstants.columnMemberIdPk} = ?',
      [member.id],
    );
    return rowsAffected > 0;
  }

  /// Deletes a member by ID.
  Future<bool> deleteMember(int id) async {
    final int rowsAffected = await _dbHelper.delete(
      AppConstants.tableMembers,
      '${AppConstants.columnMemberIdPk} = ?',
      [id],
    );
    return rowsAffected > 0;
  }
}
