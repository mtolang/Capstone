import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

/// Test script to create a contract booking
/// Run this to add a sample recurring contract booking to the database
void main() async {
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  print('🔥 Firebase initialized');

  // Get your clinic ID (replace with your actual clinic ID)
  print('Enter your clinic ID:');
  // For now, we'll use a placeholder - update this with your actual clinic ID
  final clinicId = 'YOUR_CLINIC_ID_HERE';

  // Create a test contract booking
  final contractBooking = {
    'bookingProcessType': 'contract', // This is the key field!
    'dayOfWeek':
        'Monday', // Can be: Monday, Tuesday, Wednesday, Thursday, Friday, Saturday, Sunday
    'appointmentTime': '10:00 - 11:00',
    'appointmentType': 'Occupational Therapy Session',
    'clinicId': clinicId,
    'status': 'confirmed',

    // Patient info
    'patientInfo': {
      'childName': 'Test Child',
      'parentName': 'Test Parent',
      'age': 5,
    },
    'childName': 'Test Child',
    'parentName': 'Test Parent',

    // Contract dates
    'contractStartDate': Timestamp.fromDate(DateTime.now()),
    'contractEndDate': null, // null means ongoing indefinitely

    // Other details
    'appointmentDetails': 'Weekly recurring occupational therapy session',
    'createdAt': Timestamp.now(),
  };

  try {
    // Add to AcceptedBooking collection
    final docRef = await FirebaseFirestore.instance
        .collection('AcceptedBooking')
        .add(contractBooking);

    print('✅ Contract booking created successfully!');
    print('📋 Document ID: ${docRef.id}');
    print('📅 Day: ${contractBooking['dayOfWeek']}');
    print('⏰ Time: ${contractBooking['appointmentTime']}');
    print('👤 Patient: ${contractBooking['childName']}');
    print('');
    print(
        'This booking will now appear on every ${contractBooking['dayOfWeek']} in the calendar!');
  } catch (e) {
    print('❌ Error creating contract booking: $e');
  }
}
