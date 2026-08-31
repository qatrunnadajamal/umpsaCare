import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PkuInfoPage extends StatelessWidget {
  const PkuInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;
    const Color themeColor = Color(0xFF00A2A5);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), 
      appBar: AppBar(
        title: const Text(
          'PUSAT KESIHATAN UMPSA',
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5),
        ),
        backgroundColor: themeColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: firestore.collection('pku_info').doc('main').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: themeColor));
          }

          final data = (snapshot.hasData && snapshot.data!.exists)
              ? snapshot.data!.data() as Map<String, dynamic>
              : <String, dynamic>{};

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (data['image_url'] != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        data['image_url'],
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(height: 200, color: Colors.grey[300]),
                      ),
                    ),
                  ),

                // TITLE
                Text(
                  data['title'] ?? 'PKU UMPSA',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  data['subtitle'] ?? 'Primary Health Care for the UMP Community',
                  style: TextStyle(
                    fontSize: 14,
                    color: themeColor,
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 20),

                // DESC
                _buildSectionCard(
                  child: Column(
                    children: [
                      Text(
                        data['description'] ??
                            'University Health Center (PKU) is a one-stop center under the scope of primary health care for the UMP community. Both Gambang and Pekan campuses have one center each.\n\nCurrently operating with 5 doctors and 34 other staff members.',
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.justify,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // VISION/MISSION
                _buildSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(Icons.visibility, 'Our Vision', themeColor),
                      const SizedBox(height: 8),
                      Text(
                        data['vision'] ??
                            'To be a competent University Health Center in health management and services.',
                        style: const TextStyle(
                            fontSize: 15, fontStyle: FontStyle.italic),
                      ),
                      const Divider(height: 30),
                      _buildHeader(Icons.rocket_launch, 'Our Mission', themeColor),
                      const SizedBox(height: 8),
                      _buildBulletList(
                        data['mission'] as List<dynamic>? ??
                            [
                              'Provide high quality health services.',
                              'Promote comprehensive health education to campus residents.',
                              'To be a reference center for the implementation of health-related policies and activities.',
                            ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                //OBJ
                _buildSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(Icons.check_circle, 'Objectives', themeColor),
                      const SizedBox(height: 12),
                      _buildBulletList(
                        data['objectives'] as List<dynamic>? ??
                            [
                              'Provide holistic health services to campus residents.',
                              'Provide efficient and integrity services.',
                              'Communicate health related information clearly and accurately.',
                              'Provide the best service based on the latest guidelines.',
                            ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // HISTORY
                _buildSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(Icons.history_edu, 'Our History', themeColor),
                      const SizedBox(height: 16),
                      // Hardcoded history logic based on your text, or dynamic from DB
                      ...(data['history'] as List<dynamic>? ??
                          [
                            {'year': 'Aug 2004', 'event': 'Established under JHEPA supervision. Started with 1 Doctor & 1 Senior Nurse.'},
                            {'year': '2008', 'event': 'Operations moved to current infrastructure at Gambang UMP Campus.'},
                            {'year': '2009', 'event': 'Three doctors joined the clinic.'},
                            {'year': 'Jan 2010', 'event': 'Transformed into PTJ (Pusat Tanggungjawab). Temporary Pekan clinic opened in FKM building.'},
                            {'year': '2017', 'event': 'New clinic structure became fully operational at Pekan campus.'},
                          ]).map((h) => _buildHistoryRow(h['year'], h['event'], themeColor)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // CONTACT
                if (data['contact'] != null)
                  _buildSectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(Icons.contact_support, 'Contact Us', themeColor),
                        const SizedBox(height: 16),
                        _buildContactRow(Icons.email_outlined,
                            data['contact']['email'], themeColor),
                        _buildContactRow(Icons.phone_outlined,
                            data['contact']['phone'], themeColor),
                        _buildContactRow(
                            Icons.location_on_outlined,
                            "Gambang: ${data['contact']['gambang_address'] ?? 'UMP Gambang'}",
                            themeColor),
                        _buildContactRow(
                            Icons.location_on_outlined,
                            "Pekan: ${data['contact']['pekan_address'] ?? 'UMP Pekan'}",
                            themeColor),
                      ],
                    ),
                  ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  // WIDGET

  Widget _buildSectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildHeader(IconData icon, String title, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildBulletList(List<dynamic> items) {
    return Column(
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("• ", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Expanded(
                child: Text(
                  item.toString(),
                  style: const TextStyle(fontSize: 15, color: Colors.black87),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHistoryRow(String year, String event, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 75,
            child: Text(
              year,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 14,
              ),
            ),
          ),
          Container(
            width: 2,
            height: 40, // Approximate height line
            color: Colors.grey[300],
            margin: const EdgeInsets.symmetric(horizontal: 8),
          ),
          Expanded(
            child: Text(
              event,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String? text, Color color) {
    if (text == null || text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  fontSize: 14, color: Colors.black87, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}