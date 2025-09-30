import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capstone_2/services/global_call_service.dart';
import 'package:capstone_2/services/call_utility.dart';
import 'package:capstone_2/services/dynamic_user_service.dart';

class CallButton extends StatelessWidget {
  final String targetUserId;
  final String targetUserName;
  final String currentUserId;

  const CallButton({
    Key? key,
    required this.targetUserId,
    required this.targetUserName,
    required this.currentUserId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag:
          "call_button_${targetUserId}_${currentUserId}", // Unique hero tag
      onPressed: () => _initiateCall(context),
      backgroundColor: Colors.green,
      child: const Icon(Icons.videocam, color: Colors.white),
    );
  }

  Future<void> _initiateCall(BuildContext context) async {
    try {
      // Debug: Check current SharedPreferences state
      final prefs = await SharedPreferences.getInstance();
      final userType = prefs.getString('user_type');
      final clinicId = prefs.getString('clinic_id');
      final userId = prefs.getString('user_id');
      final isLoggedIn = prefs.getBool('is_logged_in');

      CallUtility.log('CallButton', '=== DEBUGGING CALL INITIATION ===');
      CallUtility.log('CallButton', 'SharedPreferences state:');
      CallUtility.log('CallButton', '  - user_type: $userType');
      CallUtility.log('CallButton', '  - clinic_id: $clinicId');
      CallUtility.log('CallButton', '  - user_id: $userId');
      CallUtility.log('CallButton', '  - is_logged_in: $isLoggedIn');
      CallUtility.log(
          'CallButton', '  - constructor currentUserId: $currentUserId');
      CallUtility.log(
          'CallButton', '  - constructor targetUserId: $targetUserId');

      // Verify current user ID using DynamicUserService
      final verifiedUserId = await DynamicUserService.getCurrentUserId();
      final currentUserInfo = await DynamicUserService.getCurrentUserInfo();
      final targetUserInfo =
          await DynamicUserService.getTargetUserInfo(targetUserId);

      CallUtility.log('CallButton', 'DynamicUserService results:');
      CallUtility.log('CallButton', '  - verifiedUserId: $verifiedUserId');
      CallUtility.log('CallButton', '  - currentUserInfo: $currentUserInfo');
      CallUtility.log('CallButton', '  - targetUserInfo: $targetUserInfo');

      if (verifiedUserId == null) {
        throw Exception(
            'Cannot verify current user identity - no user found in storage');
      }

      if (targetUserId.isEmpty) {
        throw Exception('Target user ID is empty');
      }

      // Validate target user exists
      if (targetUserInfo == null) {
        throw Exception('Target user $targetUserId not found in database');
      }

      // Prevent self-calling with detailed comparison
      if (verifiedUserId == targetUserId) {
        CallUtility.log('CallButton',
            'BLOCKING: Self-calling detected - verifiedUserId ($verifiedUserId) == targetUserId ($targetUserId)');
        throw Exception('Cannot call yourself - self-calling not allowed');
      } else {
        CallUtility.log('CallButton',
            'ALLOWING: Different users - verifiedUserId ($verifiedUserId) != targetUserId ($targetUserId)');
      }

      // Use GlobalCallService to initiate the call with multiple reliable STUN/TURN servers
      final peerConnectionConfig = {
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
          {'urls': 'stun:stun1.l.google.com:19302'},
          {'urls': 'stun:stun2.l.google.com:19302'},
          {'urls': 'stun:stun.cloudflare.com:3478'},
          {'urls': 'stun:openrelay.metered.ca:80'},
          {
            'urls': 'turn:openrelay.metered.ca:80',
            'username': 'openrelayproject',
            'credential': 'openrelayproject'
          },
          {
            'urls': 'turn:openrelay.metered.ca:443',
            'username': 'openrelayproject',
            'credential': 'openrelayproject'
          },
        ]
      };

      CallUtility.log(
          'CallButton', 'Creating call with config: $peerConnectionConfig');

      final callId = await GlobalCallService().initiateCall(
        targetUserId: targetUserId,
        peerConnectionConfig: peerConnectionConfig,
        context: context, // Pass the current context directly
      );

      if (callId != null) {
        CallUtility.log(
            'CallButton', 'Call created successfully with ID: $callId');

        // The CallerScreen is now shown automatically by GlobalCallService.initiateCall()
        // No need to navigate manually here

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Calling ${targetUserInfo['name']}...')),
          );
        }
      } else {
        CallUtility.log('CallButton', 'Failed to create call - callId is null');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to start call - please try again'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      CallUtility.log('CallButton', 'Error initiating call: $e');
      // Close loading dialog if open
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to call $targetUserName: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
