// lib/screens/auth/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mess_meal_management_app/providers/user_provider.dart';
import 'package:mess_meal_management_app/services/auth_service.dart';
import 'package:mess_meal_management_app/routes.dart';
import 'package:mess_meal_management_app/models/user_role.dart';
import 'package:mess_meal_management_app/utils/app_constants.dart';

/// The initial splash screen that handles routing based on authentication status.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  /// Checks if an admin is registered or if a user is already logged in.
  /// Navigates to the appropriate screen.
  Future<void> _checkAuthStatus() async {
    await Future.delayed(const Duration(seconds: 2)); // Simulate loading time

    final authService = Provider.of<AuthService>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    try {
      final bool isAdminRegistered = await authService.isAdminRegistered();

      if (!isAdminRegistered) {
        // If no admin is registered, go to registration for admin setup
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.registration,
          arguments: {'isAdminRegistration': true},
        );
      } else {
        // If admin exists, try to load current user
        await userProvider.loadCurrentUser();
        if (userProvider.isAuthenticated) {
          // Navigate to the appropriate dashboard based on user role
          switch (userProvider.currentUser!.role) {
            case UserRole.Admin:
              Navigator.of(context).pushReplacementNamed(AppRoutes.adminDashboard);
              break;
            case UserRole.Manager:
              Navigator.of(context).pushReplacementNamed(AppRoutes.managerDashboard);
              break;
            case UserRole.Member:
              Navigator.of(context).pushReplacementNamed(AppRoutes.memberDashboard);
              break;
            case UserRole.None: // Should not happen if authenticated, but for safety
              Navigator.of(context).pushReplacementNamed(AppRoutes.memberLogin);
              break;
          }
        } else {
          // If no user is logged in, go to member login
          Navigator.of(context).pushReplacementNamed(AppRoutes.memberLogin);
        }
      }
    } catch (e) {
      print('Error during splash screen auth check: $e');
      // Fallback to member login on error
      Navigator.of(context).pushReplacementNamed(AppRoutes.memberLogin);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 100,
              color: Colors.white,
            ),
            const SizedBox(height: AppConstants.paddingLarge),
            Text(
              AppConstants.appTitle,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppConstants.paddingLarge * 2),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.secondary),
            ),
          ],
        ),
      ),
    );
  }
}
