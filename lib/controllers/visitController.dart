// lib/controllers/visitController.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/visit_record.dart';
import 'notificationController.dart';

class VisitController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collectionName = "visit_record";
  final NotificationController _notif = NotificationController();

  Future<void> addVisitRecord(VisitRecord record) async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception("No user is currently logged in.");
    }

    // ASSIGN DOC ID
    record.doctorId = user.uid;

    if (record.doctorId.isEmpty) {
      throw Exception(" Doctor ID cannot be empty.");
    }

    try {
      // CREATE FIRE-DOC
      DocumentReference ref = _firestore.collection(collectionName).doc();
      record.visitId = ref.id;

      Map<String, dynamic> data = record.toMap();
      data['created_at'] = FieldValue.serverTimestamp();

      // SAVE
      await ref.set(data);
      print("Visit Record Created: ${record.visitId}");

      //POST APPOINTM
      await _notif.sendPushToStudent(
        studentId: record.studentId,
        type: 'visit_created',
       title: 'Post-Visit Reminder',
        message: 'Your visit is complete! Remember to rest, stay hydrated, and follow your doctor’s advice.',
        referenceId: record.visitId!,
      );

      print("Immediate OneSignal push sent to student ${record.studentId}");


    } catch (e) {
      print("Error adding visit record: $e");
      rethrow;
    }
  }

  Future<VisitRecord?> getVisitRecordByAppointment(String appointmentId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(collectionName)
          .where("appointment_id", isEqualTo: appointmentId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final data = snapshot.docs.first.data() as Map<String, dynamic>;
      return VisitRecord.fromMap(data);

    } catch (e) {
      print(" Error fetching visit record: $e");
      return null;
    }
  }

  Future<List<VisitRecord>> getVisitRecordsByStudent(String studentId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(collectionName)
          .where("student_id", isEqualTo: studentId)
          .orderBy("created_at", descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return VisitRecord.fromMap(data);
      }).toList();

    } catch (e) {
      print(" Error fetching visits for student: $e");
      return [];
    }
  }
}
