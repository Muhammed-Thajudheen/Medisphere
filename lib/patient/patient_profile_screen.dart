import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({super.key});

  @override
  PatientProfileScreenState createState() => PatientProfileScreenState();
}

class PatientProfileScreenState extends State<PatientProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _bloodGroupController = TextEditingController();
  final TextEditingController _allergiesController = TextEditingController();

  final supabase = Supabase.instance.client;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = supabase.auth.currentUser!.id;
      final response = await supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      if (!mounted) return;

      _nameController.text = response['name'];
      _dobController.text = DateFormat('yyyy-MM-dd').format(DateTime.parse(response['dob']));
      _bloodGroupController.text = response['blood_group'];
      _allergiesController.text = response['allergies'] ?? 'No';
    } catch (e) {
      if (!mounted) return;
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = supabase.auth.currentUser!.id;
      await supabase.from('profiles').upsert({
        'id': userId,
        'name': _nameController.text,
        'dob': _dobController.text,
        'blood_group': _bloodGroupController.text,
        'allergies': _allergiesController.text.isEmpty ? 'No' : _allergiesController.text,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully!')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Patient Profile')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: 'Name'),
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _dobController,
                    decoration: InputDecoration(labelText: 'Date of Birth (YYYY-MM-DD)'),
                    keyboardType: TextInputType.datetime,
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _bloodGroupController,
                    decoration: InputDecoration(labelText: 'Blood Group'),
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _allergiesController,
                    decoration: InputDecoration(labelText: 'Allergies (Optional)'),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _saveProfile,
                    child: Text('Save Profile'),
                  ),
                ],
              ),
            ),
    );
  }
}