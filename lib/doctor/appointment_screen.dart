import 'package:doctor_patient_app/doctor/add_appointment.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppointmentScreen extends StatelessWidget {
  const AppointmentScreen({super.key});

  Future<List<Map<String, dynamic>>> _fetchAppointments() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      // Fetch appointments with patient email using the 'patient_id' relationship
      final response = await Supabase.instance.client
          .from('appointments')
          .select('*, users!appointments_patient_id_fkey(email)')
          .eq('doctor_id', userId);

      return response;
    } catch (e) {
      throw Exception('Error fetching appointments: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Appointments')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchAppointments(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No appointments found.'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final appointment = snapshot.data![index];
                final patientEmail = appointment['users']['email'] ?? 'Unknown Email';
                final dateTime = appointment['date_time'];
                final status = appointment['status'];

                return Card(
                  margin: EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text('Patient: $patientEmail'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Date & Time: $dateTime'),
                        Text('Status: $status'),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddAppointmentScreen(),
            ),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}