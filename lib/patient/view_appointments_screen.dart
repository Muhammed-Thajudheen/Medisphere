import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ViewAppointmentsScreen extends StatelessWidget {
  const ViewAppointmentsScreen({super.key});

  Future<List<Map<String, dynamic>>> fetchAppointments(String patientId) async {
    try {
      final response = await Supabase.instance.client
          .from('appointments')
          .select('*, users!appointments_doctor_id_fkey(email)')
          .eq('patient_id', patientId);

      return response;
    } catch (e) {
      throw Exception('Error fetching appointments: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final patientId = Supabase.instance.client.auth.currentUser!.id;

    return Scaffold(
      appBar: AppBar(title: Text('Appointments')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchAppointments(patientId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No appointments found.'));
          } else {
            final appointments = snapshot.data!;
            return ListView.builder(
              itemCount: appointments.length,
              itemBuilder: (context, index) {
                final appointment = appointments[index];
                final doctorEmail = appointment['users']['email'] ?? 'Unknown Doctor';
                final dateTime = appointment['date_time'];
                final formattedDateTime = dateTime != null ? DateTime.parse(dateTime).toString() : 'Unknown Date';

                return Card(
                  margin: EdgeInsets.all(8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Doctor: $doctorEmail', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Text('Date & Time: $formattedDateTime'),
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