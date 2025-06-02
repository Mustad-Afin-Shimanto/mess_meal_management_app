// lib/providers/user_provider.dart

import 'package:flutter/material.dart';
import 'package:mess_meal_management_app/models/user.dart';
import 'package:mess_meal_management_app/models/member.dart';
import 'package:mess_meal_management_app/models/user_role.dart'; // Import UserRole
import 'package:mess_meal_management_app/services/auth_service.dart';

/// Provider for managing the current authenticated user's state.
class UserProvider with ChangeNotifier {
  User? _currentUser;
  Member? _currentMember;
  final AuthService _authService;

  UserProvider(this._authService);

  User? get currentUser => _currentUser;
  Member? get currentMember => _currentMember;
  bool get isAuthenticated => _currentUser != null;

  // Role-based getters
  bool get isAdmin => _currentUser?.role == UserRole.Admin;
  bool get isManager => _currentUser?.role == UserRole.Manager;
  bool get isMember => _currentUser?.role == UserRole.Member;


  /// Loads the current user and their associated member on app start.
  Future<void> loadCurrentUser() async {
    _currentUser = await _authService.getCurrentUser();
    if (_currentUser != null) {
      _currentMember = await _authService.getMemberForUser(_currentUser!.id!);
    } else {
      _currentMember = null;
    }
    notifyListeners();
  }

  /// Handles user login.
  Future<bool> login(String username, String password) async {
    _currentUser = await _authService.loginUser(username, password);
    if (_currentUser != null) {
      _currentMember = await _authService.getMemberForUser(_currentUser!.id!);
      notifyListeners();
      return true;
    }
    notifyListeners();
    return false;
  }

  /// Handles user logout.
  Future<void> logout() async {
    await _authService.logoutUser();
    _currentUser = null;
    _currentMember = null;
    notifyListeners();
  }

  /// Updates the current user object and notifies listeners.
  void updateCurrentUser(User user) {
    _currentUser = user;
    notifyListeners();
  }

  /// Updates the current member object and notifies listeners.
  void updateCurrentMember(Member member) {
    _currentMember = member;
    notifyListeners();
  }
}
