import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/appointment.dart';
import 'notificationController.dart';
import '../services/notification_service.dart';

class AppointmentController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collectionName = 'appointments';

  // NOTIF INIIT
  final NotificationController _notif = NotificationController();

  // TRACK PREVENT DUP
  final Set<String> _notifiedAppointments = {};

  Future<void> addAppointment(Appointment appointment) async {
    try {
      // CREATE
      final docRef = _firestore.collection(collectionName).doc();
      
      // ID ASSIGN
      appointment.appointmentId = docRef.id;
      
      // SAVE & STORE
      await docRef.set(appointment.toMap());
      
    } catch (e) {
      rethrow;
    }
  }

  /// UPCOMING LIST DOC SIDE
  Stream<List<Appointment>> getDoctorPendingAppointments(String doctorId) {
    return _firestore
        .collection(collectionName)
        .where('doctor_id', isEqualTo: doctorId)
        .where('status', whereIn: ['Pending', 'Confirmed'])
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Appointment.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// UPCOMING LIST
  Stream<List<Appointment>> getStudentAppointments(String studentId) {
    return _firestore
        .collection(collectionName)
        .where('student_id', isEqualTo: studentId)
        .where('status', whereIn: ['Pending', 'Confirmed'])
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Appointment.fromMap(doc.data(), doc.id))
            .toList());
  }

  //CANCEL
  Future<void> cancelAppointment(
      String appointmentId, String remark, String studentId) async {
    try {
      await _firestore.collection(collectionName).doc(appointmentId).update({
        'status': 'Cancelled',
        'remark': remark,
      });

      // NOTIF
      if (!_notifiedAppointments.contains(appointmentId)) {
        _notifiedAppointments.add(appointmentId);

        await _notif.createNotification(
          userId: studentId,
          type: 'appointment_cancelled',
          title: 'Appointment cancelled',
          message: 'Your appointment has been cancelled. Reason: $remark',
          referenceId: appointmentId,
        );

        await NotificationService.showNotification(
          'Appointment cancelled',
          'Your appointment has been cancelled. Reason: $remark',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// UPDATE APPOINMENT STAT AFTER BOOK
  Future<void> updateAppointmentStatus(
      String appointmentId, String status) async {
    try {
      await _firestore.collection(collectionName).doc(appointmentId).update({
        'status': status,
      });
    } catch (e) {
      print("Error updating appointment status: $e");
      rethrow;
    }
  }

  // RETRIVE DOCTOR NAME
  Future<String> getDoctorName(String doctorId) async {
    try {
      final doctorSnap =
          await _firestore.collection('doctor').doc(doctorId).get();

      if (!doctorSnap.exists) return "Unknown Doctor";

      final userId = doctorSnap.data()?['user_id'];

      final userSnap =
          await _firestore.collection('users').doc(userId).get();

      if (!userSnap.exists) return "Unknown Doctor";

      return userSnap.data()?['full_name'] ?? "Unknown Doctor";
    } catch (e) {
      return "Unknown Doctor";
    }
  }

  /// ISSUE DETECT
  Future<void> debugAppointment(String appointmentId) async {
    try {
      final doc =
          await _firestore.collection(collectionName).doc(appointmentId).get();
      final data = doc.data();
      final currentUid = FirebaseAuth.instance.currentUser?.uid;

      print("DEBUG Appointment [$appointmentId]: $data");
      print("DEBUG Current UID: $currentUid");
    } catch (e) {
      print("Error debugging appointment: $e");
    }
  }
}