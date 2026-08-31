import 'package:flutter/material.dart';
import '../../controllers/appointmentController.dart';
import '../../controllers/userController.dart';
import '../../model/appointment.dart';
import '../manageProfile/profileViewD.dart';

class PendingAppointmentD extends StatelessWidget {
  final String doctorId;
  final bool onlyToday;

  const PendingAppointmentD({
    super.key,
    required this.doctorId,
    this.onlyToday = false,
  });

  static const Color primaryTeal = Color(0xFF00A2A5);
  static const Color bgGrey = Color(0xFFF5F7FA);
  static const Color textDark = Color(0xFF2D3436);

  @override
  Widget build(BuildContext context) {
    Stream<List<Appointment>> appointmentStream;
      final today = DateTime.now();

    if (onlyToday) {
      appointmentStream = AppointmentController()
          .getDoctorPendingAppointments(doctorId)
          .map((appointments) => appointments.where((appt) {
                final apptDate = appt.apTimestamp.toLocal();
                return apptDate.year == today.year &&
                       apptDate.month == today.month &&
                       apptDate.day == today.day;
              }).toList());
    } else {
       appointmentStream = AppointmentController()
      .getDoctorPendingAppointments(doctorId)
      .map((appointments) => appointments.where((appt) {
            final apptDate = appt.apTimestamp.toLocal();
            final apptClean = DateTime(apptDate.year, apptDate.month, apptDate.day);
            return !apptClean.isBefore(today); 
          }).toList());
    }

    return Scaffold(
      backgroundColor: bgGrey,
      appBar: AppBar(
        toolbarHeight: 60,
        backgroundColor: primaryTeal,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          onlyToday ? 'Today\'s Appointments' : 'Pending Appointments',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: StreamBuilder<List<Appointment>>(
        stream: appointmentStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: primaryTeal),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 50, color: Colors.grey[300]),
                  const SizedBox(height: 10),
                  Text(
                    "No pending appointments",
                    style: TextStyle(color: Colors.grey[500], fontSize: 16),
                  ),
                ],
              ),
            );
          }

          final appointments = snapshot.data!;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: appointments.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final appt = appointments[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfileViewD(
                        studentId: appt.studentId,
                        appointmentId: appt.appointmentId,
                      ),
                    ),
                  );
                },
                child: AppointmentCard(appointment: appt),
              );
            },
          );
        },
      ),
    );
  }
}

class AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  const AppointmentCard({super.key, required this.appointment});

  static const Color primaryTeal = Color(0xFF00A2A5);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: UserController().getUserById(appointment.studentId),
      builder: (context, snapshot) {
        String displayName = appointment.studentId;
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData &&
            snapshot.data != null) {
          displayName = snapshot.data!.fullName;
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: primaryTeal.withOpacity(0.3), width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: primaryTeal.withOpacity(0.1),
                    child: Text(
                      displayName.isNotEmpty
                          ? displayName[0].toUpperCase()
                          : 'S',
                      style: const TextStyle(
                        color: primaryTeal,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.access_time_filled, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              "Date: ${appointment.apTimestamp.toLocal()}".split('.')[0],
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          appointment.status.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        );
      },
    );
  }
}
