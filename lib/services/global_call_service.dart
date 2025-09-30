/*
 * GlobalCallService - Enhanced with Navigator Key Pattern
 * 
 * ✅ Fix 1: Navigator Key Pattern - Replaced BuildContext management with GlobalKey<NavigatorState>
 * ✅ Fix 2: Retry Logic - Added _startListeningWithRetry() for user ID availability
 * ✅ Fix 3: Permission Handling - Enhanced permission requests during initialization  
 * ✅ Fix 4: Initialization - Improved initialization reliability with navigator key
 * ✅ Fix 5: Error Handling - Added comprehensive error handling with fallback alerts
 * ✅ Fix 6: Debug Status - Added getDebugStatus() and getPermissionStatus() methods
 * 
 * Additional: Added reinitialize() method for service recovery
 */

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:capstone_2/chat/calling.dart'; // IncomingCallScreen
import 'package:capstone_2/chat/caller_screen.dart'; // CallerScreen
import 'package:capstone_2/chat/chat_call.dart';
import 'package:capstone_2/services/call_utility.dart';
import 'package:capstone_2/services/dynamic_user_service.dart';
import 'package:capstone_2/services/call_history_service.dart';

/// Global Call Pop-up Service
///
/// PURPOSE: Advanced global call management with pop-up functionality
/// FEATURES:
/// - Global call listening across entire app
/// - Invitation system (pending/accepted/declined)
/// - Prevents duplicate call pop-ups
/// - Auto-fetches caller names from Firebase
/// - WebRTC peer connection support
/// - Shows CallingScreen directly as overlay
///
/// USE WHEN: You need advanced call management with global scope

class GlobalCallService {
  static final GlobalCallService _instance = GlobalCallService._internal();
  factory GlobalCallService() => _instance;
  GlobalCallService._internal();

  StreamSubscription<QuerySnapshot>? _callSubscription;
  GlobalKey<NavigatorState>? _navigatorKey;
  String? _currentUserId;
  bool _isListening = false;
  Set<String> _shownCallIds = {}; // Track shown calls to prevent duplicates
  Map<String, Timer> _callTimeouts =
      {}; // Track call timeouts for missed call handling

  void initialize(GlobalKey<NavigatorState> navigatorKey) async {
    CallUtility.log('GlobalCallService', '🚀 Initializing GlobalCallService');
    _navigatorKey = navigatorKey;

    // Request permissions during initialization
    await _requestInitialPermissions();

    // Start listening with retry logic
    WidgetsBinding.instance.addPostFrameCallback((_) {
      CallUtility.log(
          'GlobalCallService', '📋 Starting listener after frame callback');
      _startListeningWithRetry();
    });
  }

  Future<void> _requestInitialPermissions() async {
    try {
      CallUtility.log('GlobalCallService', '🔐 Requesting initial permissions');

      if (Platform.isAndroid) {
        final overlayPermission = await Permission.systemAlertWindow.status;
        CallUtility.log('GlobalCallService',
            '🔐 System overlay permission status: $overlayPermission');

        if (!overlayPermission.isGranted) {
          CallUtility.log('GlobalCallService',
              '⚠️ System overlay permission not granted - requesting');
          final result = await Permission.systemAlertWindow.request();
          CallUtility.log(
              'GlobalCallService', '🔐 Permission request result: $result');
        } else {
          CallUtility.log('GlobalCallService',
              '✅ System overlay permission already granted');
        }
      }
    } catch (e) {
      CallUtility.log(
          'GlobalCallService', '❌ Error requesting permissions: $e');
    }
  }

  Future<String?> _getCurrentUserId() async {
    if (_currentUserId != null) {
      return _currentUserId;
    }

    final userId = await DynamicUserService.getCurrentUserId();
    if (userId != null) {
      _currentUserId = userId;
    }
    return userId;
  }

  Future<void> _startListeningWithRetry() async {
    CallUtility.log(
        'GlobalCallService', '🔄 Starting listener with retry logic');

    for (int attempt = 1; attempt <= 5; attempt++) {
      CallUtility.log(
          'GlobalCallService', '🔍 Attempt $attempt/5: Getting user ID');

      final userId = await _getCurrentUserId();
      if (userId != null) {
        CallUtility.log('GlobalCallService', '✅ User ID found: $userId');
        _startListening();
        return;
      }

      CallUtility.log('GlobalCallService',
          '⏳ Attempt $attempt failed, retrying in 1 second');
      await Future.delayed(Duration(seconds: 1));
    }

    CallUtility.log(
        'GlobalCallService', '❌ Failed to get user ID after 5 attempts');
  }

