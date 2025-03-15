import 'package:flutter/material.dart';
import '../auth/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  RegisterScreenState createState() => RegisterScreenState();
}

class RegisterScreenState extends State<RegisterScreen> {
  final AuthService authService = AuthService();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String? selectedRole; // To store the selected role

  // List of roles
  final List<String> roles = ['doctor', 'patient'];

  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  Future<void> _register(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      return; // Stop if validation fails
    }

    try {
      // Call the signUp method from AuthService
      await authService.signUp(
        emailController.text.trim(),
        passwordController.text.trim(),
        selectedRole!,
        context,
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration successful!')),
      );
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during registration: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Email Field
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email cannot be empty.';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                      .hasMatch(value)) {
                    return 'Please enter a valid email address.';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),

              // Password Field
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(labelText: 'Password'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password cannot be empty.';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),

              // Role Dropdown
              DropdownButtonFormField<String>(
                value: selectedRole,
                hint: Text('Select Role'),
                decoration: InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                ),
                items: roles.map((role) {
                  return DropdownMenuItem<String>(
                    value: role,
                    child: Text(role.capitalize()), // Use the capitalize method
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedRole = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a role.';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),

              // Register Button
              ElevatedButton(
                onPressed: () => _register(context),
                child: Text('Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this; // Handle empty strings
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
