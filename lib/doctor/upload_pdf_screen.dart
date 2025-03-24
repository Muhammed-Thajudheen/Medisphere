import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/file_service.dart';
import '../services/logger_service.dart';

class UploadPDFScreen extends StatefulWidget {
  const UploadPDFScreen({super.key});

  @override
  UploadPDFScreenState createState() => UploadPDFScreenState();
}

class UploadPDFScreenState extends State<UploadPDFScreen> {
  final FileService fileService = FileService();
  final TextEditingController fileNameController = TextEditingController();
  String? selectedPatientId; // To store the selected patient's ID

  Future<List<Map<String, dynamic>>> fetchPatients() async {
    try {
      final response = await Supabase.instance.client
          .from('users')
          .select()
          .eq('role', 'patient'); // Fetch only patients
      return response;
    } catch (e) {
      throw Exception('Error fetching patients: $e');
    }
  }

 Future<void> _uploadFile(BuildContext context) async {
  String? successMessage;
  String? errorMessage;

  try {
    // Get the current user's ID
    String? userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('You must be logged in.');
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

    // Insert the file metadata into the 'files' table
    await Supabase.instance.client.from('files').insert({
      'doctor_id': selectedPatientId ?? userId, // Use selectedPatientId if available, otherwise use current user's ID
      'patient_id': userId, // Patient ID is always the current user's ID
      'file_url': fileUrl, // URL of the uploaded file
      'file_name': customFileName, // Custom file name
      'uploaded_at': DateTime.now().toIso8601String(), // Current timestamp
      'user_id': userId, // User ID (current user)
      'uploaded_by': userId, // Uploaded by the current user
    });

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
      appBar: AppBar(title: Text('Upload PDF')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            FutureBuilder<List<Map<String, dynamic>>>(
              future: fetchPatients(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No patients found.'));
                } else {
                  final patients = snapshot.data!;
                  return DropdownButtonFormField<String>(
                    value: selectedPatientId,
                    hint: Text('Select Patient'),
                    decoration: InputDecoration(
                      labelText: 'Patient',
                      border: OutlineInputBorder(),
                    ),
                    items: patients.map((patient) {
                      return DropdownMenuItem<String>(
                        value: patient['id'],
                        child: Text(patient['email']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedPatientId = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a patient.';
                      }
                      return null;
                    },
                  );
                }
              },
            ),
            SizedBox(height: 20),
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