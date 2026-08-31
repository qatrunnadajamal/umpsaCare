import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/medicine.dart';

final List<Medicine> defaultMedicines = [
  Medicine(medId: '', medName: 'Paracetamol', medType: 'Tablet', medUnit: '500mg'),
  Medicine(medId: '', medName: 'Amoxicillin', medType: 'Capsule', medUnit: '250mg'),
  Medicine(medId: '', medName: 'Ibuprofen', medType: 'Tablet', medUnit: '200mg'),
  Medicine(medId: '', medName: 'Cetirizine', medType: 'Tablet', medUnit: '10mg'),
  Medicine(medId: '', medName: 'Loratadine', medType: 'Tablet', medUnit: '10mg'),
  Medicine(medId: '', medName: 'Ranitidine', medType: 'Tablet', medUnit: '150mg'),
  Medicine(medId: '', medName: 'Omeprazole', medType: 'Capsule', medUnit: '20mg'),
  Medicine(medId: '', medName: 'Metformin', medType: 'Tablet', medUnit: '500mg'),
  Medicine(medId: '', medName: 'Aspirin', medType: 'Tablet', medUnit: '100mg'),
  Medicine(medId: '', medName: 'Dextromethorphan', medType: 'Syrup', medUnit: '15mg/5ml'),
  Medicine(medId: '', medName: 'Salbutamol', medType: 'Inhaler', medUnit: '100mcg'),
  Medicine(medId: '', medName: 'Hydrocortisone', medType: 'Cream', medUnit: '1%'),
  Medicine(medId: '', medName: 'Betadine', medType: 'Solution', medUnit: '10ml'),
  Medicine(medId: '', medName: 'Chlorpheniramine', medType: 'Tablet', medUnit: '4mg'),
  Medicine(medId: '', medName: 'Diphenhydramine', medType: 'Capsule', medUnit: '25mg'),
  Medicine(medId: '', medName: 'Prednisolone', medType: 'Tablet', medUnit: '5mg'),
  Medicine(medId: '', medName: 'Diclofenac', medType: 'Tablet', medUnit: '50mg'),
  Medicine(medId: '', medName: 'Cefuroxime', medType: 'Tablet', medUnit: '250mg'),
  Medicine(medId: '', medName: 'Azithromycin', medType: 'Tablet', medUnit: '250mg'),
  Medicine(medId: '', medName: 'Mefenamic Acid', medType: 'Capsule', medUnit: '500mg'),
  Medicine(medId: '', medName: 'Naproxen', medType: 'Tablet', medUnit: '250mg'),
  Medicine(medId: '', medName: 'Metronidazole', medType: 'Tablet', medUnit: '400mg'),
  Medicine(medId: '', medName: 'Cough Drops', medType: 'Lozenge', medUnit: '10mg'),
  Medicine(medId: '', medName: 'Loperamide', medType: 'Capsule', medUnit: '2mg'),
  Medicine(medId: '', medName: 'Oral Rehydration Salt', medType: 'Powder', medUnit: '1 sachet'),
  Medicine(medId: '', medName: 'Fexofenadine', medType: 'Tablet', medUnit: '120mg'),
  Medicine(medId: '', medName: 'Clarithromycin', medType: 'Tablet', medUnit: '500mg'),
  Medicine(medId: '', medName: 'Fluconazole', medType: 'Tablet', medUnit: '150mg'),
  Medicine(medId: '', medName: 'Vitamin C', medType: 'Tablet', medUnit: '500mg'),
  Medicine(medId: '', medName: 'Multivitamins', medType: 'Tablet', medUnit: '1 daily'),
  Medicine(medId: '', medName: 'Saline Nasal Spray', medType: 'Spray', medUnit: '50ml'),
  Medicine(medId: '', medName: 'Hydroxyzine', medType: 'Tablet', medUnit: '25mg'),
  Medicine(medId: '', medName: 'Clindamycin', medType: 'Capsule', medUnit: '150mg'),
  Medicine(medId: '', medName: 'Topical Antiseptic', medType: 'Ointment', medUnit: '5g'),
  Medicine(medId: '', medName: 'Acyclovir', medType: 'Cream', medUnit: '5%'),
  Medicine(medId: '', medName: 'Salbutamol Syrup', medType: 'Syrup', medUnit: '2mg/5ml'),
  Medicine(medId: '', medName: 'Diphenhydramine Syrup', medType: 'Syrup', medUnit: '12.5mg/5ml'),
  Medicine(medId: '', medName: 'Epinephrine Auto-injector', medType: 'Injection', medUnit: '0.3mg'),
  Medicine(medId: '', medName: 'Insulin', medType: 'Injection', medUnit: '10ml'),
  Medicine(medId: '', medName: 'Glucose Gel', medType: 'Gel', medUnit: '15g'),
];

Future<void> seedMedicines() async {
  final CollectionReference medicinesCollection =
      FirebaseFirestore.instance.collection('medicines');

  for (var medicine in defaultMedicines) {
    await medicinesCollection.add(medicine.toMap());
  }

  print('Medicines seeded successfully!');
}
