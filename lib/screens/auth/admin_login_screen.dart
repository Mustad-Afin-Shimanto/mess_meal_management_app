// lib/screens/auth/admin_login_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mess_meal_management_app/providers/user_provider.dart';
import 'package:mess_meal_management_app/routes.dart';
import 'package:mess_meal_management_app/utils/app_constants.dart';
import 'package:mess_meal_management_app/widgets/custom_button.dart';
// Import UserRole

/// Admin login screen for authentication.
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
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

  /// Handles the admin login process.
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
          if (userProvider.isAdmin) {
            Navigator.of(context).pushReplacementNamed(AppRoutes.adminDashboard);
          } else {
            // If a non-admin tries to log in via admin login, redirect to member login
            // or show an error. Here, we'll redirect.
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Only Admin users can log in here.')),
            );
            await userProvider.logout(); // Log out the non-admin user
            Navigator.of(context).pushReplacementNamed(AppRoutes.memberLogin);
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
        title: const Text(AppConstants.adminLoginTitle), // Corrected constant
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppConstants.adminLoginTitle, // Corrected constant
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.paddingLarge),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: AppConstants.usernameHint, // Corrected constant
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your username';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppConstants.paddingMedium),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: AppConstants.passwordHint, // Corrected constant
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppConstants.paddingLarge),
              CustomButton(
                text: AppConstants.loginButton, // Corrected constant
                onPressed: _login,
              ),
              const SizedBox(height: AppConstants.paddingMedium),
              TextButton(
                onPressed: () {
                  // Navigate to member login if admin login is not intended
                  Navigator.of(context).pushReplacementNamed(AppRoutes.memberLogin);
                },
                child: const Text('Are you a member? Login here'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
