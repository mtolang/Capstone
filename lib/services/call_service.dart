import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capstone_2/chat/calling.dart';

class CallService {
  static final CallService _instance = CallService._internal();
  factory CallService() => _instance;
  CallService._internal();

  StreamSubscription<QuerySnapshot>? _callSubscription;
  String? _currentUserId;
  BuildContext? _context;

  void initialize(String userId, BuildContext context) {
    _currentUserId = userId;
    _context = context;
    _startListening();
  }

  void updateContext(BuildContext context) {
    _context = context;
  }

  // Try to get user ID from multiple sources
  Future<String?> _getCurrentUserId() async {
    if (_currentUserId != null) return _currentUserId;

    try {
      final prefs = await SharedPreferences.getInstance();

      // Try different storage keys
      String? userId = prefs.getString('user_id'); // For parents
      if (userId == null) {
        userId = prefs.getString('clinic_id'); // For clinics
      }

      if (userId != null) {
        _currentUserId = userId;
        return userId;
      }
    } catch (e) {
      print('Error getting user ID from SharedPreferences: $e');
    }

    // Could add more sources here like Firebase Auth
    return null;
  }

  void _startListening() async {
    final userId = await _getCurrentUserId();
    if (userId == null) {
      print('CallService: No user ID available, cannot start listening');
      return;
    }

    print('CallService: Starting to listen for calls for user: $userId');

    _callSubscription = FirebaseFirestore.instance
        .collection('Calls')
        .where('participants', arrayContains: userId)
        .where('status', isEqualTo: 'ringing')
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() as Map<String, dynamic>;
          final callerId = data['callerId'] as String?;

          print(
              'CallService: Incoming call detected from $callerId to $userId');

          // Only show incoming call if current user is not the caller
          if (callerId != null && callerId != userId) {
            _showIncomingCall(change.doc.id, data);
          }
        }
      }
    }, onError: (error) {
      print('CallService: Error listening for calls: $error');
    });
  }

  void _showIncomingCall(String callDocId, Map<String, dynamic> callData) {
    if (_context == null) {
      print('CallService: No context available to show incoming call');
      return;
    }

    final callerId = callData['callerId'] as String? ?? 'Unknown';
    final callerName = callData['callerName'] as String? ?? 'Unknown Caller';

    print('CallService: Showing incoming call dialog for $callerName');

    // Show incoming call overlay or navigate to calling screen
    showDialog(
      context: _context!,
      barrierDismissible: false,
      builder: (context) => IncomingCallOverlay(
        callDocId: callDocId,
        callerId: callerId,
        callerName: callerName,
        currentUserId: _currentUserId!,
        onAccept: () {
          Navigator.of(context).pop();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CallingScreen(
                callDocId: callDocId,
                callerId: callerId,
                callerName: callerName,
                currentUserId: _currentUserId!,
              ),
            ),
          );
        },
        onDecline: () async {
          await FirebaseFirestore.instance
              .collection('Calls')
              .doc(callDocId)
              .update({'status': 'declined'});
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void dispose() {
    print('CallService: Disposing call service');
    _callSubscription?.cancel();
    _callSubscription = null;
    _currentUserId = null;
    _context = null;
  }
}

class IncomingCallOverlay extends StatefulWidget {
  final String callDocId;
  final String callerId;
  final String callerName;
  final String currentUserId;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const IncomingCallOverlay({
    Key? key,
    required this.callDocId,
    required this.callerId,
    required this.callerName,
    required this.currentUserId,
    required this.onAccept,
    required this.onDecline,
  }) : super(key: key);

  @override
  State<IncomingCallOverlay> createState() => _IncomingCallOverlayState();
}

class _IncomingCallOverlayState extends State<IncomingCallOverlay>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue.withOpacity(0.5), width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Incoming Call',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Animated caller avatar
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.blue.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 38,
                      backgroundColor: Colors.blue.shade700,
                      child: Text(
                        widget.callerName.isNotEmpty
                            ? widget.callerName[0].toUpperCase()
                            : 'C',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),
            Text(
              widget.callerName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Video Call',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Decline button
                GestureDetector(
                  onTap: widget.onDecline,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.call_end,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),

                // Accept button
                GestureDetector(
                  onTap: widget.onAccept,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.videocam,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
