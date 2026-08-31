import 'package:cloud_firestore/cloud_firestore.dart';

class Appointment {
  String appointmentId;
  String studentId;
  String doctorId;
  DateTime apTimestamp;
  String status;
  String remark; //SERVICE
  String? prescription;

  Appointment({
    required this.appointmentId,
    required this.studentId,
    required this.doctorId,
    required this.apTimestamp,
    required this.status,
    required this.remark,
    this.prescription,
  });

  Map<String, dynamic> toMap() {
    return {
      'appointment_id': appointmentId,
      'student_id': studentId,
      'doctor_id': doctorId,
      'ap_timestamp': apTimestamp,
      'status': status,
      'remark': remark,
      'prescription': prescription,
    };
  }

  factory Appointment.fromMap(Map<String, dynamic> data, String docId) {
    return Appointment(
      appointmentId: docId,
      studentId: data['student_id'] ?? '',
      doctorId: data['doctor_id'] ?? '',
      apTimestamp: (data['ap_timestamp'] is Timestamp)
          ? (data['ap_timestamp'] as Timestamp).toDate()
          : DateTime.tryParse(data['ap_timestamp'] ?? '') ?? DateTime.now(),
      status: data['status'] ?? '',
      remark: data['remark'] ?? '',
      prescription: data['prescription'],
    );
  }
}
