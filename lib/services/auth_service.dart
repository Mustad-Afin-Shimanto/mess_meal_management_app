// lib/services/auth_service.dart

import 'package:bcrypt/bcrypt.dart'; // For password hashing
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mess_meal_management_app/database/database_helper.dart';
import 'package:mess_meal_management_app/models/user.dart';
import 'package:mess_meal_management_app/models/user_role.dart';
import 'package:mess_meal_management_app/models/member.dart';
import 'package:mess_meal_management_app/utils/app_constants.dart';

/// Service class for user authentication and authorization.
class AuthService {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final String _loggedInUserIdKey = 'loggedInUserId';

  /// Registers a new user.
  /// If `isInitialAdmin` is true, it creates the first Admin user.
  /// Passwords are hashed using bcrypt before storing.
  Future<User?> registerUser({
    required String username,
    required String password,
    required String name,
    String? email,
    bool isInitialAdmin = false,
  }) async {
    try {
      // Hash the password
      final String passwordHash = BCrypt.hashpw(password, BCrypt.gensalt());

      UserRole role = UserRole.Member;
      int? memberId;

      if (isInitialAdmin) {
        role = UserRole.Admin;
        // Admin users do not have an associated member_id
        memberId = null;
      } else {
        // For non-admin registration, create a Member first
        final member = Member(name: name, email: email);
        final int newMemberId = await _dbHelper.insert(AppConstants.tableMembers, member.toMap());

        if (newMemberId == 0) {
          throw Exception('Failed to create member during registration.');
        }
        memberId = newMemberId;
        // All non-admin registrations default to UserRole.Member.
        // Manager role will be assigned by Admin later.
        role = UserRole.Member;
      }

      // Create User object
      final user = User(
        username: username,
        passwordHash: passwordHash,
        role: role,
        isActive: true,
        memberId: memberId,
      );

      // Insert user into the database
      final int userId = await _dbHelper.insert(AppConstants.tableUsers, user.toMap());

      if (userId == 0) {
        // If user insertion fails, attempt to delete the created member (cleanup)
        if (memberId != null) {
          await _dbHelper.delete(AppConstants.tableMembers,
              '${AppConstants.columnMemberIdPk} = ?', [memberId]);
        }
        throw Exception('Failed to register user.');
      }

      user.id = userId; // Set the ID returned by the database
      return user;
    } catch (e) {
      print('Error registering user: $e');
      return null;
    }
  }

  /// Authenticates a user based on username and password.
  /// Verifies hashed passwords.
  Future<User?> loginUser(String username, String password) async {
    try {
      final List<Map<String, dynamic>> users = await _dbHelper.query(
        AppConstants.tableUsers,
        where: '${AppConstants.columnUsername} = ?',
        whereArgs: [username],
      );

      if (users.isNotEmpty) {
        final user = User.fromMap(users.first);
        // Verify password hash
        if (BCrypt.checkpw(password, user.passwordHash)) {
          if (user.isActive) {
            // Store logged-in user ID in shared preferences
            final prefs = await SharedPreferences.getInstance();
            await prefs.setInt(_loggedInUserIdKey, user.id!);
            return user;
          } else {
            throw Exception('User account is inactive.');
          }
        }
      }
      return null; // Invalid credentials
    } catch (e) {
      print('Error logging in user: $e');
      return null;
    }
  }

