import 'package:flutter/material.dart';
import 'package:capstone_2/services/global_call_service.dart';
import 'package:capstone_2/chat/chat_call.dart';

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
      onPressed: () => _initiateCall(context),
      backgroundColor: Colors.green,
      child: const Icon(Icons.videocam, color: Colors.white),
    );
  }

  Future<void> _initiateCall(BuildContext context) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Starting call...'),
            ],
          ),
        ),
      );

      // Use GlobalCallService to initiate the call
      final peerConnectionConfig = {
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
        ]
      };

      final callId = await GlobalCallService().initiateCall(
        targetUserId: targetUserId,
        peerConnectionConfig: peerConnectionConfig,
      );

      // Close loading dialog
      Navigator.of(context).pop();

      if (callId != null) {
        // Navigate to chat call screen
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ChatCallScreen(
              callId: callId,
              currentUserId: currentUserId,
              initialParticipants: [targetUserId],
            ),
          ),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Calling $targetUserName...')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to start call'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if open
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      print('Error initiating call: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to call $targetUserName'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
