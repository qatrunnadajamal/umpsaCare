import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/medicine.dart';

class MedicineController {
  final CollectionReference _medicinesCollection =
      FirebaseFirestore.instance.collection('medicines');

  //LOGIC SEARCH 
  Future<List<Medicine>> getAllMedicines() async {
    try {
      QuerySnapshot snapshot = await _medicinesCollection.get();
      return snapshot.docs
          .map((doc) => Medicine.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print("Error fetching medicines: $e");
      return [];
    }
  }
}
