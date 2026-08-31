
import 'package:flutter/material.dart';
import '../../model/visit_record.dart';
import '../../model/medicine.dart';
import '../../controllers/medicineController.dart';

class VisitDetailPage extends StatefulWidget {
  final VisitRecord visit;

  const VisitDetailPage({super.key, required this.visit});

  @override
  State<VisitDetailPage> createState() => _VisitDetailPageState();
}

class _VisitDetailPageState extends State<VisitDetailPage> {
  static const Color primaryTeal = Color(0xFF20B2AA);
  
  // STORE MEDICINE
  late Future<List<Medicine>> _medicinesFuture;
  final MedicineController _medicineController = MedicineController();

  @override
  void initState() {
    super.initState();
    _medicinesFuture = _medicineController.getAllMedicines();
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown Date';
    DateTime date = timestamp.toDate();
    return "${date.day}/${date.month}/${date.year}  ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }

  // SEARCH
  Medicine? _findMedicine(String id, List<Medicine> allMedicines) {
    try {
      return allMedicines.firstWhere((m) => m.medId == id);
    } catch (e) {
      return null;
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Visit Details",
            style: TextStyle(color: Color.fromARGB(221, 255, 255, 255),fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor:Color(0xFF20B2AA),
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Color.fromARGB(221, 255, 255, 255)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),

            const SizedBox(height: 20),

            // NOTE
            _buildSectionTitle("Doctor's Notes"),
            const SizedBox(height: 8),
            _buildContentCard(
              child: Text(
                widget.visit.note.isNotEmpty ? widget.visit.note : "No notes provided.",
                style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.5),
              ),
            ),

            const SizedBox(height: 20),

            //MEDICNE PART
            if (widget.visit.medIds.isNotEmpty) ...[
              _buildSectionTitle("Prescribed Medicines"),
              const SizedBox(height: 8),
              FutureBuilder<List<Medicine>>(
                future: _medicinesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: LinearProgressIndicator(color: primaryTeal));
                  } else if (snapshot.hasError) {
                    return const Text("Error loading medicine details.");
                  }
                  
                  final allMedicines = snapshot.data ?? [];
                  return _buildMedicineList(allMedicines);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primaryTeal,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: primaryTeal.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Diagnosis",
              style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 4),
          Text(
            widget.visit.diagnosis,
            style: const TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(
                _formatDate(widget.visit.createdAt),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildMedicineList(List<Medicine> allMedicines) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: Column(
        children: widget.visit.medIds.asMap().entries.map((entry) {
          int idx = entry.key;
          String medId = entry.value;
          bool isLast = idx == widget.visit.medIds.length - 1;

          // Lookup name
          final medicine = _findMedicine(medId, allMedicines);
          final displayName = medicine != null ? medicine.medName : "Unknown Medicine";
          final displayUnit = medicine != null ? "(${medicine.medUnit})" : medId;

          return Column(
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.medication, color: Colors.blue, size: 20),
                ),
                title: Text(
                  displayName, 
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(displayUnit),
              ),
              if (!isLast) const Divider(height: 1, indent: 70),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContentCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: child,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }
}