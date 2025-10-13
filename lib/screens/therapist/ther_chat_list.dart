import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../helper/field_helper.dart';
import '../../chat/therapist_chat.dart';
import 'ther_navbar.dart';

class TherapistChatListPage extends StatefulWidget {
  const TherapistChatListPage({Key? key}) : super(key: key);

  @override
  State<TherapistChatListPage> createState() => _TherapistChatListPageState();
}

class _TherapistChatListPageState extends State<TherapistChatListPage> {
  String? _currentTherapistId;
  List<Map<String, dynamic>> _patients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTherapistId();
  }

  Future<void> _loadTherapistId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final therapistId =
          prefs.getString('therapist_id') ?? prefs.getString('user_id');

      if (therapistId != null) {
        setState(() {
          _currentTherapistId = therapistId;
        });
        await _loadPatients();
      } else {
        print('No therapist ID found in storage');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading therapist ID: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPatients() async {
    if (_currentTherapistId == null) return;

    try {
      // Get all messages where therapist is involved
      final messagesSnapshot = await FirebaseFirestore.instance
          .collection('Message')
          .where('fromId', isEqualTo: _currentTherapistId)
          .get();

      final messagesSnapshot2 = await FirebaseFirestore.instance
          .collection('Message')
          .where('toId', isEqualTo: _currentTherapistId)
          .get();

      // Combine and get unique patient IDs
      Set<String> patientIds = {};

      for (var doc in messagesSnapshot.docs) {
        final data = doc.data();
        final toId = data['toId']?.toString();
        if (toId != null && toId != _currentTherapistId) {
          patientIds.add(toId);
        }
      }

      for (var doc in messagesSnapshot2.docs) {
        final data = doc.data();
        final fromId = data['fromId']?.toString();
        if (fromId != null && fromId != _currentTherapistId) {
          patientIds.add(fromId);
        }
      }

      // Get patient details from ParentsAcc collection
      List<Map<String, dynamic>> patients = [];
      for (String patientId in patientIds) {
        try {
          final patientDoc = await FirebaseFirestore.instance
              .collection('ParentsAcc')
              .doc(patientId)
              .get();

          if (patientDoc.exists) {
            final patientData = patientDoc.data() as Map<String, dynamic>;

            // Get last message between therapist and this patient
            final lastMessage = await _getLastMessage(patientId);

            patients.add({
              'id': patientId,
              'name': FieldHelper.getName(patientData) ?? 'Unknown Patient',
              'email': patientData['Email'] ?? '',
              'lastMessage': lastMessage?['message'] ?? 'No messages yet',
              'lastMessageTime': lastMessage?['timestamp'],
              'isOnline': true, // You can implement online status later
            });
          }
        } catch (e) {
          print('Error loading patient $patientId: $e');
        }
      }

      // Sort by last message time
      patients.sort((a, b) {
        final aTime = a['lastMessageTime'] as DateTime?;
        final bTime = b['lastMessageTime'] as DateTime?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });

      setState(() {
        _patients = patients;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading patients: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>?> _getLastMessage(String patientId) async {
    try {
      // Get last message between therapist and patient
      final querySnapshot = await FirebaseFirestore.instance
          .collection('Message')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      final filteredDocs = querySnapshot.docs.where((doc) {
        final data = doc.data();
        final fromId = data['fromId']?.toString() ?? '';
        final toId = data['toId']?.toString() ?? '';

        return (fromId == _currentTherapistId && toId == patientId) ||
            (fromId == patientId && toId == _currentTherapistId);
      }).toList();

      if (filteredDocs.isNotEmpty) {
        final data = filteredDocs.first.data();
        return {
          'message': data['message']?.toString() ?? '',
          'timestamp':
              (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        };
      }
    } catch (e) {
      print('Error getting last message: $e');
    }
    return null;
  }

  String _formatLastMessageTime(DateTime? time) {
    if (time == null) return '';

    final now = DateTime.now();
    final difference = now.difference(time);

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
      appBar: AppBar(
        backgroundColor: const Color(0xFF006A5B),
        elevation: 0,
        title: const Text(
          'Patient Chats',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Poppins',
          ),
        ),
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              color: Colors.white,
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
      ),
      drawer: const TherapistNavbar(currentPage: 'chat'),
      body: Stack(
        children: [
          // Background ellipses
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ConstrainedBox(
              constraints: BoxConstraints.expand(
                  height: MediaQuery.of(context).size.height * 0.3),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF006A5B), Color(0xFF67AFA5)],
                  ),
                ),
                child: Image.asset(
                  'asset/images/Ellipse 1.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container();
                  },
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ConstrainedBox(
              constraints: BoxConstraints.expand(
                  height: MediaQuery.of(context).size.height * 0.3),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xFF67AFA5), Colors.white],
                  ),
                ),
                child: Image.asset(
                  'asset/images/Ellipse 2.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container();
                  },
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF006A5B),
                    ),
                  )
                : _patients.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No patient conversations',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Start chatting with your patients',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _patients.length,
                        itemBuilder: (context, index) {
                          final patient = _patients[index];
                          return _buildPatientChatCard(patient);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientChatCard(Map<String, dynamic> patient) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TherapistChatPage(
                patientId: patient['id'],
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            // Patient Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFF67AFA5),
                  child: Text(
                    patient['name'].isNotEmpty
                        ? patient['name'][0].toUpperCase()
                        : 'P',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                if (patient['isOnline'] == true)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),

            // Patient info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        patient['name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF006A5B),
                          fontFamily: 'Poppins',
                        ),
                      ),
                      Text(
                        _formatLastMessageTime(patient['lastMessageTime']),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    patient['lastMessage'],
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontFamily: 'Poppins',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Arrow indicator
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}
