import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/logger_service.dart'; // Import LoggerService for debugging
import '../../services/file_service.dart';

class PatientUploadPDFScreen extends StatefulWidget {
  const PatientUploadPDFScreen({super.key});

  @override
  PatientUploadPDFScreenState createState() => PatientUploadPDFScreenState();
}

class PatientUploadPDFScreenState extends State<PatientUploadPDFScreen> {
  final FileService fileService = FileService();
  final TextEditingController fileNameController = TextEditingController();

Future<void> _uploadFile(BuildContext context) async {
  String? successMessage;
  String? errorMessage;

  try {
    // Get the current patient's ID
    String? userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('You must be logged in as a patient.');
    }

    // Pick a file using FilePicker
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'], // Allow only PDF files
    );

    if (result == null || result.files.isEmpty) {
      throw Exception('No file selected.');
    }

    PlatformFile file = result.files.first;

    // Get the custom file name from the text field
    String customFileName = fileNameController.text.trim();
    if (customFileName.isEmpty) {
      throw Exception('Please provide a file name.');
    }

    // Append the file extension if not already present
    if (!customFileName.toLowerCase().endsWith('.pdf')) {
      customFileName += '.pdf';
    }

    // Define the file path in the format `patients/<patient_id>/<file_name>`
    String filePath = 'patients/$userId/$customFileName';

    // Prepare the file data based on the platform
    dynamic fileData;
    if (kIsWeb) {
      Uint8List? fileBytes = file.bytes;
      if (fileBytes == null) {
        throw Exception('Failed to read file bytes.');
      }
      fileData = fileBytes;
    } else {
      String localFilePath = file.path!;
      fileData = localFilePath;
    }

    // Call the uploadFile method with all required parameters
    String fileUrl = await fileService.uploadFile(
      fileData,
      userId,
      filePath,
      patientId: userId, // Pass the patientId (same as userId for self-upload)
      customFileName: customFileName, // Pass the custom file name
    );

    // Log the file URL for debugging
    LoggerService.debug('Uploaded file URL: $fileUrl');

    // Set the success message
    successMessage = 'File uploaded successfully!';
  } catch (e) {
    // Set the error message
    errorMessage = 'Error uploading file: $e';
  }

  // Defer the use of BuildContext to a post-frame callback
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return; // Ensure the widget is still mounted

    if (successMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
    } else if (errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Upload Your PDF')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: fileNameController,
              decoration: InputDecoration(
                labelText: 'Enter file name',
                hintText: 'e.g., medical_report.pdf',
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _uploadFile(context),
              child: Text('Select and Upload PDF'),
            ),
          ],
        ),
      ),
    );
  }
}