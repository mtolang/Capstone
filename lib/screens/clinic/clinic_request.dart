import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ClinicRequestScreen extends StatefulWidget {
  const ClinicRequestScreen({Key? key}) : super(key: key);

  @override
  State<ClinicRequestScreen> createState() => _ClinicRequestScreenState();
}

class _ClinicRequestScreenState extends State<ClinicRequestScreen> {
  String? _clinicId;

  @override
  void initState() {
    super.initState();
    _getClinicId();
  }

  Future<void> _getClinicId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _clinicId = prefs.getString('clinic_id') ??
          prefs.getString('user_id') ??
          prefs.getString('therapist_id');
      print('Clinic ID loaded: $_clinicId');
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error getting clinic ID: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Pending Requests',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF006A5B),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: () {
              if (_clinicId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        RequestHistoryScreen(clinicId: _clinicId!),
                  ),
                );
              }
            },
            tooltip: 'View History',
          ),
        ],
      ),
      body: _buildPendingRequestsList(),
    );
  }

  Widget _buildPendingRequestsList() {
    if (_clinicId == null) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF006A5B),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Request')
          .where('serviceProvider.clinicId', isEqualTo: _clinicId)
          .where('status', isEqualTo: 'pending')
          .orderBy('appointmentDetails.requestedDate', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF006A5B),
            ),
          );
        }

        final requests = snapshot.data?.docs ?? [];

        if (requests.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Pending Requests',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'All caught up! Check history for past requests.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                      fontFamily: 'Poppins',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final request = requests[index];
            final data = request.data() as Map<String, dynamic>;
            return _buildRequestCard(request.id, data);
          },
        );
      },
    );
  }

  Widget _buildRequestCard(String requestId, Map<String, dynamic> data) {
    final parentInfo = data['parentInfo'] as Map<String, dynamic>? ?? {};
    final childInfo = data['childInfo'] as Map<String, dynamic>? ?? {};
    final appointmentDetails =
        data['appointmentDetails'] as Map<String, dynamic>? ?? {};

    final parentName = parentInfo['parentName'] ?? 'Unknown Parent';
    final childName = childInfo['childName'] ?? 'Unknown Child';
    final appointmentTime = appointmentDetails['requestedTime'] ?? 'TBD';
    final appointmentType = appointmentDetails['appointmentType'] ?? 'Therapy';
    final appointmentDate = appointmentDetails['requestedDate'] as Timestamp?;
    final dateStr = appointmentDate != null
        ? DateFormat('MMM dd, yyyy').format(appointmentDate.toDate())
        : 'Date TBD';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.pending_actions,
                  color: Colors.orange,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      parentName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Text(
                      'Child: $childName',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF67AFA5),
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'PENDING',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                dateStr,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.access_time, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                appointmentTime,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.medical_services_outlined,
                  size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                appointmentType,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// History Screen
class RequestHistoryScreen extends StatefulWidget {
  final String clinicId;

  const RequestHistoryScreen({Key? key, required this.clinicId})
      : super(key: key);

  @override
  State<RequestHistoryScreen> createState() => _RequestHistoryScreenState();
}

class _RequestHistoryScreenState extends State<RequestHistoryScreen> {
  String _selectedFilter = 'all'; // all, approved, declined

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Request History',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF006A5B),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(child: _buildHistoryList()),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          _buildFilterChip('All', 'all'),
          const SizedBox(width: 8),
          _buildFilterChip('Approved', 'approved'),
          const SizedBox(width: 8),
          _buildFilterChip('Declined', 'declined'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilter = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF006A5B) : Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[700],
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    Query query = FirebaseFirestore.instance
        .collection('Request')
        .where('serviceProvider.clinicId', isEqualTo: widget.clinicId);

    if (_selectedFilter == 'approved') {
      query = query.where('status', isEqualTo: 'approved');
    } else if (_selectedFilter == 'declined') {
      query = query.where('status', isEqualTo: 'declined');
    } else {
      query = query.where('status', whereIn: ['approved', 'declined']);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query
          .orderBy('appointmentDetails.requestedDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF006A5B),
            ),
          );
        }

        final requests = snapshot.data?.docs ?? [];

        if (requests.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No History',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No ${_selectedFilter == 'all' ? '' : _selectedFilter} requests found.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                      fontFamily: 'Poppins',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final request = requests[index];
            final data = request.data() as Map<String, dynamic>;
            return _buildHistoryCard(data);
          },
        );
      },
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> data) {
    final parentInfo = data['parentInfo'] as Map<String, dynamic>? ?? {};
    final childInfo = data['childInfo'] as Map<String, dynamic>? ?? {};
    final appointmentDetails =
        data['appointmentDetails'] as Map<String, dynamic>? ?? {};
    final status = data['status'] ?? 'unknown';

    final parentName = parentInfo['parentName'] ?? 'Unknown Parent';
    final childName = childInfo['childName'] ?? 'Unknown Child';
    final appointmentTime = appointmentDetails['requestedTime'] ?? 'TBD';
    final appointmentType = appointmentDetails['appointmentType'] ?? 'Therapy';
    final appointmentDate = appointmentDetails['requestedDate'] as Timestamp?;
    final dateStr = appointmentDate != null
        ? DateFormat('MMM dd, yyyy').format(appointmentDate.toDate())
        : 'Date TBD';

    final isApproved = status == 'approved';
    final statusColor = isApproved ? Colors.green : Colors.red;
    final statusIcon = isApproved ? Icons.check_circle : Icons.cancel;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  statusIcon,
                  color: statusColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      parentName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Text(
                      'Child: $childName',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF67AFA5),
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                dateStr,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.access_time, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                appointmentTime,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.medical_services_outlined,
                  size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                appointmentType,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
