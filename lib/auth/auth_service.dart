import 'package:doctor_patient_app/auth/login_screen.dart';
import 'package:doctor_patient_app/doctor/doctor_dashboard.dart';
import 'package:doctor_patient_app/patient/patient_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/logger_service.dart'; // Import the logger

class AuthService {
  final supabase = Supabase.instance.client;

  /// Sign up a new user with email and password.
Future<void> signUp(String email, String password, String role, BuildContext context) async {
  try {
    final response = await supabase.auth.signUp(
      email: email,
      password: password,
      data: {'role': role}, // Save role in user_metadata
    );

    if (!context.mounted) return;

    if (response.user != null) {
      LoggerService.info('User created successfully: ${response.user!.email}');
      await supabase.from('users').insert({
        'id': response.user!.id,
        'email': email,
        'role': role,
      });

      LoggerService.info('User data inserted into "users" table.');

      if (!context.mounted) return; // Check if the widget is still mounted

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration successful! Please check your email to confirm your account.')),
      );
    } else {
      LoggerService.error('Failed to create user: No user returned from Supabase.');

      if (!context.mounted) return; // Check if the widget is still mounted

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create user. Please try again.')),
      );
    }
  } catch (e) {
    LoggerService.error('Error during sign-up: $e');

    if (!context.mounted) return; // Check if the widget is still mounted

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error signing up: $e')),
    );
  }
}

  /// Sign in an existing user with email and password.
  Future<void> signIn(
      String email, String password, BuildContext context) async {
    try {
      LoggerService.debug('Attempting to sign in with email: $email');

      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (!context.mounted) return;

      LoggerService.info('User signed in successfully: ${response.user}');
      Navigator.pushReplacementNamed(context, '/dashboard');
    } catch (e) {
      if (!context.mounted) return;

      LoggerService.error('Error during sign-in: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing in: $e')),
      );
    }
  }

  /// Logs out the current user.
  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  /// Handle authentication state changes.
  Widget handleAuthState() {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          LoggerService.debug('Auth state: Waiting...');
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data!.session != null) {
          final userRole = snapshot.data!.session!.user.userMetadata?['role'];
          LoggerService.debug('User role: $userRole');

          if (userRole == 'doctor') {
            return DoctorDashboard();
          } else if (userRole == 'patient') {
            return PatientDashboard();
          } else {
            LoggerService.error('Invalid or missing user role: $userRole');
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Invalid or missing user role.'),
                    ElevatedButton(
                      onPressed: () => signOut(),
                      child: Text('Log Out'),
                    ),
                  ],
                ),
              ),
            );
          }
        } else {
          LoggerService.debug('No session found. Redirecting to login screen.');
          return LoginScreen();
        }
      },
    );
  }
}
