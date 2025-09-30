import 'package:flutter/material.dart';
import 'package:capstone_2/services/global_call_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

/// Caller Screen - for the person initiating the call
/// Shows outgoing call UI with calling animation and hang up option
class CallerScreen extends StatefulWidget {
  final String callDocId;
  final String targetUserId;
  final String targetUserName;
  final String currentUserId;

  const CallerScreen({
    Key? key,
    required this.callDocId,
    required this.targetUserId,
    required this.targetUserName,
    required this.currentUserId,
  }) : super(key: key);

  /// Static method to show caller screen with context validation
  static void show({
    required BuildContext context,
    required String callDocId,
    required String targetUserId,
    required String targetUserName,
    required String currentUserId,
  }) {
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => CallerScreen(
          callDocId: callDocId,
          targetUserId: targetUserId,
          targetUserName: targetUserName,
          currentUserId: currentUserId,
        ),
      );
    }
  }

  @override
  State<CallerScreen> createState() => _CallerScreenState();
}

class _CallerScreenState extends State<CallerScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  StreamSubscription<DocumentSnapshot>? _callStatusSubscription;
  String _callStatus = 'Calling...';

  @override
  void initState() {
    super.initState();

    // Animation for outgoing call effect
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);

    // Listen for call status changes
    _listenForCallStatus();
  }

  void _listenForCallStatus() {
    _callStatusSubscription = FirebaseFirestore.instance
        .collection('Calls')
        .doc(widget.callDocId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        final status = data['status'] as String?;

        if (mounted) {
          setState(() {
            switch (status) {
              case 'ringing':
                _callStatus = 'Calling...';
                break;
              case 'active':
                _callStatus = 'Connecting...';
                // The GlobalCallService will handle navigation
                break;
              case 'declined':
                _callStatus = 'Call Declined';
                _showCallResult('Call declined by ${widget.targetUserName}');
                break;
              case 'cancelled':
                _callStatus = 'Call Cancelled';
                break;
              default:
                _callStatus = 'Calling...';
            }
          });
        }
      }
    });
  }

  void _showCallResult(String message) {
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _callStatusSubscription?.cancel();
    super.dispose();
  }

  Future<void> _endCall() async {
    try {
      // Close the dialog immediately
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // End the call in background - use cancelCall for caller cancellation
      GlobalCallService().cancelCall(widget.callDocId).catchError((error) {
        print('Error cancelling call: $error');
      });
    } catch (e) {
      print('Error ending call: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green.shade900.withOpacity(0.9),
              Colors.green.shade700.withOpacity(0.8),
              Colors.black87,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Top section with calling text
              Column(
                children: [
                  Text(
                    _callStatus,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.targetUserName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'to ${widget.targetUserId}',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),

              // Animated target avatar
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 75,
                        backgroundColor: Colors.green.shade700,
                        child: const Icon(
                          Icons.person,
                          size: 80,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Call info
              Column(
                children: [
                  const Text(
                    'Video Call',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Animated dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      return AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(
                                (_pulseController.value + index * 0.3) % 1.0,
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  ),
                ],
              ),

              // End call button
              GestureDetector(
                onTap: _endCall,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red,
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.call_end,
                    color: Colors.white,
                    size: 35,
                  ),
                ),
              ),

              // Bottom spacing
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
