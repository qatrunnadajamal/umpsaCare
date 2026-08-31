
import 'package:flutter/material.dart';
import 'package:umpsa_care/controllers/appointmentController.dart';
import '../../controllers/visitController.dart';
import '../../controllers/medicineController.dart';
import '../../model/medicine.dart';
import '../../model/visit_record.dart';
import 'appointmentBookPageD.dart'; 

const Color primaryTeal = Color(0xFF00A2A5);
const Color screenBackgroundColor = Color(0xFFF5F7FA); 
const Color textFieldBorderColor = Color(0xFFE0E0E0);
const Color lightGreyBackground = Color(0xFFF0F0F0);

class VisitRecordScreen extends StatefulWidget {
  final String studentId;
  final String appointmentId;
  final String doctorId;

  const VisitRecordScreen({
    super.key,
    required this.studentId,
    required this.appointmentId,
    required this.doctorId,
  });

  @override
  State<VisitRecordScreen> createState() => _VisitRecordScreenState();
}

class _VisitRecordScreenState extends State<VisitRecordScreen> {
  final _diagnosisController = TextEditingController();
  final _noteController = TextEditingController();

  final MedicineController _medicineController = MedicineController();
  List<Medicine> medicines = [];
  List<Medicine> selectedMedicines = [];

  bool _isLoadingMedicines = true;

  @override
  void initState() {
    super.initState();
    _loadMedicines();
  }

  Future<void> _loadMedicines() async {
    try {
      medicines = await _medicineController.getAllMedicines();
    } catch (e) {
      print("Error loading medicines: $e");
      medicines = [];
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMedicines = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _diagnosisController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _openMedicinePicker() {
    if (_isLoadingMedicines) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        final double safeHeight = MediaQuery.of(context).size.height -
            MediaQuery.of(context).padding.top;
        return _MedicinePickerSheet(
          sheetHeight: safeHeight * 0.9,
          medicines: medicines,
          initiallySelected: selectedMedicines,
          onSelectionChanged: (List<Medicine> updatedSelection) {
            setState(() {
              selectedMedicines = updatedSelection;
            });
          },
        );
      },
    );
  }

