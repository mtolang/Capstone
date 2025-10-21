import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ClinicPatientProfile extends StatefulWidget {
  final String patientId;
  final String patientName;
  final String patientImageUrl;

  const ClinicPatientProfile({
    Key? key,
    required this.patientId,
    required this.patientName,
    required this.patientImageUrl,
  }) : super(key: key);

  @override
  _ClinicPatientProfileState createState() => _ClinicPatientProfileState();
}

class _ClinicPatientProfileState extends State<ClinicPatientProfile>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 30), // Increased spacing
            _buildProfileSection(),
            const SizedBox(height: 20), // Added spacing between profile and tabs
            _buildTabBar(),
            const SizedBox(height: 30), // Increased spacing after tabbar
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6, // More space for content
              child: _buildTabBarView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 180,
      decoration: const BoxDecoration(
        color: Color(0xFF4A90E2),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Stack(
        children: [
          // Top ellipse - removed gradient, only ellipse image
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          // Bottom ellipse - removed gradient, only ellipse image
          Positioned(
            bottom: -30,
            left: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          // App bar content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Patient Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipOval(
              child: widget.patientImageUrl.isNotEmpty
                  ? Image.network(
                      widget.patientImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => 
                          const Icon(Icons.person, size: 40, color: Colors.grey),
                    )
                  : const Icon(Icons.person, size: 40, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 20), // Improved spacing
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.patientName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Patient ID: ${widget.patientId}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF718096),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF48BB78),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Active',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF4A90E2),
        unselectedLabelColor: const Color(0xFF718096),
        labelStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        indicator: BoxDecoration(
          color: const Color(0xFF4A90E2).withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
        ),
        indicatorPadding: const EdgeInsets.all(6),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(
            icon: Icon(Icons.info_outline, size: 20),
            text: 'Info',
          ),
          Tab(
            icon: Icon(Icons.library_books, size: 20), // Changed icon for Records
            text: 'Records', // Changed from Progress to Records
          ),
          Tab(
            icon: Icon(Icons.calendar_today, size: 20),
            text: 'Sessions',
          ),
        ],
      ),
    );
  }

  Widget _buildTabBarView() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildInfoTab(),
          _buildRecordsTab(), // Changed from Progress to Records
          _buildSessionsTab(),
        ],
      ),
    );
  }

  Widget _buildInfoTab() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('ParentsAcc')
          .doc(widget.patientId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF4A90E2),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading patient info',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.red.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_off_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No patient information found',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoCard('Personal Information', [
                _buildInfoRow('Full Name', data['fullName'] ?? 'N/A'),
                _buildInfoRow('Email', data['email'] ?? 'N/A'),
                _buildInfoRow('Phone', data['phoneNumber'] ?? 'N/A'),
                _buildInfoRow('Address', data['address'] ?? 'N/A'),
              ]),
              const SizedBox(height: 16),
              _buildInfoCard('Child Information', [
                _buildInfoRow('Child Name', data['childName'] ?? 'N/A'),
                _buildInfoRow('Age', data['childAge']?.toString() ?? 'N/A'),
                _buildInfoRow('Condition', data['childCondition'] ?? 'N/A'),
                _buildInfoRow('Emergency Contact', data['emergencyContact'] ?? 'N/A'),
              ]),
              const SizedBox(height: 16),
              _buildInfoCard('Account Details', [
                _buildInfoRow('Registration Date', _formatDate(data['createdAt'])),
                _buildInfoRow('Last Updated', _formatDate(data['updatedAt'])),
                _buildInfoRow('Status', data['isActive'] == true ? 'Active' : 'Inactive'),
              ]),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecordsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Journal')
          .where('parentId', isEqualTo: widget.patientId)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF4A90E2),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading journal records',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.red.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.book_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No journal records found',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        final records = snapshot.data!.docs;
        
        return Column(
          children: [
            // Records statistics
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _buildRecordStat('Total Records', records.length.toString()),
                  _buildRecordStat('This Month', _getThisMonthCount(records).toString()),
                  _buildRecordStat('Recent', _getRecentCount(records).toString()),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Records list
            Expanded(
              child: ListView.builder(
                itemCount: records.length,
                itemBuilder: (context, index) {
                  final record = records[index].data() as Map<String, dynamic>;
                  return _buildJournalCard(record);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSessionsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('AcceptedBooking')
          .where('parentID', isEqualTo: widget.patientId)
          .orderBy('selectedDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF4A90E2),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading sessions',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.red.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.event_busy,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No sessions found',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        final sessions = snapshot.data!.docs;
        
        return ListView.builder(
          itemCount: sessions.length,
          itemBuilder: (context, index) {
            final session = sessions[index].data() as Map<String, dynamic>;
            return _buildBookingCard(session);
          },
        );
      },
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF718096),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF2D3748),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordStat(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A90E2),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF718096),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJournalCard(Map<String, dynamic> record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                record['title'] ?? 'Journal Entry',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3748),
                ),
              ),
              Text(
                _formatDate(record['timestamp']),
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF718096),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            record['content'] ?? record['description'] ?? 'No content available',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF4A5568),
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          if (record['mood'] != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF4A90E2).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Mood: ${record['mood']}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF4A90E2),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                booking['sessionType'] ?? 'Therapy Session',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3748),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(booking['status']),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  booking['status'] ?? 'Scheduled',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                _formatDate(booking['selectedDate']),
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF4A5568),
                ),
              ),
            ],
          ),
          if (booking['selectedTime'] != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  booking['selectedTime'],
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF4A5568),
                  ),
                ),
              ],
            ),
          ],
          if (booking['therapistName'] != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Therapist: ${booking['therapistName']}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF4A5568),
                  ),
                ),
              ],
            ),
          ],
          if (booking['notes'] != null && booking['notes'].toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              booking['notes'],
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF718096),
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return const Color(0xFF48BB78);
      case 'cancelled':
        return const Color(0xFFE53E3E);
      case 'pending':
        return const Color(0xFFED8936);
      default:
        return const Color(0xFF4A90E2);
    }
  }

  int _getThisMonthCount(List<QueryDocumentSnapshot> records) {
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month);
    
    return records.where((record) {
      final data = record.data() as Map<String, dynamic>;
      final timestamp = data['timestamp'];
      if (timestamp == null) return false;
      
      DateTime recordDate;
      if (timestamp is Timestamp) {
        recordDate = timestamp.toDate();
      } else if (timestamp is String) {
        recordDate = DateTime.tryParse(timestamp) ?? DateTime.now();
      } else {
        return false;
      }
      
      return recordDate.isAfter(thisMonth);
    }).length;
  }

  int _getRecentCount(List<QueryDocumentSnapshot> records) {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    
    return records.where((record) {
      final data = record.data() as Map<String, dynamic>;
      final timestamp = data['timestamp'];
      if (timestamp == null) return false;
      
      DateTime recordDate;
      if (timestamp is Timestamp) {
        recordDate = timestamp.toDate();
      } else if (timestamp is String) {
        recordDate = DateTime.tryParse(timestamp) ?? DateTime.now();
      } else {
        return false;
      }
      
      return recordDate.isAfter(weekAgo);
    }).length;
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    
    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is String) {
      date = DateTime.tryParse(timestamp) ?? DateTime.now();
    } else {
      return 'N/A';
    }
    
    return '${date.day}/${date.month}/${date.year}';
  }
}