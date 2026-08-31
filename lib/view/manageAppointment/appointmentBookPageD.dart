import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../manageProfile/profilePage.dart';
import '../../controllers/userController.dart';
import '../../controllers/appointmentController.dart';
import '../../model/user.dart';
import '../../model/appointment.dart';
import 'pendingAppoinmentD.dart';
import 'slotDocView.dart';
import 'notification.dart';

class AppointmentBookPageD extends StatefulWidget {
  const AppointmentBookPageD({super.key});

  @override
  State<AppointmentBookPageD> createState() => _AppointmentBookPageDState();
}

class _AppointmentBookPageDState extends State<AppointmentBookPageD> {
  Map<String, String?> _profile = {'name': 'Loading...', 'photoUrl': null};
  String? doctorId;
  int _selectedIndex = 0; // 0 = Home

  bool _isDoctor = false;
  bool _loading = true;

  // INITILIZE COLOR
  static const Color primaryTeal = Color(0xFF00A2A5);
  static const Color bgGrey = Color(0xFFF5F7FA);
  static const Color textDark = Color(0xFF2D3436);

  @override
  void initState() {
    super.initState();
    _checkDoctorAccess();
  }

  Future<void> _checkDoctorAccess() async {
    try {
      final UserModel? userModel = await UserController().getCurrentUser();
      if (userModel == null || userModel.userType != 'Doctor') {
        _showAccessDenied();
        return;
      }

      if (mounted) {
        setState(() {
          doctorId = userModel.userId;
          _profile = {
            'name': userModel.fullName,
            'photoUrl': (userModel.photoUrl != null &&
                    userModel.photoUrl!.isNotEmpty)
                ? userModel.photoUrl
                : null,
          };
          _isDoctor = true;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching user role: $e");
      _showAccessDenied();
    }
  }

  void _showAccessDenied() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Icon(Icons.error, color: Colors.red, size: 50),
        content: const Text(
          "Access Denied!\nOnly doctors can access this page.",
          textAlign: TextAlign.center,
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> _goToProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfilePage()),
    );
    _fetchDoctorProfile();
  }

  Future<void> _fetchDoctorProfile() async {
    try {
      final UserModel? userModel = await UserController().getCurrentUser();
      if (userModel == null) {
        if (mounted) {
          setState(() => _profile = {'name': 'Guest', 'photoUrl': null});
        }
        return;
      }
      if (mounted) {
        setState(() {
          doctorId = userModel.userId;
          _profile = {
            'name': userModel.fullName,
            'photoUrl': (userModel.photoUrl != null &&
                    userModel.photoUrl!.isNotEmpty)
                ? userModel.photoUrl
                : null,
          };
        });
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
    }
  }

  // NAV
  void _openTodaysAppointments() {
    if (doctorId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PendingAppointmentD(
            doctorId: doctorId!,
            onlyToday: true,
          ),
        ),
      );
    }
  }

  void _openAllPendingAppointments() {
    if (doctorId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PendingAppointmentD(
            doctorId: doctorId!,
            onlyToday: false,
          ),
        ),
      );
    }
  }

  void _openSchedule() {
    if (doctorId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const SlotDocView(),
        ),
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);

    if (index == 0) {
      // Already on Home/Dashboard
    } else if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ProfilePage()),
      );
    }
  }

  // WIDGET
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: primaryTeal)),
      );
    }

    if (!_isDoctor) return const SizedBox();

    return Scaffold(
      backgroundColor: bgGrey,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 30),
              const Text(
                "Dashboard Overview",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 16),
              // PENDING CARD
              GestureDetector(
                onTap: _openTodaysAppointments,
                child: StreamBuilder<List<Appointment>>(
                  stream: doctorId == null
                      ? null
                      : AppointmentController()
                          .getDoctorPendingAppointments(doctorId!),
                  builder: (context, snapshot) {
                    int count = 0;
                    if (snapshot.hasData) {
                      final today = DateTime.now();
                      count = snapshot.data!
                          .where((appt) =>
                              appt.apTimestamp.year == today.year &&
                              appt.apTimestamp.month == today.month &&
                              appt.apTimestamp.day == today.day)
                          .length;
                    }
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [primaryTeal, Color(0xFF00838F)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: primaryTeal.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Today's Appointments",
                                  style: TextStyle(
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14)),
                              const SizedBox(height: 8),
                              Text(
                                snapshot.connectionState ==
                                        ConnectionState.waiting
                                    ? "..."
                                    : count.toString(),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 36),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.assignment_ind_outlined,
                                color: Colors.white, size: 32),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              //CARD QA
              const Text(
                "Quick Actions",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      title: "Manage Schedule",
                      icon: Icons.calendar_today_rounded,
                      color: Colors.orange.shade50,
                      iconColor: Colors.orange,
                      onTap: _openSchedule,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildActionCard(
                      title: "View Appointments",
                      icon: Icons.list_alt_rounded,
                      color: const Color(0xFFE0F2F1),
                      iconColor: primaryTeal,
                      onTap: _openAllPendingAppointments,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
     bottomNavigationBar: SafeArea(
      top: false, 
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -5))
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home_filled, 0),
            _buildNavItem(Icons.person_outline_rounded, 3),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final bool isSelected = index == _selectedIndex;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? primaryTeal : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.black,
          size: 26,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: _goToProfile,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: primaryTeal, width: 2),
            ),
            child: CircleAvatar(
              radius: 26,
              backgroundColor: Colors.grey[200],
              backgroundImage: _profile['photoUrl'] != null
                  ? CachedNetworkImageProvider(
                      "${_profile['photoUrl']}?v=${DateTime.now().millisecondsSinceEpoch}")
                  : const AssetImage('assets/images/profile_placeholder.jpg')
                      as ImageProvider,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Welcome Back,",
                  style: TextStyle(fontSize: 13, color: Colors.grey)),
              Text(
                _profile['name'] ?? 'Doctor',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: textDark),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        _buildNotificationIcon(),
      ],
    );
  }

  Widget _buildNotificationIcon() {
    return StreamBuilder<QuerySnapshot>(
      stream: doctorId == null
          ? null
          : FirebaseFirestore.instance
              .collection('notifications')
              .where('user_id', isEqualTo: doctorId)
              .where('read', isEqualTo: false)
              .snapshots(),
      builder: (context, snapshot) {
        int unreadCount = 0;
        if (snapshot.hasData) unreadCount = snapshot.data!.docs.length;

        return Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, size: 28),
              onPressed: () {
                if (doctorId != null) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => NotificationPage(userId: doctorId!),
                    ),
                  );
                }
              },
            ),
            if (unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$unreadCount',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 110,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: iconColor, size: 28),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
