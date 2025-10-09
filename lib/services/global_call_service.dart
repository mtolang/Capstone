/*
 * GlobalCallService - Clean Call System Implementation
 * 
 * 🏗️ ARCHITECTURE:
 * - Calls Database: Stores 'ringing' and 'accepted' calls only
 * - CallHistory Database: Stores 'ended', 'declined', 'cancelled', 'missed' calls
 * - Clean separation between caller and recipient flows
 * - Global monitoring for incoming calls
 * 
 * 🔄 CALL FLOW:
 * 1. Caller initiates call → Creates document in Calls with status 'ringing'
 * 2. System monitors Calls collection for new 'ringing' calls
 * 3. Recipients get UI popup for calls where they are the recipient
 * 4. Active calls have status 'accepted' and stay in Calls
 * 5. Finished calls move to CallHistory and are deleted from Calls
 */

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:kindora/chat/calling.dart'; // IncomingCallScreen
import 'package:kindora/chat/caller_screen.dart'; // CallerScreen
import 'package:kindora/chat/agora_chat_call.dart'; // New Agora-based call screen
import 'package:kindora/services/call_utility.dart';
import 'package:kindora/services/dynamic_user_service.dart';

/// Global Call Service - Clean Implementation
///
/// PURPOSE: Monitor Calls database and manage call UI globally
/// FEATURES:
/// - Watches Calls collection for 'ringing' status
/// - Shows incoming call UI to recipients only
/// - Moves finished calls to CallHistory
/// - Clean separation of caller/recipient flows

class GlobalCallService {
  static final GlobalCallService _instance = GlobalCallService._internal();
  factory GlobalCallService() => _instance;
  GlobalCallService._internal();

  // Core service properties
  StreamSubscription<QuerySnapshot>? _callSubscription;
  StreamSubscription<QuerySnapshot>? _acceptedCallSubscription;
  GlobalKey<NavigatorState>? _navigatorKey;
  String? _currentUserId;
  bool _isListening = false;

  // Call tracking
  Set<String> _shownCallIds = {}; // Prevent duplicate popups
  Map<String, Timer> _callTimeouts = {}; // Auto-cleanup missed calls
  OverlayEntry? _currentOverlay; // For overlay-based incoming calls

