
import 'package:cloud_firestore/cloud_firestore.dart';

class VisitRecord {
  String? visitId; 
  String studentId;
  String appointmentId;
  String doctorId;
  List<String> medIds;
  String diagnosis;
  String note;
  Timestamp? createdAt; 

  VisitRecord({
    this.visitId, 
    required this.studentId,
    required this.appointmentId,
    required this.doctorId,
    required this.medIds,
    required this.diagnosis,
    required this.note,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'visit_id': visitId,
      'student_id': studentId,
      'appointment_id': appointmentId,
      'doctor_id': doctorId,
      'med_id': medIds,
      'diagnosis': diagnosis,
      'note': note,
      'created_at': createdAt,
    };
  }

  factory VisitRecord.fromMap(Map<String, dynamic> map) {
    return VisitRecord(
      visitId: map['visit_id'],
      studentId: map['student_id'],
      appointmentId: map['appointment_id'],
      doctorId: map['doctor_id'],
      medIds: List<String>.from(map['med_id'] ?? []),
      diagnosis: map['diagnosis'] ?? '',
      note: map['note'] ?? '',
      createdAt: map['created_at'],
    );
  }
}
