🏥 Doctor-Patient Prescription Management App

A Flutter-based mobile application that enables doctors to securely send prescriptions to patients and allows patients to view their medical records. Built with Flutter and Supabase, this app provides a seamless, real-time communication platform between healthcare providers and patients.

🌟 Features

✅ For Doctors

Send Prescriptions: Doctors can create and send multiple prescriptions to patients.

Select Patients: Choose from a list of registered patients.

Add Multiple Prescriptions: Add multiple prescription details in one go.

Timestamped Records: Prescriptions are grouped and displayed by date and time.

✅ For Patients

View Prescriptions: View all prescriptions sent by doctors.

Organized History: Prescriptions are grouped by timestamp for easy navigation.

Secure Access: Role-based authentication ensures only authorized users can access data.

🔐 Authentication & Security

Supabase Auth: Secure user authentication with email/password.

Role-Based Access: Users are assigned roles (doctor or patient) to control access.

Row-Level Security (RLS): Database policies ensure users only access their own data.

☁️ Backend & Storage

Supabase as Backend: Handles authentication, database, and real-time updates.

PostgreSQL Database: Stores user data, prescriptions, and file metadata.

File Storage: Upload and retrieve PDFs (e.g., lab reports, scans) via Supabase Storage.

🛠️ Developer Experience

Clean Architecture: Modular code structure with separation of concerns.

Error Handling: Comprehensive error logging using LoggerService.

Responsive UI: Built with Flutter for smooth performance on iOS and Android.

State Management: Uses StatefulWidget and FutureBuilder for dynamic UI updates.

📦 Technologies Used

Frontend-Flutter (Dart)

Backend-Supabase

Database-PostgreSQL (via Supabase)

Authentication-Supabase Auth

Storage-Supabase Storage

Logging-logger package

File Picker-file_picker package
