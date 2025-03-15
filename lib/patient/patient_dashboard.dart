import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../auth/login_screen.dart'; // Import your login screen
import '../patient/patient_profile_screen.dart'; // Import the profile screen
import '../patient/view_appointments_screen.dart'; // Import appointment screen
import '../patient/view_prescriptions_screen.dart'; // Import prescription screen
import '../patient/view_pdf_screen.dart'; // Import medical files screen
import '../patient/patientpdf.dart'; // Import upload PDF screen

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  PatientDashboardState createState() => PatientDashboardState();
}

class PatientDashboardState extends State<PatientDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    ViewAppointmentsScreen(), // Appointments
    ViewPrescriptionsScreen(), // Prescriptions
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
        MaterialPageRoute(
            builder: (context) => LoginScreen()), // Navigate to login screen
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
        title: Text('Patient Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout, // Add logout functionality
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                'Patient Profile',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              title: Text('Profile'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => PatientProfileScreen()),
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
              icon: Icon(Icons.calendar_today), label: 'Appointments'),
          BottomNavigationBarItem(
              icon: Icon(Icons.assignment), label: 'Prescriptions'),
          BottomNavigationBarItem(
              icon: Icon(Icons.file_present), label: 'Medical Files'),
          BottomNavigationBarItem(
              icon: Icon(Icons.upload_file), label: 'Upload PDF'), // New tab
        ],
      ),
    );
  }
}
