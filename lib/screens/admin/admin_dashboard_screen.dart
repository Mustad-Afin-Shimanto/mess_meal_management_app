// lib/screens/admin/admin_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mess_meal_management_app/providers/user_provider.dart';
import 'package:mess_meal_management_app/providers/member_provider.dart';
import 'package:mess_meal_management_app/services/auth_service.dart';
import 'package:mess_meal_management_app/models/user.dart';
import 'package:mess_meal_management_app/models/user_role.dart';
import 'package:mess_meal_management_app/routes.dart';
import 'package:mess_meal_management_app/utils/app_constants.dart';
import 'package:mess_meal_management_app/widgets/custom_button.dart';

/// Admin dashboard for managing users and performing sensitive operations.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isLoading = false;
  List<User> _users = [];
  Map<int, String> _memberNames = {}; // Map memberId to memberName

  @override
  void initState() {
    super.initState();
    _fetchUsersAndMembers();
  }

  /// Fetches all users and their associated member names.
  Future<void> _fetchUsersAndMembers() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final memberProvider = Provider.of<MemberProvider>(context, listen: false);

      // Fetch all users (AuthService.getAllUsers() now excludes Admin users)
      _users = await authService.getAllUsers();

      // Fetch all members to create a lookup map
      await memberProvider.fetchAllMembers();
      _memberNames = {
        for (var member in memberProvider.members) member.id!: member.name
      };
    } catch (e) {
      print('Error fetching users and members: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load users: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Toggles the active status of a user.
  Future<void> _toggleActiveStatus(User user) async {
    setState(() {
      _isLoading = true;
    });
    final authService = Provider.of<AuthService>(context, listen: false);
    try {
      final bool success = await authService.updateUserActiveStatus(
        user.id!,
        !user.isActive,
      );
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user.username} active status updated.')),
        );
        _fetchUsersAndMembers(); // Refresh list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update active status.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Changes a user's role.
  Future<void> _changeUserRole(User user) async {
    final UserRole? selectedRole = await showDialog<UserRole>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Change Role for ${user.username}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: UserRole.values.where((role) => role != UserRole.Admin && role != UserRole.None).map((role) {
              return RadioListTile<UserRole>(
                title: Text(role.toShortString()),
                value: role,
                groupValue: user.role,
                onChanged: (UserRole? value) {
                  Navigator.of(context).pop(value);
                },
              );
            }).toList(),
          ),
        );
      },
    );

    if (selectedRole != null && selectedRole != user.role) {
      setState(() {
        _isLoading = true;
      });
      final authService = Provider.of<AuthService>(context, listen: false);
      try {
        final bool success = await authService.changeUserRole(user.id!, selectedRole);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${user.username}\'s role changed to ${selectedRole.toShortString()}.')),
          );
          _fetchUsersAndMembers(); // Refresh list
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to change user role.')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Deletes a user.
  Future<void> _deleteUser(User user) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete User'),
          content: Text('Are you sure you want to delete user "${user.username}"? This action is irreversible.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });
      final authService = Provider.of<AuthService>(context, listen: false);
      try {
        final bool success = await authService.deleteUser(user.id!);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${user.username} deleted successfully.')),
          );
          _fetchUsersAndMembers(); // Refresh list
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete user.')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Handles user logout.
  Future<void> _logout() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.logout();
    Navigator.of(context).pushReplacementNamed(AppRoutes.memberLogin);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.adminDashboard), // Corrected constant
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchUsersAndMembers,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: AppConstants.logoutButton,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User Management',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            Expanded(
              child: _users.isEmpty
                  ? const Center(child: Text('No users registered yet.'))
                  : ListView.builder(
                itemCount: _users.length,
                itemBuilder: (context, index) {
                  final user = _users[index];
                  final memberName = user.memberId != null
                      ? _memberNames[user.memberId] ?? 'N/A'
                      : 'N/A';
                  return Card(
                    margin: const EdgeInsets.only(bottom: AppConstants.paddingSmall),
                    elevation: 2,
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(user.username[0].toUpperCase()),
                      ),
                      title: Text(user.username),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Role: ${user.role.toShortString()}'),
                          Text('Member: $memberName'),
                          Text('Active: ${user.isActive ? 'Yes' : 'No'}'),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (String choice) {
                          if (choice == 'toggle_active') {
                            _toggleActiveStatus(user);
                          } else if (choice == 'change_role') {
                            _changeUserRole(user);
                          } else if (choice == 'delete_user') {
                            _deleteUser(user);
                          }
                        },
                        itemBuilder: (BuildContext context) {
                          return <PopupMenuEntry<String>>[
                            PopupMenuItem<String>(
                              value: 'toggle_active',
                              child: Text(user.isActive ? 'Deactivate' : 'Activate'),
                            ),
                            PopupMenuItem<String>(
                              value: 'change_role',
                              child: const Text('Change Role'),
                            ),
                            PopupMenuItem<String>(
                              value: 'delete_user',
                              child: const Text('Delete User', style: TextStyle(color: Colors.red)),
                            ),
                          ];
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            CustomButton(
              text: AppConstants.resetDatabaseButton,
              onPressed: () async {
                final authService = Provider.of<AuthService>(context, listen: false);
                await authService.resetDatabase();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Database reset successfully!')),
                );
                Navigator.of(context).pushReplacementNamed(AppRoutes.splash);
              },
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }
}
