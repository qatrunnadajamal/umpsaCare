import 'package:flutter/material.dart';
import 'package:umpsa_care/view/manageAppointment/appointmentBookPage.dart';
import 'availabilityPage.dart';
import '../manageProfile/profilePage.dart';
import '../manageMedicalInfo/medicalInfo.Page.dart';

class BookAppointmentPage extends StatefulWidget {
  final bool showBottomNav;

  const BookAppointmentPage({Key? key, this.showBottomNav = true}) : super(key: key);

  @override
  State<BookAppointmentPage> createState() => _BookAppointmentPageState();
}

class _BookAppointmentPageState extends State<BookAppointmentPage> {
  int _selectedIndex = 1; // Highlight this page (Calendar)
  static const Color primaryTeal = Color(0xFF00A2A5); 
  static const Color bgGrey = Color(0xFFF5F7FA);

  final List<String> services = [
    'Health Screening',
    'Consultations',
    'Dental',
    'Health Talk',
    'Medical Checkup',
    'Physiotherapy',
  ];

  // ICON
  final Map<String, IconData> serviceIcons = {
    'Health Screening': Icons.monitor_heart_outlined,
    'Consultations': Icons.chat_bubble_outline,
    'Dental': Icons.medical_services_outlined,
    'Health Talk': Icons.campaign_outlined,
    'Medical Checkup': Icons.assignment_outlined,
    'Physiotherapy': Icons.accessibility_new_outlined,
  };

  void _onNavItemTapped(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AppointmentBookPage()),
        );
        break;
      case 1:
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MedicalInfoPage()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ProfilePage()),
        );
        break;
    }
  }

  //WIDGET 
  Widget _buildNavItem(IconData icon, int index) {
    final bool isSelected = index == _selectedIndex;
    return GestureDetector(
      onTap: () => _onNavItemTapped(index),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGrey,
      appBar: AppBar(
        title: const Text(
          'Available Services',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: primaryTeal,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: !widget.showBottomNav,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
            child: Text(
              "Select a Service",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ),
          // LIST 
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: services.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final serviceName = services[index];
                final icon = serviceIcons[serviceName] ?? Icons.medical_services_outlined;

                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AvailabilityPage(service: serviceName),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
                      border: Border.all(color: Colors.grey.withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: primaryTeal.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(icon, color: const Color.fromARGB(255, 0, 72, 88), size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            serviceName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 18,
                          color: Colors.grey[400],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      // NAV
   bottomNavigationBar: widget.showBottomNav
      ? SafeArea(
          top: false, // Only pad the bottom
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
        )
      : null,
      );
  }
}