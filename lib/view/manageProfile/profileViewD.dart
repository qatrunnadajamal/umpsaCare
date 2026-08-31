
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../controllers/userController.dart';
import '../../model/user.dart';
import '../manageMedicalInfo/medicalInfo.Page.dart';
import 'visitHistory.dart';
import '../manageAppointment/visitRecord.dart';

const Color primaryTeal = Color(0xFF00A2A5); 
const Color lightMint = Color(0xFFE0F2F1); 
const Color darkMint = Color(0xFF00796B); 
const Color textFieldBorderColor = Color(0xFFEEEEEE); 
const Color screenBackgroundColor = Color(0xFFF5F7FA); 

class ProfileViewD extends StatefulWidget {
  final String studentId;
  final String appointmentId;

  const ProfileViewD(
      {super.key, required this.studentId, required this.appointmentId});

  @override
  State<ProfileViewD> createState() => _ProfileViewDState();
}

class _ProfileViewDState extends State<ProfileViewD> {
  String? _doctorId;

  @override
  void initState() {
    super.initState();
    _fetchDoctor();
  }

  Future<void> _fetchDoctor() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final user = await UserController().getCurrentUser();
      if (mounted) {
        setState(() {
          _doctorId = user?.userId;
        });
      }
    }
  }

  //MATRIC
  // Fetch Matric No, Faculty, and Advisor together
Future<Map<String, String>> _getStudentDetailsSimple(String userId) async {
  try {
    final query = await FirebaseFirestore.instance
        .collection('students')
        .where('user_id', isEqualTo: userId)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      final data = query.docs.first;
      final matric = data['matric_no'] ?? 'N/A';
      final faculty = data['faculty'] ?? 'N/A';
      final advisor = data['advisor'] ?? 'N/A';

      // Calculate year of study from matric (e.g., CB22)
      String yearOfStudy = "N/A";
      if (matric.length >= 4) {
        int startYear = int.tryParse(matric.substring(2, 4)) ?? 0;
        int currentYear = DateTime.now().year;
        yearOfStudy = (currentYear - (2000 + startYear)).toString(); // e.g., 4
      }

      return {
        'faculty': faculty,
        'advisor': advisor,
        'year_of_study': yearOfStudy,
        'matric_no': matric,
      };
    }
  } catch (e) {
    print("Error fetching student details: $e");
  }

  return {
    'faculty': 'N/A',
    'advisor': 'N/A',
    'year_of_study': 'N/A',
    'matric_no': 'N/A', 
  };
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryTeal,
      appBar: AppBar(
        backgroundColor: primaryTeal,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Student Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),

      body: FutureBuilder<UserModel?>(
        future: UserController().getUserById(widget.studentId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
                decoration: const BoxDecoration(
                    color: screenBackgroundColor,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
                child: const Center(child: CircularProgressIndicator(color: primaryTeal)));
          }
          if (!snapshot.hasData) {
            return Container(
                decoration: const BoxDecoration(
                    color: screenBackgroundColor,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
                child: const Center(child: Text("Student not found")));
          }

          final student = snapshot.data!;
          final initial = student.fullName.isNotEmpty ? student.fullName[0].toUpperCase() : 'S';

          return Stack(
            alignment: Alignment.topCenter,
            children: [
            //CARD
              Container(
                margin: const EdgeInsets.only(top: 50), 
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(
                            top: 60, left: 24, right: 24, bottom: 24), 
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // NAME
                            Center(
                              child: Text(
                                student.fullName,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Center(
                            child: Text(
                              student.email,
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey[600]),
                            ),
                          ),
                          const SizedBox(height: 6),

                          FutureBuilder<Map<String, String>>(
                          future: _getStudentDetailsSimple(student.userId),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) return const SizedBox();
                            final data = snapshot.data!;
                            
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Faculty / Advisor / Year
                               Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: "Faculty: ", 
                                      style: TextStyle(fontSize: 14, color: const Color.fromARGB(255, 0, 0, 0), fontWeight: FontWeight.bold)
                                    ),
                                    TextSpan(
                                      text: data['faculty'], 
                                      style: TextStyle(fontSize: 14, color: Colors.grey[600])
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 2),

                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: "Academic Advisor: ", 
                                      style: TextStyle(fontSize: 14, color: const Color.fromARGB(255, 0, 0, 0), fontWeight: FontWeight.bold)
                                    ),
                                    TextSpan(
                                      text: data['advisor'], 
                                      style: TextStyle(fontSize: 14, color: Colors.grey[600])
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 2),

                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: "Year of Study: ", 
                                      style: TextStyle(fontSize: 14, color: const Color.fromARGB(255, 0, 0, 0), fontWeight: FontWeight.bold)
                                    ),
                                    TextSpan(
                                      text: data['year_of_study'], 
                                      style: TextStyle(fontSize: 14, color: Colors.grey[600])
                                    ),
                                  ],
                                ),
                              ),

                                const SizedBox(height: 10),
                                const Text('Matric ID',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey)),
                                    const SizedBox(height: 8),
                                _buildDataField(data['matric_no'] ?? 'N/A', isReadonly: true),
                              ],
                            );
                          },
                        ),
                            
                            const SizedBox(height: 20),

                            // APP TYPE
                            const Text('Appointment Type',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey)),
                            const SizedBox(height: 8),
                            _buildDataField("Health Screening", isReadonly: true),
                            
                            const SizedBox(height: 30),
                            const Divider(),
                            const SizedBox(height: 10),

                            // MEDIC INFO
                            _buildActionTile(
                              context,
                              title: 'Medical Information',
                              icon: Icons.medical_information,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MedicalInfoPage(
                                      studentId: widget.studentId,
                                      isDoctorView: true,
                                    ),
                                  ),
                                );
                              },
                            ),

                            _buildActionTile(
                              context,
                              title: 'Visit History',
                              icon: Icons.history,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        VisitHistory(studentId: widget.studentId),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Positioned(
                top: 10, 
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: lightMint,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5)),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: const TextStyle(
                          color: darkMint,
                          fontSize: 36,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),

      // NAV
      bottomNavigationBar: Container(
        color: Colors.white,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _doctorId == null
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VisitRecordScreen(
                              studentId: widget.studentId,
                              appointmentId: widget.appointmentId,
                              doctorId: _doctorId!,
                            ),
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryTeal,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Create Visit Record",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// WIDGET

Widget _buildDataField(String value, {bool isReadonly = false}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    width: double.infinity,
    decoration: BoxDecoration(
      color: isReadonly ? const Color(0xFFF9F9F9) : Colors.white,
      border: Border.all(color: textFieldBorderColor),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      value,
      style: const TextStyle(
        fontSize: 15,
        color: Colors.black87,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}

Widget _buildActionTile(BuildContext context,
    {required String title, required IconData icon, required VoidCallback onTap}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: textFieldBorderColor),
      boxShadow: [
        BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 5,
            offset: const Offset(0, 2))
      ],
    ),
    child: ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: primaryTeal.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: primaryTeal, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
    ),
  );
}