import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kindora/services/call_utility.dart';

/// Call History Service
///
/// PURPOSE: Manages call history records in Firebase
/// FEATURES:
/// - Store completed calls in CallHistory collection
/// - Track call outcomes (completed, declined, cancelled, missed)
/// - Store call duration and timestamps
/// - Link to original Calls document
///
/// CALL FLOW INTEGRATION:
/// - Declined calls -> CallHistory with 'declined' status
/// - Cancelled calls -> CallHistory with 'cancelled' status
/// - Completed calls -> CallHistory with 'completed' status and duration
/// - Missed calls -> CallHistory with 'missed' status

class CallHistoryService {
  static final CallHistoryService _instance = CallHistoryService._internal();
  factory CallHistoryService() => _instance;
  CallHistoryService._internal();

  static const String _collectionName = 'CallHistory';

  /// Store a call in history when it ends
  ///
  /// [callId] - Original call document ID from Calls collection
  /// [callerId] - User ID who initiated the call
  /// [recipientId] - User ID who received the call
  /// [callerName] - Display name of caller
  /// [recipientName] - Display name of recipient
  /// [status] - Call outcome: 'completed', 'declined', 'cancelled', 'missed'
  /// [duration] - Call duration in seconds (for completed calls)
  /// [startTime] - When call was initiated
  /// [endTime] - When call ended
  Future<String?> storeCallHistory({
    required String callId,
    required String callerId,
    required String recipientId,
    required String callerName,
    required String recipientName,
    required String status,
    int? duration,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    try {
      CallUtility.log('CallHistoryService',
          'Storing call history - ID: $callId, Status: $status, Duration: ${duration ?? 0}s');

      final historyDoc =
          FirebaseFirestore.instance.collection(_collectionName).doc();

      final historyData = {
        'historyId': historyDoc.id,
        'originalCallId': callId,
        'callerId': callerId,
        'recipientId': recipientId,
        'callerName': callerName,
        'recipientName': recipientName,
        'status': status,
        'duration': duration ?? 0,
        'startTime': startTime ?? DateTime.now(),
        'endTime': endTime ?? DateTime.now(),
        'createdAt': FieldValue.serverTimestamp(),
        'callType': 'video', // Default to video call
      };

      await historyDoc.set(historyData);

      CallUtility.log('CallHistoryService',
          'Call history stored successfully with ID: ${historyDoc.id}');

      return historyDoc.id;
    } catch (e) {
      CallUtility.log('CallHistoryService', 'Error storing call history: $e');
      return null;
    }
  }

  /// Store declined call in history
  Future<String?> storeDeclinedCall({
    required String callId,
    required String callerId,
    required String recipientId,
    required String callerName,
    required String recipientName,
  }) async {
    return await storeCallHistory(
      callId: callId,
      callerId: callerId,
      recipientId: recipientId,
      callerName: callerName,
      recipientName: recipientName,
      status: 'declined',
      startTime: DateTime.now(),
      endTime: DateTime.now(),
    );
  }

  /// Store cancelled call in history (caller cancelled before answer)
  Future<String?> storeCancelledCall({
    required String callId,
    required String callerId,
    required String recipientId,
    required String callerName,
    required String recipientName,
  }) async {
    return await storeCallHistory(
      callId: callId,
      callerId: callerId,
      recipientId: recipientId,
      callerName: callerName,
      recipientName: recipientName,
      status: 'cancelled',
      startTime: DateTime.now(),
      endTime: DateTime.now(),
    );
  }

  /// Store completed call in history with duration
  Future<String?> storeCompletedCall({
    required String callId,
    required String callerId,
    required String recipientId,
    required String callerName,
    required String recipientName,
    required int durationSeconds,
    required DateTime startTime,
  }) async {
    return await storeCallHistory(
      callId: callId,
      callerId: callerId,
      recipientId: recipientId,
      callerName: callerName,
      recipientName: recipientName,
      status: 'completed',
      duration: durationSeconds,
      startTime: startTime,
      endTime: DateTime.now(),
    );
  }

  /// Store missed call in history (recipient didn't answer)
  Future<String?> storeMissedCall({
    required String callId,
    required String callerId,
    required String recipientId,
    required String callerName,
    required String recipientName,
  }) async {
    return await storeCallHistory(
      callId: callId,
      callerId: callerId,
      recipientId: recipientId,
      callerName: callerName,
      recipientName: recipientName,
      status: 'missed',
      startTime: DateTime.now(),
      endTime: DateTime.now(),
    );
  }

  /// Get call history for a specific user
  Future<List<Map<String, dynamic>>> getUserCallHistory(String userId) async {
    try {
      CallUtility.log(
          'CallHistoryService', 'Getting call history for user: $userId');

      final snapshot = await FirebaseFirestore.instance
          .collection(_collectionName)
          .where('callerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      final recipientSnapshot = await FirebaseFirestore.instance
          .collection(_collectionName)
          .where('recipientId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      List<Map<String, dynamic>> history = [];

      // Add calls where user was caller
      for (var doc in snapshot.docs) {
        final data = doc.data();
        data['role'] = 'caller';
        history.add(data);
      }

      // Add calls where user was recipient
      for (var doc in recipientSnapshot.docs) {
        final data = doc.data();
        data['role'] = 'recipient';
        history.add(data);
      }

      // Sort by creation time
      history.sort((a, b) {
        final aTime =
            (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        final bTime =
            (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        return bTime.compareTo(aTime);
      });

      CallUtility.log(
          'CallHistoryService', 'Found ${history.length} call history records');
      return history;
    } catch (e) {
      CallUtility.log('CallHistoryService', 'Error getting call history: $e');
      return [];
    }
  }

  /// Clean up old call history records (optional)
  Future<void> cleanupOldHistory({int daysToKeep = 30}) async {
    try {
      CallUtility.log('CallHistoryService',
          'Cleaning up call history older than $daysToKeep days');

      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));

      final snapshot = await FirebaseFirestore.instance
          .collection(_collectionName)
          .where('createdAt', isLessThan: cutoffDate)
          .get();

      int deletedCount = 0;
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
        deletedCount++;
      }

      CallUtility.log('CallHistoryService',
          'Cleaned up $deletedCount old call history records');
    } catch (e) {
      CallUtility.log(
          'CallHistoryService', 'Error cleaning up call history: $e');
    }
  }

  /// Get call statistics for a user
  Future<Map<String, int>> getCallStatistics(String userId) async {
    try {
      final history = await getUserCallHistory(userId);

      Map<String, int> stats = {
        'total': history.length,
        'completed': 0,
        'declined': 0,
        'cancelled': 0,
        'missed': 0,
      };

      for (var call in history) {
        final status = call['status'] as String? ?? 'unknown';
        if (stats.containsKey(status)) {
          stats[status] = stats[status]! + 1;
        }
      }

      return stats;
    } catch (e) {
      CallUtility.log(
          'CallHistoryService', 'Error getting call statistics: $e');
      return {
        'total': 0,
        'completed': 0,
        'declined': 0,
        'cancelled': 0,
        'missed': 0
      };
    }
  }
}
