
import 'package:flutter/material.dart';

class EventItem {
  final String title;
  final String description;
  final String date;
  final String imageAsset;

  const EventItem({
    required this.title,
    required this.description,
    required this.date,
    required this.imageAsset,
  });
}

//WIDGET

class PkuEventPage extends StatelessWidget {
  const PkuEventPage({super.key});

  final List<EventItem> events = const [
    const EventItem(
      title: 'UMPSA Blood Donation Drive 2025',
      description: 'Join us to save lives! Free health check and refreshments provided.',
      date: '15 MAY 2025 | 9:00 AM - 4:00 PM',
      imageAsset: 'assets/images/blood.jpg', 
    ),
    const EventItem(
      title: 'Annual Health Screening Program',
      description: 'Free comprehensive medical check-ups for all staff and students. Book your slot now!',
      date: '01 APR 2025 - 30 APR 2025',
      imageAsset: 'assets/images/pku.jpg',
    ),
    const EventItem(
      title: 'Mental Wellness Talk: Stress Management',
      description: 'A session with a certified counselor on managing academic and work stress effectively.',
      date: '07 JUN 2025 | 2:00 PM',
      imageAsset: 'assets/images/stress-management.jpg',
    ),
  ];

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      centerTitle: true,
      backgroundColor: const Color(0xFF00A2A5),
      foregroundColor: Colors.white, 
      title: const Text(
        'PKU NEWS & EVENTS',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18, 
        ),
      ),
    ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: events.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: EventCard(event: events[index]),
          );
        },
      ),
    );
  }
}

class EventCard extends StatelessWidget {
  final EventItem event;
  const EventCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: null,// LATER CAN NAVIGATE TO DATA -FUTURE WOKRSSS!!!
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2), 
              spreadRadius: 1,
              blurRadius: 7,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.asset(
                event.imageAsset,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 180,
                    color: Colors.grey[200],
                    child: Center(
                      child: Text(
                        'Image Error: ${event.imageAsset.split('/').last}',
                        style: TextStyle(color: Colors.red.shade700, fontSize: 14),
                      ),
                    ),
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // DATE
                  Row(
                    children: [
                      const Icon(Icons.calendar_month, size: 16, color: Color(0xFF00A2A5)),
                      const SizedBox(width: 5),
                      Text(
                        event.date,
                        style: const TextStyle(
                          color: Color(0xFF00A2A5),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // TITLE
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // DESC
                  Text(
                    event.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
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