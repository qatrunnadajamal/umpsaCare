// lib/controllers/userController.dart
// ignore_for_file: unused_element

import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../model/user.dart' as model;
import '../model/medical.dart';

class UserController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  //CLOUDARY SET UP
  final String cloudName = 'dzxo7jdnk';
  final String uploadPreset = 'flutter_upload';
  
 String getEmailForRole(String uniqueId, String userType) {
  if (userType == 'Student') {
    // STUD EMAIL
    return '$uniqueId@adab.umpsa.edu.my';
  } else {
    // DOC&PKU
    return '$uniqueId@umpsa.edu.my';
  }
}

  // REGISTER
  Future<void> registerUser({
    required String fullName,
    required String email, 
    required String password,
    required String phoneNumber,
    required String gender,
    required String dob,
    required String userType,
    File? profileImage,
    String? faculty,
    String? matricNo, 
    String? staffId,  
    String? advisor,
    String? grade,
    String? specialization,
    String? position,
    String? campus,   
    List<String>? services,
  }) async {
    try {
      String uniqueLoginId = '';
      
      if (userType == 'Student') {
        if (matricNo == null || matricNo.isEmpty) {
          throw Exception("Matric Number is required for Students.");
        }
        uniqueLoginId = matricNo.trim().toUpperCase();
      } else {
        // For Doctors/Staff
        if (staffId == null || staffId.isEmpty) {
          throw Exception("Staff ID is required for $userType.");
        }
        uniqueLoginId = staffId.trim().toUpperCase();
      }
      final existing = await _firestore
          .collection('users')
          .where('id', isEqualTo: uniqueLoginId)
          .get();

      if (existing.docs.isNotEmpty) {
        throw Exception("${userType == 'Student' ? 'Matric No' : 'Staff ID'} already exists.");
      }

      // CREATE SYNTHETIC EMAIL FOR AUTH (ID + Role-based Domain)
      String authEmail = getEmailForRole(uniqueLoginId, userType);


      //CREATE
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: authEmail, 
        password: password,
      );
      
      final uid = userCredential.user!.uid;

      String? photoUrl;
      if (profileImage != null) {
        photoUrl = await _uploadToCloudinary(profileImage, uid);
      }

      // SAVE EMAIL
      final user = model.UserModel(
        userId: uid,
        fullName: fullName,
        email: (userType == 'Student') ? email : authEmail,
        password: password,
        phoneNumber: phoneNumber,
        gender: gender,
        dob: dob,
        userType: userType,
        photoUrl: photoUrl,
        uid: uid,
      );

      await _firestore.collection('users').doc(uid).set(user.toJson());

      //ROLE -DATA
      if (userType == 'Student') {
        await _firestore.collection('students').doc(uid).set({
          'student_id': uid,
          'user_id': uid,
          'faculty': faculty ?? '',
          'matric_no': uniqueLoginId,
          'advisor': advisor ?? '',
        });
      } else if (userType == 'Doctor') {
        await _firestore.collection('doctors').doc(uid).set({
          'doctor_id': uid,
          'user_id': uid,
          'staff_id': uniqueLoginId, 
          'grade': grade ?? '',
          'specialization': specialization ?? '',
          'services': services ?? [],
          'campus': campus ?? '',
        },SetOptions(merge: true));
      } else if (userType == 'PKU Staff') {
        await _firestore.collection('pkustaff').doc(uid).set({
          'staff_id': uid, 
          'user_id': uid,
          'staff_code': uniqueLoginId, 
          'position': position ?? '',
        });
      }

      print("Registration successful for $userType (ID: $uniqueLoginId)");
    } catch (e) {
      print("Error in registration: $e");
      rethrow;
    }
  }

  // UPDATE
  Future<void> updateUser(model.UserModel updatedUser, {File? newProfileImage}) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception("No user logged in");

      if (updatedUser.password.isNotEmpty) {
        await currentUser.updatePassword(updatedUser.password);
      }

      String? photoUrl = updatedUser.photoUrl;
      if (newProfileImage != null) {
        photoUrl = await _uploadToCloudinary(newProfileImage, updatedUser.userId);
      }

      await _firestore.collection('users').doc(updatedUser.userId).update({
        'full_name': updatedUser.fullName,
        'email': updatedUser.email, 
        'password': updatedUser.password,
        'phone_number': updatedUser.phoneNumber,
        'gender': updatedUser.gender,
        'DOB': updatedUser.dob,
        'user_type': updatedUser.userType,
        'photo_url': photoUrl ?? '',
      });

      print("User profile updated successfully");
    } catch (e) {
      print(" Failed to update user profile: $e");
      rethrow;
    }
  }

  // CURRENT
  Future<model.UserModel?> getCurrentUser() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;

    final data = doc.data()!;
    return model.UserModel(
      userId: data['user_id'] ?? '',
      fullName: data['full_name'] ?? '',
      email: data['email'] ?? '',
      password: data['password'] ?? '',
      phoneNumber: data['phone_number'] ?? '',
      gender: data['gender'] ?? '',
      dob: data['DOB'] ?? '',
      userType: data['user_type'] ?? '',
      photoUrl: data['photo_url'],
      uid: uid,
      oneSignalId: data['onesignal_id'] ?? '',

    );
  }

  // ID USER 
  Future<model.UserModel?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;

      final data = doc.data()!;
      return model.UserModel(
        userId: data['user_id'] ?? '',
        fullName: data['full_name'] ?? '',
        email: data['email'] ?? '',
        password: data['password'] ?? '',
        phoneNumber: data['phone_number'] ?? '',
        gender: data['gender'] ?? '',
        dob: data['DOB'] ?? '',
        userType: data['user_type'] ?? '',
        photoUrl: data['photo_url'],
        uid: userId,
        oneSignalId: data['onesignal_id'] ?? '',

      );
    } catch (e) {
      print(' Error fetching user by ID: $e');
      return null;
    }
  }

  // CLOUDINARY UPLOAD 
  Future<String?> _uploadToCloudinary(File file, String uid) async {
    try {
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );

      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = uploadPreset
        ..fields['public_id'] = uid
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();
      final resString = await response.stream.bytesToString();
      final resJson = json.decode(resString);

      if (response.statusCode == 200) {
        return resJson['secure_url'];
      } else {
        print("Cloudinary upload failed: ${resJson['error']}");
        return null;
      }
    } catch (e) {
      print(" Cloudinary exception: $e");
      return null;
    }
  }

  // MEDICAL INFO
  Future<MedicalInfo?> getMedicalInfo(String studentId) async {
    try {
      final snapshot = await _firestore
          .collection('MedicalInfo')
          .where('student_id', isEqualTo: studentId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        return MedicalInfo.fromMap(doc.data(), doc.id);
      }
    } catch (e) {
      print(' Error loading medical info: $e');
    }
    return null;
  }

  Future<void> addMedicalInfo(MedicalInfo medicalInfo) async {
    try {
      await _firestore.collection('MedicalInfo').add(medicalInfo.toMap());
      print('Medical info added successfully');
    } catch (e) {
      print('Error adding medical info: $e');
    }
  }

  Future<void> updateMedicalInfo(String medicalId, Map<String, dynamic> updatedData) async {
    try {
      updatedData['height'] = _convertToDouble(updatedData['height']);
      updatedData['weight'] = _convertToDouble(updatedData['weight']);

      await _firestore.collection('MedicalInfo').doc(medicalId).update(updatedData);
      print(' Medical info updated successfully');
    } catch (e) {
      print('Error updating medical info: $e');
    }
  }

  double _convertToDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

extension on User {
  updateEmail(String email) {}
}