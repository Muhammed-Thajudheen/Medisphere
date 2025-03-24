import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ViewAppointmentsScreen extends StatelessWidget {
  const ViewAppointmentsScreen({super.key});

  Future<List<Map<String, dynamic>>> _fetchAppointments() async {
    try {
      final patientId = Supabase.instance.client.auth.currentUser!.id;

      // Fetch appointments for the logged-in patient
      final response = await Supabase.instance.client
          .from('appointments')
          .select('*, time_slots(*)')
          .eq('patient_id', patientId);

      return response;
    } catch (e) {
      throw Exception('Error fetching appointments: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Appointments')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchAppointments(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No appointments found.'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final appointment = snapshot.data![index];
                final slot = appointment['time_slots'];
                final date = slot['date'];
                final startTime = slot['start_time'];
                final endTime = slot['end_time'];

                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text('$date - $startTime to $endTime'),
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