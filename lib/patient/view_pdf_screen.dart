import 'package:flutter/material.dart';
import '../../services/file_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class ViewPDFScreen extends StatelessWidget {
  ViewPDFScreen({super.key});

  final FileService fileService = FileService();

  Future<List<Map<String, dynamic>>> fetchFiles(String patientId) async {
    try {
      return await fileService.getFilesForPatient(patientId);
    } catch (e) {
      throw Exception('Error fetching files: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? patientId = Supabase.instance.client.auth.currentUser?.id;

    if (patientId == null) {
      return Scaffold(
        appBar: AppBar(title: Text('View Uploaded Files')),
        body: Center(child: Text('You must be logged in as a patient.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('View Uploaded Files')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchFiles(patientId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No files found.'));
          } else {
            final files = snapshot.data!;
            return ListView.builder(
              itemCount: files.length,
              itemBuilder: (context, index) {
                final file = files[index];
                return ListTile(
                  title: Text(file['file_url']),
                  onTap: () {
                    launchURL(file['file_url']);
                  },
                );
              },
            );
          }
        },
      ),
    );
  }

  void launchURL(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch $url';
    }
  }
}