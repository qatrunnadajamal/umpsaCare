// home student

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:umpsa_care/view/manageAppointment/pkuevent.dart';
import 'package:umpsa_care/view/manageAppointment/pkuorganization.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import '../../controllers/userController.dart';
import '../../model/user.dart';
import '../manageProfile/profilePage.dart';
import '../manageMedicalInfo/medicalInfo.Page.dart';
import 'upcomingApPage.dart';
import '../manageAppointment/listServices.dart';
import 'notification.dart';
import 'availabilityPage.dart';
import 'pkuInfoPage.dart';


class AppointmentBookPage extends StatefulWidget {
  const AppointmentBookPage({super.key});

  @override
  State<AppointmentBookPage> createState() => _AppointmentBookPageState();
}

class _AppointmentBookPageState extends State<AppointmentBookPage> {
  int _selectedIndex = 0;

  static const Color primaryTeal = Color(0xFF00A2A5);
  static const Color bgGrey = Color(0xFFF5F7FA);

  // PKU INFO
  late Timer _timer;
  int _currentUpdateIndex = 0;

  final List<PkuContent> _pkuUpdates = [
    PkuContent(
      title: 'Pusat Kesihatan Universiti UMPSA',
      description:
          'University Health Centre is the official hub for outpatient care, pharmacy facilities, and campus wellness support.',
      destinationPage: const PkuInfoPage(),
    ),
    PkuContent(
      title: 'Upcoming Health Events!',
      description:
          'Blood donation drives, campaigns, and wellness activities. Click to view schedule.',
      imageAsset: 'assets/images/blood.jpg',
      destinationPage: const PkuEventPage(),
    ),
    PkuContent(
      title: 'Meet Our Dedicated Team',
      description:
          'Get to know the professional healthcare team ensuring high-quality services.',
      imageAsset: 'assets/images/organization.jpg',
      destinationPage: const PkuOrganizationPage(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startAutoShuffle();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _startAutoShuffle() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          _currentUpdateIndex =
              (_currentUpdateIndex + 1) % _pkuUpdates.length;
        });
      }
    });
  }

  Future<UserModel?> _getCurrentUser() async {
    return await UserController().getCurrentUser();
  }
  //SOS 
  Future<void> _callEmergency(BuildContext context) async {
    final Uri launchUri = Uri(scheme: 'tel', path: '09-549 3333');
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cannot open phone dialer.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  //NAV 
  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const BookAppointmentPage()));
        break;
      case 2:
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const MedicalInfoPage()));
        break;
      case 3:
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const ProfilePage()));
        break;
    }
  }

  //NOTIFICATION 
  Stream<int> _unreadNotificationCount() {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userId.isEmpty) return Stream.value(0);

    return FirebaseFirestore.instance
        .collection('notifications')
        .where('user_id', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  @override
  Widget build(BuildContext context) {
    final currentPkuContent = _pkuUpdates[_currentUpdateIndex];

    // LIST SERVICES 
    final List<Map<String, dynamic>> services = [
      {'name': 'Health Screening', 'icon': Icons.monitor_heart_outlined},
      {'name': 'Consultations', 'icon': Icons.chat_bubble_outline},
      {'name': 'Dental', 'icon': Icons.medical_services_outlined},
      {'name': 'Health Talk', 'icon': Icons.campaign_outlined},
      {'name': 'Medical Checkup', 'icon': Icons.assignment_outlined},
      {'name': 'Physiotherapy', 'icon': Icons.accessibility_new_outlined},
    ];

    //CARD FOR BK-A AND UP-A
    return Scaffold(
      backgroundColor: bgGrey,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileHeader(),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _homeCard(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE0F2F1), Color.fromARGB(255, 1, 165, 151)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      iconColor: const Color.fromARGB(255, 0, 82, 100),
                      icon: Icons.calendar_today,
                      title: 'Book\nAppointment', 
                      onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BookAppointmentPage(showBottomNav: false),
                        ),
                      );
                    },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _homeCard(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFF3E0), Color(0xFFFFCC80)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      iconColor: const Color.fromARGB(255, 242, 67, 9),
                      icon: Icons.event_available,
                      title: 'Upcoming\nAppointments', // Added \n for cleaner break
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const UpcomingAppointmentsPage()),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // SERVICES
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Our Services',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: Colors.black87),
                  ),
                  GestureDetector(
                    onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BookAppointmentPage(showBottomNav: false),
                      ),
                    );
                  },
                    child: const Text('View All',
                        style: TextStyle(
                            color: Color.fromARGB(255, 0, 72, 88),
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              GridView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: services.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, 
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.0, 
                ),
                itemBuilder: (context, index) {
                  return _buildServiceGridItem(services[index]);
                },
              ),

              const SizedBox(height: 30),

              // PKU CONTENT VIEW
              const Text(
                'Featured Updates',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: Colors.black87),
              ),
              const SizedBox(height: 12),
              _buildDynamicInfoCard(currentPkuContent),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),

      // BOTTOM NAV 
      bottomNavigationBar: SafeArea(
      top: false, // 
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
            _buildNavItem(Icons.calendar_month_outlined, 1),
            _buildNavItem(Icons.content_paste_rounded, 2),
            _buildNavItem(Icons.person_outline_rounded, 3),
          ],
        ),
        ),
      ),

    );
  }

  // WIDGET FOR HOME 

  Widget _buildProfileHeader() {
    return FutureBuilder<UserModel?>(
      future: _getCurrentUser(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        return Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ProfilePage())),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: const Color.fromARGB(255, 0, 72, 88), width: 2),
                ),
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: user?.photoUrl != null &&
                          user!.photoUrl!.isNotEmpty
                      ? NetworkImage(user.photoUrl!)
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
                  const Text('Welcome Back,',
                      style: TextStyle(
                          fontSize: 13,
                          color:  Color.fromARGB(255, 56, 161, 163),
                          fontWeight: FontWeight.w500)),
                  Text(
                    user?.fullName.split(' ').first ?? 'User',
                    style: const TextStyle(
                        fontSize: 18,
                        color: Colors.black87),
                  ),
                ],
              ),
            ),
            _buildNotificationIcon(),
            const SizedBox(width: 8),
            _buildSOSButton(),
          ],
        );
      },
    );
  }

  Widget _buildNotificationIcon() {
    return StreamBuilder<int>(
      stream: _unreadNotificationCount(),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, size: 28),
              onPressed: () {
                final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => NotificationPage(userId: uid)));
              },
            ),
            if (count > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                      color: Colors.red, shape: BoxShape.circle),
                  child: Text('$count',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ),
              )
          ],
        );
      },
    );
  }

  Widget _buildSOSButton() {
    return ElevatedButton(
      onPressed: () => _callEmergency(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.redAccent.withOpacity(0.1),
        elevation: 0,
        side: const BorderSide(color: Colors.red, width: 1.5),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: const Text('SOS',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.w800)),
    );
  }

 Widget _homeCard({
    required Gradient gradient,
    required Color iconColor,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: iconColor.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: iconColor.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween, 
          children: [
            Icon(icon, color: iconColor, size: 30),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15, 
                height: 1.2, 
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceGridItem(Map<String, dynamic> service) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => AvailabilityPage(service: service['name'])),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 5,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(service['icon'],
                color: const Color.fromARGB(255, 0, 72, 88), size: 28),
            const SizedBox(height: 8),
            Text(
              service['name'],
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicInfoCard(PkuContent content) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => content.destinationPage));
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [primaryTeal, Color(0xFF007A8C)], 
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: primaryTeal.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5))
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    content.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.9), fontSize: 13),
                  ),
                ],
              ),
            ),
            if (content.imageAsset != null) ...[
              const SizedBox(width: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(content.imageAsset!,
                    width: 60, height: 60, fit: BoxFit.cover),
              ),
            ]
          ],
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
          color: isSelected
              ? const Color.fromARGB(255, 255, 255, 255)
              : const Color.fromARGB(255, 0, 0, 0),
          size: 26,
        ),
      ),
    );
  }
}

// TEMPORARY CLASS CONTENT FOR PKU 
class PkuContent {
  final String title;
  final String description;
  final String? imageAsset;
  final Widget destinationPage;

  PkuContent({
    required this.title,
    required this.description,
    this.imageAsset,
    required this.destinationPage,
  });
}