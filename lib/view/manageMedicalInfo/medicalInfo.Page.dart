
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../controllers/userController.dart';
import '../../model/medical.dart';
import '../manageAppointment/appointmentBookPageD.dart';
import '../manageProfile/profilePage.dart';
import '../manageAppointment/appointmentBookPage.dart';
import '../manageAppointment/listServices.dart';


class MedicalInfoPage extends StatefulWidget {
  final String? studentId;
  final bool isDoctorView;

  const MedicalInfoPage({
    super.key,
    this.studentId,
    this.isDoctorView = false,
  });

  @override
  State<MedicalInfoPage> createState() => _MedicalInfoPageState();
}

class _MedicalInfoPageState extends State<MedicalInfoPage> {
  late final UserController _userController;
  MedicalInfo? _medicalInfo;
  String? _studentId;
  bool _isLoading = true;

  // FORM
  int _selectedIndex = 2; 
  static const Color primaryTeal = Color(0xFF00A2A5); 
  static const Color bgGrey = Color(0xFFF5F7FA);
  final bloodCtrl = TextEditingController();
  final heightCtrl = TextEditingController();
  final weightCtrl = TextEditingController();
  List<String> chronicDiseases = [];
  List<String> allergies = [];
  List<Map<String, String>> vaccinations = [];

  @override
  void initState() {
    super.initState();
    _userController = UserController();
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    if (widget.isDoctorView && widget.studentId != null) {
      _studentId = widget.studentId;
    } else {
      _studentId = FirebaseAuth.instance.currentUser?.uid;
    }
    if (_studentId != null) await _loadMedicalData(_studentId!);
  }

  Future<void> _loadMedicalData(String studentId) async {
    final info = await _userController.getMedicalInfo(studentId);
    _medicalInfo = info;

    if (info != null) {
      bloodCtrl.text = info.bloodType;
      heightCtrl.text = info.height?.toString() ?? '';
      weightCtrl.text = info.weight?.toString() ?? '';

      // Load lists for the Edit Dialog
      chronicDiseases = List<String>.from(info.chronicDiseases);
      allergies = List<String>.from(info.allergies);
      vaccinations = List<Map<String, String>>.from(info.vaccinations);
    }

    if (mounted) setState(() => _isLoading = false);
  }

  //SAVE

  Future<void> _saveAll() async {
    if (_studentId == null) return;
    final cleanDiseases =
        chronicDiseases.where((e) => e.trim().isNotEmpty).toList();
    final cleanAllergies =
        allergies.where((e) => e.trim().isNotEmpty).toList();
    final cleanVaccines = vaccinations
        .where((e) => (e['name'] ?? '').trim().isNotEmpty)
        .toList();

    final data = {
      'blood_type': bloodCtrl.text,
      'height': heightCtrl.text,
      'weight': weightCtrl.text,
      'chronic_diseases': cleanDiseases,
      'allergies': cleanAllergies,
      'vaccinations': cleanVaccines,
    };

    if (_medicalInfo != null) {
      await _userController.updateMedicalInfo(_medicalInfo!.medicalId, data);
    } else {
      await _userController.addMedicalInfo(
        MedicalInfo(
          medicalId: '',
          studentId: _studentId!,
          bloodType: bloodCtrl.text,
          height: double.tryParse(heightCtrl.text),
          weight: double.tryParse(weightCtrl.text),
          chronicDiseases: cleanDiseases,
          allergies: cleanAllergies,
          vaccinations: cleanVaccines,
        ),
      );
    }

    if (mounted) Navigator.pop(context);
    await _loadMedicalData(_studentId!); //REFRESH
  }

