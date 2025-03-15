import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';

class FileService {
  final supabase = Supabase.instance.client;

  /// Upload a file to Supabase Storage with a custom file path.
Future<String> uploadFile(
  dynamic fileData,
  String userId,
  String filePath, {
  required String patientId, // Patient ID for metadata
  required String customFileName, // Custom file name provided by the user
}) async {
  try {
    if (kIsWeb) {
      Uint8List fileBytes = fileData as Uint8List;
      await supabase.storage.from('files').uploadBinary(
        filePath,
        fileBytes,
        fileOptions: FileOptions(
          contentType: 'application/pdf',
          upsert: false,
          cacheControl: '3600',
        ),
      );
    } else {
      File localFile = File(fileData as String);
      await supabase.storage.from('files').upload(
        filePath,
        localFile,
        fileOptions: FileOptions(
          contentType: 'application/pdf',
          upsert: false,
          cacheControl: '3600',
        ),
      );
    }

    // Get the public URL of the uploaded file
    final fileUrl = supabase.storage.from('files').getPublicUrl(filePath);

    // Save metadata in the database, including the custom file name
    await supabase.from('files').insert({
      'user_id': userId,
      'patient_id': patientId,
      'file_url': fileUrl,
      'file_name': customFileName, // Save the custom file name
      'uploaded_at': DateTime.now().toIso8601String(),
    });

    return fileUrl;
  } catch (e) {
    throw Exception('Error uploading file: $e');
  }
}

  /// Fetch all files for a specific patient from Supabase.
Future<List<Map<String, dynamic>>> getFilesForPatient(String patientId) async {
    final response = await supabase
        .from('files')
        .select('*')
        .eq('patient_id', patientId);

    return response;
  }

  /// Delete a file from Supabase Storage.
  Future<void> deleteFile(String filePath) async {
    try {
      await supabase.storage.from('files').remove([filePath]); // Wrap filePath in a list
    } catch (e) {
      throw Exception('Error deleting file: $e');
    }
  }

  /// List all files in a specific folder (e.g., `patients/<patient_id>/`).
  Future<List<dynamic>> listFilesInFolder(String folderPath) async {
    try {
      final response = await supabase.storage.from('files').list(path: folderPath);
      return response;
    } catch (e) {
      throw Exception('Error listing files: $e');
    }
  }
}