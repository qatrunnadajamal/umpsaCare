
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:umpsa_care/view/manageAppointment/slotPage.dart';

class SelectDoctorPage extends StatefulWidget {
  const SelectDoctorPage({super.key});

  @override
  State<SelectDoctorPage> createState() => _SelectDoctorPageState();
}

class _SelectDoctorPageState extends State<SelectDoctorPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const Color primaryTeal = Color(0xFF00A2A5);
  static const Color bgGrey = Color(0xFFF5F7FA);
  static const Color textDark = Color(0xFF2D3436);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGrey,
      appBar: AppBar(
        title: const Text(
          'Select Doctor',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(221, 255, 255, 255),
            fontSize: 18,
          ),
        ),
        backgroundColor: Color(0xFF00A2A5),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color.fromARGB(221, 255, 255, 255)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('doctors').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: primaryTeal));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final doctors = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: doctors.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final doctor = doctors[index];
              final doctorData = doctor.data() as Map<String, dynamic>;

              final String grade = doctorData['grade'] ?? '';
              final String specialization = doctorData['specialization'] ?? '';
              final String userId = doctorData['user_id'] ?? '';

              // RETRIVE DOC NAME
              return FutureBuilder<DocumentSnapshot>(
                future: _firestore.collection('users').doc(userId).get(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox();
                  }

                  if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                    return const SizedBox();
                  }

                  final userData =
                      userSnapshot.data!.data() as Map<String, dynamic>;
                  final String fullName = userData['full_name'] ?? 'Unknown';
                  final String campus = doctorData['campus'] ?? '';

                  return _buildDoctorCard(
                    fullName: fullName,
                    grade: grade,
                    specialization: specialization,
                    campus: campus,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SlotPage(
                            doctorId: doctor.id,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off_outlined, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            "No doctors available.",
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorCard({
    required String fullName,
    required String grade,
    required String specialization,
     required String campus,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: primaryTeal.withOpacity(0.5)),
                  ),
                  child: const CircleAvatar(
                    radius: 28,
                    backgroundColor: Color(0xFFE0F2F1),
                    // Use a safe asset or icon fallback
                    backgroundImage: AssetImage('assets/images/doctor.png'),
                    child: Icon(Icons.person, color: Color.fromARGB(255, 13, 96, 97), size: 30),
                  ),
                ),
                const SizedBox(width: 16),
                
                // INFO
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        specialization.isNotEmpty
                            ? specialization
                            : 'General Practitioner',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                       Text(
                        campus.isNotEmpty ? "Campus: $campus" : "",
                        style: TextStyle(
                          color: const Color.fromARGB(255, 0, 0, 0),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (grade.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: primaryTeal.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            "Grade: $grade",
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color.fromARGB(255, 0, 93, 94),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}