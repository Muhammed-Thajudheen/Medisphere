import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PrescriptionScreen extends StatefulWidget {
  const PrescriptionScreen({super.key});

  @override
  PrescriptionScreenState createState() => PrescriptionScreenState();
}

class PrescriptionScreenState extends State<PrescriptionScreen> {
  final TextEditingController prescriptionController = TextEditingController();
  final supabase = Supabase.instance.client;

  String? selectedPatientId; // To store the selected patient's ID
  List<Map<String, dynamic>> patients = [];
  List<Map<String, dynamic>> prescriptions = [];
  bool isLoading = true;

  Future<void> fetchPatients() async {
    try {
      final response = await supabase
          .from('users')
          .select()
          .eq('role', 'patient'); // Fetch only patients

      setState(() {
        patients = response;
      });
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching patients: $e')),
        );
      });
    }
  }

  Future<void> fetchPrescriptions(String doctorId) async {
    try {
      final response = await supabase
          .from('prescriptions')
          .select('*, users!prescriptions_patient_id_fkey(email)')
          .eq('doctor_id', doctorId);

      setState(() {
        prescriptions = response;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching prescriptions: $e')),
        );
      });
    }
  }

  Future<void> _sendPrescription(String patientId, String details) async {
    try {
      final doctorId = supabase.auth.currentUser!.id;
      await supabase.from('prescriptions').insert({
        'doctor_id': doctorId,
        'patient_id': patientId,
        'details': details,
        'created_at': DateTime.now().toIso8601String(),
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Prescription sent successfully!')),
        );

        // Refresh the prescriptions list after adding a new one
        fetchPrescriptions(doctorId);
      });
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending prescription: $e')),
        );
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchPatients();
    fetchPrescriptions(supabase.auth.currentUser!.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Prescriptions')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : prescriptions.isEmpty
              ? Center(child: Text('No prescriptions found.'))
              : ListView.builder(
                  itemCount: prescriptions.length,
                  itemBuilder: (context, index) {
                    final prescription = prescriptions[index];
                    final patientEmail = prescription['users']['email'] ?? 'Unknown Patient';
                    final details = prescription['details'];
                    final createdAt = prescription['created_at'];
                    final formattedDate =
                        createdAt != null ? DateTime.parse(createdAt).toString() : 'Unknown Date';

                    return Card(
                      margin: EdgeInsets.all(8.0),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Patient: $patientEmail',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            SizedBox(height: 8),
                            Text('Details: $details'),
                            SizedBox(height: 8),
                            Text('Date: $formattedDate'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Add Prescription'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedPatientId,
                    hint: Text('Select Patient'),
                    decoration: InputDecoration(labelText: 'Patient'),
                    items: patients.map((patient) {
                      return DropdownMenuItem<String>(
                        value: patient['id'],
                        child: Text(patient['email'] ?? 'Unknown Patient'),
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
                  SizedBox(height: 16),
                  TextField(
                    controller: prescriptionController,
                    decoration: InputDecoration(labelText: 'Prescription Details'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close the dialog
                  },
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: selectedPatientId == null || prescriptionController.text.isEmpty
                      ? null
                      : () async {
                          await _sendPrescription(selectedPatientId!, prescriptionController.text);

                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!mounted) return; // Guard with mounted check
                            prescriptionController.clear(); // Clear the text field
                            Navigator.pop(context); // Close the dialog
                          });
                        },
                  child: Text('Send'),
                ),
              ],
            ),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}