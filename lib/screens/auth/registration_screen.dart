// lib/screens/auth/registration_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mess_meal_management_app/services/auth_service.dart';
import 'package:mess_meal_management_app/routes.dart';
import 'package:mess_meal_management_app/utils/app_constants.dart';
import 'package:mess_meal_management_app/widgets/custom_button.dart';

/// Screen for initial admin registration or general user registration.
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool _isLoading = false;
  bool _isAdminRegistration = false; // Flag to determine if it's initial admin setup

  @override
  void initState() {
    super.initState();
    _checkIfAdminExists();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  /// Checks if an admin user already exists to determine registration type.
  Future<void> _checkIfAdminExists() async {
    setState(() {
      _isLoading = true;
    });
    final authService = Provider.of<AuthService>(context, listen: false);
    _isAdminRegistration = !(await authService.isAdminRegistered());
    setState(() {
      _isLoading = false;
    });
  }

  /// Handles user registration.
  Future<void> _registerUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final authService = Provider.of<AuthService>(context, listen: false);

      try {
        final user = await authService.registerUser(
          username: _usernameController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim(),
          email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          isInitialAdmin: _isAdminRegistration,
        );

        if (user != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${user.username} registered successfully!')),
          );
          // Redirect based on whether it was admin registration or regular user
          if (_isAdminRegistration) {
            Navigator.of(context).pushReplacementNamed(AppRoutes.adminLogin);
          } else {
            Navigator.of(context).pushReplacementNamed(AppRoutes.memberLogin);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration failed. Please try again.')),
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
        title: Text(_isAdminRegistration ? AppConstants.registrationScreenTitle : AppConstants.registerButton),
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
                _isAdminRegistration
                    ? 'Register the first Admin account.'
                    : 'Register a new member account.',
                style: Theme.of(context).textTheme.titleLarge,
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
                    return 'Please enter a username';
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
                    return 'Please enter a password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters long';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppConstants.paddingMedium),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: AppConstants.confirmPasswordHint,
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (value) {
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppConstants.paddingMedium),
              // Member details are required for non-admin users
              if (!_isAdminRegistration) ...[
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: AppConstants.nameHint,
                    prefixIcon: Icon(Icons.badge),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your full name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppConstants.paddingMedium),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: AppConstants.emailHint,
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: AppConstants.paddingLarge),
              ],
              CustomButton(
                text: AppConstants.registerButton, // Corrected constant
                onPressed: _registerUser,
              ),
              const SizedBox(height: AppConstants.paddingMedium),
              TextButton(
                onPressed: () {
                  if (_isAdminRegistration) {
                    // If it's admin registration, there's no going back without registering
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please register the admin account to proceed.')),
                    );
                  } else {
                    // For regular member registration, allow navigation to login
                    Navigator.of(context).pushReplacementNamed(AppRoutes.memberLogin);
                  }
                },
                child: Text(_isAdminRegistration
                    ? 'Admin registration required to proceed'
                    : 'Already have an account? Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
