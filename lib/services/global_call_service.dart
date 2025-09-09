import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capstone_2/chat/calling.dart';

class GlobalCallService {
  static final GlobalCallService _instance = GlobalCallService._internal();
  factory GlobalCallService() => _instance;
  GlobalCallService._internal();

  StreamSubscription<QuerySnapshot>? _callSubscription;
  BuildContext? _context;
  String? _currentUserId;
  bool _isListening = false;

  void initialize(BuildContext context) {
    _context = context;
    _startListening();
  }

  Future<void> _startListening() async {
    if (_isListening) return;

    // Get current user ID from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getString('user_id') ?? prefs.getString('clinic_id');

    if (_currentUserId == null || _context == null) {
      print('GlobalCallService: No user ID found or context is null');
      return;
    }

    print(
        'GlobalCallService: Starting to listen for calls for user: $_currentUserId');
    _isListening = true;

    // Listen for incoming calls where this user is in participants but not the caller
    _callSubscription = FirebaseFirestore.instance
        .collection('Calls')
        .where('participants', arrayContains: _currentUserId)
        .where('status', isEqualTo: 'ringing')
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final callData = change.doc.data() as Map<String, dynamic>;
          final callerId = callData['callerId'] as String?;
          final callerName =
              callData['callerName'] as String? ?? 'Unknown Caller';

          // Only show incoming call if current user is not the caller
          if (callerId != null && callerId != _currentUserId) {
            print(
                'GlobalCallService: Incoming call from $callerId ($callerName)');
            _showIncomingCall(change.doc.id, callerId, callerName);
          }
        }
      }
    }, onError: (error) {
      print('GlobalCallService: Error listening for calls: $error');
    });
  }

  void _showIncomingCall(String callDocId, String callerId, String callerName) {
    if (_context == null) return;

    print('GlobalCallService: Showing incoming call screen for $callerName');

    // Navigate to calling screen
    Navigator.of(_context!).push(
      MaterialPageRoute(
        builder: (context) => CallingScreen(
          callDocId: callDocId,
          callerId: callerId,
          callerName: callerName,
          currentUserId: _currentUserId!,
        ),
      ),
    );
  }

  void stopListening() {
    print('GlobalCallService: Stopping call listener');
    _callSubscription?.cancel();
    _callSubscription = null;
    _isListening = false;
  }

  void updateContext(BuildContext context) {
    _context = context;
  }

  void dispose() {
    stopListening();
    _context = null;
    _currentUserId = null;
  }
}
