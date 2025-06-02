// lib/models/user.dart

import 'package:mess_meal_management_app/models/user_role.dart';
import 'package:mess_meal_management_app/utils/app_constants.dart';

/// Represents a user in the application with authentication details and a role.
class User {
  int? id; // Primary Key
  String username;
  String passwordHash; // Hashed password
  UserRole role;
  bool isActive; // Whether the user account is active
  int? memberId; // Foreign Key to Member, nullable for admin users

  User({
    this.id,
    required this.username,
    required this.passwordHash,
    this.role = UserRole.Member, // Default role
    this.isActive = true,
    this.memberId,
  });

  /// Converts a User object into a Map for database operations.
  Map<String, dynamic> toMap() {
    return {
      AppConstants.columnUserId: id,
      AppConstants.columnUsername: username,
      AppConstants.columnPasswordHash: passwordHash,
      AppConstants.columnUserRole: role.toShortString(), // Store enum as string
      AppConstants.columnIsActive: isActive ? 1 : 0, // Store bool as int
      AppConstants.columnMemberId: memberId,
    };
  }

  /// Creates a User object from a Map (e.g., from database query).
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map[AppConstants.columnUserId],
      username: map[AppConstants.columnUsername],
      passwordHash: map[AppConstants.columnPasswordHash],
      role: UserRoleExtension.fromShortString(map[AppConstants.columnUserRole]), // Corrected method call
      isActive: map[AppConstants.columnIsActive] == 1,
      memberId: map[AppConstants.columnMemberId],
    );
  }

  /// Creates a copy of the User object with updated values.
  User copyWith({
    int? id,
    String? username,
    String? passwordHash,
    UserRole? role,
    bool? isActive,
    int? memberId,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      passwordHash: passwordHash ?? this.passwordHash,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      memberId: memberId ?? this.memberId,
    );
  }
}
