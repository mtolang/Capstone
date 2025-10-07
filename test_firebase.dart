import 'package:cloud_firestore/cloud_firestore.dart';

// Simple test to verify Firebase collections exist
void main() async {
  final firestore = FirebaseFirestore.instance;
  
  // Test collections
  final collections = ['ParentsReg', 'ParentsAcc', 'ClinicReg', 'ClinicAcc', 'TherapistReg', 'TherapistAcc'];
  
  for (String collection in collections) {
    try {
      final snapshot = await firestore.collection(collection).limit(1).get();
      print('✅ $collection collection accessible - ${snapshot.docs.length} documents found');
    } catch (e) {
      print('❌ Error accessing $collection: $e');
    }
  }
}