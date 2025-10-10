import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/accepted_booking_service.dart';
import '../../helper/field_helper.dart';

class TherapistRequestBookingPage extends StatefulWidget {
  const TherapistRequestBookingPage({Key? key}) : super(key: key);

  @override
  State<TherapistRequestBookingPage> createState() =>
      _TherapistRequestBookingPageState();
}

class _TherapistRequestBookingPageState
    extends State<TherapistRequestBookingPage> {
  String? _therapistId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _getTherapistId();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _getTherapistId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _therapistId = prefs.getString('therapist_id') ??
          prefs.getString('user_id') ??
          prefs.getString('clinic_id');
      print('Therapist ID loaded: $_therapistId');
    } catch (e) {
      print('Error getting therapist ID: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF006A5B),
        elevation: 0,
        title: const Text(
          'Booking Requests',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: _showFilterOptions,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF006A5B),
              ),
            )
          : Column(
              children: [
                // Header with stats
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFF006A5B),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(25),
                      bottomRight: Radius.circular(25),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _getBookingRequestsStream(),
                      builder: (context, snapshot) {
                        final requests = snapshot.data?.docs ?? [];
                        final pendingCount = requests.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return data['status'] == 'pending';
                        }).length;

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$pendingCount Pending Request${pendingCount != 1 ? 's' : ''}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${requests.length} total requests',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.inbox,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Quick actions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildQuickActionCard(
                          'Accept All',
                          Icons.check_circle,
                          Colors.green,
                          _showBulkActionDialog,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickActionCard(
                          'View History',
                          Icons.history,
                          Colors.blue,
                          _showRequestHistory,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Requests list
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Incoming Requests',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF006A5B),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: StreamBuilder<QuerySnapshot>(
                            stream: _getBookingRequestsStream(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF006A5B),
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
                                        color: Colors.red[300],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Error loading requests',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.red[600],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${snapshot.error}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.red[400],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                );
                              }

                              final requests = snapshot.data?.docs ?? [];

                              if (requests.isEmpty) {
                                return _buildEmptyState();
                              }

                              return ListView.builder(
                                itemCount: requests.length,
                                itemBuilder: (context, index) {
                                  final doc = requests[index];
                                  final data =
                                      doc.data() as Map<String, dynamic>;
                                  return _buildRequestCard(doc.id, data);
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildQuickActionCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No booking requests',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'When patients request appointments,\nthey will appear here.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(String requestId, Map<String, dynamic> request) {
    final createdAt = request['createdAt'] as Timestamp?;
    final requestDate = createdAt != null
        ? DateFormat('MMM dd, yyyy').format(createdAt.toDate())
        : 'Recently';

    final parentInfo = request['parentInfo'] as Map<String, dynamic>? ?? {};
    final childInfo = request['childInfo'] as Map<String, dynamic>? ?? {};
    final appointmentDetails =
        request['appointmentDetails'] as Map<String, dynamic>? ?? {};

    final parentName = FieldHelper.getName(parentInfo) ?? 'Unknown Parent';
    final childName = FieldHelper.getName(childInfo) ?? 'Unknown Child';
    final childAge = childInfo['childAge']?.toString() ?? '';

    final appointmentTimestamp =
        appointmentDetails['requestedDate'] as Timestamp?;
    final appointmentDateStr = appointmentTimestamp != null
        ? DateFormat('MMM dd, yyyy').format(appointmentTimestamp.toDate())
        : 'TBD';
    final appointmentTime = appointmentDetails['requestedTime'] ?? 'TBD';
    final appointmentType =
        appointmentDetails['appointmentType'] ?? 'Therapy Session';

    final status = request['status'] ?? 'pending';
    final priority = _getRequestPriority(request);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: priority == 'urgent'
              ? Colors.red.withOpacity(0.3)
              : Colors.grey.withOpacity(0.2),
          width: priority == 'urgent' ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: _getStatusColor(status),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (priority == 'urgent') ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.priority_high,
                                color: Colors.red, size: 12),
                            SizedBox(width: 2),
                            Text(
                              'URGENT',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  requestDate,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Child and parent information
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.child_care,
                          size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Child: $childName${childAge.isNotEmpty ? ' ($childAge years)' : ''}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.person, size: 16, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Parent: $parentName',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  if (FieldHelper.getContactNumber(parentInfo) != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.phone, size: 16, color: Colors.orange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Contact: ${FieldHelper.getContactNumber(parentInfo)}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Appointment details
            Row(
              children: [
                Expanded(
                  child: _buildDetailChip(
                    Icons.calendar_today,
                    appointmentDateStr,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDetailChip(
                    Icons.access_time,
                    appointmentTime,
                    Colors.purple,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            _buildDetailChip(
              Icons.medical_services,
              appointmentType,
              Colors.blue,
            ),

            const SizedBox(height: 16),

            // Action buttons
            if (status == 'pending') ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _handleRequestAction(requestId, request, 'accept'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Accept'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _handleRequestAction(requestId, request, 'decline'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Decline'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () => _viewRequestDetails(requestId, request),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF006A5B),
                  ),
                  icon: const Icon(Icons.info_outline, size: 18),
                  label: const Text('View Details'),
                ),
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getStatusIcon(status),
                      color: _getStatusColor(status),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: _getStatusColor(status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getRequestPriority(Map<String, dynamic> request) {
    // Determine priority based on various factors
    final createdAt = request['createdAt'] as Timestamp?;
    if (createdAt != null) {
      final daysSinceCreated =
          DateTime.now().difference(createdAt.toDate()).inDays;
      if (daysSinceCreated >= 3) {
        return 'urgent';
      }
    }

    final appointmentDetails =
        request['appointmentDetails'] as Map<String, dynamic>? ?? {};
    final requestedDate = appointmentDetails['requestedDate'] as Timestamp?;
    if (requestedDate != null) {
      final daysUntilAppointment =
          requestedDate.toDate().difference(DateTime.now()).inDays;
      if (daysUntilAppointment <= 2) {
        return 'urgent';
      }
    }

    return 'normal';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
      case 'accepted':
        return Colors.green;
      case 'declined':
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.pending;
      case 'approved':
      case 'accepted':
        return Icons.check_circle;
      case 'declined':
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  Stream<QuerySnapshot> _getBookingRequestsStream() {
    if (_therapistId == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('Request')
        .where('serviceProvider.therapistId', isEqualTo: _therapistId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  void _handleRequestAction(
      String requestId, Map<String, dynamic> request, String action) async {
    try {
      if (action == 'accept') {
        // Show confirmation dialog first
        final confirmed = await _showAcceptConfirmationDialog(request);
        if (!confirmed) return;

        // Use AcceptedBookingService to accept the request
        await AcceptedBookingService.acceptBookingRequest(
          requestId: requestId,
          requestData: request,
          approvedById: _therapistId!,
          assignedTherapistId: _therapistId,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Booking request accepted successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        // Show decline reason dialog
        final reason = await _showDeclineReasonDialog();
        if (reason == null) return;

        // Decline the request
        await FirebaseFirestore.instance
            .collection('Request')
            .doc(requestId)
            .update({
          'status': 'declined',
          'declinedAt': FieldValue.serverTimestamp(),
          'declinedBy': _therapistId,
          'declineReason': reason,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Booking request declined'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('Error in _handleRequestAction: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<bool> _showAcceptConfirmationDialog(
      Map<String, dynamic> request) async {
    final childInfo = request['childInfo'] as Map<String, dynamic>? ?? {};
    final childName = FieldHelper.getName(childInfo) ?? 'Unknown Child';
    final appointmentDetails =
        request['appointmentDetails'] as Map<String, dynamic>? ?? {};
    final appointmentTime = appointmentDetails['requestedTime'] ?? 'TBD';

    final appointmentTimestamp =
        appointmentDetails['requestedDate'] as Timestamp?;
    final appointmentDateStr = appointmentTimestamp != null
        ? DateFormat('MMM dd, yyyy').format(appointmentTimestamp.toDate())
        : 'TBD';

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text(
              'Confirm Acceptance',
              style: TextStyle(
                color: Color(0xFF006A5B),
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                    'Are you sure you want to accept this booking request?'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Patient: $childName',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('Date: $appointmentDateStr'),
                      const SizedBox(height: 4),
                      Text('Time: $appointmentTime'),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: const Text('Accept'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<String?> _showDeclineReasonDialog() async {
    String? selectedReason;
    final reasons = [
      'Schedule conflict',
      'Not my specialty',
      'Fully booked',
      'Patient requirements don\'t match',
      'Other'
    ];

    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Decline Reason',
          style: TextStyle(
            color: Color(0xFF006A5B),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please select a reason for declining this request:'),
            const SizedBox(height: 16),
            ...reasons
                .map((reason) => RadioListTile<String>(
                      title: Text(reason),
                      value: reason,
                      groupValue: selectedReason,
                      onChanged: (value) {
                        selectedReason = value;
                        Navigator.pop(context, value);
                      },
                    ))
                .toList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _viewRequestDetails(String requestId, Map<String, dynamic> request) {
    final parentInfo = request['parentInfo'] as Map<String, dynamic>? ?? {};
    final childInfo = request['childInfo'] as Map<String, dynamic>? ?? {};
    final appointmentDetails =
        request['appointmentDetails'] as Map<String, dynamic>? ?? {};

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Request Details',
          style: TextStyle(
            color: Color(0xFF006A5B),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(
                  'Child Name', FieldHelper.getName(childInfo) ?? 'Unknown'),
              _buildDetailRow(
                  'Child Age', childInfo['childAge']?.toString() ?? ''),
              _buildDetailRow('Child Gender', childInfo['childGender'] ?? ''),
              _buildDetailRow(
                  'Parent Name', FieldHelper.getName(parentInfo) ?? 'Unknown'),
              _buildDetailRow(
                  'Contact', FieldHelper.getContactNumber(parentInfo) ?? ''),
              _buildDetailRow('Email', FieldHelper.getEmail(parentInfo) ?? ''),
              _buildDetailRow('Requested Date',
                  _formatTimestamp(appointmentDetails['requestedDate'])),
              _buildDetailRow(
                  'Requested Time', appointmentDetails['requestedTime'] ?? ''),
              _buildDetailRow('Appointment Type',
                  appointmentDetails['appointmentType'] ?? ''),
              if (request['additionalNotes'] != null)
                _buildDetailRow('Notes', request['additionalNotes']),
              _buildDetailRow('Status',
                  request['status']?.toString().toUpperCase() ?? 'PENDING'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: Color(0xFF006A5B)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF006A5B),
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return DateFormat('MMM dd, yyyy').format(timestamp.toDate());
    }
    return timestamp?.toString() ?? '';
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter Requests',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF006A5B),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.pending, color: Colors.orange),
              title: const Text('Pending Only'),
              onTap: () {
                Navigator.pop(context);
                // Implement filter logic
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: const Text('Accepted Only'),
              onTap: () {
                Navigator.pop(context);
                // Implement filter logic
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel, color: Colors.red),
              title: const Text('Declined Only'),
              onTap: () {
                Navigator.pop(context);
                // Implement filter logic
              },
            ),
            ListTile(
              leading: const Icon(Icons.list, color: Color(0xFF006A5B)),
              title: const Text('All Requests'),
              onTap: () {
                Navigator.pop(context);
                // Implement filter logic
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showBulkActionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Bulk Action',
          style: TextStyle(
            color: Color(0xFF006A5B),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'This feature will allow you to accept multiple requests at once. It\'s coming soon!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showRequestHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFF006A5B),
            title: const Text(
              'Request History',
              style: TextStyle(color: Colors.white),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: const Center(
            child: Text('Request history feature coming soon!'),
          ),
        ),
      ),
    );
  }
}
