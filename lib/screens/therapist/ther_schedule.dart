import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../helper/field_helper.dart';

class TherapistSchedulePage extends StatefulWidget {
  const TherapistSchedulePage({Key? key}) : super(key: key);

  @override
  State<TherapistSchedulePage> createState() => _TherapistSchedulePageState();
}

class _TherapistSchedulePageState extends State<TherapistSchedulePage> {
  String? _therapistId;
  bool _isLoading = true;

  // Calendar state
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Map<String, dynamic>>> _appointmentEvents = {};
  List<Map<String, dynamic>> _selectedDayAppointments = [];

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _getTherapistId();
    await _loadAppointmentEvents();
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

  Future<void> _loadAppointmentEvents() async {
    if (_therapistId == null) return;

    try {
      // Load appointments for the current month and next month
      final startDate = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
      final endDate = DateTime(_focusedDay.year, _focusedDay.month + 2, 0);

      print('Loading appointments from $startDate to $endDate');

      final querySnapshot = await FirebaseFirestore.instance
          .collection('AcceptedBooking')
          .where('serviceProvider.therapistId', isEqualTo: _therapistId)
          .where('appointmentDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('appointmentDate',
              isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('appointmentDate')
          .orderBy('appointmentTime')
          .get();

      final Map<DateTime, List<Map<String, dynamic>>> events = {};

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;

        final appointmentTimestamp = data['appointmentDate'] as Timestamp?;
        if (appointmentTimestamp != null) {
          final appointmentDate = appointmentTimestamp.toDate();
          final dateKey = DateTime(
              appointmentDate.year, appointmentDate.month, appointmentDate.day);

          if (!events.containsKey(dateKey)) {
            events[dateKey] = [];
          }
          events[dateKey]!.add(data);
        }
      }

      setState(() {
        _appointmentEvents = events;
        _selectedDayAppointments =
            _getEventsForDay(_selectedDay ?? DateTime.now());
      });

      print('Loaded appointments for ${events.length} days');
    } catch (e) {
      print('Error loading appointment events: $e');
    }
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    final dateKey = DateTime(day.year, day.month, day.day);
    return _appointmentEvents[dateKey] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF006A5B),
        elevation: 0,
        title: const Text(
          'My Schedule',
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
          IconButton(
            icon: const Icon(Icons.today, color: Colors.white),
            onPressed: () {
              setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = DateTime.now();
                _selectedDayAppointments = _getEventsForDay(DateTime.now());
              });
            },
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
                // Calendar widget
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TableCalendar<Map<String, dynamic>>(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) {
                      return isSameDay(_selectedDay, day);
                    },
                    eventLoader: _getEventsForDay,
                    calendarFormat: CalendarFormat.month,
                    startingDayOfWeek: StartingDayOfWeek.sunday,
                    daysOfWeekHeight: 40,
                    rowHeight: 45,
                    calendarStyle: const CalendarStyle(
                      outsideDaysVisible: false,
                      weekendTextStyle: TextStyle(color: Colors.black87),
                      defaultTextStyle: TextStyle(color: Colors.black87),
                      selectedDecoration: BoxDecoration(
                        color: Color(0xFF006A5B),
                        shape: BoxShape.circle,
                      ),
                      selectedTextStyle: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      todayDecoration: BoxDecoration(
                        color: Color(0xFF7FB069),
                        shape: BoxShape.circle,
                      ),
                      todayTextStyle: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      markerDecoration: BoxDecoration(
                        color: Color(0xFF006A5B),
                        shape: BoxShape.circle,
                      ),
                      markersMaxCount: 3,
                      markerSize: 6,
                      canMarkersOverflow: false,
                      cellMargin: EdgeInsets.all(2),
                      cellPadding: EdgeInsets.all(0),
                    ),
                    daysOfWeekStyle: const DaysOfWeekStyle(
                      weekdayStyle: TextStyle(
                        color: Color(0xFF006A5B),
                        fontWeight: FontWeight.w600,
                      ),
                      weekendStyle: TextStyle(
                        color: Color(0xFF006A5B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      headerPadding: EdgeInsets.symmetric(vertical: 8),
                      titleTextStyle: TextStyle(
                        color: Color(0xFF006A5B),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      leftChevronIcon: Icon(
                        Icons.chevron_left,
                        color: Color(0xFF006A5B),
                        size: 24,
                      ),
                      rightChevronIcon: Icon(
                        Icons.chevron_right,
                        color: Color(0xFF006A5B),
                        size: 24,
                      ),
                    ),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                        _selectedDayAppointments =
                            _getEventsForDay(selectedDay);
                      });
                    },
                    onPageChanged: (focusedDay) {
                      setState(() {
                        _focusedDay = focusedDay;
                      });
                      _loadAppointmentEvents(); // Reload data when month changes
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Selected day appointments
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedDay != null
                              ? 'Appointments for ${DateFormat('MMMM dd, yyyy').format(_selectedDay!)}'
                              : 'Select a date to view appointments',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF006A5B),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: _selectedDayAppointments.isEmpty
                              ? _buildEmptyDayState()
                              : ListView.builder(
                                  itemCount: _selectedDayAppointments.length,
                                  itemBuilder: (context, index) {
                                    return _buildAppointmentCard(
                                        _selectedDayAppointments[index]);
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showScheduleOverview,
        backgroundColor: const Color(0xFF006A5B),
        icon: const Icon(Icons.analytics_outlined, color: Colors.white),
        label: const Text(
          'Overview',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildEmptyDayState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.free_breakfast,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No appointments for this day',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enjoy your free time!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF006A5B).withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Time indicator
            Container(
              width: 4,
              height: 60,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 16),

            // Appointment details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        appointmentTime,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              statusIcon,
                              color: statusColor,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    patientName,
                    style: const TextStyle(
                      fontSize: 16,
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
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.person_outline,
                          size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Child: ${FieldHelper.getName(childInfo) ?? 'Unknown'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Action button
            IconButton(
              onPressed: () => _viewAppointmentDetails(appointment),
              icon: const Icon(
                Icons.more_vert,
                color: Color(0xFF006A5B),
              ),
            ),
          ],
        ),
      ),
    );
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
              _buildDetailRow('Email', FieldHelper.getEmail(parentInfo) ?? ''),
              _buildDetailRow('Date',
                  _formatAppointmentDate(appointment['appointmentDate'])),
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
              onPressed: () => _showStatusUpdateDialog(appointment),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006A5B),
              ),
              child: const Text('Update Status'),
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

  String _formatAppointmentDate(dynamic date) {
    if (date is Timestamp) {
      return DateFormat('MMM dd, yyyy').format(date.toDate());
    }
    return date?.toString() ?? '';
  }

  void _showStatusUpdateDialog(Map<String, dynamic> appointment) {
    final currentStatus = appointment['status'] ?? 'confirmed';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Update Appointment Status',
          style: TextStyle(
            color: Color(0xFF006A5B),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusOption('confirmed', 'Confirmed',
                Icons.check_circle_outline, Colors.green, currentStatus),
            _buildStatusOption('in_progress', 'In Progress',
                Icons.play_circle_outline, Colors.orange, currentStatus),
            _buildStatusOption('completed', 'Completed', Icons.done_all,
                Colors.blue, currentStatus),
            _buildStatusOption('cancelled', 'Cancelled', Icons.cancel_outlined,
                Colors.red, currentStatus),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF006A5B)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusOption(String status, String label, IconData icon,
      Color color, String currentStatus) {
    final isSelected = status == currentStatus;

    return InkWell(
      onTap: () {
        Navigator.pop(context); // Close status dialog
        Navigator.pop(context); // Close details dialog
        _updateAppointmentStatus(status);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey[50],
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: color,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : Colors.black87,
              ),
            ),
            if (isSelected) ...[
              const Spacer(),
              Icon(
                Icons.check,
                color: color,
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _updateAppointmentStatus(String newStatus) async {
    final selectedAppointment = _selectedDayAppointments.firstWhere(
      (apt) => apt['id'] == _selectedDayAppointments.first['id'],
      orElse: () => {},
    );

    if (selectedAppointment.isEmpty) return;

    try {
      await FirebaseFirestore.instance
          .collection('AcceptedBooking')
          .doc(selectedAppointment['id'])
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
      _loadAppointmentEvents();
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

  void _showScheduleOverview() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Schedule Overview',
          style: TextStyle(
            color: Color(0xFF006A5B),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildOverviewStat('Total Appointments', _getTotalAppointments()),
              _buildOverviewStat('This Week', _getWeeklyAppointments()),
              _buildOverviewStat('This Month', _getMonthlyAppointments()),
              _buildOverviewStat('Completed', _getCompletedAppointments()),
              _buildOverviewStat('Upcoming', _getUpcomingAppointments()),
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

  Widget _buildOverviewStat(String label, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF006A5B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                color: Color(0xFF006A5B),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _getTotalAppointments() {
    return _appointmentEvents.values.expand((events) => events).length;
  }

  int _getWeeklyAppointments() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    return _appointmentEvents.entries
        .where((entry) {
          final date = entry.key;
          return date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
              date.isBefore(endOfWeek.add(const Duration(days: 1)));
        })
        .expand((entry) => entry.value)
        .length;
  }

  int _getMonthlyAppointments() {
    final now = DateTime.now();
    return _appointmentEvents.entries
        .where((entry) {
          final date = entry.key;
          return date.year == now.year && date.month == now.month;
        })
        .expand((entry) => entry.value)
        .length;
  }

  int _getCompletedAppointments() {
    return _appointmentEvents.values
        .expand((events) => events)
        .where((apt) => apt['status'] == 'completed')
        .length;
  }

  int _getUpcomingAppointments() {
    final now = DateTime.now();
    return _appointmentEvents.entries
        .where((entry) {
          final date = entry.key;
          return date.isAfter(now.subtract(const Duration(days: 1)));
        })
        .expand((entry) => entry.value)
        .where((apt) =>
            apt['status'] != 'completed' && apt['status'] != 'cancelled')
        .length;
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });
    await _loadAppointmentEvents();
    setState(() {
      _isLoading = false;
    });
  }
}
