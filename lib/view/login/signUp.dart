import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../controllers/userController.dart';
import '../login/loginPage.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _controller = UserController();
  final _formKey = GlobalKey<FormState>();
  final List<String> _campuses = ['Gambang', 'Pekan']; 
  String? _selectedCampus; 

  static const Color primaryTeal = Color(0xFF00A2A5); 
  static const Color darkBlue = Color(0xFF003B46); 
  static const Color bgCoolGrey = Color(0xFFF4F6F8); 

  final List<String> _faculties = [
    'FTKA', 'FTKEE', 'FTKKP', 'FTKMA', 'FTKPM', 'FK', 'FIST', 'FIM',
  ];

  final List<String> allServices = [
    'Health Screening',
    'Consultations',
    'Dental',
    'Health Talk',
    'Medical Checkup',
    'Physiotherapy',
  ];

  final Set<String> _selectedServices = {};

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _genderController = TextEditingController();
  final _dobController = TextEditingController();
  
  // STUD FIELD
  final _facultyController = TextEditingController();
  final _matricNoController = TextEditingController();
  final _advisorController = TextEditingController();

  // DOC /STAFF
  final _gradeController = TextEditingController();
  final _specializationController = TextEditingController();
  final _positionController = TextEditingController();
  final _staffIdController = TextEditingController(); 

  String _selectedRole = "User Type";
  String? _selectedFaculty;
  bool _obscurePassword = true;
  String? _selectedGender;

  // ERROR HDLING
  Future<void> _showErrorDialog(String message) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.error_outline,
                    size: 48, color: Colors.red),
              ),
              const SizedBox(height: 20),
              const Text(
                "Oops!",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "OK",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryTeal,
              onPrimary: Colors.white,
              onSurface: darkBlue,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dobController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  // SIGN UP
  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all required fields.")),
      );
      return;
    }

    if (_selectedRole == "User Type") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a user type.")),
      );
      return;
    }

    try {
      await _controller.registerUser(
        fullName: _fullNameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        phoneNumber: _phoneController.text,
        gender: _genderController.text,
        dob: _dobController.text,
        userType: _selectedRole,
        faculty: _facultyController.text,
        matricNo: _matricNoController.text,
        advisor: _advisorController.text,
        staffId: _staffIdController.text,
        grade: _gradeController.text,
        specialization: _specializationController.text,
        position: _positionController.text,
        services: _selectedRole == 'Doctor' ? _selectedServices.toList() : null,
        campus: _selectedRole == 'Doctor' ? _selectedCampus! : null,
      );

      if (!mounted) return;

      // SUCCESS DIALOG
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00A2A5).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded,
                      size: 48, color: Color(0xFF00A2A5)),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Congratulations!",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF003B46),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Your account has been created successfully. You can now log in using your ID.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A2A5),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Go to Login",
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      if (e.code == 'email-already-in-use') {
        String msg = _selectedRole == 'Student'
            ? "Matric ID already exists."
            : "Staff ID already exists.";
        await _showErrorDialog(msg);
      } else {
        await _showErrorDialog(e.message ?? "Registration failed.");
      }
    } catch (e) {
      if (!mounted) return;

      String errorMsg = e.toString();
      if (errorMsg.contains("already exists")) {
        await _showErrorDialog(errorMsg);
      } else {
        await _showErrorDialog("Unexpected error: $errorMsg");
      }
    }
  }

  // DROPDOWN
  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool obscure = false,
    bool readOnly = false,
    VoidCallback? onTap,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: darkBlue,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: TextFormField(
              controller: controller,
              obscureText: obscure ? _obscurePassword : false,
              readOnly: readOnly,
              onTap: onTap,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return "This field is required.";
                }
                return null;
              },
              style: const TextStyle(fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                prefixIcon:
                    icon != null ? Icon(icon, color: Colors.grey[400]) : null,
                suffixIcon: obscure
                    ? IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      )
                    : null,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    String? hintText,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: darkBlue,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: DropdownButtonFormField<T>(
              value: value,
              items: items,
              onChanged: onChanged,
              validator: (v) => v == null ? "This field is required." : null,
              dropdownColor: Colors.white,
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: primaryTeal),
              style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 15,
                  fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              ),
              hint: hintText != null
                  ? Text(hintText,
                      style: TextStyle(color: Colors.grey[400]))
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  // MAIN WIDGET
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgCoolGrey,
      appBar: AppBar(
        backgroundColor: const Color(0xFF00A2A5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Color.fromARGB(255, 255, 255, 255), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "Create Account",
          style: TextStyle(
            color: Color.fromARGB(255, 255, 255, 255),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          physics: const BouncingScrollPhysics(),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Join UMPSA Care',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: primaryTeal,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Fill in your details to get started',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 32),

                _buildTextField('Full Name', _fullNameController,
                    icon: Icons.person_outline),
                _buildTextField('Email', _emailController,
                    icon: Icons.email_outlined),
                _buildTextField('Password', _passwordController,
                    obscure: true, icon: Icons.lock_outline),
                _buildTextField('Phone Number', _phoneController,
                    icon: Icons.phone_outlined),

                _buildDropdown<String>(
                  label: 'Gender',
                  value: _selectedGender,
                  items: const [
                    DropdownMenuItem(value: 'Male', child: Text('Male')),
                    DropdownMenuItem(value: 'Female', child: Text('Female')),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedGender = val;
                      _genderController.text = val!;
                    });
                  },
                  hintText: 'Select Gender',
                ),

                _buildTextField(
                  'Date of Birth',
                  _dobController,
                  readOnly: true,
                  onTap: () => _selectDate(context),
                  icon: Icons.calendar_today_outlined,
                ),

                const Divider(height: 40),

                _buildDropdown<String>(
                  label: 'Register As',
                  value: _selectedRole == "User Type" ? null : _selectedRole,
                  items: const [
                    DropdownMenuItem(value: 'Student', child: Text('Student')),
                    DropdownMenuItem(value: 'Doctor', child: Text('Doctor')),
                    DropdownMenuItem(
                        value: 'PKU Staff', child: Text('PKU Staff')),
                  ],
                  onChanged: (val) => setState(() => _selectedRole = val!),
                  hintText: 'Select Role',
                ),

                // Role-specific fields
                if (_selectedRole == 'Student') ...[
                  _buildDropdown<String>(
                    label: 'Faculty',
                    value: _selectedFaculty,
                    items: _faculties
                        .map((code) => DropdownMenuItem(
                              value: code,
                              child: Text(code),
                            ))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedFaculty = val;
                        _facultyController.text = val!;
                      });
                    },
                    hintText: 'Select Faculty',
                  ),
                  _buildTextField('Matric No', _matricNoController,
                      icon: Icons.badge_outlined),
                  _buildTextField(
                      'Personal Academic Advisor', _advisorController,
                      icon: Icons.school_outlined),
                ] else if (_selectedRole == 'Doctor') ...[
                  _buildTextField(' Doctor ID', _staffIdController, 
                      icon: Icons.badge_outlined),
                  _buildTextField('Grade', _gradeController,
                      icon: Icons.stars_outlined),
                  _buildTextField('Specialization', _specializationController,
                      icon: Icons.medical_services_outlined),
                  const SizedBox(height: 16),
                  _buildDropdown<String>(
                    label: 'Campus',
                    value: _selectedCampus,
                    items: _campuses
                        .map((campus) => DropdownMenuItem(
                              value: campus,
                              child: Text(campus),
                            ))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedCampus = val;
                      });
                    },
                    hintText: 'Select Campus',
                  ),
                  const SizedBox(height: 16),
                  const Text('Select Services Offered',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: darkBlue,
                          fontSize: 14)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: allServices.map((service) {
                        return CheckboxListTile(
                          title: Text(service,
                              style: const TextStyle(fontSize: 14)),
                          value: _selectedServices.contains(service),
                          activeColor: primaryTeal,
                          dense: true,
                          controlAffinity: ListTileControlAffinity.leading,
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                _selectedServices.add(service);
                              } else {
                                _selectedServices.remove(service);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ] else if (_selectedRole == 'PKU Staff') ...[
                  // PKU STAFF ID
                  _buildTextField('Staff ID', _staffIdController, 
                      icon: Icons.badge_outlined),
                      
                  _buildTextField('Position', _positionController,
                      icon: Icons.work_outline),
                ],

                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryTeal,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: primaryTeal.withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _handleSignUp,
                    child: const Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}