  void _startListening() async {
    if (_isListening) return;

    final userId = await _getCurrentUserId();
    if (userId == null) {
      return;
    }

    _isListening = true;

    _callSubscription = FirebaseFirestore.instance
        .collection('Calls')
        .where('participants', arrayContains: userId)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added ||
            change.type == DocumentChangeType.modified) {
          final callData = change.doc.data() as Map<String, dynamic>;
          final callId = change.doc.id;
          final createdBy = callData['createdBy'] as String?;
          final callStatus = callData['status'] as String?;
          final participants =
              List<String>.from(callData['participants'] ?? []);

          CallUtility.log('GlobalCallService',
              'Processing call: $callId, status: $callStatus, createdBy: $createdBy, participants: $participants, changeType: ${change.type.name}');

          // Handle different call status changes
          if (callStatus == 'active' && createdBy == userId) {
            // Call was accepted - caller should navigate to call screen
            CallUtility.log('GlobalCallService',
                'Call $callId accepted - navigating caller to call screen');
            _navigateToCallScreen(callId, userId, participants);
            continue;
          }

          // Only process incoming ringing calls for non-creators
          if (callStatus != 'ringing' || createdBy == userId) {
            CallUtility.log('GlobalCallService',
                'Skipping call $callId - not ringing (status: $callStatus) or user is creator');
            continue;
          }

          final invitations =
              callData['invitations'] as Map<String, dynamic>? ?? {};

          // Check if this user has a pending invitation
          if (invitations.containsKey(userId)) {
            final invitation = invitations[userId] as Map<String, dynamic>;
            final invitationStatus = invitation['status'];
            final invitedBy = invitation['invitedBy'] as String?;

            CallUtility.log('GlobalCallService',
                'User $userId has invitation with status: $invitationStatus, invited by: $invitedBy');

            // Only show incoming call if validation passes and not shown already
            if (invitationStatus == 'pending' &&
                CallUtility.shouldShowCall(
                  currentUserId: userId,
                  callerId: invitedBy ?? createdBy ?? '',
                  createdBy: createdBy,
                ) &&
                !_shownCallIds.contains(callId)) {
              CallUtility.log('GlobalCallService',
                  'All conditions met - showing call UI for call $callId');
              _shownCallIds.add(callId);

              // Set up timeout for missed call handling (30 seconds)
              _callTimeouts[callId] = Timer(Duration(seconds: 30), () {
                CallUtility.log('GlobalCallService',
                    'Call $callId timed out - handling as missed call');
                handleMissedCall(callId);
              });

              _getCallerNameAndShowCall(callId, invitedBy ?? createdBy!);
            } else {
              CallUtility.log('GlobalCallService',
                  'Call blocked - Status: $invitationStatus, CallId already shown: ${_shownCallIds.contains(callId)}, Shown IDs: $_shownCallIds');
            }
          }
        }
      }
    }, onError: (error) {
      CallUtility.log('GlobalCallService', 'Error listening for calls: $error');
    });
  }

  Future<void> _navigateToCallScreen(
      String callId, String currentUserId, List<String> participants) async {
    final currentContext = _navigatorKey?.currentContext;
    if (currentContext == null || !currentContext.mounted) return;

    try {
      // Close any existing caller screen dialog
      if (Navigator.of(currentContext).canPop()) {
        Navigator.of(currentContext).pop();
      }

      // Navigate to actual call screen
      await Navigator.of(currentContext).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ChatCallScreen(
            callId: callId,
            currentUserId: currentUserId,
            initialParticipants: participants,
          ),
        ),
      );

      CallUtility.log('GlobalCallService',
          'Successfully navigated to call screen for call: $callId');
    } catch (e) {
      CallUtility.log(
          'GlobalCallService', 'Error navigating to call screen: $e');
    }
  }

  Future<void> _getCallerNameAndShowCall(
      String callId, String createdBy) async {
    CallUtility.log('GlobalCallService',
        'Getting caller name for call $callId, created by: $createdBy');
    try {
      // Get caller name
      String callerName = 'Unknown Caller';

      // Try to get from ClinicAcc first
      final clinicDoc = await FirebaseFirestore.instance
          .collection('ClinicAcc')
          .doc(createdBy)
          .get();

      if (clinicDoc.exists) {
        callerName = clinicDoc.data()?['Clinic Name'] ?? 'Clinic';
      } else {
        // Try ParentsAcc
        final parentDoc = await FirebaseFirestore.instance
            .collection('ParentsAcc')
            .doc(createdBy)
            .get();

        if (parentDoc.exists) {
          callerName = parentDoc.data()?['Name'] ?? 'Parent';
        }
      }

      _showIncomingCall(callId, createdBy, callerName);
    } catch (e) {
      CallUtility.log('GlobalCallService', 'Error getting caller name: $e');
      _showIncomingCall(callId, createdBy, 'Unknown Caller');
    }
  }

  void _showIncomingCall(
      String callDocId, String callerId, String callerName) async {
    CallUtility.log('GlobalCallService', 'Attempting to show incoming call UI');
    final currentContext = _navigatorKey?.currentContext;
    CallUtility.log(
        'GlobalCallService', 'Context available: ${currentContext != null}');
    CallUtility.log('GlobalCallService', 'Current user ID: $_currentUserId');
    CallUtility.log('GlobalCallService', 'Call ID: $callDocId');
    CallUtility.log('GlobalCallService', 'Caller ID: $callerId');
    CallUtility.log('GlobalCallService', 'Caller Name: $callerName');

    if (currentContext == null) {
      CallUtility.log(
          'GlobalCallService', 'ERROR: No context available to show call UI');
      return;
    }

    if (_currentUserId == null) {
      CallUtility.log(
          'GlobalCallService', 'ERROR: No current user ID available');
      return;
    }

    CallUtility.log(
        'GlobalCallService', 'Showing incoming call overlay for $callerName');

    try {
      // Check overlay permission on Android before showing dialog
      if (Platform.isAndroid) {
        final overlayPermission = await Permission.systemAlertWindow.status;
        if (!overlayPermission.isGranted) {
          CallUtility.log('GlobalCallService',
              'System alert window permission not granted, requesting...');

          // Reduced delay for faster UI response
          await Future.delayed(Duration(milliseconds: 50));

          try {
            final result = await Permission.systemAlertWindow.request();
            if (!result.isGranted) {
              CallUtility.log('GlobalCallService',
                  'System alert window permission denied - using regular dialog');
            }
          } catch (permissionError) {
            CallUtility.log('GlobalCallService',
                'Permission request failed: $permissionError - continuing with dialog');
          }
        }
      }

      // Check if context is still valid before showing dialog
      if (!currentContext.mounted) {
        CallUtility.log('GlobalCallService',
            'Context is no longer mounted, attempting to get fresh context');

        // Try to get a fresh context from navigator key
        final freshContext = _navigatorKey?.currentContext;
        if (freshContext == null || !freshContext.mounted) {
          CallUtility.log('GlobalCallService',
              'No valid context available, cannot show call UI');
          return;
        }

        // Use fresh context for dialog
        _showDialogWithContext(freshContext, callDocId, callerName, callerId);
        return;
      }

      // Use current context for dialog
      _showDialogWithContext(currentContext, callDocId, callerName, callerId);
    } catch (e, stackTrace) {
      CallUtility.log('GlobalCallService', 'ERROR in _showIncomingCall: $e');
      CallUtility.log('GlobalCallService', 'Stack trace: $stackTrace');
    }
  }

  void _showDialogWithContext(BuildContext context, String callDocId,
      String callerName, String callerId) {
    try {
      // Show incoming call as an overlay on top of current page with fast rendering
      showDialog(
        context: context,
        barrierDismissible: false, // Cannot dismiss by tapping outside
        barrierColor:
            Colors.black.withOpacity(0.6), // Lighter for faster rendering
        builder: (context) => PopScope(
          canPop: false, // Prevent back button dismiss
          child: IncomingCallScreen(
            callDocId: callDocId,
            callerId: callerId,
            callerName: callerName,
            currentUserId: _currentUserId!,
          ),
        ),
      );

      CallUtility.log('GlobalCallService', 'Call UI dialog shown successfully');
    } catch (e, stackTrace) {
      CallUtility.log('GlobalCallService', 'ERROR showing call UI: $e');
      CallUtility.log('GlobalCallService', 'Stack trace: $stackTrace');

      // Attempt to show a simple alert as fallback
      try {
        if (!context.mounted) return;

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Incoming Call'),
            content: Text('Call from $callerName'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Dismiss'),
              ),
            ],
          ),
        );
        CallUtility.log('GlobalCallService', 'Fallback alert shown');
      } catch (fallbackError) {
        CallUtility.log(
            'GlobalCallService', 'Fallback alert also failed: $fallbackError');
      }
    }
  }

  void stopListening() {
    CallUtility.log('GlobalCallService', 'Stopping call listener');
    _callSubscription?.cancel();
    _callSubscription = null;
    _isListening = false;
  }

  void updateContext(BuildContext context) {
    // Context updates are now handled through navigator key
    // This method is kept for backward compatibility but does nothing
    CallUtility.log('GlobalCallService',
        'updateContext called - using navigator key instead');
  }

  void removeShownCallId(String callId) {
    _shownCallIds.remove(callId);
    // Also clean up timeout timer
    _callTimeouts[callId]?.cancel();
    _callTimeouts.remove(callId);
  }

  // Method to initiate a call with peer connection data
  Future<String?> initiateCall({
    required String targetUserId,
    required Map<String, dynamic> peerConnectionConfig,
    BuildContext?
        context, // Optional context for immediate caller screen display
  }) async {
    final currentUserId = await DynamicUserService.getCurrentUserId();
    if (currentUserId == null) {
      CallUtility.log(
          'GlobalCallService', 'Cannot initiate call - no current user');
      return null;
    }

    try {
      // Get target user info BEFORE async operations to avoid context issues
      final targetUserInfo =
          await DynamicUserService.getTargetUserInfo(targetUserId);
      final targetUserName = targetUserInfo?['name'] ?? 'Unknown User';

      // Validate target user exists
      if (targetUserInfo == null) {
        CallUtility.log(
            'GlobalCallService', 'Target user $targetUserId not found');
        return null;
      }

      // Use provided context or fallback to navigator key context
      final currentContext = context ?? _navigatorKey?.currentContext;
      if (currentContext == null) {
        CallUtility.log('GlobalCallService',
            'No context available for showing caller screen');
        return null;
      }

      // Create a new call document
      final callDoc = FirebaseFirestore.instance.collection('Calls').doc();
      final callId = callDoc.id;

      // Show caller screen IMMEDIATELY after getting call ID
      // to avoid context disposal issues
      if (currentContext.mounted) {
        CallerScreen.show(
          context: currentContext,
          callDocId: callId,
          targetUserId: targetUserId,
          targetUserName: targetUserName,
          currentUserId: currentUserId,
        );
        CallUtility.log('GlobalCallService',
            'Caller screen shown immediately with call ID: $callId');
      } else {
        CallUtility.log('GlobalCallService',
            'Context not mounted, cannot show caller screen');
        return null;
      }

      await callDoc.set({
        'callId': callId,
        'createdBy': currentUserId,
        'participants': [currentUserId, targetUserId],
        'status': 'ringing',
        'callType': 'video',
        'timestamp': FieldValue.serverTimestamp(),
        'invitations': {
          targetUserId: {
            'status': 'pending',
            'invitedAt': FieldValue.serverTimestamp(),
            'invitedBy': currentUserId,
          }
        },
        'peerConnectionConfig': peerConnectionConfig,
        'offers': {},
        'answers': {},
        'iceCandidates': [],
      });

      CallUtility.log('GlobalCallService', 'Call initiated with ID: $callId');

      // Caller screen was already shown immediately above
      // No need to show again here to avoid context issues

      return callId;
    } catch (e) {
      CallUtility.log('GlobalCallService', 'Error initiating call: $e');
      return null;
    }
  }

  // Method to accept a call and navigate to chat call screen
  Future<void> acceptCall(String callId) async {
    final currentContext = _navigatorKey?.currentContext;
    if (currentContext == null) return;

    try {
      final currentUserId = await _getCurrentUserId();
      if (currentUserId == null) return;

      // Cancel timeout timer since call is being accepted
      _callTimeouts[callId]?.cancel();
      _callTimeouts.remove(callId);

      // Navigate immediately for faster user experience
      if (currentContext.mounted) {
        Navigator.of(currentContext).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ChatCallScreen(
              callId: callId,
              currentUserId: currentUserId,
              initialParticipants: [], // Joining existing call
            ),
          ),
        );
      }

      // Update invitation status to accepted in background
      FirebaseFirestore.instance.collection('Calls').doc(callId).update({
        'invitations.$currentUserId.status': 'accepted',
        'status': 'active',
        'acceptedAt': FieldValue.serverTimestamp(),
      }).catchError((error) {
        CallUtility.log(
            'GlobalCallService', 'Background update failed: $error');
      });
    } catch (e) {
      CallUtility.log('GlobalCallService', 'Error accepting call: $e');
    }
  }

  // Method to decline a call and store in CallHistory
  Future<void> declineCall(String callId) async {
    try {
      final currentUserId = await _getCurrentUserId();
      if (currentUserId == null) return;

      CallUtility.log('GlobalCallService', 'Declining call: $callId');

      // Cancel timeout timer since call is being declined
      _callTimeouts[callId]?.cancel();
      _callTimeouts.remove(callId);

      // Get call data for history storage
      final callDoc = await FirebaseFirestore.instance
          .collection('Calls')
          .doc(callId)
          .get();

      if (callDoc.exists) {
        final callData = callDoc.data()!;
        final callerId = callData['createdBy'] as String;

        // Get user names for history
        final callerInfo = await DynamicUserService.getTargetUserInfo(callerId);
        final recipientInfo =
            await DynamicUserService.getTargetUserInfo(currentUserId);

        final callerName = callerInfo?['name'] ?? 'Unknown Caller';
        final recipientName = recipientInfo?['name'] ?? 'Unknown User';

        // Store declined call in history
        await CallHistoryService().storeDeclinedCall(
          callId: callId,
          callerId: callerId,
          recipientId: currentUserId,
          callerName: callerName,
          recipientName: recipientName,
        );

        CallUtility.log(
            'GlobalCallService', 'Call declined and stored in history');
      }

      // Update call status to declined
      await FirebaseFirestore.instance.collection('Calls').doc(callId).update({
        'invitations.$currentUserId.status': 'declined',
        'status': 'declined',
        'declinedAt': FieldValue.serverTimestamp(),
      });

      removeShownCallId(callId);
    } catch (e) {
      CallUtility.log('GlobalCallService', 'Error declining call: $e');
    }
  }

  // Method to cancel a call (caller cancels before recipient answers)
  Future<void> cancelCall(String callId) async {
    try {
      final currentUserId = await _getCurrentUserId();
      if (currentUserId == null) return;

      CallUtility.log('GlobalCallService', 'Cancelling call: $callId');

      // Cancel timeout timer since call is being cancelled
      _callTimeouts[callId]?.cancel();
      _callTimeouts.remove(callId);

      // Get call data for history storage
      final callDoc = await FirebaseFirestore.instance
          .collection('Calls')
          .doc(callId)
          .get();

      if (callDoc.exists) {
        final callData = callDoc.data()!;
        final participants = List<String>.from(callData['participants'] ?? []);

        // Find the recipient (not the caller)
        final recipientId = participants.firstWhere(
          (id) => id != currentUserId,
          orElse: () => '',
        );

        if (recipientId.isNotEmpty) {
          // Get user names for history
          final callerInfo =
              await DynamicUserService.getTargetUserInfo(currentUserId);
          final recipientInfo =
              await DynamicUserService.getTargetUserInfo(recipientId);

          final callerName = callerInfo?['name'] ?? 'Unknown Caller';
          final recipientName = recipientInfo?['name'] ?? 'Unknown User';

          // Store cancelled call in history
          await CallHistoryService().storeCancelledCall(
            callId: callId,
            callerId: currentUserId,
            recipientId: recipientId,
            callerName: callerName,
            recipientName: recipientName,
          );

          CallUtility.log(
              'GlobalCallService', 'Call cancelled and stored in history');
        }
      }

      // Update call status to cancelled
      await FirebaseFirestore.instance.collection('Calls').doc(callId).update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });

      removeShownCallId(callId);
    } catch (e) {
      CallUtility.log('GlobalCallService', 'Error cancelling call: $e');
    }
  }

  // Method to end a completed call and store in CallHistory
  Future<void> endCall({
    required String callId,
    required int durationSeconds,
    required DateTime startTime,
  }) async {
    try {
      final currentUserId = await _getCurrentUserId();
      if (currentUserId == null) return;

      CallUtility.log('GlobalCallService',
          'Ending completed call: $callId with duration: ${durationSeconds}s');

      // Get call data for history storage
      final callDoc = await FirebaseFirestore.instance
          .collection('Calls')
          .doc(callId)
          .get();

      if (callDoc.exists) {
        final callData = callDoc.data()!;
        final participants = List<String>.from(callData['participants'] ?? []);
        final callerId = callData['createdBy'] as String;

        // Find the other participant (not current user)
        final otherUserId = participants.firstWhere(
          (id) => id != currentUserId,
          orElse: () => '',
        );

        if (otherUserId.isNotEmpty) {
          // Get user names for history
          final callerInfo =
              await DynamicUserService.getTargetUserInfo(callerId);
          final otherUserInfo =
              await DynamicUserService.getTargetUserInfo(otherUserId);

          final callerName = callerInfo?['name'] ?? 'Unknown Caller';
          final otherUserName = otherUserInfo?['name'] ?? 'Unknown User';

          // Determine recipient (the one who didn't create the call)
          final recipientId =
              callerId == currentUserId ? otherUserId : callerId;
          final recipientName =
              callerId == currentUserId ? otherUserName : callerName;

          // Store completed call in history
          await CallHistoryService().storeCompletedCall(
            callId: callId,
            callerId: callerId,
            recipientId: recipientId,
            callerName: callerName,
            recipientName: recipientName,
            durationSeconds: durationSeconds,
            startTime: startTime,
          );

          CallUtility.log('GlobalCallService',
              'Completed call stored in history with duration: ${durationSeconds}s');
        }
      }

      // Update call status to ended
      await FirebaseFirestore.instance.collection('Calls').doc(callId).update({
        'status': 'ended',
        'endedBy': currentUserId,
        'endedAt': FieldValue.serverTimestamp(),
        'duration': durationSeconds,
      });

      removeShownCallId(callId);
    } catch (e) {
      CallUtility.log('GlobalCallService', 'Error ending call: $e');
    }
  }

  // Method to handle missed calls (timeout or no answer)
  Future<void> handleMissedCall(String callId) async {
    try {
      final currentUserId = await _getCurrentUserId();
      if (currentUserId == null) return;

      CallUtility.log('GlobalCallService', 'Handling missed call: $callId');

      // Get call data for history storage
      final callDoc = await FirebaseFirestore.instance
          .collection('Calls')
          .doc(callId)
          .get();

      if (callDoc.exists) {
        final callData = callDoc.data()!;
        final callerId = callData['createdBy'] as String;
        final participants = List<String>.from(callData['participants'] ?? []);

        // Find the recipient (not the caller)
        final recipientId = participants.firstWhere(
          (id) => id != callerId,
          orElse: () => '',
        );

        if (recipientId.isNotEmpty) {
          // Get user names for history
          final callerInfo =
              await DynamicUserService.getTargetUserInfo(callerId);
          final recipientInfo =
              await DynamicUserService.getTargetUserInfo(recipientId);

          final callerName = callerInfo?['name'] ?? 'Unknown Caller';
          final recipientName = recipientInfo?['name'] ?? 'Unknown User';

          // Store missed call in history
          await CallHistoryService().storeMissedCall(
            callId: callId,
            callerId: callerId,
            recipientId: recipientId,
            callerName: callerName,
            recipientName: recipientName,
          );

          CallUtility.log('GlobalCallService', 'Missed call stored in history');
        }
      }

      // Update call status to missed
      await FirebaseFirestore.instance.collection('Calls').doc(callId).update({
        'status': 'missed',
        'missedAt': FieldValue.serverTimestamp(),
      });

      removeShownCallId(callId);
    } catch (e) {
      CallUtility.log('GlobalCallService', 'Error handling missed call: $e');
    }
  }

  void dispose() {
    stopListening();
    // Navigator key is managed externally, no need to clear
    _currentUserId = null;
    _shownCallIds.clear();

    // Cancel all timeout timers
    for (var timer in _callTimeouts.values) {
      timer.cancel();
    }
    _callTimeouts.clear();
  }

  // Reinitialize service if it becomes unreliable
  Future<void> reinitialize() async {
    CallUtility.log('GlobalCallService', '🔄 Reinitializing service...');

    // Stop current operations
    stopListening();
    _currentUserId = null;
    _shownCallIds.clear();

    // Cancel all timers
    for (var timer in _callTimeouts.values) {
      timer.cancel();
    }
    _callTimeouts.clear();

    // Restart with retry logic
    await _startListeningWithRetry();

    CallUtility.log('GlobalCallService', '✅ Service reinitialized');
  }

  // Debug method to check service status
  Map<String, dynamic> getServiceStatus() {
    return {
      'isListening': _isListening,
      'hasContext': _navigatorKey?.currentContext != null,
      'currentUserId': _currentUserId,
      'shownCallIds': _shownCallIds.toList(),
    };
  }

  // Comprehensive debug status for troubleshooting
  Map<String, dynamic> getDebugStatus() {
    final context = _navigatorKey?.currentContext;
    return {
      'service': {
        'isListening': _isListening,
        'hasNavigatorKey': _navigatorKey != null,
        'hasContext': context != null,
        'contextMounted': context?.mounted ?? false,
        'currentUserId': _currentUserId,
        'hasSubscription': _callSubscription != null,
      },
      'calls': {
        'shownCallIds': _shownCallIds.toList(),
        'activeTimeouts': _callTimeouts.keys.toList(),
        'timeoutCount': _callTimeouts.length,
      },
      'permissions': {
        'info': 'Check permissions separately with _getPermissionStatus()',
      },
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  // Get current permission status
  Future<Map<String, dynamic>> getPermissionStatus() async {
    final permissions = <String, dynamic>{};

    try {
      if (Platform.isAndroid) {
        permissions['systemAlertWindow'] =
            (await Permission.systemAlertWindow.status).toString();
        permissions['camera'] = (await Permission.camera.status).toString();
        permissions['microphone'] =
            (await Permission.microphone.status).toString();
        permissions['notification'] =
            (await Permission.notification.status).toString();
      } else if (Platform.isIOS) {
        permissions['camera'] = (await Permission.camera.status).toString();
        permissions['microphone'] =
            (await Permission.microphone.status).toString();
        permissions['notification'] =
            (await Permission.notification.status).toString();
      }
    } catch (e) {
      permissions['error'] = e.toString();
    }

    return permissions;
  }

  // Test call reception method removed - was interfering with normal call popup functionality

  // Cleanup old problematic calls from database
  Future<void> cleanupProblematicCalls() async {
    try {
      CallUtility.log(
          'GlobalCallService', '🧹 Starting cleanup of problematic calls...');

      final snapshot =
          await FirebaseFirestore.instance.collection('Calls').get();

      int deletedCount = 0;
      int selfCallCount = 0;
      int pendingCount = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String?;
        final participants = List<String>.from(data['participants'] ?? []);

        bool shouldDelete = false;
        String reason = '';

        // Remove self-calling records
        if (participants.length == 2 && participants[0] == participants[1]) {
          selfCallCount++;
          shouldDelete = true;
          reason += 'self-calling ';
        }

        // Remove old pending status calls (should be 'ringing' now)
        if (status == 'pending') {
          pendingCount++;
          shouldDelete = true;
          reason += 'old-pending-status ';
        }

        // Remove old ended calls for cleanup
        if (status == 'ended') {
          shouldDelete = true;
          reason += 'ended-cleanup ';
        }

        if (shouldDelete) {
          CallUtility.log(
              'GlobalCallService', '🗑️ Deleting ${doc.id} - $reason');
          await doc.reference.delete();
          deletedCount++;
        }
      }

      CallUtility.log('GlobalCallService',
          '✅ Cleanup complete: $deletedCount calls deleted');
      CallUtility.log(
          'GlobalCallService', '   - Self-calling records: $selfCallCount');
      CallUtility.log(
          'GlobalCallService', '   - Old pending calls: $pendingCount');
    } catch (e) {
      CallUtility.log('GlobalCallService', '❌ Cleanup error: $e');
    }
  }
}
