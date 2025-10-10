import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../helper/field_helper.dart';

class TherapistTodayPage extends StatefulWidget {
  const TherapistTodayPage({Key? key}) : super(key: key);

  @override
  State<TherapistTodayPage> createState() => _TherapistTodayPageState();
}

class _TherapistTodayPageState extends State<TherapistTodayPage> {
  String? _therapistId;
  bool _isLoading = true;
  List<Map<String, dynamic>> _todayAppointments = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _getTherapistId();
    await _loadTodayAppointments();
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

  Future<void> _loadTodayAppointments() async {
    if (_therapistId == null) return;

    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

      print('Loading today\'s appointments for therapist: $_therapistId');

      final querySnapshot = await FirebaseFirestore.instance
          .collection('AcceptedBooking')
          .where('serviceProvider.therapistId', isEqualTo: _therapistId)
          .where('appointmentDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('appointmentDate',
              isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .orderBy('appointmentDate')
          .orderBy('appointmentTime')
          .get();

      setState(() {
        _todayAppointments = querySnapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
      });

      print('Loaded ${_todayAppointments.length} appointments for today');
    } catch (e) {
      print('Error loading today\'s appointments: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('EEEE, MMMM dd, yyyy').format(DateTime.now());

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF006A5B),
        elevation: 0,
        title: const Text(
          'Today\'s Schedule',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF006A5B),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header section
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            today,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_todayAppointments.length} Appointments',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    _getStatusSummary(),
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
                                  Icons.calendar_today,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Quick stats
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                            child: _buildStatCard('Confirmed',
                                _getStatusCount('confirmed'), Colors.green)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _buildStatCard('In Progress',
                                _getStatusCount('in_progress'), Colors.orange)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _buildStatCard('Completed',
                                _getStatusCount('completed'), Colors.blue)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Appointments list
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Today\'s Appointments',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF006A5B),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_todayAppointments.isEmpty)
                          _buildEmptyState()
                        else
                          ..._todayAppointments
                              .map((appointment) =>
                                  _buildAppointmentCard(appointment))
                              .toList(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, int count, Color color) {
    return Container(
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
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    final childInfo = appointment['childInfo'] as Map<String, dynamic>? ?? {};
    final parentInfo = appointment['parentInfo'] as Map<String, dynamic>? ?? {};

    final patientName = FieldHelper.getName(childInfo) ??
        FieldHelper.getName(parentInfo) ??
        'Unknown Patient';

    final appointmentTime = appointment['appointmentTime'] ?? '';
    final appointmentType = appointment['appointmentType'] ?? 'Therapy Session';
    final status = appointment['status'] ?? 'confirmed';

    Color statusColor = _getStatusColor(status);
    IconData statusIcon = _getStatusIcon(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patientName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF006A5B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        appointmentType,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        statusIcon,
                        color: statusColor,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Time and patient info
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  appointmentTime,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Child: ${FieldHelper.getName(childInfo) ?? 'Unknown'}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _viewAppointmentDetails(appointment),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF006A5B),
                      side: const BorderSide(color: Color(0xFF006A5B)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('View Details'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleStatusChange(appointment),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: statusColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(_getActionText(status)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(
            Icons.calendar_today,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No appointments for today',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Take a well-deserved break!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  String _getStatusSummary() {
    if (_todayAppointments.isEmpty) {
      return 'No appointments scheduled';
    }

    final confirmed = _getStatusCount('confirmed');
    final inProgress = _getStatusCount('in_progress');
    final completed = _getStatusCount('completed');

    return '$confirmed pending • $inProgress active • $completed completed';
  }

  int _getStatusCount(String status) {
    return _todayAppointments.where((apt) => apt['status'] == status).length;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'in_progress':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'in_progress':
        return Icons.play_circle_outline;
      case 'completed':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }

  String _getActionText(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return 'Start Session';
      case 'in_progress':
        return 'Complete';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Update';
    }
  }

  void _handleStatusChange(Map<String, dynamic> appointment) async {
    final currentStatus = appointment['status'] ?? 'confirmed';

    String newStatus;
    switch (currentStatus.toLowerCase()) {
      case 'confirmed':
        newStatus = 'in_progress';
        break;
      case 'in_progress':
        newStatus = 'completed';
        break;
      default:
        return; // No action for completed or cancelled
    }

    try {
      await FirebaseFirestore.instance
          .collection('AcceptedBooking')
          .doc(appointment['id'])
          .update({
        'status': newStatus,
        '${newStatus}At': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Appointment status updated to ${newStatus.replaceAll('_', ' ')}'),
            backgroundColor: _getStatusColor(newStatus),
          ),
        );
      }

      // Refresh the data
      _loadTodayAppointments();
    } catch (e) {
      print('Error updating appointment status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _viewAppointmentDetails(Map<String, dynamic> appointment) {
    final childInfo = appointment['childInfo'] as Map<String, dynamic>? ?? {};
    final parentInfo = appointment['parentInfo'] as Map<String, dynamic>? ?? {};

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Appointment Details',
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
              _buildDetailRow('Patient (Child)',
                  FieldHelper.getName(childInfo) ?? 'Unknown'),
              _buildDetailRow('Age', childInfo['childAge']?.toString() ?? ''),
              _buildDetailRow('Parent/Guardian',
                  FieldHelper.getName(parentInfo) ?? 'Unknown'),
              _buildDetailRow(
                  'Contact', FieldHelper.getContactNumber(parentInfo) ?? ''),
              _buildDetailRow('Time', appointment['appointmentTime'] ?? ''),
              _buildDetailRow(
                  'Type', appointment['appointmentType'] ?? 'Therapy Session'),
              _buildDetailRow(
                  'Status',
                  appointment['status']?.toString().toUpperCase() ??
                      'CONFIRMED'),
              if (appointment['notes'] != null)
                _buildDetailRow('Notes', appointment['notes']),
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
          if (appointment['status'] != 'completed' &&
              appointment['status'] != 'cancelled')
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _handleStatusChange(appointment);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006A5B),
              ),
              child: Text(_getActionText(appointment['status'] ?? 'confirmed')),
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

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });
    await _loadTodayAppointments();
    setState(() {
      _isLoading = false;
    });
  }
}
