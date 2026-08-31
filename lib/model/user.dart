// lib/model/user.dart

class UserModel {
  final String userId;
  final String fullName;
  final String email;
  final String password;
  final String phoneNumber;
  final String gender;
  final String dob;
  final String userType;
  final String? photoUrl;
  final String uid;
  final String? oneSignalId;

  UserModel({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.password,
    required this.phoneNumber,
    required this.gender,
    required this.dob,
    required this.userType,
    this.photoUrl,
    required this.uid,
    this.oneSignalId,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'full_name': fullName,
      'email': email,
      'password': password,
      'phone_number': phoneNumber,
      'gender': gender,
      'DOB': dob,
      'user_type': userType,
      'photo_url': photoUrl ?? '',
      if (oneSignalId != null) 'onesignal_id': oneSignalId,
      'timestamp': DateTime.now(),
    };
  }
}

// SUB

class StudentModel {
  final String studentId;
  final String userId;
  final String faculty;
  final String matricNo;
  final String advisor;

  StudentModel({
    required this.studentId,
    required this.userId,
    required this.faculty,
    required this.matricNo,
    required this.advisor,
  });

  Map<String, dynamic> toJson() {
    return {
      'student_id': studentId,
      'user_id': userId,
      'faculty': faculty,
      'matric_no': matricNo,
      'advisor': advisor,
    };
  }
}

class DoctorModel {
  final String doctorId;
  final String userId;
  final String staffId; 
  final String grade;
  final String specialization;
   final String campus;

  DoctorModel({
    required this.doctorId,
    required this.userId,
    required this.staffId,
    required this.grade,
    required this.specialization,
    required this.campus,
  });

  Map<String, dynamic> toJson() {
    return {
      'doctor_id': doctorId,
      'user_id': userId,
      'staff_id': staffId,
      'grade': grade,
      'specialization': specialization,
      'campus': campus,
    };
  }
}

class PKUStaffModel {
  final String staffId;
  final String userId;
  final String staffCode;
  final String position;

  PKUStaffModel({
    required this.staffId,
    required this.userId,
    required this.staffCode,
    required this.position,
  });

  Map<String, dynamic> toJson() {
    return {
      'staff_id': staffId,
      'user_id': userId,
      'staff_code': staffCode,
      'position': position,
    };
  }
}