  /// Logs out the current user by clearing shared preferences.
  Future<void> logoutUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_loggedInUserIdKey);
  }

  /// Checks if an admin user already exists in the database.
  Future<bool> isAdminRegistered() async {
    try {
      final List<Map<String, dynamic>> users = await _dbHelper.query(
        AppConstants.tableUsers,
        where: '${AppConstants.columnUserRole} = ?',
        whereArgs: [UserRole.Admin.toShortString()],
      );
      return users.isNotEmpty;
    } catch (e) {
      print('Error checking admin registration: $e');
      return false;
    }
  }

  /// Gets the currently logged-in user from shared preferences and database.
  Future<User?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? userId = prefs.getInt(_loggedInUserIdKey);

      if (userId != null) {
        final List<Map<String, dynamic>> users = await _dbHelper.query(
          AppConstants.tableUsers,
          where: '${AppConstants.columnUserId} = ?',
          whereArgs: [userId],
        );
        if (users.isNotEmpty) {
          return User.fromMap(users.first);
        }
      }
      return null;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  /// Retrieves the Member associated with a given User ID.
  Future<Member?> getMemberForUser(int userId) async {
    try {
      final List<Map<String, dynamic>> users = await _dbHelper.query(
        AppConstants.tableUsers,
        where: '${AppConstants.columnUserId} = ?',
        whereArgs: [userId],
      );

      if (users.isNotEmpty) {
        final user = User.fromMap(users.first);
        if (user.memberId != null) {
          final List<Map<String, dynamic>> members = await _dbHelper.query(
            AppConstants.tableMembers,
            where: '${AppConstants.columnMemberIdPk} = ?',
            whereArgs: [user.memberId],
          );
          if (members.isNotEmpty) {
            return Member.fromMap(members.first);
          }
        }
      }
      return null;
    } catch (e) {
      print('Error getting member for user: $e');
      return null;
    }
  }

  /// Retrieves all users from the database, excluding Admin users.
  Future<List<User>> getAllUsers() async {
    try {
      final List<Map<String, dynamic>> userMaps = await _dbHelper.query(
        AppConstants.tableUsers,
        where: '${AppConstants.columnUserRole} != ?', // Exclude Admin users
        whereArgs: [UserRole.Admin.toShortString()],
      );
      return List.generate(userMaps.length, (i) => User.fromMap(userMaps[i]));
    } catch (e) {
      print('Error getting all users: $e');
      return [];
    }
  }

  /// Updates a user's active status.
  Future<bool> updateUserActiveStatus(int userId, bool isActive) async {
    try {
      final int rowsAffected = await _dbHelper.update(
        AppConstants.tableUsers,
        {AppConstants.columnIsActive: isActive ? 1 : 0},
        '${AppConstants.columnUserId} = ?',
        [userId],
      );
      return rowsAffected > 0;
    } catch (e) {
      print('Error updating user active status: $e');
      return false;
    }
  }

  /// Changes a user's role and manages associated member entries.
  /// If a user becomes Admin, their member_id is set to NULL.
  /// If a user becomes Manager/Member, and they don't have a member_id, a new member is created.
  Future<bool> changeUserRole(int userId, UserRole newRole) async {
    try {
      final List<Map<String, dynamic>> users = await _dbHelper.query(
        AppConstants.tableUsers,
        where: '${AppConstants.columnUserId} = ?',
        whereArgs: [userId],
      );

      if (users.isEmpty) return false;

      User user = User.fromMap(users.first);
      int? updatedMemberId = user.memberId;

      if (newRole == UserRole.Admin) {
        // If changing to Admin, disassociate from Member
        updatedMemberId = null;
      } else {
        // If changing to Manager/Member and no associated member, create one
        if (user.memberId == null) {
          // Fetch user details to get username for member name
          final memberName = user.username; // Use username as member name if no member exists
          final newMember = Member(name: memberName);
          updatedMemberId = await _dbHelper.insert(AppConstants.tableMembers, newMember.toMap());
          if (updatedMemberId == 0) {
            throw Exception('Failed to create new member for role change.');
          }
        }
      }

      final int rowsAffected = await _dbHelper.update(
        AppConstants.tableUsers,
        {
          AppConstants.columnUserRole: newRole.toShortString(),
          AppConstants.columnMemberId: updatedMemberId,
        },
        '${AppConstants.columnUserId} = ?',
        [userId],
      );
      return rowsAffected > 0;
    } catch (e) {
      print('Error changing user role: $e');
      return false;
    }
  }

  /// Deletes a user and cascades deletion to associated member and other data.
  /// (Note: SQLite CASCADE handles related tables if foreign keys are set correctly).
  Future<bool> deleteUser(int userId) async {
    try {
      final List<Map<String, dynamic>> users = await _dbHelper.query(
        AppConstants.tableUsers,
        where: '${AppConstants.columnUserId} = ?',
        whereArgs: [userId],
      );

      if (users.isEmpty) return false;

      final user = User.fromMap(users.first);

      // Delete the user
      final int userRowsAffected = await _dbHelper.delete(
        AppConstants.tableUsers,
        '${AppConstants.columnUserId} = ?',
        [userId],
      );

      // If user had an associated member, delete that member.
      // The CASCADE DELETE on meal_entries, expenses, contributions, market_schedules
      // will handle those records if the member is deleted.
      if (user.memberId != null) {
        await _dbHelper.delete(
          AppConstants.tableMembers,
          '${AppConstants.columnMemberIdPk} = ?',
          [user.memberId],
        );
      }

      return userRowsAffected > 0;
    } catch (e) {
      print('Error deleting user: $e');
      return false;
    }
  }

  /// Resets the entire database.
  Future<void> resetDatabase() async {
    await _dbHelper.resetDatabase();
    await logoutUser(); // Ensure no user is logged in after reset
  }
}
