class Medicine {
  String medId;
  String medName;
  String medType;
  String medUnit;

  Medicine({
    required this.medId,
    required this.medName,
    required this.medType,
    required this.medUnit,
  });

  factory Medicine.fromMap(Map<String, dynamic> data, String docId) {
    return Medicine(
      medId: data['med_id'] ?? docId,
      medName: data['med_name'] ?? '',
      medType: data['med_type'] ?? '',
      medUnit: data['med_unit'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'med_id': medId,
      'med_name': medName,
      'med_type': medType,
      'med_unit': medUnit,
    };
  }

  @override
  String toString() {
    return "$medName (${medUnit})"; // DROPDWN DISP
  }
}
