import 'package:flutter/material.dart';
import 'package:kindora/services/global_call_service.dart';
import 'package:kindora/chat/agora_chat_call.dart';

/// Recipient Screen - for the person receiving the call
/// Shows incoming call UI with accept/decline options
class IncomingCallScreen extends StatefulWidget {
  final String callDocId;
  final String callerId;
  final String callerName;
  final String currentUserId;

  const IncomingCallScreen({
    Key? key,
    required this.callDocId,
    required this.callerId,
    required this.callerName,
    required this.currentUserId,
  }) : super(key: key);

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Animation for incoming call effect
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _acceptCall() async {
    try {
      print('📞 Accepting call: ${widget.callDocId}');

      // Close dialog first for immediate UI response
      if (Navigator.of(context).canPop() && mounted) {
        Navigator.of(context).pop();
      }

      // Show connecting screen immediately
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => AgoraChatCallScreen(
              callId: widget.callDocId,
              currentUserId: widget.currentUserId,
              initialParticipants: [widget.callerId],
            ),
          ),
        );
        print('📱 Navigated to AgoraChatCallScreen immediately');
      }

      // Accept the call in background (non-blocking)
      GlobalCallService().acceptCall(widget.callDocId).then((_) {
        print('✅ Call accepted successfully in background');
      }).catchError((e) {
        print('❌ Error accepting call in background: $e');
      });
    } catch (e) {
      print('❌ Error accepting call: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept call: $e')),
        );
      }
    }
  }

  Future<void> _declineCall() async {
    try {
      // Close the dialog immediately
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // Decline the call using new clean system
      GlobalCallService().declineCall(widget.callDocId).catchError((error) {
        print('Error declining call: $error');
      });
    } catch (e) {
      print('Error declining call: $e');
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
              Colors.blue.shade900.withOpacity(0.9),
              Colors.black87,
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Top section with incoming call text
              Column(
                children: [
                  const Text(
                    'Incoming call',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.callerName} is calling you',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Video Call Request',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),

              // Animated caller avatar
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
                            color: Colors.blue.withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 75,
                        backgroundColor: Colors.blue.shade700,
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

              // Action buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 60),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Decline button
                    GestureDetector(
                      onTap: _declineCall,
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

                    // Accept button
                    GestureDetector(
                      onTap: _acceptCall,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green,
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.call,
                          color: Colors.white,
                          size: 35,
                        ),
                      ),
                    ),
                  ],
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
