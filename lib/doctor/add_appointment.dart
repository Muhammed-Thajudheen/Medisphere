import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddAppointmentScreen extends StatefulWidget {
  const AddAppointmentScreen({super.key});

  @override
  AddAppointmentScreenState createState() => AddAppointmentScreenState();
}

class AddAppointmentScreenState extends State<AddAppointmentScreen> {
  final supabase = Supabase.instance.client;

  String? selectedPatientId; // To store the selected patient's ID
  List<Map<String, dynamic>> patients = [];
  bool isLoading = true;

  DateTime? selectedDate; // To store the selected date
  TimeOfDay? selectedTime; // To store the selected time

  @override
  void initState() {
    super.initState();
    fetchPatients();
  }

  Future<void> fetchPatients() async {
    try {
      final response = await supabase
          .from('users')
          .select()
          .eq('role', 'patient'); // Fetch only patients

      setState(() {
        patients = response;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching patients: $e')),
        );
      });
    }
  }

Future<void> _createAppointment(BuildContext context) async {
  try {
    if (selectedPatientId == null || selectedDate == null || selectedTime == null) {
      throw Exception('Please fill all fields.');
    }

    // Combine the selected date and time into a single DateTime object
    final combinedDateTime = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );

    final doctorId = supabase.auth.currentUser!.id;

    await supabase.from('appointments').insert({
      'doctor_id': doctorId,
      'patient_id': selectedPatientId,
      'date_time': combinedDateTime.toIso8601String(), // Store as ISO 8601 string
      'status': 'scheduled', // Use one of the allowed values ('scheduled', 'completed', 'cancelled')
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // Show success snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Appointment created successfully!')),
      );

      // Navigate back to the previous screen
      Navigator.pop(context);
    });
  } catch (e) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating appointment: $e')),
      );
    });
  }
}
  Future<void> _pickDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)), // Allow up to 1 year in the future
    );

    if (pickedDate != null && mounted) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null && mounted) {
      setState(() {
        selectedTime = pickedTime;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Appointment')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedPatientId,
                    hint: Text('Select Patient'),
                    decoration: InputDecoration(
                      labelText: 'Patient',
                      border: OutlineInputBorder(),
                    ),
                    items: patients.map((patient) {
                      return DropdownMenuItem<String>(
                        value: patient['id'],
                        child: Text(patient['email']),
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
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _pickDate(context),
                          child: Text(selectedDate == null
                              ? 'Pick Date'
                              : '${selectedDate!.year}-${selectedDate!.month}-${selectedDate!.day}'),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                       child: ElevatedButton(
                         onPressed: () => _pickTime(context),
                         child: Text(
                         selectedTime == null
                          ? 'Pick Time'
                          : selectedTime!.format(context), // Simplified to avoid unnecessary interpolation
                          ),
                       ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => _createAppointment(context),
                    child: Text('Create Appointment'),
                  ),
                ],
              ),
            ),
    );
  }
}