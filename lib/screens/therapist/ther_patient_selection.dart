import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kindora/helper/therapist_auth.dart';
import 'package:kindora/helper/field_helper.dart';
import '../../chat/therapist_chat.dart';
import 'ther_navbar.dart';

class TherapistPatientSelectionPage extends StatefulWidget {
  const TherapistPatientSelectionPage({super.key});

  @override
  State<TherapistPatientSelectionPage> createState() =>
      _TherapistPatientSelectionPageState();
}

class _TherapistPatientSelectionPageState
    extends State<TherapistPatientSelectionPage> {
  final TextEditingController _searchController = TextEditingController();
  List<PatientMessage> _allPatients = [];
  List<PatientMessage> _filteredPatients = [];

  String _therapistId = 'TherAcc01'; // Default fallback

  @override
  void initState() {
    super.initState();
    _loadUserIdFromStorage();
  }

  // Load current therapist ID from SharedPreferences
  Future<void> _loadUserIdFromStorage() async {
    try {
      // Use TherapistAuthService to check authentication
      final isLoggedIn = await TherapistAuthService.isLoggedIn;
      final therapistId = await TherapistAuthService.getStoredTherapistId();

      final prefs = await SharedPreferences.getInstance();
      final userType = prefs.getString('user_type');
      final storedIsLoggedIn = prefs.getBool('is_logged_in');

      print('TherapistPatientSelection: Debug therapist auth state:');
      print('  therapist_id from TherapistAuthService: $therapistId');
      print('  isLoggedIn from TherapistAuthService: $isLoggedIn');
      print('  user_type from prefs: $userType');
      print('  is_logged_in from prefs: $storedIsLoggedIn');

      if (therapistId != null && isLoggedIn && userType == 'therapist') {
        setState(() {
          _therapistId = therapistId;
        });
        print(
            'TherapistPatientSelection: Using validated therapist ID: $_therapistId');
        // Load patients after getting the correct therapist ID
        _loadPatients();
      } else {
        print(
            'TherapistPatientSelection: No valid therapist authentication found');
        print(
            'TherapistPatientSelection: User might need to log in as therapist');
        // Show a message that user needs to log in
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Please log in as a therapist to view patient messages'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        // Still load with default ID for testing
        print(
            'TherapistPatientSelection: Using default therapist ID: $_therapistId');
        _loadPatients();
      }
      _filteredPatients = _allPatients;
    } catch (e) {
      print('TherapistPatientSelection: Error loading therapist ID: $e');
      // Keep default fallback value and load patients
      _loadPatients();
      _filteredPatients = _allPatients;
    }
  }

  void _loadPatients() async {
    // Load conversations from Firestore Message collection
    try {
      print(
          'TherapistPatientSelection: Loading conversations for therapist ID: $_therapistId');

      // Check Firebase connection
      print('TherapistPatientSelection: Checking Firebase connection...');

      final messagesSnapshot = await FirebaseFirestore.instance
          .collection('Message')
          .where('fromId', isEqualTo: _therapistId)
          .get();

      final receivedSnapshot = await FirebaseFirestore.instance
          .collection('Message')
          .where('toId', isEqualTo: _therapistId)
          .get();

      print('TherapistPatientSelection: Firebase query results:');
      print('  Sent messages: ${messagesSnapshot.docs.length}');
      print('  Received messages: ${receivedSnapshot.docs.length}');

      // Debug: Log all found messages
      print('TherapistPatientSelection: Sent message details:');
      for (var doc in messagesSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        print(
            '  From: ${data['fromId']} To: ${data['toId']} Message: ${data['message']}');
      }

      print('TherapistPatientSelection: Received message details:');
      for (var doc in receivedSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        print(
            '  From: ${data['fromId']} To: ${data['toId']} Message: ${data['message']}');
      }

      // Combine both sent and received messages
      final allMessages = [...messagesSnapshot.docs, ...receivedSnapshot.docs];
      print(
          'TherapistPatientSelection: Total messages found: ${allMessages.length}');

      // Debug: Let's also check what parent accounts exist
      final parentsSnapshot =
          await FirebaseFirestore.instance.collection('ParentsAcc').get();
      print('TherapistPatientSelection: Available parent accounts:');
      for (var doc in parentsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final name = FieldHelper.getName(data) ?? data['Name'] ?? 'Unknown';
        final email = data['Email'] ?? 'No email';
        print('  ID: ${doc.id}, Name: $name, Email: $email');
      }

      // Get unique patient IDs
      final uniqueContacts = <String, Map<String, dynamic>>{};

      for (var doc in allMessages) {
        final data = doc.data();
        final fromId = data['fromId']?.toString() ?? '';
        final toId = data['toId']?.toString() ?? '';
        final message = data['message']?.toString() ?? '';
        final timestamp = data['timestamp'];

        // Determine the other party (not the current therapist)
        final otherPartyId = fromId == _therapistId ? toId : fromId;

        if (otherPartyId.isNotEmpty && otherPartyId != _therapistId) {
          // Only keep the latest message for each contact
          if (!uniqueContacts.containsKey(otherPartyId) ||
              (timestamp != null &&
                  uniqueContacts[otherPartyId]!['timestamp'] != null &&
                  (timestamp as Timestamp).compareTo(
                          uniqueContacts[otherPartyId]!['timestamp']) >
                      0)) {
            uniqueContacts[otherPartyId] = {
              'id': otherPartyId,
              'lastMessage': message,
              'timestamp': timestamp,
              'isFromMe': fromId == _therapistId,
            };
          }
        }
      }

      // Convert to PatientMessage objects and get patient names
      final List<PatientMessage> conversations = [];

      for (var contact in uniqueContacts.values) {
        final contactId = contact['id'] as String;
        final lastMessage = contact['lastMessage'] as String;
        final timestamp = contact['timestamp'] as Timestamp?;
        final isFromMe = contact['isFromMe'] as bool;

        // Get patient/parent name from ParentsAcc collection
        String contactName = 'Unknown';
        try {
          final parentDoc = await FirebaseFirestore.instance
              .collection('ParentsAcc')
              .doc(contactId)
              .get();
          if (parentDoc.exists) {
            final parentData = parentDoc.data() as Map<String, dynamic>;
            contactName = FieldHelper.getName(parentData) ??
                parentData['Name'] ??
                'Unknown Parent';
          }
        } catch (e) {
          print('Error fetching parent name: $e');
        }

        conversations.add(PatientMessage(
          id: contactId,
          name: contactName,
          lastMessage: isFromMe ? 'You: $lastMessage' : lastMessage,
          timestamp: timestamp != null
              ? _formatTimestamp(timestamp.toDate())
              : 'Unknown',
          profileImage: '',
          unreadCount: 0, // You can implement unread count logic later
        ));
      }

      // Sort by timestamp (most recent first)
      conversations.sort((a, b) {
        if (a.timestamp == 'Unknown' && b.timestamp == 'Unknown') return 0;
        if (a.timestamp == 'Unknown') return 1;
        if (b.timestamp == 'Unknown') return -1;
        // For now, we'll just sort alphabetically by timestamp string
        // In a real app, you'd want to store the actual DateTime for sorting
        return b.timestamp.compareTo(a.timestamp);
      });

      setState(() {
        _allPatients = conversations;
        _filteredPatients = conversations;
      });
    } catch (e) {
      print('Error loading conversations: $e');
      setState(() {
        _allPatients = [];
        _filteredPatients = [];
      });
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

  void _filterPatients(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredPatients = _allPatients;
      } else {
        _filteredPatients = _allPatients
            .where((patient) =>
                patient.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      drawer: const TherapistNavbar(currentPage: 'chat'),
      body: Column(
        children: [
          // Custom Header with wave design
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF006A5B),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.menu, color: Colors.white),
                          onPressed: () {
                            Scaffold.of(context).openDrawer();
                          },
                        ),
                        const Expanded(
                          child: Text(
                            'Patient Chats',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 48), // Balance the menu icon
                      ],
                    ),
                    const SizedBox(height: 15),
                    // Search Bar
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _filterPatients,
                        decoration: const InputDecoration(
                          hintText: 'Search patients...',
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontFamily: 'Poppins',
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Color(0xFF67AFA5),
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Messages Section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // Messages label
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Patient Messages',
                    style: TextStyle(
                      color: Color(0xFF67AFA5),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                // Patient List
                Expanded(
                  child: _filteredPatients.isEmpty
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
                                _allPatients.isEmpty
                                    ? 'No patient conversations yet'
                                    : 'No patients found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _allPatients.isEmpty
                                    ? 'Start chatting with your patients'
                                    : 'Try adjusting your search',
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
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _filteredPatients.length,
                          itemBuilder: (context, index) {
                            final patient = _filteredPatients[index];
                            return _buildPatientTile(patient);
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),

      // Floating Action Button
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Handle new message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Start new conversation with a patient'),
              backgroundColor: Color(0xFF006A5B),
            ),
          );
        },
        backgroundColor: const Color(0xFF006A5B),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildPatientTile(PatientMessage patient) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: const Color(0xFF67AFA5),
              child: Text(
                patient.name.isNotEmpty ? patient.name[0].toUpperCase() : 'P',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            // Online indicator
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
        title: Row(
          children: [
            Expanded(
              child: Text(
                patient.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Color(0xFF006A5B),
                  fontFamily: 'Poppins',
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (patient.unreadCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF006A5B),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  patient.unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              patient.lastMessage,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontFamily: 'Poppins',
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              patient.timestamp,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Color(0xFF67AFA5),
        ),
        onTap: () {
          // Navigate to chat page with selected patient
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TherapistChatPage(
                patientId: patient.id,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class PatientMessage {
  final String id;
  final String name;
  final String lastMessage;
  final String timestamp;
  final String profileImage;
  final int unreadCount;

  PatientMessage({
    required this.id,
    required this.name,
    required this.lastMessage,
    required this.timestamp,
    required this.profileImage,
    required this.unreadCount,
  });
}
