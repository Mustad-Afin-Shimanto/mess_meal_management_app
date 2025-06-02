// lib/models/user_role.dart

/// Enum representing the different user roles in the application.
enum UserRole {
  Admin,
  Manager,
  Member,
  None, // Used for initial state or unauthenticated users
}

/// Extension to convert UserRole enum to String and vice-versa.
extension UserRoleExtension on UserRole {
  String toShortString() {
    return toString().split('.').last;
  }

  // Corrected method name from 'fromString' to 'fromShortString'
  static UserRole fromShortString(String roleString) {
    switch (roleString) {
      case 'Admin':
        return UserRole.Admin;
      case 'Manager':
        return UserRole.Manager;
      case 'Member':
        return UserRole.Member;
      default:
        return UserRole.None;
    }
  }
}
