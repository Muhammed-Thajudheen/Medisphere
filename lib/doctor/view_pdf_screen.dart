import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/file_service.dart';

class ViewPDFScreen extends StatefulWidget {
  const ViewPDFScreen({super.key});

  @override
  ViewPDFScreenState createState() => ViewPDFScreenState();
}

class ViewPDFScreenState extends State<ViewPDFScreen> {
  final FileService fileService = FileService();
  String? selectedPatientId; // To store the selected patient's ID
  List<Map<String, dynamic>> patients = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPatients();
  }

  Future<void> fetchPatients() async {
    try {
      final response = await Supabase.instance.client
          .from('users')
          .select()
          .eq('role', 'patient'); // Fetch only patients

      setState(() {
        patients = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching patients: $e')),
      );
    }
  }

  Future<List<Map<String, dynamic>>> fetchFiles(String patientId) async {
    try {
      final response = await Supabase.instance.client
          .from('files')
          .select('*')
          .eq('patient_id', patientId);

      return response;
    } catch (e) {
      throw Exception('Error fetching files: $e');
    }
  }

  void onViewFilesPressed() {
    if (selectedPatientId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a patient first.')),
      );
      return;
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('View PDF Files')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
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
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => onViewFilesPressed(),
                    child: Text('View Files'),
                  ),
                  SizedBox(height: 20),
                  Expanded(
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: selectedPatientId != null
                          ? fetchFiles(selectedPatientId!)
                          : null,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(
                              child: Text('Error: ${snapshot.error}'));
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return Center(child: Text('No files found.'));
                        } else {
                          final files = snapshot.data!;
                          return ListView.builder(
                            itemCount: files.length,
                            itemBuilder: (context, index) {
                              final file = files[index];
                              return ListTile(
                                title: Text(file['file_name'] ?? 'Unknown File'),
                                subtitle: Text(file['file_url']),
                                onTap: () {
                                  launchURL(file['file_url']);
                                },
                              );
                            },
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void launchURL(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $url')),
      );
    }
  }
}