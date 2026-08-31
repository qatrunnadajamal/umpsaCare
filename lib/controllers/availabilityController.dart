
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../model/availability.dart';
import 'notificationController.dart';

class AvailabilityController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collectionName = "doctor_availability";
  final NotificationController _notificationController = NotificationController();
  final Set<String> _notifiedSlots = {};
  static const Color primaryTeal = Color(0xFF00A2A5);
  static const Color bgGrey = Color(0xFFF5F7FA);


  Future<void> setAvailability(
    Availability availability, [
    BuildContext? context,
    bool isStaff = true, 
  ]) async {
    await _firestore
        .collection(collectionName)
        .doc(availability.availabilityId)
        .set(availability.toMap());

    // SINGLE SET
    if (!_notifiedSlots.contains(availability.availabilityId)) {
      _notifiedSlots.add(availability.availabilityId);

      final targetUserId =
          isStaff ? availability.doctorId : availability.availabilityId.split('_')[0];

      await _notificationController.createNotification(
        userId: targetUserId,
        type: 'slot_assigned',
        title: 'New Slot Assigned',
        message: isStaff
            ? 'A new slot has been set for ${availability.avDate} at ${availability.avTimestamp}.'
            : 'Slot have successfully on ${availability.avDate} at ${availability.avTimestamp}.',
        referenceId: availability.availabilityId,
        context: null,
      );
    }



    // DOCTOR NAME
    String doctorDisplayName = availability.doctorId; 
    try {
      final userDoc = await _firestore.collection('users').doc(availability.doctorId).get();
      if (userDoc.exists) {
        doctorDisplayName = userDoc.data()?['full_name'] ?? availability.doctorId;
      }
    } catch (e) {
      print("Error fetching doctor name for dialog: $e");
    }


    if (context != null && context.mounted) {
      _showSuccessDialog(
        context, 
        isStaff 
          ? 'You have successfully set the slot availability.' 
          : 'You have successfully set slot availability.',
        [
          _buildDetailRow('Doctor:', doctorDisplayName), 
          const SizedBox(height: 8),
          _buildDetailRow('Date:', availability.avDate),
          const SizedBox(height: 8),
          _buildDetailRow('Time:', availability.avTimestamp),
        ]
      );
    }
  }

 
  Future<void> setBulkAvailability({
    required String doctorId,
    required Set<DateTime> dates,
    required List<TimeOfDay> times,
    required int duration,
    BuildContext? context,
    bool isStaff = true,
  }) async {
    final List<Availability> slots = [];

    for (final date in dates) {
      final dateString = DateFormat('yyyy-MM-dd').format(date);
      for (final time in times) {
        final timestamp =
            "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";

        final availabilityId =
            "${doctorId}_${dateString}_${timestamp.replaceAll(':', '-')}";
            
        final slot = Availability(
          availabilityId: availabilityId,
          doctorId: doctorId,
          avDate: dateString,
          avTimestamp: timestamp,
          avDuration: duration,
          avStatus: 'available',
        );
        slots.add(slot);
      }
    }

    // SIZE SET
    final int batchSize = 400; 
    for (var i = 0; i < slots.length; i += batchSize) {
      final WriteBatch batch = _firestore.batch();
      final end = (i + batchSize < slots.length) ? i + batchSize : slots.length;
      final chunk = slots.sublist(i, end);

      for (final slot in chunk) {
        batch.set(
          _firestore.collection(collectionName).doc(slot.availabilityId), 
          slot.toMap()
        );
      }
      await batch.commit();
    }
    await _notificationController.createNotification(
      userId: doctorId,
      type: 'bulk_slots_assigned',
      title: 'Schedule Updated',
      message: 'Bulk availability updated: ${dates.length} days, ${times.length} slots per day added.',
      referenceId: 'bulk_${DateTime.now().millisecondsSinceEpoch}',
      context: null,
    );

    // SUCCSS
    if (context != null) {
      _showSuccessDialog(
        context, 
        'Bulk slots set successfully!',
        [
          _buildDetailRow('Doctor ID:', doctorId),
          const SizedBox(height: 8),
          _buildDetailRow('Dates:', '${dates.length} day(s)'),
          const SizedBox(height: 8),
          _buildDetailRow('Times/Day:', '${times.length} slot(s)'),
          const SizedBox(height: 8),
          _buildDetailRow('Total:', '${slots.length} slots created'),
        ]
      );
    }
  }

  /// BLOCK LOGIC
  Future<void> blockDay(String doctorId, String date, [BuildContext? context]) async {
    final availabilityId = "${doctorId}_${date}_blocked";
    final blockedSlot = Availability(
      availabilityId: availabilityId,
      doctorId: doctorId,
      avDate: date,
      avTimestamp: '00:00',
      avDuration: 0,
      avStatus: 'blocked',
    );

    await _firestore
        .collection(collectionName)
        .doc(availabilityId)
        .set(blockedSlot.toMap());

    if (!_notifiedSlots.contains(availabilityId)) {
      _notifiedSlots.add(availabilityId);
      await _notificationController.createNotification(
        userId: doctorId,
        type: 'day_blocked',
        title: 'Schedule Updated', 
        message: 'You have successfully blocked $date for appointments.',
        referenceId: availabilityId,
        context: null,
      );
    }
  }

 Stream<List<Availability>> getAvailabilities(String doctorId) {
  return _firestore
      .collection(collectionName)
      .where('doctor_id', isEqualTo: doctorId)
      .orderBy('av_date')
      .orderBy('av_timestamp')
      .snapshots()
      .asyncMap((snapshot) async {
        

        String doctorName = "Unknown Doctor";
        try {
  
          final userDoc = await _firestore.collection('users').doc(doctorId).get();
          if (userDoc.exists) {
            doctorName = userDoc.data()?['full_name'] ?? "Doctor";
          }
        } catch (e) {
          print("Error fetching doctor name: $e");
        }

        //MAP SLOT
        return snapshot.docs.map((doc) {
          final data = Map<String, dynamic>.from(doc.data() as Map);
          
          if (!data.containsKey('availability_id')) {
            data['availability_id'] = doc.id;
          }
          

          return Availability.fromMap(data);
        }).toList();
      });
}

  Future<void> toggleStatus(String availabilityId, String newStatus) async {
    await _firestore
        .collection(collectionName)
        .doc(availabilityId)
        .update({'av_status': newStatus});
  }

  Future<void> deleteAvailability(String availabilityId) async {
    await _firestore.collection(collectionName).doc(availabilityId).delete();
  }

  // CONFRIMATION
  Future<void> _showSuccessDialog(BuildContext context, String message, List<Widget> details) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, size: 40, color: Colors.green),
              ),
              const SizedBox(height: 20),
              const Text('Success', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: bgGrey, borderRadius: BorderRadius.circular(12)),
                child: Column(children: details),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryTeal,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('OK', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey))),
        Expanded(
            child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87))),
      ],
    );
  }
}

// ignore_for_file: unused_local_variable