// lib/providers/member_provider.dart

import 'package:flutter/material.dart';
import 'package:mess_meal_management_app/models/member.dart';
import 'package:mess_meal_management_app/services/member_service.dart';
import 'package:mess_meal_management_app/services/auth_service.dart'; // Added AuthService for role-related member fetching

/// Provider for managing Member data.
class MemberProvider with ChangeNotifier {
  final MemberService _memberService;
  final AuthService _authService; // Added AuthService for role-related member fetching
  List<Member> _members = [];
  List<Member> _activeMembers = []; // Members associated with active non-admin users

  MemberProvider(this._memberService, this._authService);

  List<Member> get members => _members;
  List<Member> get activeMembers => _activeMembers;

  /// Fetches all members from the database.
  Future<void> fetchAllMembers() async {
    _members = await _memberService.getAllMembers();
    await _fetchActiveMembersInternal(); // Also update active members
    notifyListeners();
  }

  /// Fetches only members who are associated with active non-admin users.
  /// This is used for selection in forms (e.g., meal entry, expense, contribution).
  Future<void> fetchActiveMembers() async {
    await _fetchActiveMembersInternal();
    notifyListeners();
  }

  /// Internal helper to fetch active members without notifying listeners immediately.
  Future<void> _fetchActiveMembersInternal() async {
    final allUsers = await _authService.getAllUsers(); // Corrected method call
    final activeUserMemberIds = allUsers
        .where((user) => user.isActive && user.memberId != null)
        .map((user) => user.memberId!)
        .toSet();

    _activeMembers = _members
        .where((member) => activeUserMemberIds.contains(member.id))
        .toList();
  }


  /// Adds a new member.
  Future<bool> addMember(Member member) async {
    final int id = await _memberService.addMember(member);
    if (id > 0) {
      await fetchAllMembers(); // Refresh list
      return true;
    }
    return false;
  }

  /// Updates an existing member.
  Future<bool> updateMember(Member member) async {
    final bool success = await _memberService.updateMember(member);
    if (success) {
      await fetchAllMembers(); // Refresh list
    }
    return success;
  }

  /// Deletes a member.
  Future<bool> deleteMember(int id) async {
    final bool success = await _memberService.deleteMember(id);
    if (success) {
      await fetchAllMembers(); // Refresh list
    }
    return success;
  }

  /// Retrieves a member by ID from the currently loaded list.
  Member? getMemberById(int id) {
    try {
      return _members.firstWhere((member) => member.id == id);
    } catch (e) {
      return null;
    }
  }
}
