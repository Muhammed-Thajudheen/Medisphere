import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:logger/logger.dart'; // For logging
import '../../services/file_service.dart';

class ViewPDFScreen extends StatefulWidget {
  const ViewPDFScreen({super.key});

  @override
  State<ViewPDFScreen> createState() => _ViewPDFScreenState();
}

class _ViewPDFScreenState extends State<ViewPDFScreen> {
  final FileService fileService = FileService();
  final Logger _logger = Logger();
  List<Map<String, dynamic>> _files = []; // State variable to store files
  List<Map<String, dynamic>> _patients = []; // State variable to store patients
  String? _selectedPatientId; // Selected patient's ID
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPatients();
  }

  // Fetch all patients
  Future<void> fetchPatients() async {
    try {
      final response = await Supabase.instance.client
          .from('users')
          .select()
          .eq('role', 'patient'); // Fetch only patients

      _logger.d('Fetched patients: $response'); // Log the fetched patients
      setState(() {
        _patients = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      _logger.e('Error fetching patients: $e'); // Log the error
      setState(() {
        isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching patients: $e')),
      );
    }
  }

  // Fetch files for the selected patient
  Future<void> fetchFiles(String patientId) async {
    try {
      _logger.d('Fetching files for patient: $patientId'); // Log the patient ID

      // Fetch files where:
      // 1. The file is associated with the selected patient (patient_id = selectedPatientId)
      // 2. The file was uploaded by the selected patient (uploaded_by = selectedPatientId)
      final response = await Supabase.instance.client
          .from('files')
          .select('*')
          .or('patient_id.eq.$patientId,uploaded_by.is.null'); // Include rows where uploaded_by is null

      _logger.d('Fetched files: $response'); // Log the fetched files

      if (response.isEmpty) {
        _logger.d('No files found for patient: $patientId'); // Log if no files are found
      }

      // Ensure that file_name is not null
      final validFiles = response.where((file) => file['file_name'] != null).toList();

      setState(() {
        _files = validFiles;
      });
    } catch (e) {
      _logger.e('Error fetching files: $e'); // Log the error
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching files: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('View Uploaded Files')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Dropdown to select a patient
                  DropdownButtonFormField<String>(
                    value: _selectedPatientId,
                    hint: const Text('Select Patient'),
                    decoration: InputDecoration(
                      labelText: 'Patient',
                      border: OutlineInputBorder(),
                    ),
                    items: _patients.map((patient) {
                      return DropdownMenuItem<String>(
                        value: patient['id'],
                        child: Text(patient['email']), // Display patient email
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPatientId = value;
                      });
                      if (value != null) {
                        fetchFiles(value); // Fetch files for the selected patient
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  // List of files
                  Expanded(
                    child: _files.isEmpty
                        ? const Center(child: Text('No files found.'))
                        : ListView.builder(
                            itemCount: _files.length,
                            itemBuilder: (context, index) {
                              final file = _files[index];
                              return ListTile(
                                leading: const Icon(Icons.picture_as_pdf), // PDF icon
                                title: Text(file['file_name'] ?? 'Unknown File'), // Handle null file_name
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete), // Delete icon
                                  onPressed: () => deleteFile(file['id'], file['file_url']), // Delete function
                                ),
                                onTap: () {
                                  launchURL(file['file_url']); // Launch the file
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  // Function to launch the URL
  void launchURL(String url) async {
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      if (!mounted) return; // Ensure the widget is still mounted
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open the file: $e')),
      );
    }
  }

  // Function to delete a file
  Future<void> deleteFile(String fileId, String fileUrl) async {
    try {
      // Delete the file from Supabase Storage
      final filePath = fileUrl.split('/').last; // Extract the file path from the URL
      await Supabase.instance.client.storage
          .from('your-bucket-name') // Replace with your bucket name
          .remove([filePath]);

      _logger.d('File deleted from storage: $filePath'); // Log the deletion

      // Delete the file record from the database
      await Supabase.instance.client
          .from('files')
          .delete()
          .eq('id', fileId);

      _logger.d('File deleted from database: $fileId'); // Log the deletion

      // Remove the file from the state variable
      setState(() {
        _files.removeWhere((file) => file['id'] == fileId);
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('File deleted successfully.')),
      );
    } catch (e) {
      if (!mounted) return; // Ensure the widget is still mounted
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete the file: $e')),
      );
    }
  }
}