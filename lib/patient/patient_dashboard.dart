import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../auth/login_screen.dart'; // Import your login screen
import 'patient_profile_screen.dart'; // Import the profile screen
import 'view_appointments_screen.dart'; // Import appointment screen
import 'view_prescriptions_screen.dart'; // Import prescription screen
import 'view_pdf_screen.dart'; // Import medical files screen
import 'patientpdf.dart'; // Import upload PDF screen
import 'book_appointment_screen.dart'; // Import the new Book Appointment screen

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    ViewAppointmentsScreen(), // Existing Appointments
    ViewPrescriptionsScreen(), // Prescriptions
    BookAppointmentScreen(), // New: Book Appointments
    ViewPDFScreen(), // Medical Files
    PatientUploadPDFScreen(), // Upload PDF
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _logout() async {
    try {
      await Supabase.instance.client.auth.signOut(); // Sign out the user

      if (!mounted) return; // Check if the widget is still mounted

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } catch (e) {
      if (!mounted) return; // Check if the widget is still mounted

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout, // Add logout functionality
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                'Patient Profile',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              title: const Text('Profile'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PatientProfileScreen()),
                );
              },
            ),
          ],
        ),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // Required for more than 3 items
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Appointments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Prescriptions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add), // Icon for booking appointments
            label: 'Book Appointment',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.file_present),
            label: 'Medical Files',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.upload_file),
            label: 'Upload PDF', // New tab
          ),
        ],
      ),
    );
  }
}