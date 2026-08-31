

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:umpsa_care/services/onesignal_helper.dart';
import 'package:umpsa_care/view/manageAppointment/appointmentBookPage.dart';
import 'package:umpsa_care/view/manageAppointment/appointmentBookPageD.dart';
import 'package:umpsa_care/view/manageAppointment/appointmentBookPageS.dart';
import 'package:umpsa_care/view/login/signUp.dart';



class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String _selectedRole = "Student"; // DEFAULT
  String? _resetEmailError;

  static const Color primaryTeal = Color(0xFF00A2A5);
  static const Color darkBlue = Color(0xFF003B46);
  static const Color bgCoolGrey = Color(0xFFF4F6F8);


// CONVERT ID T0 EMAIL
String getEmailForRole(String uniqueId, String userType) {
  if (userType == 'Student') {
    return '$uniqueId@adab.umpsa.edu.my';
  } else {
    return '$uniqueId@umpsa.edu.my';
  }
}

Future<void> _loginUser() async {
  String idInput = _idController.text.trim().toUpperCase();  // ID
  String password = _passwordController.text.trim();

  if (idInput.isEmpty || password.isEmpty) {
    _showErrorDialog("Please fill in all fields");
    return;
  }

  setState(() => _isLoading = true);

  try {
    // EMAIL CREATE AUTH
    String emailForAuth = getEmailForRole(idInput, _selectedRole);

    // SIGN IN
    UserCredential userCredential = await _auth.signInWithEmailAndPassword(
      email: emailForAuth,
      password: password,
    );

    // QUERY EMAIL
    QuerySnapshot snapshot = await _firestore
        .collection('users')
        .where('email', isEqualTo: emailForAuth)
        .get();

    if (snapshot.docs.isEmpty) {
      _showErrorDialog("User data not found.");
      return;
    }

    DocumentSnapshot userDoc = snapshot.docs.first;
    String userType = userDoc['user_type'];

    // CHECK
    if (_selectedRole != userType) {
      _showErrorDialog("Selected role does not match your account.");
      return;
    }

    // NAV
    Widget nextPage;
    if (userType == 'Student') {
      nextPage = const AppointmentBookPage();
    } else if (userType == 'Doctor') {
      nextPage = const AppointmentBookPageD();
    } else {
      nextPage = const AppointmentBookPageS();
    }
   
   await forceSaveOneSignalIdAfterLogin();
   
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => nextPage));

    }//ERROR HANDLING
     on FirebaseAuthException catch (e) {
      String message = 'Login failed.';
      if (e.code == 'user-not-found' || e.code == 'invalid-email')
        message = 'ID not found. Please register first.';
      else if (e.code == 'wrong-password') message = 'Incorrect password.';
      _showErrorDialog(message);
    } catch (e) {
      _showErrorDialog('Unexpected error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
}


 void _showResetPasswordDialog() {
  final TextEditingController _resetEmailController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_reset_rounded,
                  size: 40, color: Colors.teal),
            ),
            const SizedBox(height: 20),
            const Text(
              'Reset Password',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            const Text(
              'Enter your registered email to reset your password.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _resetEmailController,
              decoration: InputDecoration(
                hintText: 'Enter your email',
                prefixIcon: const Icon(Icons.email_outlined),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  String idInput = _resetEmailController.text.trim();
                  if (idInput.isEmpty) {
                     setState(() {
                    _resetEmailError = "Please enter your email"; //INLINE ERROR
                  });
                    return;
                }
                  try {
                    await FirebaseAuth.instance.sendPasswordResetEmail(email: idInput);

                    if (mounted) {
                    Navigator.pop(context);
                    _showMessageDialog("Reset Link Sent", "Password reset email sent! Check your inbox.");
                  }

                  } on FirebaseAuthException catch (e) {
                    String msg = "Please enter a valid email address.";
                    if (e.code == 'user-not-found') {
                      msg = "User not found.";
                    }
                    _showMessageDialog("Error", msg);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Send Reset Email',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}



  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                child: const Icon(Icons.error_outline_rounded,
                    size: 40, color: Colors.red),
              ),
              const SizedBox(height: 20),
              const Text(
                'Login Failed',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: darkBlue,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryTeal,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('OK',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  void _showMessageDialog(String title, String message) {
  showDialog(
    context: context,
    barrierDismissible: false, 
    builder: (context) => Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                title == "Reset Link Sent" ? Icons.check_circle_outline : Icons.error_outline,
                size: 40,
                color: title == "Reset Link Sent" ? Colors.teal : Colors.red,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'OK',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgCoolGrey,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(4), 
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryTeal.withOpacity(0.2),
                          blurRadius: 25,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),
                  
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/logo.jpg', 
                        width: 100, 
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                const Center(
                  child: Text(
                    'UMPSA Care',
                    style: TextStyle(
                      color: darkBlue,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Center(
                  child: Text(
                    'Welcome back, please login.',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                const Text('User ID',
                    style: TextStyle(
                        color: darkBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                const SizedBox(height: 8),
                _buildShadowTextField(
                  controller: _idController,
                  hint: 'Enter your ID',
                  icon: Icons.badge_outlined, 
                  inputType: TextInputType.text,
                ),
                const SizedBox(height: 20),

                const Text('Password',
                    style: TextStyle(
                        color: darkBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                const SizedBox(height: 8),
                _buildShadowTextField(
                  controller: _passwordController,
                  hint: 'Enter your password',
                  icon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.grey,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _showResetPasswordDialog(),
                    child: Text(
                      "Forgot Password?",
                      style: TextStyle(
                        color: primaryTeal.withOpacity(0.8),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10), 

                // DROPDOWN
                const Text('I am a',
                    style: TextStyle(
                        color: darkBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
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
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedRole,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded,
                          color: primaryTeal),
                      style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 15,
                          fontWeight: FontWeight.w600),
                      dropdownColor: Colors.white,
                      items: const [
                        DropdownMenuItem(
                            value: 'Student',
                            child: Center(child: Text('Student'))),
                        DropdownMenuItem(
                            value: 'Doctor',
                            child: Center(child: Text('Doctor'))),
                        DropdownMenuItem(
                            value: 'PKU Staff',
                            child: Center(child: Text('PKU Staff'))),
                      ],
                      onChanged: (value) =>
                          setState(() => _selectedRole = value!),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // SIGN IN
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryTeal,
                      foregroundColor: Colors.white,
                      elevation: 8,
                      shadowColor: primaryTeal.withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isLoading ? null : _loginUser,
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // SIGN UP
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account? ",
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SignUpPage()),
                        );
                      },
                      child: const Text(
                        "Sign Up",
                        style: TextStyle(
                          color: primaryTeal,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShadowTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? inputType,
  }) {
    return Container(
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
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: inputType,
        style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          prefixIcon: Icon(icon, color: Colors.grey[400], size: 22),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}

// ignore_for_file: unused_field, unused_local_variable