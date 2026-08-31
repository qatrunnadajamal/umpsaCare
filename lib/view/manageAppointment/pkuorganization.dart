
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:url_launcher/url_launcher.dart';

class PkuOrganizationPage extends StatefulWidget {
  const PkuOrganizationPage({super.key});

  @override
  State<PkuOrganizationPage> createState() => _PkuOrganizationPageState();
}

class _PkuOrganizationPageState extends State<PkuOrganizationPage> {
  int _currentSlide = 0;
  final CarouselSliderController _carouselController = CarouselSliderController();

  // LINK
  final Uri _pkuUrl = Uri.parse('https://pku.umpsa.edu.my/');

  Future<void> _launchPKUWebsite() async {
    if (!await launchUrl(_pkuUrl, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        // Fallback if link fails
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch website')),
        );
      }
    }
  }

  final List<String> organizationImages = [
    'assets/images/organization.jpg',
    'assets/images/org2.jpg',
    'assets/images/org3.jpg',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Our Organization',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white, 
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF00A2A5),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 15),
            
            // SLIDER
            Column(
              children: [
                CarouselSlider.builder(
                  carouselController: _carouselController,
                  itemCount: organizationImages.length,
                  itemBuilder: (context, index, realIndex) {
                    final item = organizationImages[index];
                    return Container(
                      width: MediaQuery.of(context).size.width* 0.8,
                      margin: const EdgeInsets.symmetric(horizontal: 5.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
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
                        child: Image.asset(
                          item,
                            fit: BoxFit.contain,
                             width: MediaQuery.of(context).size.width * 0.9, 
                              height: 250,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.image_not_supported_outlined,
                                      size: 40, color: Colors.grey.shade400),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Image not found',
                                    style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                  options: CarouselOptions(
                    height: 250,
                    autoPlay: true,
                    autoPlayInterval: const Duration(seconds: 4),
                    enlargeCenterPage: true,
                    aspectRatio: 16 / 9,
                    viewportFraction: 0.85,
                    onPageChanged: (index, reason) {
                      setState(() {
                        _currentSlide = index;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 10),
                // IINDCATOR
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: organizationImages.asMap().entries.map((entry) {
                    return GestureDetector(
                      onTap: () => _carouselController.animateToPage(entry.key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: _currentSlide == entry.key ? 20 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: _currentSlide == entry.key
                              ? const Color(0xFF00A2A5)
                              : Colors.grey.shade300,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),

            // ORG
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome to PKU Organization',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    'The Pusat Kesihatan Universiti (University Health Centre) is dedicated to providing comprehensive healthcare services and promoting wellness among the university community.',
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 25),
                  
                  // MISSION
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F8F8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF00A2A5).withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Our Mission',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00A2A5),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'To deliver accessible, high-quality, and patient-centered healthcare services, foster health education, and support public health initiatives.',
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: _launchPKUWebsite, 
                      icon: const Icon(Icons.info_outline, color: Colors.white), 
                      label: const Text(
                        'Learn More', 
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00A2A5),
                        elevation: 4,
                        shadowColor: const Color(0xFF00A2A5).withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}