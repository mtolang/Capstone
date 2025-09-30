import 'package:cloud_firestore/cloud_firestore.dart';

/// Cleanup script to remove problematic old calls from database
/// Run this once to clean up calls created before the fixes
Future<void> cleanupOldCalls() async {
  final firestore = FirebaseFirestore.instance;

  try {
    print('🧹 Starting cleanup of old problematic calls...');

    // Get all calls
    final callsSnapshot = await firestore.collection('Calls').get();

    int totalCalls = callsSnapshot.docs.length;
    int selfCallCount = 0;
    int pendingStatusCount = 0;
    int endedStatusCount = 0;
    int deletedCount = 0;

    print('📊 Found $totalCalls total calls in database');

    for (var doc in callsSnapshot.docs) {
      final data = doc.data();
      final callId = doc.id;
      final status = data['status'] as String?;
      final participants = List<String>.from(data['participants'] ?? []);
      final createdBy = data['createdBy'] as String?;

      bool shouldDelete = false;
      String reason = '';

      // Check for self-calling (same user in participants)
      if (participants.length == 2 && participants[0] == participants[1]) {
        selfCallCount++;
        shouldDelete = true;
        reason += 'self-calling ';
      }

      // Check for old pending status calls (should be 'ringing' now)
      if (status == 'pending') {
        pendingStatusCount++;
        shouldDelete = true;
        reason += 'pending-status ';
      }

      // Also clean up old ended calls to reduce clutter
      if (status == 'ended') {
        endedStatusCount++;
        shouldDelete = true;
        reason += 'ended-cleanup ';
      }

      if (shouldDelete) {
        print('🗑️  Deleting call $callId - Reason: $reason');
        print(
            '   - Status: $status, Participants: $participants, CreatedBy: $createdBy');

        await doc.reference.delete();
        deletedCount++;
      }
    }

    print('\n✅ Cleanup completed!');
    print('📈 Summary:');
    print('   - Total calls found: $totalCalls');
    print('   - Self-calling records: $selfCallCount');
    print('   - Pending status calls: $pendingStatusCount');
    print('   - Ended calls cleaned: $endedStatusCount');
    print('   - Total deleted: $deletedCount');
    print('   - Remaining calls: ${totalCalls - deletedCount}');
  } catch (e) {
    print('❌ Error during cleanup: $e');
  }
}

void main() async {
  await cleanupOldCalls();
}
