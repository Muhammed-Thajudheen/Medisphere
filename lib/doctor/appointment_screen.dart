import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppointmentScreen extends StatefulWidget {
  const AppointmentScreen({super.key});

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  final supabase = Supabase.instance.client;

  // Controllers for the form fields
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();

  // Key to force the FutureBuilder to rebuild
  UniqueKey _futureBuilderKey = UniqueKey();

  // Fetch all time slots (both booked and unbooked)
  Future<List<Map<String, dynamic>>> _fetchAvailableSlots() async {
    try {
      final userId = supabase.auth.currentUser!.id;

      // Fetch all time slots for the doctor
      final response = await supabase
          .from('time_slots')
          .select('*')
          .eq('doctor_id', userId); // Removed the is_booked filter

      return response;
    } catch (e) {
      throw Exception('Error fetching time slots: $e');
    }
  }

  // Add a new time slot
  Future<void> _addTimeSlot(BuildContext context) async {
    try {
      final userId = supabase.auth.currentUser!.id;

      // Insert the new time slot into the database
      await supabase.from('time_slots').insert({
        'doctor_id': userId,
        'date': _dateController.text,
        'start_time': _startTimeController.text,
        'end_time': _endTimeController.text,
        'is_booked': false,
      });

      // Ensure the widget is still mounted before using the BuildContext
      if (!mounted) return;

      // Show success message using a safe BuildContext
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Time slot added successfully!')),
          );
        }
      });

      // Clear the form fields
      _dateController.clear();
      _startTimeController.clear();
      _endTimeController.clear();

      // Refresh the list of available slots by updating the key
      setState(() {
        _futureBuilderKey = UniqueKey();
      });
    } catch (e) {
      // Ensure the widget is still mounted before using the BuildContext
      if (!mounted) return;

      // Show error message using a safe BuildContext
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding time slot: $e')),
          );
        }
      });
    }
  }

  // Function to show date picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = "${picked.toLocal()}".split(' ')[0];
      });
    }
  }

  // Function to show time picker
  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        final time = "${picked.hour}:${picked.minute.toString().padLeft(2, '0')}";
        if (isStartTime) {
          _startTimeController.text = time;
        } else {
          _endTimeController.text = time;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Available Time Slots')),
      body: Column(
        children: [
          // Form to add a new time slot
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Date Picker
                TextField(
                  controller: _dateController,
                  decoration: InputDecoration(
                    labelText: 'Date (YYYY-MM-DD)',
                    labelStyle: TextStyle(fontSize: 14), // Smaller label text
                    contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 10), // Smaller padding
                  ),
                  readOnly: true,
                  onTap: () => _selectDate(context),
                ),
                const SizedBox(height: 16),
                // Start Time Picker
                TextField(
                  controller: _startTimeController,
                  decoration: InputDecoration(
                    labelText: 'Start Time (HH:MM)',
                    labelStyle: TextStyle(fontSize: 14), // Smaller label text
                    contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 10), // Smaller padding
                  ),
                  readOnly: true,
                  onTap: () => _selectTime(context, true),
                ),
                const SizedBox(height: 16),
                // End Time Picker
                TextField(
                  controller: _endTimeController,
                  decoration: InputDecoration(
                    labelText: 'End Time (HH:MM)',
                    labelStyle: TextStyle(fontSize: 14), // Smaller label text
                    contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 10), // Smaller padding
                  ),
                  readOnly: true,
                  onTap: () => _selectTime(context, false),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _addTimeSlot(context),
                  child: const Text('Add Time Slot'),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
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
                      final isBooked = slot['is_booked'];

                      return Card(
                        margin: const EdgeInsets.all(8.0),
                        color: isBooked ? Colors.green[100] : null, // Highlight if booked
                        child: ListTile(
                          title: Text('$date - $startTime to $endTime'),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}