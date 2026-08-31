
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../manageProfile/profilePage.dart';
import '../../controllers/userController.dart';
import '../../controllers/notificationController.dart';
import 'selectDoctor.dart';

class AppointmentBookPageS extends StatefulWidget {
  const AppointmentBookPageS({super.key});

  @override
  State<AppointmentBookPageS> createState() => _AppointmentBookPageSState();
}

class _AppointmentBookPageSState extends State<AppointmentBookPageS> {
  Map<String, String?> _profile = {'name': 'Loading...', 'photoUrl': null};
  String? staffId;
  int _selectedIndex = 0;
  final NotificationController _notificationController = NotificationController();

  // Design Constants
  static const Color primaryTeal = Color(0xFF00A2A5);
  static const Color bgGrey = Color(0xFFF5F7FA);
  static const Color textDark = Color(0xFF2D3436);

  @override
  void initState() {
    super.initState();
    _fetchStaffProfile();
  }

  Future<void> _fetchStaffProfile() async {
    try {
      final currentUser = await UserController().getCurrentUser();
      if (currentUser == null) {
        if (mounted) {
          setState(() => _profile = {'name': 'Guest', 'photoUrl': null});
        }
        return;
      }
      if (mounted) {
        setState(() {
          staffId = currentUser.userId;
          _profile = {
            'name': currentUser.fullName,
            'photoUrl': (currentUser.photoUrl != null &&
                    currentUser.photoUrl!.isNotEmpty)
                ? currentUser.photoUrl
                : null,
          };
        });
      }
    } catch (e) {
      debugPrint(" Error fetching staff profile: $e");
    }
  }

  Future<void> _goToProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfilePage()),
    );
    _fetchStaffProfile();
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    if (index == 0) {

    } else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfilePage()),
      ).then((_) {
        // Reset selection when returning
        setState(() => _selectedIndex = 0);
      });
    }
  }

  // NOTIFICATION FOR STAFF ACTION
  Future<void> _sendSlotNotification({
    required String studentId,
    required String date,
    required String time,
  }) async {
    if (staffId == null) return;
    final referenceId = '${studentId}_$date\_$time';

    try {
      // DOC
      await _notificationController.createNotification(
        userId: studentId,
        type: "slot_assigned",
        title: "New Slot Assigned",
        message:
            "A staff has assigned a new appointment slot for you on $date at $time.",
        referenceId: referenceId,
      );

      // STAFF
      await _notificationController.createNotification(
        userId: staffId!,
        type: "slot_assigned",
        title: "Slot Created",
        message:
            "You successfully assigned a new appointment slot on $date at $time.",
        referenceId: referenceId,
      );
    } catch (e) {
      debugPrint("Error sending notifications: $e");
    }
  }

  //WIDGET

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGrey,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Row(
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
                        radius: 24,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: _profile['photoUrl'] != null
                            ? CachedNetworkImageProvider(
                                "${_profile['photoUrl']}?v=${DateTime.now().millisecondsSinceEpoch}")
                            : const AssetImage(
                                    'assets/images/profile_placeholder.jpg')
                                as ImageProvider,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Welcome Back,",
                            style: TextStyle(fontSize: 13, color: Colors.grey)),
                        Text(
                          _profile['name'] ?? 'Unknown Staff',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: textDark),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

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

              // CARD
              _buildOptionCard(
                title: "Manage Doctors' Schedules",
                icon: Icons.medical_services_outlined,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SelectDoctorPage()),
                  );
                },
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),

      // NAV
     bottomNavigationBar: SafeArea(
      top: false, // no padding at top, only bottom
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
            _buildNavItem(
              icon: _selectedIndex == 0 ? Icons.home_rounded : Icons.home_outlined, 
              index: 0
            ),
            _buildNavItem(
              icon: _selectedIndex == 1 ? Icons.person_rounded : Icons.person_outline_rounded, 
              index: 1
            ),
          ],
        ),
      ),
    ),

    );
  }

  Widget _buildOptionCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryTeal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: primaryTeal, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required int index}) {
    final bool isSelected = index == _selectedIndex;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? primaryTeal : Colors.transparent, 
          borderRadius: BorderRadius.circular(14), 
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : const Color.fromARGB(255, 0, 0, 0), 
          size: 28, 
        ),
      ),
    );
  }
}