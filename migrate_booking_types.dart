import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'lib/firebase_options.dart';

/// Migration script to add bookingProcessType to existing AcceptedBooking documents
/// This helps identify which bookings should be treated as recurring contracts
void main() async {
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  print('🔥 Firebase initialized');
  print('📋 Starting migration...\n');

  try {
    // Get all accepted bookings
    final snapshot =
        await FirebaseFirestore.instance.collection('AcceptedBooking').get();

    print('Found ${snapshot.docs.length} bookings to check\n');

    int updatedCount = 0;
    int skippedCount = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data();

      // Check if already has bookingProcessType
      if (data.containsKey('bookingProcessType')) {
        print(
            '⏭️  Skipped ${doc.id} - already has bookingProcessType: ${data['bookingProcessType']}');
        skippedCount++;
        continue;
      }

      // Check if this looks like a contract booking
      // (has dayOfWeek or contractStartDate or requestType == 'contract_booking')
      bool isContract = false;
      String bookingProcessType = 'single';

      if (data.containsKey('dayOfWeek') && data['dayOfWeek'] != null) {
        isContract = true;
      }

      if (data.containsKey('contractStartDate') &&
          data['contractStartDate'] != null) {
        isContract = true;
      }

      if (data.containsKey('requestType') &&
          data['requestType'] == 'contract_booking') {
        isContract = true;
      }

      if (isContract) {
        bookingProcessType = 'contract';
      }

      // Update the document
      await FirebaseFirestore.instance
          .collection('AcceptedBooking')
          .doc(doc.id)
          .update({
        'bookingProcessType': bookingProcessType,
      });

      print('✅ Updated ${doc.id}: bookingProcessType = $bookingProcessType');
      if (isContract) {
        print('   📅 Day: ${data['dayOfWeek']}');
        print('   ⏰ Time: ${data['appointmentTime']}');
        print('   👤 Patient: ${data['childName'] ?? data['patientName']}');
      }
      updatedCount++;
    }

    print('\n📊 Migration complete!');
    print('   ✅ Updated: $updatedCount bookings');
    print('   ⏭️  Skipped: $skippedCount bookings (already migrated)');
  } catch (e) {
    print('❌ Error during migration: $e');
  }
}
