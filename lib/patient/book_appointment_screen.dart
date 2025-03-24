import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';

class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({super.key});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  // Key to force FutureBuilder to rebuild
  UniqueKey _futureBuilderKey = UniqueKey();

  // Logger instance
  final Logger _logger = Logger();

  Future<List<Map<String, dynamic>>> _fetchAvailableSlots() async {
    try {
      // Fetch available time slots (not booked)
      final response = await Supabase.instance.client
          .from('time_slots')
          .select('*')
          .eq('is_booked', false);

      // Log the response for debugging
      _logger.d('Fetched time slots: $response');

      return response;
    } catch (e) {
      // Log the error for debugging
      _logger.e('Error fetching time slots: $e');
      throw Exception('Error fetching time slots: $e');
    }
  }

  Future<void> _bookAppointment(String timeSlotId) async {
    try {
      final patientId = Supabase.instance.client.auth.currentUser!.id;

      // Fetch the time slot to get the date and time
      final timeSlot = await Supabase.instance.client
          .from('time_slots')
          .select('date, start_time, is_booked')
          .eq('id', timeSlotId)
          .single();

      // Log the current state of the time slot
      _logger.d('Time slot before update: $timeSlot');

      // Ensure the time slot is not already booked
      if (timeSlot['is_booked'] == true) {
        _logger.w('Time slot is already booked');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return; // Ensure the widget is still mounted
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This time slot is already booked.')),
          );
        });
        return;
      }

      // Mark the time slot as booked
      final updateResponse = await Supabase.instance.client
          .from('time_slots')
          .update({'is_booked': true}) // Only update is_booked to true
          .eq('id', timeSlotId)
          .select(); // Add .select() to return the updated row

      // Log the update response for debugging
      _logger.d('Update response: $updateResponse');

      if (updateResponse.isEmpty) {
        _logger.e('Failed to update time slot: No rows updated');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return; // Ensure the widget is still mounted
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to book appointment. Please try again.')),
          );
        });
        return;
      }

      // Create an appointment record
      await Supabase.instance.client.from('appointments').insert({
        'patient_id': patientId,
        'time_slot_id': timeSlotId,
        'date_time': '${timeSlot['date']} ${timeSlot['start_time']}', // Add the date_time value
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return; // Ensure the widget is still mounted
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment booked successfully!')),
        );

        // Refresh the list of available slots
        setState(() {
          _futureBuilderKey = UniqueKey(); // Force FutureBuilder to rebuild
        });
      });
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return; // Ensure the widget is still mounted
        _logger.e('Error booking appointment: $e');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error booking appointment: $e')),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book Appointment')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        key: _futureBuilderKey, // Use the key to force rebuild
        future: _fetchAvailableSlots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No available time slots found.'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final slot = snapshot.data![index];
                final date = slot['date'];
                final startTime = slot['start_time'];
                final endTime = slot['end_time'];
                final timeSlotId = slot['id'];

                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text('$date - $startTime to $endTime'),
                    trailing: ElevatedButton(
                      onPressed: () => _bookAppointment(timeSlotId.toString()),
                      child: const Text('Book'),
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