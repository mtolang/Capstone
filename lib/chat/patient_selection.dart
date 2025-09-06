import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PatientSelectionPage extends StatefulWidget {
  const PatientSelectionPage({super.key});

  @override
  State<PatientSelectionPage> createState() => _PatientSelectionPageState();
}

class _PatientSelectionPageState extends State<PatientSelectionPage> {
  final TextEditingController _searchController = TextEditingController();
  List<PatientMessage> _allPatients = [];
  List<PatientMessage> _filteredPatients = [];

  // Use CLI01 as the current clinic ID - replace with actual clinic ID
  final String _clinicId = 'CLI01';

  @override
  void initState() {
    super.initState();
    _loadPatients();
    _filteredPatients = _allPatients;
  }

  void _loadPatients() async {
    // Load conversations from Firestore Message collection
    try {
      final messagesSnapshot = await FirebaseFirestore.instance
          .collection('Message')
          .where('fromId', isEqualTo: _clinicId)
          .get();

      final receivedSnapshot = await FirebaseFirestore.instance
          .collection('Message')
          .where('toId', isEqualTo: _clinicId)
          .get();

      // Combine both sent and received messages
      final allMessages = [...messagesSnapshot.docs, ...receivedSnapshot.docs];

      // Get unique patient IDs
      final uniqueContacts = <String, Map<String, dynamic>>{};

      for (var doc in allMessages) {
        final data = doc.data();
        final fromId = data['fromId']?.toString() ?? '';
        final toId = data['toId']?.toString() ?? '';
        final message = data['message']?.toString() ?? '';
        final timestamp = data['timestamp'];

        // Determine the other party (not the current clinic)
        final otherPartyId = fromId == _clinicId ? toId : fromId;

        if (otherPartyId.isNotEmpty && otherPartyId != _clinicId) {
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
              'isFromMe': fromId == _clinicId,
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
            contactName = parentData['Name'] ?? 'Unknown Parent';
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
                            'Your Messages',
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
                        onChanged: _filterPatients,
                        decoration: InputDecoration(
                          hintText: 'Search for messages',
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
                    'Messages',
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
                                Icons.message_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No messages found',
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
            const SnackBar(content: Text('Start new conversation')),
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
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: const Color(0xFF67AFA5),
          backgroundImage: AssetImage(patient.profileImage),
          onBackgroundImageError: (exception, stackTrace) {
            // Handle image loading error
          },
          child: patient.profileImage.isEmpty
              ? Text(
                  patient.name.isNotEmpty ? patient.name[0].toUpperCase() : 'P',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                )
              : null,
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
        onTap: () {
          // Navigate to chat page with selected patient
          Navigator.pushNamed(
            context,
            '/therapistchat',
            arguments: patient.id,
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