  Future<void> _pickVaccineDate(int index) async {
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() {
        vaccinations[index]['date'] = date.toIso8601String().split('T')[0];
      });
      Navigator.pop(context);
      _openEditDialog();
    }
  }

  void _openEditDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            
            title: Row(
              children: const [
                Icon(Icons.edit_note_rounded, color: Color(0xFF003B46), size: 28),
                SizedBox(width: 12),
                Text(
                  'Edit Medical Info',
                  style: TextStyle(
                    color: Color.fromARGB(255, 0, 0, 0),
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
              ],
            ),

            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Physical Information",
                      style: TextStyle(
                        color: Color.fromARGB(255, 0, 0, 0), 
                        fontSize: 12, 
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0
                      ),
                    ),
                    const SizedBox(height: 12),
                    _inputField('Blood Type', bloodCtrl, icon: Icons.bloodtype),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                            child: _inputField('Height (cm)', heightCtrl,
                                number: true, icon: Icons.height)),
                        const SizedBox(width: 16),
                        Expanded(
                            child: _inputField('Weight (kg)', weightCtrl,
                                number: true,
                                icon: Icons.monitor_weight_outlined)),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Divider(),
                    ),
                    _buildDynamicList(
                        "Chronic Diseases", chronicDiseases, setStateDialog),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Divider(),
                    ),
                    _buildDynamicList("Allergies", allergies, setStateDialog),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Divider(),
                    ),
                    _buildVaccinationList(setStateDialog),
                  ],
                ),
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[600],
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _saveAll,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryTeal,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Save'),
              ),
            ],
          );
        });
      },
    );
  }

  Widget _inputField(String label, TextEditingController c,
      {bool number = false, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon, size: 20) : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
    );
  }

  Widget _buildDynamicList(
      String title, List<String> list, StateSetter setStateDialog) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        ...List.generate(list.length, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: list[i],
                    onChanged: (val) => list[i] = val,
                    decoration: InputDecoration(
                      hintText: 'Enter $title',
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    setStateDialog(() {
                      list.removeAt(i);
                    });
                  },
                ),
              ],
            ),
          );
        }),
        TextButton.icon(
          onPressed: () {
            setStateDialog(() {
              list.add('');
            });
          },
          icon: const Icon(Icons.add, size: 18),
          label: Text("Add $title"),
        ),
      ],
    );
  }

  Widget _buildVaccinationList(StateSetter setStateDialog) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Vaccinations",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        ...List.generate(vaccinations.length, (i) {
          final date = vaccinations[i]['date'] ?? '';
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: vaccinations[i]['name'],
                    onChanged: (val) => vaccinations[i]['name'] = val,
                    decoration: InputDecoration(
                      hintText: 'Vaccine Name',
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _pickVaccineDate(i);
                  },
                  child: Text(
                    date.isEmpty ? 'Date' : date,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    setStateDialog(() {
                      vaccinations.removeAt(i);
                    });
                  },
                ),
              ],
            ),
          );
        }),
        TextButton.icon(
          onPressed: () {
            setStateDialog(() {
              vaccinations.add({'name': '', 'date': ''});
            });
          },
          icon: const Icon(Icons.add, size: 18),
          label: const Text("Add Vaccine"),
        ),
      ],
    );
  }

  Widget _buildVitalsSection() {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Container(
            height: 160,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryTeal, primaryTeal.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: primaryTeal.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.bloodtype, color: Colors.white, size: 20),
                    SizedBox(width: 3),
                    Text("Blood Type",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w500)),
                  ],
                ),
                Center(
                  child: Text(
                    _medicalInfo?.bloodType.isNotEmpty == true
                        ? _medicalInfo!.bloodType
                        : "-",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 5,
          child: SizedBox(
            height: 160,
            child: Column(
              children: [
                _buildSmallVitalCard(
                    "Height",
                    "${_medicalInfo?.height?.toString() ?? '-'} cm",
                    Icons.height),
                const SizedBox(height: 12),
                _buildSmallVitalCard(
                    "Weight",
                    "${_medicalInfo?.weight?.toString() ?? '-'} kg",
                    Icons.monitor_weight_outlined),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSmallVitalCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                Text(value,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            Icon(icon, color: const Color.fromARGB(255, 0, 72, 88), size: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsList(String title, List<String> items, IconData icon) {
    bool isEmpty = items.isEmpty;
    String content = items.join("\n• ");
    if (content.isNotEmpty) content = "• $content";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryTeal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color.fromARGB(255, 0, 72, 88), size: 24),
          ),
          title: Text(
            title,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: Text(
                  isEmpty ? "No information added yet." : content,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: isEmpty ? Colors.grey[400] : Colors.grey[800],
                    fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVaccineDisplay(List<Map<String, String>> vaccines) {
    bool isEmpty = vaccines.isEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryTeal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.vaccines_outlined,
                color: Color.fromARGB(255, 0, 72, 88), size: 24),
          ),
          title: const Text(
            "Vaccinations",
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: isEmpty
                    ? Text(
                        "No information added yet.",
                        style: TextStyle(
                            fontSize: 15,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[400]),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: vaccines.map((v) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("• ${v['name']}",
                                    style: const TextStyle(
                                        fontSize: 15, color: Colors.black87)),
                                Text(v['date'] ?? '',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600])),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  //NAV

  void _onNavItemTapped(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
    
    if (widget.isDoctorView) {
      if (index == 0) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const AppointmentBookPageD()));
      } else if (index == 1) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const ProfilePage()));
      }
    } else {
      if (index == 0) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const AppointmentBookPage()));
      } else if (index == 1) {
        // Changed to navigate to BookAppointmentPage (List of services) 
        // to match the flow from the other pages
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const BookAppointmentPage()));
      } else if (index == 3) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const ProfilePage()));
      }
    }
  }

  
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
              : const Color.fromARGB(255, 0, 0, 0), // Black for unselected
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
        backgroundColor: primaryTeal,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color.fromARGB(221, 255, 255, 255)),
        title: const Text(
          'Medical Information',
          style: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (!widget.isDoctorView)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                icon: const Icon(Icons.edit_note_rounded,
                    color: Color.fromARGB(255, 255, 255, 255), size: 30),
                onPressed: _openEditDialog,
                tooltip: 'Edit Info',
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryTeal))
          : SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Physical Information",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    _buildVitalsSection(),
                    const SizedBox(height: 24),
                    const Text(
                      "Medical History",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailsList(
                      'Chronic Diseases',
                      _medicalInfo?.chronicDiseases ?? [],
                      Icons.monitor_heart_outlined,
                    ),
                    _buildDetailsList(
                      'Allergies',
                      _medicalInfo?.allergies ?? [],
                      Icons.warning_amber_rounded,
                    ),
                    _buildVaccineDisplay(_medicalInfo?.vaccinations ?? []),
                  ],
                ),
              ),
            ),
            
      // BOTTOM NAV
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
                offset: const Offset(0, -5),
              )
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: widget.isDoctorView
                ? [
                    _buildNavItem(Icons.home_outlined, 0),
                    _buildNavItem(Icons.person_outline, 1),
                  ]
                : [
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
}