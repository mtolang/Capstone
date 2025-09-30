import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capstone_2/helper/parent_auth.dart';

class PatientSideSelectPage extends StatefulWidget {
  const PatientSideSelectPage({super.key});

  @override
  State<PatientSideSelectPage> createState() => _PatientSideSelectPageState();
}

class _PatientSideSelectPageState extends State<PatientSideSelectPage> {
  final TextEditingController _searchController = TextEditingController();
  List<TherapistMessage> _allTherapists = [];
  List<TherapistMessage> _filteredTherapists = [];

  String _patientId = 'PARAcc01'; // Default fallback

  @override
  void initState() {
    super.initState();
    _loadUserIdFromStorage();
  }

  // Load current user ID from SharedPreferences
  Future<void> _loadUserIdFromStorage() async {
    try {
      // Use ParentAuthService to check authentication
      final isLoggedIn = await ParentAuthService.isLoggedIn();
      final userId = await ParentAuthService.getCurrentParentId();

      final prefs = await SharedPreferences.getInstance();
      final userType = prefs.getString('user_type');
      final storedIsLoggedIn = prefs.getBool('is_logged_in');

      print('PatientSideSelect: Debug auth state:');
      print('  user_id from ParentAuthService: $userId');
      print('  isLoggedIn from ParentAuthService: $isLoggedIn');
      print('  user_type from prefs: $userType');
      print('  is_logged_in from prefs: $storedIsLoggedIn');

      if (userId != null && isLoggedIn) {
        setState(() {
          _patientId = userId;
        });
        print('PatientSideSelect: Using validated patient ID: $_patientId');
        // Load therapists after getting the correct user ID
        _loadTherapists();
      } else {
        print('PatientSideSelect: No valid parent authentication found');
        print('PatientSideSelect: User might need to log in as parent');
        // Show a message that user needs to log in
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please log in as a parent to view conversations'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        // Still load with default ID for testing
        _loadTherapists();
      }
      _filteredTherapists = _allTherapists;
    } catch (e) {
      print('PatientSideSelect: Error loading user ID: $e');
      // Keep default fallback value and load therapists
      _loadTherapists();
      _filteredTherapists = _allTherapists;
    }
  }

  void _loadTherapists() async {
    // Load conversations from Firestore Message collection
    try {
      print(
          'PatientSideSelect: Loading conversations for patient ID: $_patientId');

      // Check if Firebase is properly connected
      print('PatientSideSelect: Checking Firebase connection...');

      final messagesSnapshot = await FirebaseFirestore.instance
          .collection('Message')
          .where('fromId', isEqualTo: _patientId)
          .get();

      final receivedSnapshot = await FirebaseFirestore.instance
          .collection('Message')
          .where('toId', isEqualTo: _patientId)
          .get();

      print('PatientSideSelect: Firebase query results:');
      print('  Sent messages: ${messagesSnapshot.docs.length}');
      print('  Received messages: ${receivedSnapshot.docs.length}');

      // Debug: Log all found messages
      print('PatientSideSelect: Sent message details:');
      for (var doc in messagesSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        print(
            '  From: ${data['fromId']} To: ${data['toId']} Message: ${data['message']}');
      }

      print('PatientSideSelect: Received message details:');
      for (var doc in receivedSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        print(
            '  From: ${data['fromId']} To: ${data['toId']} Message: ${data['message']}');
      }

      // Combine both sent and received messages
      final allMessages = [...messagesSnapshot.docs, ...receivedSnapshot.docs];
      print('PatientSideSelect: Total messages found: ${allMessages.length}');

      // Debug: Let's also check what parent accounts exist
      final parentsSnapshot =
          await FirebaseFirestore.instance.collection('ParentsAcc').get();
      print('PatientSideSelect: Available parent accounts:');
      for (var doc in parentsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        print(
            '  ID: ${doc.id}, Name: ${data['Name']}, Email: ${data['Email']}');
      }

      // Get unique clinic/therapist IDs
      final uniqueContacts = <String, Map<String, dynamic>>{};

      for (var doc in allMessages) {
        final data = doc.data();
        final fromId = data['fromId']?.toString() ?? '';
        final toId = data['toId']?.toString() ?? '';
        final message = data['message']?.toString() ?? '';
        final timestamp = data['timestamp'];

        // Determine the other party (not the current patient)
        final otherPartyId = fromId == _patientId ? toId : fromId;

        if (otherPartyId.isNotEmpty && otherPartyId != _patientId) {
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
              'isFromMe': fromId == _patientId,
            };
          }
        }
      }

      // Convert to TherapistMessage objects and get clinic names
      final List<TherapistMessage> conversations = [];

