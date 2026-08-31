// lib/model/medical.dart
class MedicalInfo {
  String medicalId;
  String studentId;
  String bloodType;
  double? height;
  double? weight;
  List<String> chronicDiseases;
  List<String> allergies;
  List<Map<String, String>> vaccinations; 

  MedicalInfo({
    required this.medicalId,
    required this.studentId,
    required this.bloodType,
    this.height,
    this.weight,
    this.chronicDiseases = const [],
    this.allergies = const [],
    this.vaccinations = const [],
  });

  factory MedicalInfo.fromMap(Map<String, dynamic> data, String id) {
    double parseToDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return MedicalInfo(
      medicalId: id,
      studentId: data['student_id']?.toString() ?? '',
      bloodType: data['blood_type']?.toString() ?? '',
      height: parseToDouble(data['height']),
      weight: parseToDouble(data['weight']),
    
      chronicDiseases: List<String>.from(data['chronic_diseases'] ?? []),
      allergies: List<String>.from(data['allergies'] ?? []),

     
      vaccinations: List<Map<String, String>>.from(
        (data['vaccinations'] as List<dynamic>? ?? []).map((item) {
          final map = item as Map<dynamic, dynamic>;
          return {
            'name': map['name']?.toString() ?? '',
            'date': map['date']?.toString() ?? '',
          };
        }),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'student_id': studentId,
      'blood_type': bloodType,
      'height': height ?? 0.0,
      'weight': weight ?? 0.0,
      'chronic_diseases': chronicDiseases,
      'allergies': allergies,
      'vaccinations': vaccinations,
    };
  }
}