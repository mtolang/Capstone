import 'package:flutter/material.dart';

class PatientSideSelectPage extends StatefulWidget {
  const PatientSideSelectPage({Key? key}) : super(key: key);

  @override
  State<PatientSideSelectPage> createState() => _PatientSideSelectPageState();
}

class _PatientSideSelectPageState extends State<PatientSideSelectPage> {
  final TextEditingController _searchController = TextEditingController();
  List<TherapistMessage> _allTherapists = [];
  List<TherapistMessage> _filteredTherapists = [];

  @override
  void initState() {
    super.initState();
    _loadTherapists();
    _filteredTherapists = _allTherapists;
  }

  void _loadTherapists() {
    // Sample therapist data - replace with actual data from your backend
    _allTherapists = [
      TherapistMessage(
        id: '1',
        name: 'Dr. Maria Santos',
        lastMessage:
            'Great progress today! Keep practicing the exercises we discussed.',
        timestamp: '2:30 PM',
        profileImage: 'asset/images/profile.jpg',
        unreadCount: 1,
        specialization: 'Speech Therapist',
        isOnline: true,
      ),
      TherapistMessage(
        id: '2',
        name: 'Dr. Juan Cruz',
        lastMessage:
            'Your next appointment is scheduled for tomorrow at 10 AM.',
        timestamp: '11:45 AM',
        profileImage: 'asset/images/profile.jpg',
        unreadCount: 0,
        specialization: 'Occupational Therapist',
        isOnline: true,
      ),
      TherapistMessage(
        id: '3',
        name: 'Dr. Sarah Wilson',
        lastMessage: 'Please bring your exercise chart to our next session.',
        timestamp: 'Yesterday',
        profileImage: 'asset/images/profile.jpg',
        unreadCount: 2,
        specialization: 'Physical Therapist',
        isOnline: false,
      ),
      TherapistMessage(
        id: '4',
        name: 'The Tiny House Therapy Center',
        lastMessage:
            'Welcome to our therapy center! How can we help you today?',
        timestamp: '2 days ago',
        profileImage: 'asset/images/profile.jpg',
        unreadCount: 0,
        specialization: 'Main Reception',
        isOnline: true,
      ),
    ];
    _filteredTherapists = _allTherapists;
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
        onPressed: () {
          // Handle new message
          _showNewConversationDialog();
        },
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

  void _showNewConversationDialog() {
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
            ListTile(
              leading:
                  const Icon(Icons.local_hospital, color: Color(0xFF006A5B)),
              title: const Text('Contact Reception'),
              subtitle: const Text('General inquiries and appointments'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  '/patientchat',
                  arguments: {
                    'therapistId': '4',
                    'therapistName': 'The Tiny House Therapy Center',
                    'isPatientSide': true,
                  },
                );
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.person_search, color: Color(0xFF006A5B)),
              title: const Text('Find a Therapist'),
              subtitle: const Text('Browse available specialists'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Find therapist functionality')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline, color: Color(0xFF006A5B)),
              title: const Text('Help & Support'),
              subtitle: const Text('Get help with the app'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Help & Support functionality')),
                );
              },
            ),
          ],
        ),
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
