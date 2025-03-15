import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://kgzycpnpzxvcfhclkrqv.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtnenljcG5wenh2Y2ZoY2xrcnF2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzg0OTk5OTYsImV4cCI6MjA1NDA3NTk5Nn0.SR6ecdG-KZPywMZBZvwvl8PMCfhgMh4QXQi4FRkPfl0',
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Doctor-Patient App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: AuthService().handleAuthState(),
    );
  }
}
