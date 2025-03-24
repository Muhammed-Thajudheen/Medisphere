import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/logger_service.dart'; // Import your LoggerService

class PrescriptionScreen extends StatefulWidget {
  const PrescriptionScreen({super.key});

  @override
  PrescriptionScreenState createState() => PrescriptionScreenState();
}

class PrescriptionScreenState extends State<PrescriptionScreen> {
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
      LoggerService.error('Error fetching patients: $e'); // Log error
    }
  }

  Future<void> fetchPrescriptions(String doctorId) async {
    try {
      final response = await supabase
          .from('prescriptions')
          .select('*, users!prescriptions_patient_id_fkey(email)')
          .eq('doctor_id', doctorId);

      // Group prescriptions by created_at
      final groupedPrescriptions = <String, Map<String, dynamic>>{};
      for (final prescription in response) {
        final createdAt = prescription['created_at'];
        if (!groupedPrescriptions.containsKey(createdAt)) {
          groupedPrescriptions[createdAt] = {
            'timestamp': createdAt,
            'prescriptions': <Map<String, dynamic>>[],
          };
        }
        groupedPrescriptions[createdAt]!['prescriptions'].add({
          'patientEmail': prescription['users']['email'] ?? 'Unknown Patient',
          'details': prescription['details'],
        });
      }

      // Convert grouped data to a list and sort by timestamp (descending order)
      final sortedPrescriptions = groupedPrescriptions.values.toList();
      sortedPrescriptions.sort((a, b) {
        final dateA = DateTime.tryParse(a['timestamp']) ?? DateTime(0);
        final dateB = DateTime.tryParse(b['timestamp']) ?? DateTime(0);
        return dateB.compareTo(dateA); // Descending order
      });

      setState(() {
        prescriptions = sortedPrescriptions;
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
      LoggerService.error('Error fetching prescriptions: $e'); // Log error
    }
  }

  Future<void> _sendPrescription(
      String patientId, String details, String timestamp) async {
    try {
      final doctorId = supabase.auth.currentUser!.id;
      await supabase.from('prescriptions').insert({
        'doctor_id': doctorId,
        'patient_id': patientId,
        'details': details,
        'created_at': timestamp,
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
      LoggerService.error('Error sending prescription: $e'); // Log error
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
                    final group = prescriptions[index];
                    final timestamp = group['timestamp'];
                    final formattedDate = timestamp != null
                        ? DateTime.parse(timestamp).toString()
                        : 'Unknown Date';
                    final groupedPrescriptions =
                        group['prescriptions'] as List<Map<String, dynamic>>;

                    return Card(
                      margin: EdgeInsets.all(8.0),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Sent on: $formattedDate',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            SizedBox(height: 8),
                            ...groupedPrescriptions.map((prescription) {
                              final patientEmail = prescription['patientEmail'];
                              final details = prescription['details'];

                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Patient: $patientEmail'),
                                    SizedBox(height: 4),
                                    Text('Details: $details'),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final List<TextEditingController> controllers = [
            TextEditingController()
          ];

          showDialog(
            context: context,
            builder: (context) {
              return StatefulBuilder(
                builder: (context, setState) {
                  return AlertDialog(
                    title: Text('Add Prescription(s)'),
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
                              child:
                                  Text(patient['email'] ?? 'Unknown Patient'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedPatientId = value;
                              LoggerService.debug(
                                  'Selected Patient ID updated to: $selectedPatientId');
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
                        ...controllers.map((controller) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: TextField(
                              controller: controller,
                              decoration: InputDecoration(
                                  labelText: 'Prescription Details'),
                              onChanged: (value) {
                                // Rebuild the dialog when text changes
                                setState(() {});
                              },
                            ),
                          );
                        }),
                        SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              controllers.add(TextEditingController());
                              LoggerService.debug(
                                  'Added new controller. Total controllers: ${controllers.length}');
                            });
                          },
                          child: Text('Add Another Prescription'),
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
                        onPressed: selectedPatientId == null ||
                                controllers.every((controller) =>
                                    controller.text.trim().isEmpty)
                            ? null
                            : () async {
                                LoggerService.debug(
                                    'Selected Patient ID: $selectedPatientId');
                                LoggerService.debug(
                                    'Prescriptions to send: ${controllers.map((c) => c.text).toList()}');

                                final timestamp = DateTime.now()
                                    .toIso8601String(); // Generate a single timestamp
                                for (final controller in controllers) {
                                  if (controller.text.trim().isNotEmpty) {
                                    await _sendPrescription(selectedPatientId!,
                                        controller.text.trim(), timestamp);
                                  }
                                }

                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  if (!mounted) return;
                                  Navigator.pop(context); // Close the dialog
                                });
                              },
                        child: Text('Send'),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
