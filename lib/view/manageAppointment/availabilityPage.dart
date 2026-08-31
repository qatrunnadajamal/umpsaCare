

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:umpsa_care/controllers/availabilityController.dart';
import 'package:umpsa_care/view/manageAppointment/appointmentBookPage.dart'; 
import '../../controllers/appointmentController.dart';
import '../../controllers/notificationController.dart';
import '../../model/appointment.dart';

const Color primaryTeal = Color(0xFF00A2A5);
const Color bgGrey = Color(0xFFF5F7FA);
const Color textDark = Color(0xFF2D3436);

// CONFIRMATION
class ConfirmPopup extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;

  const ConfirmPopup({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
  });

//WIDGET
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryTeal.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.help_outline_rounded,
                  color: primaryTeal, size: 32),
            ),
            const SizedBox(height: 20),
            // TITTLE
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            const SizedBox(height: 12),
            // MESSAGE
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: bgGrey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                message,
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // BUTTON
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      foregroundColor: Colors.grey[600],
                    ),
                    child: Text(cancelText,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryTeal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(confirmText,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// CLASS CONFIRMATION
class AlertPopup extends StatelessWidget {
  final VoidCallback onOkPressed;
  final String title;
  final String message;
  final IconData icon;
  final Color iconColor;

  const AlertPopup({
    super.key,
    required this.onOkPressed,
    required this.title,
    required this.message,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ICON
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 40),
            ),
            const SizedBox(height: 20),
            // TITTLE
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            const SizedBox(height: 12),
            // Message
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            // OKEY
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onOkPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: iconColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('OK',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// AVAILBILITY 

class AvailabilityPage extends StatefulWidget {
  final String service;

  const AvailabilityPage({Key? key, required this.service}) : super(key: key);

  @override
  State<AvailabilityPage> createState() => _AvailabilityPageState();
}

class _AvailabilityPageState extends State<AvailabilityPage> {
  Map<DateTime, List<Map<String, dynamic>>> _availableSlots = {};
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  final AppointmentController _appointmentController = AppointmentController();
  final NotificationController _notificationController =
      NotificationController();

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchAvailability();
  }

  DateTime _getCleanDate(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  String _formatDateToKey(DateTime date) =>
      DateFormat('yyyy-MM-dd').format(date);

  // TIME FFORMAT
  String _formatTimeAMPM(String time24) {
    try {
      final parts = time24.split(':');
      final dt = DateTime(2022, 1, 1, int.parse(parts[0]), int.parse(parts[1]));
      return DateFormat('h:mm a').format(dt);
    } catch (e) {
      return time24; 
    }
  }

  Future<void> _fetchAvailability() async {
    final firestore = FirebaseFirestore.instance;

    try {
      final doctorsQuery = await firestore
          .collection('doctors')
          .where('services', arrayContains: widget.service)
          .get();

      if (doctorsQuery.docs.isEmpty) {
        setState(() => _availableSlots = {});
        return;
      }

      final Map<String, String> doctorIdToUserId = {};
      for (var doc in doctorsQuery.docs) {
        doctorIdToUserId[doc.id] = doc.data()['user_id'];
      }

      final availabilityQuery = await firestore
          .collection('doctor_availability')
          .where('doctor_id', whereIn: doctorIdToUserId.keys.toList())
          .where('av_status', isEqualTo: 'available')
          .get();

      final userDocs = await firestore
          .collection('users')
          .where('user_id', whereIn: doctorIdToUserId.values.toList())
          .get();

      final Map<String, String> userIdToName = {
        for (var doc in userDocs.docs)
          doc['user_id']: doc['full_name'] ?? 'Doctor'
      };

      final Map<DateTime, List<Map<String, dynamic>>> slots = {};
      for (var doc in availabilityQuery.docs) {
        final data = doc.data();
        final doctorId = data['doctor_id'];
        final userId = doctorIdToUserId[doctorId];
        final doctorName = userIdToName[userId] ?? 'Doctor';
        final doctorDoc = doctorsQuery.docs.firstWhere((d) => d.id == doctorId);
        final campus = doctorDoc.data()['campus'] ?? '';



        data['doctor_name'] = doctorName;
         data['campus'] = campus;
        data['availability_id'] = doc.id; 

        final date =
            _getCleanDate(DateFormat('yyyy-MM-dd').parse(data['av_date']));
        slots.putIfAbsent(date, () => []);
        slots[date]!.add(data);
      }

      setState(() => _availableSlots = slots);
    } catch (_) {
    }
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    final cleanDay = _getCleanDate(day);
    return _availableSlots[cleanDay] ?? [];
  }

  //CONFIRMATION
  Future<void> _confirmAppointment(Map<String, dynamic> slot) async {
    if (_selectedDay == null) return;

    final studentId = FirebaseAuth.instance.currentUser!.uid;
    final firestore = FirebaseFirestore.instance;

    final dateDisplay = DateFormat('EEE, d MMM').format(_selectedDay!);

    final rawTime = slot['av_timestamp'] as String;
    final timeDisplay = _formatTimeAMPM(rawTime);

    try {
     // DUPLICATE CHECK
    final startOfDay = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final dayAppointmentsQuery = await firestore
        .collection('appointments')
        .where('student_id', isEqualTo: studentId)
        .where('status', whereIn: ['Pending', 'Confirmed'])
        .get();

    final appointmentsToday = dayAppointmentsQuery.docs.where((doc) {
      final ts = doc['ap_timestamp']; 
      DateTime apTime;

    if (ts is Timestamp) {
      apTime = ts.toDate();
    } else if (ts is DateTime) {
      apTime = ts;
    } else {
      return false; 
    }

    return apTime.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
          apTime.isBefore(endOfDay);
  }).toList();

    if (appointmentsToday.length >= 2) {
      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertPopup(
          title: 'Cannot Book Appointment',
          message:
              'You already have 2 appointments on this day. Please choose another day.',
          icon: Icons.warning_amber_rounded,
          iconColor: Colors.orange,
          onOkPressed: () => Navigator.pop(context),
        ),
      );
      return;

}

      final timeParts = rawTime.split(':');
      final hour = int.tryParse(timeParts[0]) ?? 0;
      final minute = int.tryParse(timeParts[1]) ?? 0;

      final appointmentDateTime = DateTime(
        _selectedDay!.year,
        _selectedDay!.month,
        _selectedDay!.day,
        hour,
        minute,
      );

      if (!mounted) return;
      final confirm = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => ConfirmPopup(
          title: 'Confirm Booking',
          message:
              'Service: ${widget.service}\nDoctor: Dr. ${slot['doctor_name']}\nDate: $dateDisplay at $timeDisplay',
          confirmText: 'Set Appointment',
          cancelText: 'Cancel',
        ),
      );

      if (confirm != true) return;

      // CREATE APPOINT
      final appointment = Appointment(
        appointmentId: '', 
        studentId: studentId,
        doctorId: slot['doctor_id'],
        apTimestamp: appointmentDateTime,
        status: 'Pending',
        remark: widget.service,
      );

      // DB
      await _appointmentController.addAppointment(appointment);
      
      if (slot['availability_id'] != null) {
        await AvailabilityController()
            .toggleStatus(slot['availability_id'] as String, 'booked');
      }

      await _notificationController.createNotification(
        userId: studentId,
        type: 'appointment_booked',
        title: 'Appointment Booked',
        message:
            'Your appointment with DR. ${slot['doctor_name']} on $dateDisplay at $timeDisplay has been booked successfully.',
        referenceId: appointment.appointmentId,
      );

      //CONFRIMATION
      if (!mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertPopup(
          title: 'Booking Successful!',
          message:
              '${slot['doctor_name']} - ${widget.service}\n$dateDisplay at $timeDisplay',
          icon: Icons.check_circle_rounded,
          iconColor: primaryTeal,
          onOkPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const AppointmentBookPage()),
              (route) => false,
            );
          },
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to set appointment: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    return Scaffold(
      backgroundColor: bgGrey,
      appBar: AppBar(
        title: Text(
          widget.service,
          style: const TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryTeal,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- CALENDAR CARD ---
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
              ),
              
              child: TableCalendar(
                firstDay: DateTime.now(),
                lastDay: DateTime.now().add(const Duration(days: 365)),
                focusedDay: _focusedDay,
                daysOfWeekHeight: isTablet ? 44 : 32,
                calendarFormat: _calendarFormat,
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: primaryTeal.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: const TextStyle(color: primaryTeal, fontWeight: FontWeight.bold),
                  selectedDecoration: const BoxDecoration(
                    color: primaryTeal,
                    shape: BoxShape.circle,
                  ),
                ),
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onFormatChanged: (format) {
                  if (_calendarFormat != format) {
                    setState(() => _calendarFormat = format);
                  }
                },
                onPageChanged: (focusedDay) => _focusedDay = focusedDay,
                eventLoader: _getEventsForDay,
                
                //DOT IN CALENDAR
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, day, events) {
                    if (events.isNotEmpty) {
                      return Positioned(
                        bottom: 6, 
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: primaryTeal, 
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    }
                    return null;
                  },
                ),
              ),
            ),

            // HEADER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  const Icon(Icons.access_time_filled,
                      color: primaryTeal, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _selectedDay != null
                        ? 'Available Slots: ${DateFormat('d MMM y').format(_selectedDay!)}'
                        : 'Select a date',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textDark),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // SLOT LIST
            _buildSelectedDaySlotsList(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedDaySlotsList() {
    if (_selectedDay == null) {
      return const Center(child: Text("Select a day to view slots"));
    }

    final slots = _getEventsForDay(_selectedDay!);

    if (slots.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 40.0),
          child: Column(
            children: [
              Icon(Icons.event_busy, size: 50, color: Colors.grey[300]),
              const SizedBox(height: 10),
              Text("No slots available",
                  style: TextStyle(color: Colors.grey[500])),
            ],
          ),
        ),
      );
    }

    slots.sort((a, b) => (a['av_timestamp'] as String).compareTo(b['av_timestamp'] as String));

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: slots.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final slot = slots[index];
        final timestampDisplay = _formatTimeAMPM(slot['av_timestamp']);

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 5,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _confirmAppointment(slot),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    // Time Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: primaryTeal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        timestampDisplay, 
                        style: const TextStyle(
                          color: primaryTeal,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dr. ${slot['doctor_name']}(${slot['campus']})', 
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: textDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Available',
                            style: TextStyle(
                                color: primaryTeal,
                                fontSize: 12,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    // Action
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_forward_ios_rounded,
                          size: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}