      for (var contact in uniqueContacts.values) {
        final contactId = contact['id'] as String;
        final lastMessage = contact['lastMessage'] as String;
        final timestamp = contact['timestamp'] as Timestamp?;
        final isFromMe = contact['isFromMe'] as bool;

        // Get clinic/therapist name from ClinicAcc collection
        String contactName = 'Unknown';
        try {
          final clinicDoc = await FirebaseFirestore.instance
              .collection('ClinicAcc')
              .doc(contactId)
              .get();
          if (clinicDoc.exists) {
            final clinicData = clinicDoc.data() as Map<String, dynamic>;
            contactName = clinicData['Clinic Name'] ?? 'Unknown Clinic';
          }
        } catch (e) {
          print('Error fetching clinic name: $e');
        }

        conversations.add(TherapistMessage(
          id: contactId,
          name: contactName,
          lastMessage: isFromMe ? 'You: $lastMessage' : lastMessage,
          timestamp: timestamp != null
              ? _formatTimestamp(timestamp.toDate())
              : 'Unknown',
          profileImage: '',
          unreadCount: 0, // You can implement unread count logic later
          specialization: 'Clinic',
          isOnline: false, // You can implement online status later
        ));

        print(
            'Added conversation with: $contactName (ID: $contactId)'); // Debug log
      }

      print(
          'PatientSideSelect: Total conversations loaded: ${conversations.length}');

      setState(() {
        _allTherapists = conversations;
        _filteredTherapists = conversations;
      });
    } catch (e) {
      print('Error loading conversations: $e');
      setState(() {
        _allTherapists = [];
        _filteredTherapists = [];
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

  Future<void> _showNewConversationDialog() async {
    // Ensure we have a valid patient ID before showing new conversation options
    if (_patientId.isEmpty || _patientId == 'PARAcc01') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to start a conversation'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final clinicsSnapshot =
        await FirebaseFirestore.instance.collection('ClinicAcc').get();
    final clinics = clinicsSnapshot.docs;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Start New Conversation',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF006A5B),
              ),
            ),
            const SizedBox(height: 20),
            ...clinics.map((doc) {
              final data = doc.data();
              return ListTile(
                leading:
                    const Icon(Icons.local_hospital, color: Color(0xFF006A5B)),
                title: Text(data['Clinic Name'] ?? 'Clinic'),
                subtitle: Text(data['email'] ?? ''),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(
                    context,
                    '/patientchat',
                    arguments: {
                      'therapistId': doc.id,
                      'therapistName': data['Clinic Name'] ?? 'Clinic',
                      'isPatientSide': true,
                    },
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _filterTherapists(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredTherapists = _allTherapists;
      } else {
        _filteredTherapists = _allTherapists
            .where((therapist) =>
                therapist.name.toLowerCase().contains(query.toLowerCase()) ||
                therapist.specialization
                    .toLowerCase()
                    .contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
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
                          icon: const Icon(Icons.menu,
                              color: Colors.white, size: 24),
                          onPressed: () {
                            // Handle drawer menu
                            Navigator.pop(context);
                          },
                        ),
                        const Expanded(
                          child: Text(
                            'Your Therapists',
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
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _filterTherapists,
                        decoration: InputDecoration(
                          hintText: 'Search therapists or specializations',
                          hintStyle: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                            fontFamily: 'Poppins',
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Color(0xFF006A5B),
                            size: 20,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 15,
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
                    'Conversations',
                    style: TextStyle(
                      color: Color(0xFF67AFA5),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                // Therapist List
                Expanded(
                  child: _filteredTherapists.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.message_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No conversations found',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _filteredTherapists.length,
                          itemBuilder: (context, index) {
                            final therapist = _filteredTherapists[index];
                            return _buildTherapistTile(therapist);
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
        onPressed: _showNewConversationDialog,
        backgroundColor: const Color(0xFF006A5B),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildTherapistTile(TherapistMessage therapist) {
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
              backgroundImage: AssetImage(therapist.profileImage),
              onBackgroundImageError: (exception, stackTrace) {
                // Handle image loading error
              },
              child: therapist.profileImage.isEmpty
                  ? Text(
                      therapist.name.isNotEmpty
                          ? therapist.name[0].toUpperCase()
                          : 'T',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    )
                  : null,
            ),
            // Online status indicator
            if (therapist.isOnline)
              Positioned(
                bottom: 0,
                right: 0,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    therapist.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Color(0xFF006A5B),
                      fontFamily: 'Poppins',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    therapist.specialization,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            if (therapist.unreadCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF006A5B),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  therapist.unreadCount.toString(),
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
              therapist.lastMessage,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontFamily: 'Poppins',
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  therapist.timestamp,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                    fontFamily: 'Poppins',
                  ),
                ),
                if (therapist.isOnline) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Online',
                    style: TextStyle(
                      color: Colors.green[600],
                      fontSize: 12,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        onTap: () {
          // Navigate to patient chat page with selected therapist
          Navigator.pushNamed(
            context,
            '/patientchat',
            arguments: {
              'therapistId': therapist.id,
              'therapistName': therapist.name,
              'isPatientSide': true,
            },
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

class TherapistMessage {
  final String id;
  final String name;
  final String lastMessage;
  final String timestamp;
  final String profileImage;
  final int unreadCount;
  final String specialization;
  final bool isOnline;

  TherapistMessage({
    required this.id,
    required this.name,
    required this.lastMessage,
    required this.timestamp,
    required this.profileImage,
    required this.unreadCount,
    required this.specialization,
    required this.isOnline,
  });
}
