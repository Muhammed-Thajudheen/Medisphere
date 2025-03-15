class PrescriptionModel {
  final String id;
  final String doctorId;
  final String patientId;
  final String details;
  final String createdAt;

  PrescriptionModel({
    required this.id,
    required this.doctorId,
    required this.patientId,
    required this.details,
    required this.createdAt,
  });

  factory PrescriptionModel.fromJson(Map<String, dynamic> json) {
    return PrescriptionModel(
      id: json['id'],
      doctorId: json['doctor_id'],
      patientId: json['patient_id'],
      details: json['details'],
      createdAt: json['created_at'],
    );
  }
}
