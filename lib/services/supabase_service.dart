import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final supabase = Supabase.instance.client;

  // ==============================
  // AUTHENTICATION
  // ==============================

  /// Sign up a new user with email and password.
  Future<void> signUp(String email, String password, String role) async {
    try {
      final response = await supabase.auth.signUp(
        email: email, // Use named arguments
        password: password,
      );
      if (response.user != null) {
        // Save user metadata (role) in the database
        await supabase.from('users').insert({
          'id': response.user!.id,
          'email': email,
          'role': role,
        });
      }
    } catch (e) {
      throw Exception('Error during sign-up: $e');
    }
  }

  /// Sign in an existing user with email and password.
  Future<void> signIn(String email, String password) async {
    try {
      await supabase.auth.signInWithPassword(
        // Updated method name
        email: email,
        password: password,
      );
    } catch (e) {
      throw Exception('Error during sign-in: $e');
    }
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    try {
      await supabase.auth.signOut();
    } catch (e) {
      throw Exception('Error during sign-out: $e');
    }
  }

  /// Get the current authenticated user's ID.
  String? getCurrentUserId() {
    return supabase.auth.currentUser?.id;
  }

  /// Get the current authenticated user's role.
  String? getCurrentUserRole() {
    return supabase
        .auth.currentUser?.userMetadata?['role']; // Use null-aware operator
  }

  // ==============================
  // DATABASE OPERATIONS
  // ==============================

  /// Fetch appointments for a specific user (doctor or patient).
  Future<List<Map<String, dynamic>>> getAppointments(
      String userId, String role) async {
    try {
      if (role == 'doctor') {
        return await supabase
            .from('appointments')
            .select()
            .eq('doctor_id', userId);
      } else {
        return await supabase
            .from('appointments')
            .select()
            .eq('patient_id', userId);
      }
    } catch (e) {
      throw Exception('Error fetching appointments: $e');
    }
  }

  /// Create a new appointment.
  Future<void> createAppointment(
      String doctorId, String patientId, String dateTime) async {
    try {
      await supabase.from('appointments').insert({
        'doctor_id': doctorId,
        'patient_id': patientId,
        'date_time': dateTime,
        'status': 'scheduled',
      });
    } catch (e) {
      throw Exception('Error creating appointment: $e');
    }
  }

  /// Fetch prescriptions for a specific user (doctor or patient).
  Future<List<Map<String, dynamic>>> getPrescriptions(
      String userId, String role) async {
    try {
      if (role == 'doctor') {
        return await supabase
            .from('prescriptions')
            .select()
            .eq('doctor_id', userId);
      } else {
        return await supabase
            .from('prescriptions')
            .select()
            .eq('patient_id', userId);
      }
    } catch (e) {
      throw Exception('Error fetching prescriptions: $e');
    }
  }

  /// Create a new prescription.
  Future<void> createPrescription(
      String doctorId, String patientId, String details) async {
    try {
      await supabase.from('prescriptions').insert({
        'doctor_id': doctorId,
        'patient_id': patientId,
        'details': details,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Error creating prescription: $e');
    }
  }

  // ==============================
  // FILE STORAGE OPERATIONS
  // ==============================

  /// Upload a file to Supabase Storage.
  Future<String> uploadFile(String filePath, String userId) async {
    try {
      final file = File(filePath);
      final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      await supabase.storage.from('files').upload(fileName, file);
      final fileUrl = supabase.storage.from('files').getPublicUrl(fileName);

      // Save file metadata in the database
      await supabase.from('files').insert({
        'user_id': userId,
        'file_url': fileUrl,
        'uploaded_at': DateTime.now().toIso8601String(),
      });

      return fileUrl;
    } catch (e) {
      throw Exception('Error uploading file: $e');
    }
  }

  /// Fetch files for a specific user.
  Future<List<Map<String, dynamic>>> getFiles(String userId) async {
    try {
      return await supabase.from('files').select().eq('user_id', userId);
    } catch (e) {
      throw Exception('Error fetching files: $e');
    }
  }
}
