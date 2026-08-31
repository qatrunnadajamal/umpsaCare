
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import '../../controllers/visitController.dart';
import '../../model/visit_record.dart';
import 'visitDetailPage.dart';

class VisitHistory extends StatefulWidget {
  final String studentId;

  const VisitHistory({super.key, required this.studentId});

  @override
  State<VisitHistory> createState() => _VisitHistoryState();
}

class _VisitHistoryState extends State<VisitHistory> {
  final VisitController _visitController = VisitController();
  late Future<List<VisitRecord>> _visitsFuture;

  static const Color primaryTeal = Color(0xFF20B2AA);

  @override
  void initState() {
    super.initState();
    _visitsFuture = _visitController.getVisitRecordsByStudent(widget.studentId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Visit History",
          style: TextStyle(color: Color.fromARGB(221, 255, 255, 255), fontSize: 18,fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color(0xFF20B2AA),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color.fromARGB(221, 255, 255, 255)),
      ),
      body: FutureBuilder<List<VisitRecord>>(
        future: _visitsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryTeal));
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final visits = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: visits.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return _VisitCardItem(visit: visits[index]);
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
          Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "No visit records found",
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

// WIDGET
class _VisitCardItem extends StatefulWidget {
  final VisitRecord visit;

  const _VisitCardItem({required this.visit});

  @override
  State<_VisitCardItem> createState() => _VisitCardItemState();
}

class _VisitCardItemState extends State<_VisitCardItem> {
  String _doctorName = "Loading...";
  String _appointmentType = "General Visit"; // Default
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAdditionalDetails();
  }

  // FECTH DOCTOR AND ID STUD
  Future<void> _fetchAdditionalDetails() async {
    try {
      if (widget.visit.doctorId.isNotEmpty) {
        final docRef = FirebaseFirestore.instance.collection('users').doc(widget.visit.doctorId);
        final docSnap = await docRef.get();
        if (docSnap.exists) {
          final data = docSnap.data();
          setState(() {
            _doctorName = data?['full_name'] ?? data?['name'] ?? "Unknown Doctor";
          });
        }
      }

      // TYPE APP
      if (widget.visit.appointmentId.isNotEmpty) {
        final appRef = FirebaseFirestore.instance.collection('appointments').doc(widget.visit.appointmentId);
        final appSnap = await appRef.get();
        if (appSnap.exists) {
          final data = appSnap.data();
          setState(() {
            _appointmentType = data?['remark'] ??  "Consultation";
          });
        }
      }
    } catch (e) {
      print("Error fetching details: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    DateTime date = widget.visit.createdAt?.toDate() ?? DateTime.now();
    String day = date.day.toString();
    String month = DateFormat('MMM').format(date).toUpperCase(); 

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
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => VisitDetailPage(visit: widget.visit)),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 70,
                  decoration: BoxDecoration(
                    color: const Color(0xFF20B2AA).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF20B2AA).withOpacity(0.3)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        day,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF20B2AA),
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        month,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF20B2AA).withOpacity(0.8),
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      //APP TYPE
                      Text(
                        _isLoading ? "Loading..." : _appointmentType,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // DOC NAME
                      Row(
                        children: [
                          const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _doctorName,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          widget.visit.diagnosis.isNotEmpty ? widget.visit.diagnosis : "No diagnosis",
                          style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}