
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../controllers/userController.dart';
import '../../model/user.dart';

class PersonalDetailsForm extends StatefulWidget {
  final bool isEditable;

  const PersonalDetailsForm({super.key, this.isEditable = true});

  @override
  State<PersonalDetailsForm> createState() => _PersonalDetailsFormState();
}

class _PersonalDetailsFormState extends State<PersonalDetailsForm> {
  final UserController _userController = UserController();
  final ImagePicker _picker = ImagePicker();

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController genderController = TextEditingController();
  final TextEditingController dobController = TextEditingController();

  static const Color primaryTeal = Color(0xFF20B2AA);
  // ignore: unused_field
  static const Color accentTeal = Color(0xFFE0F2F1);

  bool _isLoading = true;
  bool _obscurePassword = true;
  String _userId = '';
  String? _photoUrl;
  File? _pickedImage;

  String _userType = 'Student'; 
  final List<String> _userTypes = ['Student', 'Doctor', 'PKU Staff'];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await _userController.getCurrentUser();
    if (user != null) {
      if (mounted) {
        setState(() {
          _userId = user.userId;
          fullNameController.text = user.fullName;
          emailController.text = user.email;
          passwordController.text = user.password;
          phoneController.text = user.phoneNumber;
          genderController.text = user.gender;
          dobController.text = user.dob;
          _photoUrl = user.photoUrl;
          _userType = user.userType;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _updateUser() async {
    if (_userId.isEmpty) return;

    UserModel updatedUser = UserModel(
      userId: _userId,
      fullName: fullNameController.text,
      email: emailController.text,
      password: passwordController.text,
      phoneNumber: phoneController.text,
      gender: genderController.text,
      dob: dobController.text,
      userType: _userType,
      photoUrl: _photoUrl,
      uid: '',
    );

    setState(() => _isLoading = true);

    try {
      await _userController.updateUser(updatedUser,
          newProfileImage: _pickedImage);

      final user = await _userController.getCurrentUser();
      if (mounted) {
        setState(() {
         _photoUrl = user?.photoUrl != null
        ? "${user!.photoUrl}?t=${DateTime.now().millisecondsSinceEpoch}"
        : null;
          _pickedImage = null;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: primaryTeal,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update profile'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isEditable ? "Edit Profile" : "Personal Details",
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryTeal))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 30),
                  _buildFormFields(),
                  const SizedBox(height: 30),
                  if (widget.isEditable) _buildUpdateButton(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  // HEADER
  Widget _buildProfileHeader() {
    return Center(
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: primaryTeal.withOpacity(0.5), width: 2),
            ),
            child: CircleAvatar(
              radius: 55,
              backgroundColor: Colors.grey[200],
              child: ClipOval(
                child: _pickedImage != null
                    ? Image.file(_pickedImage!, fit: BoxFit.cover, width: 110, height: 110)
                    : (_photoUrl != null && _photoUrl!.isNotEmpty)
                        ? Image.network(
                            _photoUrl!,
                            key: ValueKey(_photoUrl),
                            fit: BoxFit.cover,
                            width: 110,
                            height: 110,
                          )
                        : Image.asset(
                            'assets/images/profile_placeholder.jpg',
                            fit: BoxFit.cover,
                            width: 110,
                            height: 110,
                          ),
              ),
            ),
          ),
          if (widget.isEditable)
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 36,
                  width: 36,
                  decoration: BoxDecoration(
                    color: primaryTeal,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 5,
                      )
                    ],
                  ),
                  child: const Icon(Icons.camera_alt,
                      color: Colors.white, size: 18),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // FORM
  Widget _buildFormFields() {
    return Column(
      children: [
        _buildTextField("Full Name", fullNameController, Icons.person_outline),
        const SizedBox(height: 16),
        _buildTextField("Email Address", emailController, Icons.email_outlined,
            keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 16),
        _buildTextField("Phone Number", phoneController, Icons.phone_outlined,
            keyboardType: TextInputType.phone),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
                child: _buildTextField(
                    "Gender", genderController, Icons.wc_outlined)),
            const SizedBox(width: 16),
            Expanded(
                child: _buildTextField("Date of Birth", dobController,
                    Icons.calendar_today_outlined)),
          ],
        ),
        const SizedBox(height: 16),
        _buildUserTypeDropdown(),
        const SizedBox(height: 16),
        _buildPasswordField(),
      ],
    );
  }


  Widget _buildTextField(
      String label, TextEditingController controller, IconData icon,
      {TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      enabled: widget.isEditable,
      keyboardType: keyboardType,
      style: TextStyle(
        color: widget.isEditable ? Colors.black87 : Colors.grey[700],
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey[600], size: 22),
        filled: true,
        fillColor: widget.isEditable ? Colors.grey[50] : Colors.grey[100],
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryTeal, width: 1.5),
        ),
      ),
    );
  }

  // PASS
  Widget _buildPasswordField() {
    return TextFormField(
      controller: passwordController,
      obscureText: _obscurePassword,
      enabled: widget.isEditable,
      style: TextStyle(
          color: widget.isEditable ? Colors.black87 : Colors.grey[700]),
      decoration: InputDecoration(
        labelText: "Password",
        prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[600], size: 22),
        suffixIcon: widget.isEditable
            ? IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.grey[600],
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              )
            : null,
        filled: true,
        fillColor: widget.isEditable ? Colors.grey[50] : Colors.grey[100],
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryTeal, width: 1.5),
        ),
      ),
    );
  }

  // DROPDOWN
  Widget _buildUserTypeDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: widget.isEditable ? Colors.grey[50] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: widget.isEditable ? Colors.grey[200]! : Colors.transparent),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(Icons.badge_outlined, color: Colors.grey[600], size: 22),
          ),
          Expanded(
            child: widget.isEditable
                ? DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _userType,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                      style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.w500),
                      items: _userTypes.map((type) {
                        return DropdownMenuItem(value: type, child: Text(type));
                      }).toList(),
                      onChanged: (val) => setState(() => _userType = val!),
                    ),
                  )
                : Text(
                    _userType,
                    style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 16,
                        fontWeight: FontWeight.w500),
                  ),
          ),
        ],
      ),
    );
  }

  // BUTTON UPDOWN
  Widget _buildUpdateButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _updateUser,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTeal,
          elevation: 2,
          shadowColor: primaryTeal.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          "Update Profile",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}