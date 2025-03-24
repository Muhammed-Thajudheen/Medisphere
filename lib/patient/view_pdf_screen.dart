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

  @override
  void initState() {
    super.initState();
    final patientId = Supabase.instance.client.auth.currentUser?.id;
    if (patientId != null) {
      fetchFiles(patientId);
    }
  }

  // Fetch files for the current patient and doctors
  Future<void> fetchFiles(String patientId) async {
    try {
      // Fetch files where patient_id matches the current patient
      final patientFiles = await Supabase.instance.client
          .from('files')
          .select('*')
          .eq('patient_id', patientId);

      // Fetch files where uploaded_by is not null (uploaded by a doctor)
      final doctorFiles = await Supabase.instance.client
          .from('files')
          .select('*')
          .not('uploaded_by', 'is', 'null');

      // Combine the results
      final combinedFiles = [...patientFiles, ...doctorFiles];

      _logger.d('Fetched files: $combinedFiles'); // Log the fetched files

      setState(() {
        _files = combinedFiles;
      });
    } catch (e) {
      _logger.e('Error fetching files: $e'); // Log the error
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching files: $e')),
      );
    }
  }

  // Helper function to extract the file name from the URL
  String getFileNameFromUrl(String url) {
    return url.split('/').last;
  }

  @override
  Widget build(BuildContext context) {
    final String? patientId = Supabase.instance.client.auth.currentUser?.id;

    if (patientId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('View Uploaded Files')),
        body: const Center(child: Text('You must be logged in as a patient.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('View Uploaded Files')),
      body: _files.isEmpty
          ? const Center(child: Text('No files found.'))
          : ListView.builder(
              itemCount: _files.length,
              itemBuilder: (context, index) {
                final file = _files[index];
                return ListTile(
                  leading: const Icon(Icons.picture_as_pdf), // PDF icon
                  title: Text(getFileNameFromUrl(file['file_url'])), // File name
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
    } catch (e) {
      if (!mounted) return; // Ensure the widget is still mounted
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete the file: $e')),
      );
    }
  }
}