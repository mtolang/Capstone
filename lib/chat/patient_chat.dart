import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_call.dart';

class PatientChatPage extends StatefulWidget {
  final String? therapistId;
  final String? therapistName;
  final bool isPatientSide;

  const PatientChatPage({
    super.key,
    this.therapistId,
    this.therapistName,
    this.isPatientSide = true,
  });

  @override
  State<PatientChatPage> createState() => _PatientChatPageState();
}

class _PatientChatPageState extends State<PatientChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _contactName = '';

  @override
  void initState() {
    super.initState();
    _loadContactInfo();
  }

  void _loadContactInfo() {
    // Load contact information based on the ID
    if (widget.isPatientSide) {
      // Patient side - showing therapist info
      Map<String, String> therapistNames = {
        '1': 'Dr. Maria Santos',
        '2': 'Dr. Juan Cruz',
        '3': 'Dr. Sarah Wilson',
        '4': 'The Tiny House Therapy Center',
      };
      _contactName = widget.therapistName ??
          therapistNames[widget.therapistId] ??
          'Unknown Therapist';
    } else {
      // Therapist side - showing patient info
      Map<String, String> patientNames = {
        '1': 'Tiny House Therapy Clinic',
        '2': 'Taylor Swift',
        '3': 'Maria Santos',
        '4': 'John Doe',
        '5': 'Sarah Wilson',
      };
      _contactName = patientNames[widget.therapistId] ?? 'Unknown Patient';
    }
  }

  // Use the current parent/patient ID from Firestore
  final String _patientId = 'PARAcc01';

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final messageText = _messageController.text.trim();
    final timestamp = DateTime.now();
    final fromId =
        widget.isPatientSide ? _patientId : (widget.therapistId ?? 'therapist');
    final toId =
        widget.isPatientSide ? (widget.therapistId ?? 'therapist') : _patientId;

    // Save to Firestore
    FirebaseFirestore.instance.collection('Message').add({
      'fromId': fromId,
      'toId': toId,
      'message': messageText,
      'timestamp': timestamp,
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
                _contactName.isNotEmpty ? _contactName[0].toUpperCase() : 'C',
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
                    _contactName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  Text(
                    widget.isPatientSide ? 'Therapist' : 'Patient',
                    style: const TextStyle(
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatCallScreen(
                    callId:
                        'call_${widget.therapistId}_${DateTime.now().millisecondsSinceEpoch}',
                    currentUserId: _patientId,
                    initialParticipants: [widget.therapistId ?? 'CLI01'],
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.call, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatCallScreen(
                    callId:
                        'voice_call_${widget.therapistId}_${DateTime.now().millisecondsSinceEpoch}',
                    currentUserId: _patientId,
                    initialParticipants: [widget.therapistId ?? 'CLI01'],
                  ),
                ),
              );
            },
          ),
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
                      // Filter messages between this patient and clinic
                      final filteredDocs = docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final fromId = data['fromId']?.toString() ?? '';
                        final toId = data['toId']?.toString() ?? '';
                        final therapistId = widget.therapistId ?? 'therapist';

                        // Check if message is between patient and this clinic
                        return (fromId == _patientId && toId == therapistId) ||
                            (fromId == therapistId && toId == _patientId);
                      }).toList();

                      final messages = filteredDocs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final isFromTherapist = data['fromId'] ==
                            (widget.therapistId ?? 'therapist');
                        return ChatMessage(
                          id: doc.id,
                          senderId: data['fromId']?.toString() ?? '',
                          senderName: isFromTherapist
                              ? (widget.therapistName ?? 'Therapist')
                              : 'You',
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
    // For patient side: show user messages on right, therapist on left
    // For therapist side: show therapist messages on right, patient on left
    bool isCurrentUser = widget.isPatientSide
        ? !message.isFromTherapist
        : message.isFromTherapist;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isCurrentUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF67AFA5),
              child: Text(
                message.senderName.isNotEmpty
                    ? message.senderName[0].toUpperCase()
                    : 'C',
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
                color: isCurrentUser ? const Color(0xFF006A5B) : Colors.white,
                borderRadius: BorderRadius.circular(18).copyWith(
                  bottomLeft: isCurrentUser
                      ? const Radius.circular(18)
                      : const Radius.circular(4),
                  bottomRight: isCurrentUser
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
                      color: isCurrentUser
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
                      color: isCurrentUser ? Colors.white70 : Colors.grey[500],
                      fontSize: 10,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isCurrentUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF006A5B),
              child: Text(
                'You'[0].toUpperCase(),
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
