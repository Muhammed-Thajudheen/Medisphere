import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ViewPrescriptionsScreen extends StatelessWidget {
  const ViewPrescriptionsScreen({super.key});

  Future<List<Map<String, dynamic>>> fetchPrescriptions(String patientId) async {
    try {
      final response = await Supabase.instance.client
          .from('prescriptions')
          .select('*, users!prescriptions_doctor_id_fkey(email)')
          .eq('patient_id', patientId);

      return response;
    } catch (e) {
      throw Exception('Error fetching prescriptions: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final patientId = Supabase.instance.client.auth.currentUser!.id;

    return Scaffold(
      appBar: AppBar(title: Text('Prescriptions')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchPrescriptions(patientId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No prescriptions found.'));
          } else {
            final prescriptions = snapshot.data!;
            return ListView.builder(
              itemCount: prescriptions.length,
              itemBuilder: (context, index) {
                final prescription = prescriptions[index];
                final doctorEmail = prescription['users']['email'] ?? 'Unknown Doctor';
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
                        Text('Doctor: $doctorEmail', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Text('Details: $details'),
                        SizedBox(height: 8),
                        Text('Date: $formattedDate'),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}