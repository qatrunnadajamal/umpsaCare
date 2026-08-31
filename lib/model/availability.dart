
class Availability {
  final String availabilityId;
  final String doctorId;
  final String avDate; 
  final String avTimestamp;
  final int avDuration;
  final String avStatus; //AVAIL,UNAVAIL,BLOCKED
  final String? createdBy; 

  Availability({
    required this.availabilityId,
    required this.doctorId,
    required this.avDate, 
    required this.avTimestamp,
    required this.avDuration,
    required this.avStatus,
    this.createdBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'availability_id': availabilityId, 
      'doctor_id': doctorId,
      'av_date': avDate,
      'av_timestamp': avTimestamp,
      'av_duration': avDuration,
      'av_status': avStatus,
      'created_by': createdBy,
    };
  }

  factory Availability.fromMap(Map<String, dynamic> data) {
    return Availability(
      availabilityId: data['availability_id'] as String, 
      doctorId: data['doctor_id'] as String,
      avDate: data['av_date'] as String,
      avTimestamp: data['av_timestamp'] as String,
      avDuration: data['av_duration'] as int,
      avStatus: data['av_status'] as String,
      createdBy: data['created_by'] as String?,
    );
  }
}
