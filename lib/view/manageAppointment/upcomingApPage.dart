

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../controllers/appointmentController.dart';
import '../../model/appointment.dart';
import 'cancelForm.dart';

const Color primaryTeal = Color(0xFF00A2A5);
const Color bgGrey = Color(0xFFF5F7FA);
const Color textDark = Color(0xFF2D3436);

//MAP CAMPUS
String getClinicNameByFaculty(String faculty) {
  const pekanFaculties = ['FTKEE', 'FTKMA', 'FTKPM', 'FK'];
  const gambangFaculties = ['FTKA', 'FTKKP', 'FSTI', 'FIM'];

  if (pekanFaculties.contains(faculty)) {
    return 'UMPSA Health Centre,Pekan';
  } else if (gambangFaculties.contains(faculty)) {
    return 'UMPSA Health Centre,Gambang';
  } else {
    return 'UMPSA Health Centre';
  }
}


class UpcomingAppointmentsPage extends StatelessWidget {
  const UpcomingAppointmentsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final studentId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final controller = AppointmentController();

    return Scaffold(
      backgroundColor: bgGrey,
      appBar: AppBar(
        backgroundColor: const Color(0xFF20B2AA),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Upcoming Appointments',
          style: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),

      // FEATCH STUD
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('students')
            .doc(studentId)
            .get(),
        builder: (context, studentSnapshot) {
          if (studentSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: primaryTeal));
          }

          if (!studentSnapshot.hasData || !studentSnapshot.data!.exists) {
            return _emptyState();
          }

          final studentData =
              studentSnapshot.data!.data() as Map<String, dynamic>;
          final faculty = studentData['faculty'] ?? '';
          final clinicName = getClinicNameByFaculty(faculty);

          //APP DATA
          return StreamBuilder<List<Appointment>>(
            stream: controller.getStudentAppointments(studentId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: primaryTeal));
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _emptyState();
              }

              final upcomingAppointments = snapshot.data!
                  .where((appt) => appt.apTimestamp
                      .isAfter(DateTime.now().subtract(const Duration(hours: 1))))
                  .toList()
                ..sort((a, b) => a.apTimestamp.compareTo(b.apTimestamp));

              if (upcomingAppointments.isEmpty) {
                return _emptyState();
              }

              return ListView.separated(
                padding: const EdgeInsets.all(20.0),
                itemCount: upcomingAppointments.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final appt = upcomingAppointments[index];
                  return AppointmentCard(
                    appointment: appt,
                    clinicName: clinicName,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }


  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: primaryTeal.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.event_available, size: 50, color: primaryTeal),
          ),
          const SizedBox(height: 16),
          const Text(
            'No upcoming appointments',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

//APP CARD
class AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final String clinicName;

  const AppointmentCard({
    Key? key,
    required this.appointment,
    required this.clinicName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final date = appointment.apTimestamp;
    final dateString = "${date.day} ${_monthName(date.month)} ${date.year}";
    final timeString =
        "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} ${date.hour < 12 ? 'AM' : 'PM'}";

    final status = appointment.status;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection("users")
          .doc(appointment.doctorId)
          .get(),
      builder: (context, snapshot) {
        String doctorName = "Loading...";

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          doctorName = data['full_name'] ?? "Doctor (Unknown)";
        }

        return _buildCard(context, doctorName, dateString, timeString, status);
      },
    );
  }

  //WIDGET
  
  Widget _buildCard(BuildContext context, String doctorName, String date,
      String time, String status) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: primaryTeal.withOpacity(0.08),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: primaryTeal),
                      const SizedBox(width: 6),
                      Text(clinicName,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: primaryTeal)),
                    ],
                  ),
                  _buildStatusChip(status),
                ],
              ),
            ),

            const SizedBox(height: 16),
            // Doctor & Service
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.person, size: 24, color: Colors.grey),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctorName,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textDark),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(appointment.remark,
                          style: TextStyle(
                              fontSize: 14, color: Colors.grey[600])),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Date & Time
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                      Icons.calendar_today_outlined, "Date", date),
                ),
                Container(height: 30, width: 1, color: Colors.grey[300]),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: _buildInfoItem(Icons.access_time, "Time", time),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _showAppointmentDetails(
                          context, appointment, doctorName, clinicName, date, time, status);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryTeal,
                      side: const BorderSide(color: primaryTeal),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('View Details'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CancelForm(
                              appointmentId: appointment.appointmentId,
                              studentId: appointment.studentId),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            Text(value,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600, color: textDark)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    Color textColor;

    switch (status) {
      case 'Confirmed':
        color = Colors.green.withOpacity(0.1);
        textColor = Colors.green;
        break;
      case 'Pending':
        color = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange[800]!;
        break;
      case 'Cancelled':
        color = Colors.red.withOpacity(0.1);
        textColor = Colors.red;
        break;
      default:
        color = Colors.grey.withOpacity(0.1);
        textColor = Colors.grey[700]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
            color: textColor, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month];
  }

  void _showAppointmentDetails(
      BuildContext context,
      Appointment appointment,
      String doctorName,
      String clinicName,
      String date,
      String time,
      String status) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: primaryTeal.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.assignment_outlined,
                          color: primaryTeal, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Text('Appointment Details',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87)),
                  ],
                ),
                const SizedBox(height: 24),
                _buildDialogDetailRow(Icons.person_outline, "Doctor", doctorName),
                _buildDialogDetailRow(Icons.medical_services_outlined,
                    "Service", appointment.remark),
                _buildDialogDetailRow(Icons.location_on_outlined, "Location",
                    clinicName),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: Color(0xFFEEEEEE)),
                ),
                _buildDialogDetailRow(Icons.calendar_today_outlined, "Date", date),
                _buildDialogDetailRow(Icons.access_time, "Time", time),
                _buildDialogDetailRow(Icons.info_outline, "Status", status,
                    isStatus: true),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryTeal,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Close',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDialogDetailRow(IconData icon, String label, String value,
      {bool isStatus = false}) {
    Color textColor = Colors.black87;
    FontWeight fontWeight = FontWeight.w500;

    if (isStatus) {
      if (value.toLowerCase() == 'confirmed' ||
          value.toLowerCase() == 'completed') {
        textColor = Colors.green[700]!;
        fontWeight = FontWeight.bold;
      } else if (value.toLowerCase() == 'cancelled') {
        textColor = Colors.red[700]!;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[400]),
          const SizedBox(width: 12),
          SizedBox(
            width: 70,
            child: Text(label,
                style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w400)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(fontSize: 15, color: textColor, fontWeight: fontWeight)),
          ),
        ],
      ),
    );
  }
}
