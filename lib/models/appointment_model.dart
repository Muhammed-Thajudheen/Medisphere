class AppointmentModel {
  final String id;
  final String doctorId;
  final String patientId;
  final String dateTime;
  final String status;

  AppointmentModel({
    required this.id,
    required this.doctorId,
    required this.patientId,
    required this.dateTime,
    required this.status,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'],
      doctorId: json['doctor_id'],
      patientId: json['patient_id'],
      dateTime: json['date_time'],
      status: json['status'],
    );
  }
}
