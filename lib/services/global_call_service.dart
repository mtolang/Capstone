import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:capstone_2/chat/calling.dart';
import 'package:capstone_2/chat/chat_call.dart';
import 'package:capstone_2/services/call_utility.dart';

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
  BuildContext? _context;
  String? _currentUserId;
  bool _isListening = false;
  Set<String> _shownCallIds = {}; // Track shown calls to prevent duplicates

  void initialize(BuildContext context) {
    _context = context;
    _startListening();
  }

  Future<String?> _getCurrentUserId() async {
    if (_currentUserId != null) return _currentUserId;

    final userId = await CallUtility.getCurrentUserId();
    if (userId != null) {
      _currentUserId = userId;
    }
    return userId;
  }

  void _startListening() async {
    if (_isListening) return;

    final userId = await _getCurrentUserId();
    if (userId == null) {
      CallUtility.log(
          'GlobalCallService', 'No user ID available, cannot start listening');
      return;
    }

    CallUtility.log(
        'GlobalCallService', 'Starting to listen for calls for user: $userId');
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
          final invitations =
              callData['invitations'] as Map<String, dynamic>? ?? {};

          CallUtility.log(
              'GlobalCallService', 'Call update detected for call $callId');

          // Check if this user has a pending invitation
          if (invitations.containsKey(userId)) {
            final invitation = invitations[userId] as Map<String, dynamic>;
            final invitationStatus = invitation['status'];

            // Only show incoming call if validation passes and not shown already
            if (invitationStatus == 'pending' &&
                CallUtility.shouldShowCall(
                  currentUserId: userId,
                  callerId: createdBy ?? '',
                  createdBy: createdBy,
                ) &&
                !_shownCallIds.contains(callId)) {
              _shownCallIds.add(callId);
              _getCallerNameAndShowCall(callId, createdBy!);
            }
          }
        }
      }
    }, onError: (error) {
      CallUtility.log('GlobalCallService', 'Error listening for calls: $error');
    });
  }

  Future<void> _getCallerNameAndShowCall(
      String callId, String createdBy) async {
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

  void _showIncomingCall(String callDocId, String callerId, String callerName) {
    if (_context == null) return;

    CallUtility.log(
        'GlobalCallService', 'Showing incoming call overlay for $callerName');

    // Show incoming call as an overlay on top of current page
    showDialog(
      context: _context!,
      barrierDismissible: false, // Cannot dismiss by tapping outside
      barrierColor:
          Colors.black.withOpacity(0.8), // Semi-transparent background
      builder: (context) => WillPopScope(
        onWillPop: () async => false, // Prevent back button dismiss
        child: CallingScreen(
          callDocId: callDocId,
          callerId: callerId,
          callerName: callerName,
          currentUserId: _currentUserId!,
        ),
      ),
    );
  }

  void stopListening() {
    CallUtility.log('GlobalCallService', 'Stopping call listener');
    _callSubscription?.cancel();
    _callSubscription = null;
    _isListening = false;
  }

  void updateContext(BuildContext context) {
    _context = context;
  }

  void removeShownCallId(String callId) {
    _shownCallIds.remove(callId);
  }

  // Method to initiate a call with peer connection data
  Future<String?> initiateCall({
    required String targetUserId,
    required Map<String, dynamic> peerConnectionConfig,
  }) async {
    final currentUserId = await _getCurrentUserId();
    if (currentUserId == null) {
      CallUtility.log(
          'GlobalCallService', 'Cannot initiate call - no current user');
      return null;
    }

    try {
      // Create a new call document
      final callDoc = FirebaseFirestore.instance.collection('Calls').doc();
      final callId = callDoc.id;

      await callDoc.set({
        'callId': callId,
        'createdBy': currentUserId,
        'participants': [currentUserId, targetUserId],
        'status': 'pending',
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
      return callId;
    } catch (e) {
      CallUtility.log('GlobalCallService', 'Error initiating call: $e');
      return null;
    }
  }

  // Method to accept a call and navigate to chat call screen
  Future<void> acceptCall(String callId) async {
    if (_context == null) return;

    try {
      final currentUserId = await _getCurrentUserId();
      if (currentUserId == null) return;

      // Update invitation status to accepted
      await FirebaseFirestore.instance.collection('Calls').doc(callId).update({
        'invitations.$currentUserId.status': 'accepted',
        'status': 'active',
      });

      // Navigate to chat call screen
      Navigator.of(_context!).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ChatCallScreen(
            callId: callId,
            currentUserId: currentUserId,
            initialParticipants: [], // Joining existing call
          ),
        ),
      );
    } catch (e) {
      CallUtility.log('GlobalCallService', 'Error accepting call: $e');
    }
  }

  // Method to decline a call
  Future<void> declineCall(String callId) async {
    try {
      final currentUserId = await _getCurrentUserId();
      if (currentUserId == null) return;

      await FirebaseFirestore.instance.collection('Calls').doc(callId).update({
        'invitations.$currentUserId.status': 'declined',
      });

      removeShownCallId(callId);
    } catch (e) {
      CallUtility.log('GlobalCallService', 'Error declining call: $e');
    }
  }

  void dispose() {
    stopListening();
    _context = null;
    _currentUserId = null;
    _shownCallIds.clear();
  }
}
