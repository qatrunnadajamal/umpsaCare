
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'personalDetailsForm.dart';
import '../../controllers/userController.dart';
import '../../model/user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../login/loginPage.dart';
import 'visitHistory.dart';
import '../manageAppointment/appointmentBookPage.dart'; 
import '../manageAppointment/appointmentBookPageD.dart'; 
import '../manageAppointment/appointmentBookPageS.dart'; 

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final UserController _userController = UserController();
  bool _isLoading = true;
  UserModel? _user;

  static const Color primaryTeal = Color(0xFF20B2AA);

  final Map<String, String> _facultyFullNames = {
  'FTKEE': 'Faculty of Electrical & Electronics Engineering Technology',
  'FTKMA': 'Faculty of Mechanical & Automotive Engineering Technology',
  'FTKPM': 'Faculty of Manufacturing & Mechatronic Engineering Technology',
  'FTKA': 'Faculty of Civil Engineering Technology',
  'FTKKP': 'Faculty of Chemical & Process Engineering Technology',
  'FK': 'Faculty of Computing',
  'FSTI': 'Faculty of Industrial Sciences & Technology',
  'FIM': 'Faculty of Industrial Management',
};


  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await _userController.getCurrentUser();
    if (mounted) {
      setState(() {
        _user = user;
        _isLoading = false;
      });
    }
  }

  void _goBackByRole() async {
    final user = await _userController.getCurrentUser();
    if (!mounted) return;

    if (user?.userType == "Student") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AppointmentBookPage()),
      );
    } else if (user?.userType == "Doctor") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AppointmentBookPageD()),
      );
    } else if (user?.userType == "PKU Staff") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AppointmentBookPageS()),
      );
    }
  }

  Future<void> _handleLogout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logout failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF00A2A5),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Color.fromARGB(221, 255, 255, 255), size: 20),
          onPressed: _goBackByRole,
        ),
        title: const Text(
          'My Profile',
          style: TextStyle(
              color: Color.fromARGB(221, 255, 255, 255),
              fontSize: 18,
              fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryTeal))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 24),
                  _buildMenuSection(),
                ],
              ),
            ),
            bottomNavigationBar: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24.0, top: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: _handleLogout,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.black,
                      ),
                      child: const Text(
                        "Log Out",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

  // HEADER
  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: primaryTeal.withOpacity(0.5), width: 2),
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey[200],
              backgroundImage: _user?.photoUrl != null &&
                      _user!.photoUrl!.isNotEmpty
                  ? NetworkImage(_user!.photoUrl!)
                  : const AssetImage('assets/images/profile_placeholder.jpg')
                      as ImageProvider,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _user?.fullName ?? "User",
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: primaryTeal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _user?.userType ?? 'Guest',
              style: const TextStyle(
                color: Color(0xFF003B46),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          
          // FOR STUD
          if (_user?.userType == "Student") ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: FirebaseFirestore.instance
                  .collection('students')
                  .doc(_user!.userId)
                  .get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2));
                }
                final studentData = snapshot.data!.data();
                final matricNo = studentData?['matric_no'] ?? '-';
                final advisorName = studentData?['advisor'] ?? 'Not Assigned';

                // --- LOGIC: Calculate Current Year ---
                String calculatedYear = "Year 1"; // Default
                if (matricNo.length >= 4) {
                  try {
                    // Extract "22" from "CB22..."
                    String yearDigits = matricNo.substring(2, 4);
                    int startYear = 2000 + int.parse(yearDigits); // e.g., 2022
                    int currentYear = DateTime.now().year; // e.g., 2025
                    
                    // Formula: Year Now - Start Year
                    int studyYear = currentYear - startYear;
                    
                    // If calculation is 0 (e.g. joined 2025, now 2025), show Year 1
                    if (studyYear < 1) studyYear = 1;
                    
                    calculatedYear = "Year $studyYear";
                  } catch (e) {
                    calculatedYear = "Year -";
                  }
                }

               String facultyCode = studentData?['faculty'] ?? '';
               String facultyName = _facultyFullNames[facultyCode] ?? 'No Academic Name';
                return Column(
                  children: [
                     _buildInfoRow(Icons.school_outlined, facultyName),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.badge_outlined,
                        "Matric ID: $matricNo"),
                    const SizedBox(height: 8),
                  _buildInfoRow(Icons.calendar_today_outlined, "Current Year of Study: $calculatedYear"),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.person_search_outlined,
                        "Academic Advisor: $advisorName"),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: const Color.fromARGB(255, 0, 0, 0)),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Color.fromARGB(255, 0, 0, 0),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // WIDGET
  Widget _buildMenuSection() {
    return Column(
      children: [
        _buildMenuTile(
          title: 'User Account',
          subtitle: 'View and edit your details',
          icon: Icons.person_outline,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const PersonalDetailsForm(isEditable: false),
              ),
            );
          },
          trailingWidget: TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const PersonalDetailsForm(isEditable: true),
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF003B46),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              backgroundColor: primaryTeal.withOpacity(0.05),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.edit, size: 16),
            label: const Text("Edit",
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 12),
        FutureBuilder<UserModel?>(
          future: _userController.getCurrentUser(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox();
            final user = snapshot.data!;
            if (user.userType != "Student") return const SizedBox();

            return _buildMenuTile(
              title: 'Visit History',
              subtitle: 'Check your past appointments',
              icon: Icons.history,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VisitHistory(studentId: user.userId),
                  ),
                );
              },
              trailingWidget:
                  const Icon(Icons.chevron_right, color: Colors.grey),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMenuTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    Widget? trailingWidget,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
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
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryTeal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: const Color(0xFF003B46), size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailingWidget != null) trailingWidget,
              ],
            ),
          ),
        ),
      ),
    );
  }
}