  /// Initialize the service with navigator key
  /// MUST be called from root widget during app startup
  void initialize(GlobalKey<NavigatorState> navigatorKey) async {
    CallUtility.log('GlobalCallService', '🚀 Initializing Clean Call System');
    _navigatorKey = navigatorKey;

    // Request permissions upfront
    await _requestPermissions();

    // Start monitoring calls after frame is built AND user ID is cached
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureUserIdAndStartMonitoring();
    });
  }

  /// Ensure user ID is cached before starting monitoring
  Future<void> _ensureUserIdAndStartMonitoring() async {
    CallUtility.log('GlobalCallService',
        '🔄 Ensuring user ID is cached before monitoring...');

    // Aggressive user ID caching with retries
    for (int attempt = 1; attempt <= 10; attempt++) {
      _currentUserId = await DynamicUserService.getCurrentUserId();

      if (_currentUserId != null) {
        CallUtility.log('GlobalCallService',
            '✅ User ID cached: $_currentUserId - starting monitoring');
        break;
      }

      CallUtility.log('GlobalCallService',
          '⏳ Waiting for user ID... (attempt $attempt/10)');
      await Future.delayed(Duration(seconds: 2));
    }

    if (_currentUserId == null) {
      CallUtility.log('GlobalCallService',
          '❌ Could not get user ID after 10 attempts - starting background retry');

      // Keep trying in background
      _startBackgroundUserIdRetry();
      return;
    }

    // Start monitoring now that we have cached user ID
    _startMonitoringCalls();
  }

  /// Keep trying to get user ID in background
  void _startBackgroundUserIdRetry() {
    Timer.periodic(Duration(seconds: 5), (timer) async {
      _currentUserId = await DynamicUserService.getCurrentUserId();
      if (_currentUserId != null) {
        timer.cancel();
        CallUtility.log('GlobalCallService',
            '✅ Background retry successful - starting monitoring');
        _startMonitoringCalls();
      } else {
        CallUtility.log(
            'GlobalCallService', '⏳ Background retry for user ID...');
      }
    });
  }

  /// Request necessary permissions for call system
  Future<void> _requestPermissions() async {
    try {
      CallUtility.log('GlobalCallService', '🔐 Requesting permissions...');

      if (Platform.isAndroid) {
        // Request system alert window permission for overlays
        await Permission.systemAlertWindow.request();
      }

      // Request other permissions
      await [
        Permission.camera,
        Permission.microphone,
      ].request();

      CallUtility.log('GlobalCallService', '✅ Permission requests completed');
    } catch (e) {
      CallUtility.log('GlobalCallService', '❌ Permission error: $e');
    }
  }

  /// Start monitoring Calls collection for new ringing calls
  Future<void> _startMonitoringCalls() async {
    if (_currentUserId == null) {
      CallUtility.log(
          'GlobalCallService', '❌ Cannot start monitoring - no cached user ID');
      return;
    }

    _startCallListener();
  }

  /// Listen to Calls collection for incoming calls
  void _startCallListener() {
    if (_isListening) {
      CallUtility.log('GlobalCallService', '⚠️ Already listening - skipping');
      return;
    }

    _isListening = true;
    CallUtility.log('GlobalCallService',
        '👂 Starting to monitor Calls collection for user: $_currentUserId');

    // Monitor calls where current user is the recipient (to show incoming call popup)
    _callSubscription = FirebaseFirestore.instance
        .collection('Calls')
        .where('recipientId', isEqualTo: _currentUserId)
        .where('status', isEqualTo: 'ringing')
        .snapshots()
        .listen((snapshot) {
      CallUtility.log('GlobalCallService',
          '📡 Incoming call snapshot: ${snapshot.docs.length} documents');
      _processIncomingCalls(snapshot);
    }, onError: (error) {
      CallUtility.log('GlobalCallService', '❌ Listener error: $error');
      _isListening = false;

      // Retry listening after error
      Future.delayed(Duration(seconds: 5), () {
        if (!_isListening) {
          CallUtility.log(
              'GlobalCallService', '🔄 Retrying listener after error...');
          _startCallListener();
        }
      });
    });

    // Also listen for accepted calls where current user is the caller
    _acceptedCallSubscription = FirebaseFirestore.instance
        .collection('Calls')
        .where('callerId', isEqualTo: _currentUserId)
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docs) {
        final callId = doc.id;
        CallUtility.log('GlobalCallService',
            '✅ Call $callId was accepted - navigating caller to call screen');
        _navigateToCallScreen(callId);
      }
    });
  }

  /// Process incoming calls for current user
  void _processIncomingCalls(QuerySnapshot snapshot) {
    CallUtility.log('GlobalCallService',
        '⚡ Processing incoming calls: ${snapshot.docChanges.length} changes');

    // Process only actual changes (added/modified) - much faster!
    for (var change in snapshot.docChanges) {
      if (change.type == DocumentChangeType.added ||
          change.type == DocumentChangeType.modified) {
        final doc = change.doc;
        final callData = doc.data() as Map<String, dynamic>?;

        if (callData == null) {
          CallUtility.log(
              'GlobalCallService', '⚠️ Null data for document ${doc.id}');
          continue;
        }

        final callId = doc.id;
        final callerId = callData['callerId'] as String?;

        // Enhanced logging
        CallUtility.log(
            'GlobalCallService', '🔥 INCOMING CALL DETECTED: $callId');
        CallUtility.log('GlobalCallService', '   Caller: $callerId');
        CallUtility.log('GlobalCallService', '   Change Type: ${change.type}');

        // Validate required fields
        if (callerId == null) {
          CallUtility.log('GlobalCallService',
              '❌ Missing caller ID in call $callId - skipping');
          continue;
        }

        // This query already filters for recipientId == currentUserId and status == 'ringing'
        // So we just need to check if not already shown
        if (!_shownCallIds.contains(callId)) {
          CallUtility.log('GlobalCallService',
              '🎯 SHOWING INCOMING CALL UI for call $callId');
          _showIncomingCallUI(callId, callerId, callData);
        } else {
          CallUtility.log(
              'GlobalCallService', '⏸️ Call $callId already shown - skipping');
        }
      }
    }
  }

  /// Validate service health and readiness
  Map<String, dynamic> getServiceHealthCheck() {
    return {
      'isListening': _isListening,
      'hasNavigatorKey': _navigatorKey != null,
      'hasContext': _navigatorKey?.currentContext != null,
      'cachedUserId': _currentUserId,
      'activeCallIds': _shownCallIds.toList(),
      'activeTimeouts': _callTimeouts.keys.toList(),
    };
  }

  /// Log detailed service status for debugging
  void logServiceStatus() {
    final health = getServiceHealthCheck();
    CallUtility.log('GlobalCallService', '📊 SERVICE HEALTH CHECK:');
    health.forEach((key, value) {
      CallUtility.log('GlobalCallService', '   $key: $value');
    });
  }

  /// Show incoming call UI to recipient
  void _showIncomingCallUI(
      String callId, String callerId, Map<String, dynamic> callData) {
    CallUtility.log('GlobalCallService',
        '⚡ FAST UI: Showing incoming call immediately for $callId from $callerId');

    // Mark as shown to prevent duplicates
    _shownCallIds.add(callId);

    // Set up auto-cleanup timer (30 seconds)
    _callTimeouts[callId] = Timer(Duration(seconds: 30), () {
      _handleMissedCall(callId);
    });

    // Show UI immediately with caller ID
    _displayIncomingCallInstant(callId, callerId);
  }

  /// Display incoming call UI instantly with enhanced context validation
  void _displayIncomingCallInstant(String callId, String callerId) {
    CallUtility.log('GlobalCallService',
        '🚀 INSTANT DISPLAY: Attempting to show call UI for $callId');

    // Enhanced context validation
    if (_navigatorKey == null) {
      CallUtility.log(
          'GlobalCallService', '❌ NavigatorKey is null - cannot show popup');
      logServiceStatus();
      return;
    }

    final context = _navigatorKey?.currentContext;
    if (context == null) {
      CallUtility.log('GlobalCallService',
          '❌ Navigator context is null - cannot show popup');
      logServiceStatus();
      return;
    }

    if (!context.mounted) {
      CallUtility.log(
          'GlobalCallService', '❌ Context is not mounted - cannot show popup');
      logServiceStatus();
      return;
    }

    CallUtility.log('GlobalCallService',
        '✅ Context validation passed - proceeding with popup');

    // Show immediately with caller ID
    String displayName = callerId; // Start with caller ID for instant display

    try {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final freshContext = _navigatorKey?.currentContext;
        if (freshContext != null && freshContext.mounted) {
          CallUtility.log('GlobalCallService',
              '🎬 Creating instant showDialog for call $callId');

          showDialog(
            context: freshContext,
            barrierDismissible: false,
            useRootNavigator: true,
            builder: (dialogContext) {
              CallUtility.log('GlobalCallService',
                  '🎭 Dialog builder called for call $callId');
              return PopScope(
                canPop: false,
                child: IncomingCallScreen(
                  callDocId: callId,
                  callerId: callerId,
                  callerName: displayName, // Will be updated when name resolves
                  currentUserId: _currentUserId!,
                ),
              );
            },
          );

          CallUtility.log('GlobalCallService',
              '✅ Instant call dialog shown successfully for call $callId');

          // Resolve caller name in background (non-blocking)
          _resolveCallerNameInBackground(callId, callerId);
        } else {
          CallUtility.log('GlobalCallService',
              '❌ Fresh context validation failed in postFrameCallback');
        }
      });
    } catch (e) {
      CallUtility.log(
          'GlobalCallService', '❌ Error showing instant dialog: $e');
    }
  }

  /// Resolve caller name in background without blocking UI
  Future<void> _resolveCallerNameInBackground(
      String callId, String callerId) async {
    CallUtility.log('GlobalCallService',
        '🔍 Background: Resolving caller name for: $callerId');

    try {
      String callerName = callerId; // Default to caller ID

      // Search in ClinicAcc
      final clinicDoc = await FirebaseFirestore.instance
          .collection('ClinicAcc')
          .doc(callerId)
          .get();

      if (clinicDoc.exists) {
        final clinicData = clinicDoc.data() as Map<String, dynamic>;
        callerName = clinicData['Name'] ?? callerId;
        CallUtility.log('GlobalCallService', '✅ Found clinic: $callerName');
      } else {
        // Search in ParentsAcc
        final parentDoc = await FirebaseFirestore.instance
            .collection('ParentsAcc')
            .doc(callerId)
            .get();

        if (parentDoc.exists) {
          final parentData = parentDoc.data() as Map<String, dynamic>;
          callerName = parentData['Name'] ?? callerId;
          CallUtility.log('GlobalCallService', '✅ Found parent: $callerName');
        }
      }

      CallUtility.log('GlobalCallService', '📱 Final caller name: $callerName');
      // For now, we prioritize speed over perfect names
    } catch (e) {
      CallUtility.log('GlobalCallService', '❌ Error resolving caller name: $e');
    }
  }

  /// Navigate to call screen
  void _navigateToCallScreen(String callId) async {
    CallUtility.log(
        'GlobalCallService', '🎯 Navigating to call screen for call: $callId');

    final context = _navigatorKey?.currentContext;

    if (context == null || !context.mounted) {
      CallUtility.log(
          'GlobalCallService', '❌ Cannot navigate - context issues');
      return;
    }

    // Ensure we have current user ID for navigation
    if (_currentUserId == null) {
      _currentUserId = await DynamicUserService.getCurrentUserId();
      CallUtility.log('GlobalCallService',
          '🔄 Refreshed user ID for navigation: $_currentUserId');
    }

    if (_currentUserId == null) {
      CallUtility.log(
          'GlobalCallService', '❌ Cannot navigate - no user ID available');
      return;
    }

    // Immediate navigation without delays
    try {
      CallUtility.log('GlobalCallService',
          '🎬 Creating AgoraChatCallScreen with callId: $callId, userId: $_currentUserId');

      // Navigate to AgoraChatCallScreen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => AgoraChatCallScreen(
            callId: callId,
            currentUserId: _currentUserId!,
            initialParticipants: [], // Will be populated from call document
          ),
        ),
      );

      CallUtility.log('GlobalCallService', '✅ Navigation successful');
    } catch (e) {
      CallUtility.log('GlobalCallService', '❌ Navigation error: $e');
    }
  }

  /// Create a new call document in Calls collection
  /// Returns the call ID if successful
  Future<String?> createCall({
    required String recipientId,
    required Map<String, dynamic> peerConnectionConfig,
  }) async {
    try {
      final currentUserId = await DynamicUserService.getCurrentUserId();
      if (currentUserId == null) {
        CallUtility.log(
            'GlobalCallService', '❌ Cannot create call - no current user');
        return null;
      }

      // Create new call document
      final callDoc = FirebaseFirestore.instance.collection('Calls').doc();

      await callDoc.set({
        'callerId': currentUserId,
        'recipientId': recipientId,
        'status': 'ringing',
        'createdAt': FieldValue.serverTimestamp(),
        'peerConnectionConfig': peerConnectionConfig,
      });

      CallUtility.log(
          'GlobalCallService', '✅ Call created with ID: ${callDoc.id}');
      return callDoc.id;
    } catch (e) {
      CallUtility.log('GlobalCallService', '❌ Error creating call: $e');
      return null;
    }
  }

  /// Initiate a call with UI navigation (for Therapist Chat compatibility)
  Future<String?> initiateCall({
    required String targetUserId,
    required Map<String, dynamic> peerConnectionConfig,
    BuildContext? context,
  }) async {
    try {
      final callId = await createCall(
        recipientId: targetUserId,
        peerConnectionConfig: peerConnectionConfig,
      );

      if (callId != null && context != null && context.mounted) {
        // Show caller screen using the provided context
        CallerScreen.show(
          context: context,
          callDocId: callId,
          targetUserId: targetUserId,
          targetUserName: 'User',
          currentUserId: _currentUserId ?? '',
        );
      }

      return callId;
    } catch (e) {
      CallUtility.log('GlobalCallService', '❌ Error initiating call: $e');
      return null;
    }
  }

  /// Accept a call (recipient action)
  Future<void> acceptCall(String callId) async {
    try {
      CallUtility.log('GlobalCallService', '✅ Accepting call: $callId');

      // Ensure we have current user ID
      if (_currentUserId == null) {
        _currentUserId = await DynamicUserService.getCurrentUserId();
      }

      if (_currentUserId == null) {
        CallUtility.log(
            'GlobalCallService', '❌ Cannot accept call - no user ID');
        throw Exception('Cannot verify user identity');
      }

      // Update call status to accepted
      await FirebaseFirestore.instance.collection('Calls').doc(callId).update({
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      // Clean up tracking
      _shownCallIds.remove(callId);
      _callTimeouts[callId]?.cancel();
      _callTimeouts.remove(callId);
      _currentOverlay?.remove();
      _currentOverlay = null;

      CallUtility.log('GlobalCallService',
          '✅ Call accepted successfully - navigation handled by calling screen');
      // Note: Navigation is handled by IncomingCallScreen._acceptCall() for immediate UI response
    } catch (e) {
      CallUtility.log('GlobalCallService', '❌ Error accepting call: $e');
      rethrow;
    }
  }

  /// Decline a call (recipient action)
  Future<void> declineCall(String callId) async {
    try {
      CallUtility.log('GlobalCallService', '✅ Declining call: $callId');

      // Update call status to declined
      await FirebaseFirestore.instance.collection('Calls').doc(callId).update({
        'status': 'declined',
        'declinedAt': FieldValue.serverTimestamp(),
      });

      // Clean up tracking
      _shownCallIds.remove(callId);
      _callTimeouts[callId]?.cancel();
      _callTimeouts.remove(callId);

      CallUtility.log('GlobalCallService', '✅ Call declined successfully');
    } catch (e) {
      CallUtility.log('GlobalCallService', '❌ Error declining call: $e');
    }
  }

  /// Cancel a call (caller action)
  Future<void> cancelCall(String callId) async {
    try {
      // Update call status to cancelled
      await FirebaseFirestore.instance.collection('Calls').doc(callId).update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });

      CallUtility.log('GlobalCallService', '✅ Call cancelled successfully');
    } catch (e) {
      CallUtility.log('GlobalCallService', '❌ Error cancelling call: $e');
    }
  }

  /// End an active call
  Future<void> endCall(String callId) async {
    try {
      // Update call status to ended
      await FirebaseFirestore.instance.collection('Calls').doc(callId).update({
        'status': 'ended',
        'endedAt': FieldValue.serverTimestamp(),
      });

      CallUtility.log('GlobalCallService', '✅ Call ended successfully');
    } catch (e) {
      CallUtility.log('GlobalCallService', '❌ Error ending call: $e');
    }
  }

  /// Handle missed call (timeout)
  Future<void> _handleMissedCall(String callId) async {
    try {
      // Update call status to missed
      await FirebaseFirestore.instance.collection('Calls').doc(callId).update({
        'status': 'missed',
        'missedAt': FieldValue.serverTimestamp(),
      });

      // Clean up tracking
      _shownCallIds.remove(callId);
      _callTimeouts.remove(callId);

      CallUtility.log('GlobalCallService', '✅ Missed call handled');
    } catch (e) {
      CallUtility.log('GlobalCallService', '❌ Error handling missed call: $e');
    }
  }

  /// Clean shutdown
  void dispose() {
    CallUtility.log('GlobalCallService', '🛑 Shutting down GlobalCallService');

    _callSubscription?.cancel();
    _acceptedCallSubscription?.cancel();

    // Cancel all timeouts
    for (var timer in _callTimeouts.values) {
      timer.cancel();
    }
    _callTimeouts.clear();

    _shownCallIds.clear();
    _isListening = false;
  }

  /// Get service status for debugging
  Map<String, dynamic> getServiceStatus() {
    return {
      'isListening': _isListening,
      'hasNavigatorKey': _navigatorKey != null,
      'cachedUserId': _currentUserId,
      'activeCallIds': _shownCallIds.length,
      'activeTimeouts': _callTimeouts.length,
    };
  }

  /// Test call creation with detailed logging
  Future<Map<String, dynamic>> testCreateCall(String recipientId) async {
    final result = <String, dynamic>{
      'success': false,
      'currentUserId': null,
      'callId': null,
      'error': null,
      'steps': <String>[],
    };

    try {
      result['steps'].add('Starting call creation test');

      // Get current user ID
      final currentUserId = await DynamicUserService.getCurrentUserId();
      result['currentUserId'] = currentUserId;
      result['steps'].add('Current user ID: $currentUserId');

      if (currentUserId == null) {
        result['error'] = 'No current user ID available';
        result['steps'].add('ERROR: No current user ID');
        return result;
      }

      // Create peer connection configuration
      final peerConnectionConfig = {
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
          {'urls': 'stun:stun1.l.google.com:19302'},
        ]
      };
      result['steps'].add('Peer connection config created');

      // Create call
      final callId = await createCall(
        recipientId: recipientId,
        peerConnectionConfig: peerConnectionConfig,
      );

      result['callId'] = callId;

      if (callId != null) {
        result['success'] = true;
        result['steps'].add('Call created successfully with ID: $callId');

        // Cleanup test call after creation
        Future.delayed(Duration(seconds: 2), () {
          cancelCall(callId).catchError((error) {
            CallUtility.log('GlobalCallService', 'Test cleanup error: $error');
          });
        });
        result['steps'].add('Test call scheduled for cleanup');
      } else {
        result['error'] = 'Call creation returned null';
        result['steps'].add('ERROR: Call creation failed');
      }
    } catch (e) {
      result['error'] = e.toString();
      result['steps'].add('EXCEPTION: ${e.toString()}');
    }

    return result;
  }
}
