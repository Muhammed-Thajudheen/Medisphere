import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ViewPrescriptionsScreen extends StatelessWidget {
  const ViewPrescriptionsScreen({super.key});

  Future<List<Map<String, dynamic>>> _fetchPrescriptions() async {
    try {
      final patientId = Supabase.instance.client.auth.currentUser!.id;

      // Fetch prescriptions for the logged-in patient
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
    return Scaffold(
      appBar: AppBar(title: const Text('My Prescriptions')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchPrescriptions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No prescriptions found.'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final prescription = snapshot.data![index];
                final doctorEmail = prescription['users']['email'] ?? 'Unknown Doctor';
                final details = prescription['details'];
                final createdAt = prescription['created_at'];

                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text('Doctor: $doctorEmail'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Details: $details'),
                        Text('Sent on: $createdAt'),
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