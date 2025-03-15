import 'package:flutter/material.dart';
import '../auth/auth_service.dart';
import '../doctor/upload_pdf_screen.dart'; // Import the upload screen
import '../doctor/view_pdf_screen.dart';  // Import the view PDF screen
import '../doctor/appointment_screen.dart'; // Import the appointment screen
import '../doctor/prescription_screen.dart'; // Import the prescription screen
import 'package:supabase_flutter/supabase_flutter.dart';

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});

  @override
  DoctorDashboardState createState() => DoctorDashboardState();
}

class DoctorDashboardState extends State<DoctorDashboard> {
  int _selectedIndex = 0; // Tracks the selected tab in the navigation bar

  // List of widgets for each tab
  final List<Widget> _pages = [
    PatientListScreen(), // Default page: List of patients
    AppointmentScreen(),
    PrescriptionScreen(),
    UploadPDFScreen(),
    ViewPDFScreen(), // Ensure this screen is accessible only via patient selection
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Doctor Dashboard'),
        leading: IconButton(
          icon: Icon(Icons.logout),
          onPressed: () async {
            final authService = AuthService();
            try {
              await authService.signOut();
              if (!context.mounted) return;
              Navigator.pushReplacementNamed(context, '/login');
            } catch (e) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error during logout: $e')),
              );
            }
          },
        ),
      ),
      body: _pages[_selectedIndex], // Display the selected page
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // Allows more than 3 items
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Patients',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Appointments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Prescriptions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.upload_file),
            label: 'Upload Files',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.file_present),
            label: 'View Files',
          ),
        ],
      ),
    );
  }
}

// Patient List Screen (Default Page)
class PatientListScreen extends StatelessWidget {
  const PatientListScreen({super.key});

  Future<List<Map<String, dynamic>>> fetchPatients() async {
    final response = await Supabase.instance.client
        .from('users')
        .select()
        .eq('role', 'patient'); // Fetch only patients
    return response;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchPatients(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No patients found.'));
          } else {
            final patients = snapshot.data!;
            return ListView.builder(
              itemCount: patients.length,
              itemBuilder: (context, index) {
                final patient = patients[index];
                return Card(
                  margin: EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text(patient['email']),
                    subtitle: Text('ID: ${patient['id']}'),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Patient Details'),
                          content: Text('Email: ${patient['email']}\nRole: ${patient['role']}'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
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