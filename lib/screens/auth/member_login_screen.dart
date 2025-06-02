// lib/screens/auth/member_login_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mess_meal_management_app/providers/user_provider.dart';
import 'package:mess_meal_management_app/routes.dart';
import 'package:mess_meal_management_app/models/user_role.dart';
import 'package:mess_meal_management_app/utils/app_constants.dart';
import 'package:mess_meal_management_app/widgets/custom_button.dart';

/// Login screen for general members and managers.
class MemberLoginScreen extends StatefulWidget {
  const MemberLoginScreen({super.key});

  @override
  State<MemberLoginScreen> createState() => _MemberLoginScreenState();
}

class _MemberLoginScreenState extends State<MemberLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Handles the member/manager login process.
  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final userProvider = Provider.of<UserProvider>(context, listen: false);

      try {
        final bool success = await userProvider.login(
          _usernameController.text.trim(),
          _passwordController.text,
        );

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login successful!')),
          );
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
            case UserRole.None: // Should not happen if authenticated
              Navigator.of(context).pushReplacementNamed(AppRoutes.memberLogin);
              break;
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid username or password.')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.memberLoginTitle), // Corrected constant
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text( // Removed const from Text widget as it uses non-const AppConstants.memberLoginTitle
                  AppConstants.memberLoginTitle, // Corrected constant
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppConstants.paddingLarge),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: AppConstants.usernameHint,
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter username';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppConstants.paddingMedium),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: AppConstants.passwordHint,
                    prefixIcon: Icon(Icons.lock),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppConstants.paddingLarge),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : CustomButton(
                  text: AppConstants.loginButton, // Corrected constant
                  onPressed: _login,
                ),
                const SizedBox(height: AppConstants.paddingMedium),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      AppRoutes.registration,
                      arguments: {'isAdminRegistration': false},
                    );
                  },
                  child: const Text('Don\'t have an account? Register Now'),
                ),
                const SizedBox(height: AppConstants.paddingMedium),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed(AppRoutes.adminLogin);
                  },
                  child: const Text('Admin Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
