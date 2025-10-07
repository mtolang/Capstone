import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capstone_2/helper/clinic_auth.dart';
import 'package:capstone_2/services/global_call_service.dart';
import 'package:capstone_2/services/call_utility.dart';
import 'package:capstone_2/services/dynamic_user_service.dart';
import 'package:capstone_2/chat/caller_screen.dart';

class TherapistChatPage extends StatefulWidget {
  final String? patientId;

  const TherapistChatPage({super.key, this.patientId});

  @override
  State<TherapistChatPage> createState() => _TherapistChatPageState();
}

class _TherapistChatPageState extends State<TherapistChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _patientName = '';

  // Dynamic clinic ID - will be loaded from storage
  String _clinicId = 'CLI01'; // Default fallback

  @override
  void initState() {
    super.initState();
    _loadClinicIdFromStorage();
    _loadPatientInfo();
  }

  // Load current clinic ID from SharedPreferences
  Future<void> _loadClinicIdFromStorage() async {
    try {
      // Use ClinicAuthService to check authentication
      final isLoggedIn = await ClinicAuthService.isLoggedIn;
      final clinicId = await ClinicAuthService.getStoredClinicId();

      final prefs = await SharedPreferences.getInstance();
      final userType = prefs.getString('user_type');

      print('TherapistChat: Debug clinic auth state:');
      print('  clinic_id from ClinicAuthService: $clinicId');
      print('  isLoggedIn from ClinicAuthService: $isLoggedIn');
      print('  user_type from prefs: $userType');

      if (clinicId != null && isLoggedIn && userType == 'clinic') {
        setState(() {
          _clinicId = clinicId;
        });
        print('TherapistChat: Using validated clinic ID: $_clinicId');
      } else {
        print('TherapistChat: No valid clinic authentication found');
        print('TherapistChat: Using default clinic ID: $_clinicId');
        // Show a warning that user might need to log in
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Warning: Please ensure you are logged in as a clinic'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print('TherapistChat: Error loading clinic ID: $e');
      // Keep default fallback value
    }
  }

  void _loadPatientInfo() async {
    // Load patient information from ParentsAcc collection
    try {
      if (widget.patientId != null) {
        final parentDoc = await FirebaseFirestore.instance
            .collection('ParentsAcc')
            .doc(widget.patientId!)
            .get();

        if (parentDoc.exists) {
          final parentData = parentDoc.data() as Map<String, dynamic>;
          setState(() {
            _patientName = parentData['Name'] ?? 'Unknown Patient';
          });
        } else {
          setState(() {
            _patientName = 'Unknown Patient';
          });
        }
      }
    } catch (e) {
      print('Error loading patient info: $e');
      setState(() {
        _patientName = 'Unknown Patient';
      });
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final messageText = _messageController.text.trim();
    final timestamp = DateTime.now();
    final fromId = _clinicId;
    final toId = widget.patientId ?? 'unknown';

    print('TherapistChat: Sending message:');
    print('  From (clinic): $fromId');
    print('  To (patient): $toId');
    print('  Message: $messageText');

    // Save to Firestore
    FirebaseFirestore.instance.collection('Message').add({
      'fromId': fromId,
      'toId': toId,
      'message': messageText,
      'timestamp': timestamp,
    }).then((docRef) {
      print('TherapistChat: Message saved successfully with ID: ${docRef.id}');
    }).catchError((error) {
      print('TherapistChat: Error saving message: $error');
    });

    _messageController.clear();

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Method to initiate a call
  Future<void> _initiateCall() async {
    try {
      CallUtility.log('TherapistChat', '🚀 Starting call initiation...');

      // Verify current user ID using DynamicUserService
      final currentUserId = await DynamicUserService.getCurrentUserId();
      CallUtility.log(
          'TherapistChat', '🔍 DynamicUserService returned: $currentUserId');

      if (currentUserId == null) {
        CallUtility.log('TherapistChat', '❌ Current user ID is null');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to verify user identity')),
          );
        }
        return;
      }

      final targetUserId = widget.patientId ?? '';
      if (targetUserId.isEmpty) {
        CallUtility.log('TherapistChat', '❌ Target user ID is empty');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid patient ID')),
          );
        }
        return;
      }

      // Prevent self-calling
      if (currentUserId == targetUserId) {
        CallUtility.log('TherapistChat', '❌ Attempted self-call');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cannot call yourself')),
          );
        }
        return;
      }

      CallUtility.log(
          'TherapistChat', '📞 Creating call: $currentUserId → $targetUserId');

      // Create peer connection configuration
      final peerConnectionConfig = {
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
          {'urls': 'stun:stun1.l.google.com:19302'},
          {'urls': 'stun:stun2.l.google.com:19302'},
          {'urls': 'stun:stun.cloudflare.com:3478'},
        ]
      };

      CallUtility.log('TherapistChat',
          '🔧 Peer config created, calling GlobalCallService.createCall()');

      // Create call using the new clean system (same as patient chat)
      final callId = await GlobalCallService().createCall(
        recipientId: targetUserId,
        peerConnectionConfig: peerConnectionConfig,
      );

      CallUtility.log('TherapistChat',
          '📋 GlobalCallService.createCall() returned: $callId');

      if (callId != null && mounted) {
        CallUtility.log('TherapistChat', '✅ Call created with ID: $callId');
        CallUtility.log('TherapistChat', '📱 Showing CallerScreen');

        // Show caller screen using the static method (same as patient chat)
        CallerScreen.show(
          context: context,
          callDocId: callId,
          targetUserId: targetUserId,
          targetUserName: _patientName.isNotEmpty ? _patientName : 'Patient',
          currentUserId: currentUserId,
        );

        // Show feedback message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Calling ${_patientName.isNotEmpty ? _patientName : 'Patient'}...')),
        );

        CallUtility.log('TherapistChat', '✅ CallerScreen shown successfully');
      } else {
        CallUtility.log(
            'TherapistChat', '❌ Failed to create call - callId is null');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to create call')),
          );
        }
      }
    } catch (e) {
      CallUtility.log('TherapistChat', '❌ Error initiating call: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start call: $e')),
        );
      }
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF006A5B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF67AFA5),
              child: Text(
                _patientName.isNotEmpty ? _patientName[0].toUpperCase() : 'P',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _patientName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const Text(
                    'Online',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam, color: Colors.white),
            onPressed: () {
              print('🎥 Call button pressed in TherapistChat');
              _initiateCall();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SafeArea(
            child: Column(
              children: [
                // Messages Area
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('Message')
                        .orderBy('timestamp', descending: false)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data == null) {
                        return const Center(child: Text('No messages yet.'));
                      }
                      final docs = snapshot.data!.docs;
                      // Filter messages between this clinic and patient
                      final filteredDocs = docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final fromId = data['fromId']?.toString() ?? '';
                        final toId = data['toId']?.toString() ?? '';
                        final patientId = widget.patientId ?? 'unknown';

                        // Check if message is between clinic and this patient
                        return (fromId == _clinicId && toId == patientId) ||
                            (fromId == patientId && toId == _clinicId);
                      }).toList();

                      final messages = filteredDocs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final isFromTherapist = data['fromId'] == _clinicId;
                        return ChatMessage(
                          id: doc.id,
                          senderId: data['fromId']?.toString() ?? '',
                          senderName: isFromTherapist ? 'You' : _patientName,
                          message: data['message']?.toString() ?? '',
                          timestamp: (data['timestamp'] is Timestamp)
                              ? (data['timestamp'] as Timestamp).toDate()
                              : DateTime.now(),
                          isFromTherapist: isFromTherapist,
                        );
                      }).toList();
                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          return _buildMessageBubble(message);
                        },
                      );
                    },
                  ),
                ),

                // Message Input Area
                Container(
                  constraints: BoxConstraints(
                    maxHeight:
                        constraints.maxHeight * 0.2, // Max 20% of screen height
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, -1),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: TextField(
                            controller: _messageController,
                            decoration: const InputDecoration(
                              hintText: 'Type a message...',
                              hintStyle: TextStyle(
                                color: Colors.grey,
                                fontFamily: 'Poppins',
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                            ),
                            maxLines: 4,
                            minLines: 1,
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _sendMessage,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: Color(0xFF006A5B),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.send,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: message.isFromTherapist
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!message.isFromTherapist) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF67AFA5),
              child: Text(
                message.senderName.isNotEmpty
                    ? message.senderName[0].toUpperCase()
                    : 'P',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: message.isFromTherapist
                    ? const Color(0xFF006A5B)
                    : Colors.white,
                borderRadius: BorderRadius.circular(18).copyWith(
                  bottomLeft: message.isFromTherapist
                      ? const Radius.circular(18)
                      : const Radius.circular(4),
                  bottomRight: message.isFromTherapist
                      ? const Radius.circular(4)
                      : const Radius.circular(18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.message,
                    style: TextStyle(
                      color: message.isFromTherapist
                          ? Colors.white
                          : const Color(0xFF006A5B),
                      fontSize: 14,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTimestamp(message.timestamp),
                    style: TextStyle(
                      color: message.isFromTherapist
                          ? Colors.white70
                          : Colors.grey[500],
                      fontSize: 10,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message.isFromTherapist) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF006A5B),
              child: Text(
                message.senderName.isNotEmpty
                    ? message.senderName[0].toUpperCase()
                    : 'T',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime timestamp;
  final bool isFromTherapist;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.timestamp,
    required this.isFromTherapist,
  });
}
