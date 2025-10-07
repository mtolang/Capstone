import 'package:flutter/material.dart';
import 'package:capstone_2/services/global_call_service.dart';
import 'package:capstone_2/services/call_utility.dart';
import 'package:capstone_2/services/dynamic_user_service.dart';
import 'package:capstone_2/chat/caller_screen.dart';

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
      CallUtility.log('CallButton', '🚀 Starting optimized call initiation...');

      // Get current user ID with timeout for faster failure
      final currentUserId = await DynamicUserService.getCurrentUserId()
          .timeout(Duration(seconds: 3), onTimeout: () {
        throw Exception('User ID lookup timeout - please try again');
      });

      CallUtility.log(
          'CallButton', '🔍 DynamicUserService returned: $currentUserId');

      if (currentUserId == null) {
        CallUtility.log('CallButton', '❌ Current user ID is null');
        throw Exception('User not properly logged in - please restart app');
      }

      if (targetUserId.isEmpty) {
        CallUtility.log('CallButton', '❌ Target user ID is empty');
        throw Exception('Target user ID is empty');
      }

      // Prevent self-calling
      if (currentUserId == targetUserId) {
        CallUtility.log('CallButton', '❌ Self-calling attempt blocked');
        throw Exception('Cannot call yourself');
      }

      CallUtility.log(
          'CallButton', '📞 Creating call: $currentUserId → $targetUserId');

      // Simplified config for faster processing - Agora doesn't need STUN servers
      final peerConnectionConfig = <String, dynamic>{};

      CallUtility.log('CallButton',
          '🔧 Starting GlobalCallService.createCall() - optimized');

      // Create call with timeout for faster failure detection
      final callId = await GlobalCallService()
          .createCall(
        recipientId: targetUserId,
        peerConnectionConfig: peerConnectionConfig,
      )
          .timeout(Duration(seconds: 5), onTimeout: () {
        throw Exception('Call creation timeout - network issue');
      });

      CallUtility.log(
          'CallButton', '📋 GlobalCallService.createCall() returned: $callId');

      if (callId != null) {
        CallUtility.log('CallButton', '✅ Call created with ID: $callId');

        // Show caller screen
        if (context.mounted) {
          CallUtility.log('CallButton', '📱 Showing CallerScreen');

          CallerScreen.show(
            context: context,
            callDocId: callId,
            targetUserId: targetUserId,
            targetUserName: targetUserName,
            currentUserId: currentUserId,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Calling $targetUserName...')),
          );

          CallUtility.log('CallButton', '✅ CallerScreen shown successfully');
        } else {
          CallUtility.log(
              'CallButton', '⚠️ Context not mounted, cannot show CallerScreen');
        }
      } else {
        CallUtility.log(
            'CallButton', '❌ createCall returned null - call creation failed');
        throw Exception(
            'Failed to create call - GlobalCallService.createCall() returned null');
      }
    } catch (e) {
      CallUtility.log('CallButton', '❌ Error initiating call: $e');

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
