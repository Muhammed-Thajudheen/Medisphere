import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/logger_service.dart';

class PatientListScreen extends StatefulWidget {
  const PatientListScreen({super.key});

  @override
  PatientListScreenState createState() => PatientListScreenState(); // Make the state class public
}

class PatientListScreenState extends State<PatientListScreen> {
  List<Map<String, dynamic>> patients = [];
  String? selectedPatientId; // Tracks the selected patient's ID
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

      LoggerService.debug('Fetched patients: $patients');
    } catch (e) {
      LoggerService.error('Error fetching patients: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void onViewFilesPressed(BuildContext context) {
    if (selectedPatientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a patient first.')),
      );
      return;
    }

    // Navigate to ViewPDFScreen with the selected patient's ID
    Navigator.pushNamed(
      context,
      '/view_files',
      arguments: selectedPatientId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Patient to View Files'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Select Patient',
                      border: OutlineInputBorder(),
                    ),
                    value: selectedPatientId,
                    items: patients.map((patient) {
                      return DropdownMenuItem<String>(
                        value: patient['id'],
                        child: Text(patient['email']),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedPatientId = newValue; // Update selected patient ID
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a patient.';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => onViewFilesPressed(context),
                  child: Text('View Files'),
                ),
              ],
            ),
    );
  }
}