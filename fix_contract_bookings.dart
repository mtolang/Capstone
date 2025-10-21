import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'lib/firebase_options.dart';

/// Fix contract bookings by adding missing dayOfWeek field
/// This script will automatically detect the day from appointmentDate
void main() async {
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  print('🔥 Firebase initialized');
  print('🔧 Fixing contract bookings...\n');

  try {
    // Get all contract bookings
    final snapshot = await FirebaseFirestore.instance
        .collection('AcceptedBooking')
        .where('bookingProcessType', isEqualTo: 'contract')
        .get();

    print('Found ${snapshot.docs.length} contract bookings\n');

    const dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];

    int fixedCount = 0;
    int skippedCount = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data();

      // Check if already has dayOfWeek
      if (data['dayOfWeek'] != null &&
          data['dayOfWeek'].toString().isNotEmpty) {
        print('✅ ${doc.id} - Already has dayOfWeek: ${data['dayOfWeek']}');
        skippedCount++;
        continue;
      }

      // Try to get day from appointmentDate
      String? dayOfWeek;
      dynamic appointmentDate = data['appointmentDate'];

      if (appointmentDate != null) {
        DateTime? date;

        if (appointmentDate is Timestamp) {
          date = appointmentDate.toDate();
        } else if (appointmentDate is String) {
          try {
            date = DateTime.parse(appointmentDate);
          } catch (e) {
            print('❌ ${doc.id} - Error parsing date: $e');
            continue;
          }
        }

        if (date != null) {
          dayOfWeek = dayNames[date.weekday - 1];

          // Update the document
          await FirebaseFirestore.instance
              .collection('AcceptedBooking')
              .doc(doc.id)
              .update({
            'dayOfWeek': dayOfWeek,
          });

          print('✅ Fixed ${doc.id}');
          print('   📅 Added dayOfWeek: $dayOfWeek');
          print('   ⏰ Time: ${data['appointmentTime']}');
          print('   👤 Patient: ${data['childName'] ?? data['patientName']}');
          print('');
          fixedCount++;
        }
      } else {
        print('⚠️  ${doc.id} - No appointmentDate found, skipping');
      }
    }

    print('\n✨ Completed!');
    print('   🔧 Fixed: $fixedCount bookings');
    print('   ⏭️  Skipped: $skippedCount bookings (already had dayOfWeek)');
    print('\nYour contract bookings should now appear on the calendar! 📅');
  } catch (e) {
    print('❌ Error: $e');
  }
}