  //CONFIRMATION
  Future<void> _saveVisitRecord() async {

    final visitController = VisitController();
    final appointmentController = AppointmentController();

    try {
      final record = VisitRecord(
        studentId: widget.studentId,
        appointmentId: widget.appointmentId,
        doctorId: widget.doctorId,
        medIds: selectedMedicines.map((m) => m.medId).toList(),
        diagnosis: _diagnosisController.text,
        note: _noteController.text,
      );

      // CREATE
      await visitController.addVisitRecord(record);
      await appointmentController.debugAppointment(widget.appointmentId);

      // STATUS UPDATE
      await appointmentController.updateAppointmentStatus(
          widget.appointmentId, "Completed");

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => Dialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_rounded,
                        size: 40, color: Colors.green),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Success!',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Visit record has been successfully created.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop(); 
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const AppointmentBookPageD()),
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryTeal,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Back to Home',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to create visit record: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: screenBackgroundColor,
      appBar: AppBar(
        title: const Text("Visit Record",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryTeal,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField("Diagnosis", _diagnosisController, maxLines: 3),
            const SizedBox(height: 16),
            _buildMedicineChipsSection(),
            const SizedBox(height: 16),
            _buildTextField("Note / Remark", _noteController, maxLines: 3),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saveVisitRecord,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryTeal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  shadowColor: primaryTeal.withOpacity(0.3),
                ),
                child: const Text(
                  "CREATE RECORD",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: "Enter $label...",
            hintStyle: TextStyle(color: Colors.grey[400]),
            contentPadding: EdgeInsets.symmetric(
                horizontal: 16, vertical: maxLines > 1 ? 16 : 14),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: textFieldBorderColor),
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: textFieldBorderColor),
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: primaryTeal, width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMedicineChipsSection() {
    if (_isLoadingMedicines) {
      return const Center(
          child: Padding(
        padding: EdgeInsets.all(20.0),
        child: CircularProgressIndicator(color: primaryTeal),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Prescription",
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: textFieldBorderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (selectedMedicines.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: selectedMedicines.map((med) {
                      return Chip(
                        label: Text(
                          "${med.medName} (${med.medUnit})",
                          style: TextStyle(
                              color: primaryTeal.withOpacity(0.8),
                              fontWeight: FontWeight.w600),
                        ),
                        backgroundColor: primaryTeal.withOpacity(0.05),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                              color: primaryTeal.withOpacity(0.2)),
                        ),
                        deleteIcon:
                            const Icon(Icons.close, size: 16, color: primaryTeal),
                        onDeleted: () {
                          setState(() {
                            selectedMedicines
                                .removeWhere((m) => m.medId == med.medId);
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _openMedicinePicker,
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  label: Text(
                    selectedMedicines.isEmpty
                        ? "Select Medicines"
                        : "Add More Medicines",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryTeal,
                    side: const BorderSide(color: primaryTeal),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// MED
class _MedicinePickerSheet extends StatefulWidget {
  final List<Medicine> medicines;
  final List<Medicine> initiallySelected;
  final ValueChanged<List<Medicine>> onSelectionChanged;
  final double sheetHeight;

  const _MedicinePickerSheet({
    Key? key,
    required this.medicines,
    required this.initiallySelected,
    required this.onSelectionChanged,
    required this.sheetHeight,
  }) : super(key: key);

  @override
  State<_MedicinePickerSheet> createState() => _MedicinePickerSheetState();
}

class _MedicinePickerSheetState extends State<_MedicinePickerSheet> {
  late List<Medicine> filtered;
  late List<Medicine> selected;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filtered = List.from(widget.medicines);
    selected = List.from(widget.initiallySelected);
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final q = _searchController.text.toLowerCase();
    setState(() {
      filtered = widget.medicines.where((m) {
        final combined =
            "${m.medName.toLowerCase()} ${m.medType.toLowerCase()} ${m.medUnit.toLowerCase()}";
        return combined.contains(q);
      }).toList();
    });
  }

  void _toggleSelect(Medicine med) {
    setState(() {
      final already = selected.any((m) => m.medId == med.medId);
      if (already) {
        selected.removeWhere((m) => m.medId == med.medId);
      } else {
        selected.add(med);
      }
    });
  }

  bool _isSelected(Medicine med) =>
      selected.any((m) => m.medId == med.medId);

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: widget.sheetHeight,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 10),
              child: Row(
                children: [
                  const Text(
                    "Select Medicines",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                          color: Colors.grey[200], shape: BoxShape.circle),
                      child: const Icon(Icons.close_rounded,
                          size: 20, color: Colors.black54),
                    ),
                  ),
                ],
              ),
            ),
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Search medicine...",
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: const Icon(Icons.search, color: primaryTeal),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: textFieldBorderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: textFieldBorderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: primaryTeal, width: 1.5),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const Divider(height: 1),
            // List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.medication_liquid_outlined,
                              size: 48, color: Colors.grey[300]),
                          const SizedBox(height: 12),
                          Text("No medicines found",
                              style: TextStyle(color: Colors.grey[500])),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: Colors.grey[100]),
                      itemBuilder: (context, index) {
                        final med = filtered[index];
                        final isSel = _isSelected(med);
                        return ListTile(
                          onTap: () => _toggleSelect(med),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 20),
                          leading: CircleAvatar(
                            radius: 22,
                            backgroundColor: isSel
                                ? primaryTeal
                                : primaryTeal.withOpacity(0.1),
                            child: Icon(
                                isSel
                                    ? Icons.check
                                    : Icons.local_pharmacy_outlined,
                                color: isSel ? Colors.white : primaryTeal,
                                size: 20),
                          ),
                          title: Text(
                            med.medName,
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isSel ? primaryTeal : Colors.black87),
                          ),
                          subtitle: Text(
                            "${med.medType} • ${med.medUnit}",
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey[600]),
                          ),
                          trailing: isSel
                              ? const Icon(Icons.check_circle,
                                  color: primaryTeal)
                              : Icon(Icons.circle_outlined,
                                  color: Colors.grey[300]),
                        );
                      },
                    ),
            ),
            // Bottom Action Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -4))
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: selected.isEmpty
                          ? null
                          : () {
                              setState(() {
                                selected.clear();
                              });
                            },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Clear"),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onSelectionChanged(selected);
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryTeal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text("Confirm (${selected.length})",
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
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