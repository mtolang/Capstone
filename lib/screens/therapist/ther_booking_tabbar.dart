import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/accepted_booking_service.dart';
import '../../helper/field_helper.dart';

class TherapistBookingTabBar extends StatefulWidget {
  const TherapistBookingTabBar({Key? key}) : super(key: key);

  @override
  State<TherapistBookingTabBar> createState() => _TherapistBookingTabBarState();
}

class _TherapistBookingTabBarState extends State<TherapistBookingTabBar>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _currentMonth = DateTime.now();
  Map<int, List<Map<String, dynamic>>> _monthlyAppointments = {};
  String? _therapistId;
  bool _isLoading = true;

  final List<Map<String, dynamic>> sampleBookings = [
    {
      'name': 'Alice Johnson',
      'time': '09:00 - 10:00 AM',
      'color': Colors.teal,
    },
    {
      'name': 'Michael Chen',
      'time': '10:30 - 11:30 AM',
      'color': Colors.lightGreen,
    },
    {
      'name': 'Emma Rodriguez',
      'time': '02:00 - 03:00 PM',
      'color': Colors.blue,
    },
    {
      'name': 'David Wilson',
      'time': '03:30 - 04:30 PM',
      'color': Colors.indigo,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _getTherapistId();
    await _loadMonthlyAppointments();
    setState(() {
      _isLoading = false;
    });
  }

  // Get therapist ID from shared preferences
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

  // Calendar navigation methods
  void _navigateToPreviousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
      _loadMonthlyAppointments();
    });
  }

  void _navigateToNextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
      _loadMonthlyAppointments();
    });
  }

  // Load monthly appointments from AcceptedBooking collection
  Future<void> _loadMonthlyAppointments() async {
    if (_therapistId == null) return;

    try {
      // Get the first and last day of the current month
      final firstDayOfMonth =
          DateTime(_currentMonth.year, _currentMonth.month, 1);
      final lastDayOfMonth =
          DateTime(_currentMonth.year, _currentMonth.month + 1, 0);

      print('Loading appointments for therapist: $_therapistId');
      print('Date range: $firstDayOfMonth to $lastDayOfMonth');

      // Query AcceptedBooking collection for this therapist
      final querySnapshot = await FirebaseFirestore.instance
          .collection('AcceptedBooking')
          .where('serviceProvider.therapistId', isEqualTo: _therapistId)
          .where('appointmentDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(firstDayOfMonth))
          .where('appointmentDate',
              isLessThanOrEqualTo: Timestamp.fromDate(lastDayOfMonth))
          .get();

      // Group appointments by day
      final Map<int, List<Map<String, dynamic>>> groupedAppointments = {};

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final appointmentTimestamp = data['appointmentDate'] as Timestamp?;

        if (appointmentTimestamp != null) {
          final appointmentDate = appointmentTimestamp.toDate();
          final day = appointmentDate.day;

          if (!groupedAppointments.containsKey(day)) {
            groupedAppointments[day] = [];
          }

          // Extract patient information using FieldHelper
          final childInfo = data['childInfo'] as Map<String, dynamic>? ?? {};
          final parentInfo = data['parentInfo'] as Map<String, dynamic>? ?? {};

          final patientName = FieldHelper.getName(childInfo) ??
              FieldHelper.getName(parentInfo) ??
              'Unknown Patient';

          groupedAppointments[day]!.add({
            'id': doc.id,
            'patientName': patientName,
            'appointmentTime': data['appointmentTime'] ?? '',
            'appointmentType': data['appointmentType'] ?? 'Therapy Session',
            'status': data['status'] ?? 'confirmed',
            'childInfo': childInfo,
            'parentInfo': parentInfo,
            'fullData': data,
          });
        }
      }

      setState(() {
        _monthlyAppointments = groupedAppointments;
      });

      print('Loaded ${querySnapshot.docs.length} appointments for the month');
    } catch (e) {
      print('Error loading monthly appointments: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('MMMM dd, yyyy').format(DateTime.now());

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF006A5B),
          ),
        ),
      );
    }

    return Column(
      children: [
        Container(
          decoration: const BoxDecoration(
            color: Color(0xFF006A5B),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(25),
              bottomRight: Radius.circular(25),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 40),
              const Text(
                'My Bookings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                today,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 20),
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                labelStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                tabs: const [
                  Tab(text: 'Today'),
                  Tab(text: 'Schedule'),
                  Tab(text: 'Requests'),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildTodayTab(today),
              _buildScheduleTab(),
              _buildRequestTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTodayTab(String today) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
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

          // Today's appointments from Firebase
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _getTodayAppointments(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF006A5B),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              }

              final appointments = snapshot.data ?? [];

              if (appointments.isEmpty) {
                return const Center(
                  child: Column(
                    children: [
                      SizedBox(height: 40),
                      Icon(
                        Icons.calendar_today,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No appointments for today',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: appointments
                    .map((appointment) =>
                        _buildTodayAppointmentCard(appointment))
                    .toList(),
              );
            },
          ),

          const SizedBox(height: 24),

          // Quick actions
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF006A5B),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  'View Schedule',
                  Icons.calendar_view_week,
                  () => _tabController.animateTo(1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  'Pending Requests',
                  Icons.pending_actions,
                  () => _tabController.animateTo(2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Calendar header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _navigateToPreviousMonth,
                icon: const Icon(Icons.chevron_left, size: 30),
                color: const Color(0xFF006A5B),
              ),
              Text(
                DateFormat('MMMM yyyy').format(_currentMonth),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF006A5B),
                ),
              ),
              IconButton(
                onPressed: _navigateToNextMonth,
                icon: const Icon(Icons.chevron_right, size: 30),
                color: const Color(0xFF006A5B),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Calendar grid
          _buildCalendarGrid(),

          const SizedBox(height: 24),

          // Weekly overview
          const Text(
            'This Week\'s Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF006A5B),
            ),
          ),
          const SizedBox(height: 12),

          FutureBuilder<List<Map<String, dynamic>>>(
            future: _getWeeklyAppointments(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF006A5B),
                  ),
                );
              }

              final weeklyAppointments = snapshot.data ?? [];

              if (weeklyAppointments.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No appointments this week',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                );
              }

              return Column(
                children: weeklyAppointments
                    .map((appointment) =>
                        _buildWeeklyAppointmentCard(appointment))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRequestTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Booking Requests',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF006A5B),
            ),
          ),
          const SizedBox(height: 16),

          // Pending requests from Firebase
          StreamBuilder<QuerySnapshot>(
            stream: _getBookingRequestsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF006A5B),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              }

              final requests = snapshot.data?.docs ?? [];

              if (requests.isEmpty) {
                return const Center(
                  child: Column(
                    children: [
                      SizedBox(height: 40),
                      Icon(
                        Icons.inbox,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No pending requests',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: requests
                    .map((doc) => _buildRequestCard(
                        doc.id, doc.data() as Map<String, dynamic>))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF006A5B).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF006A5B).withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: const Color(0xFF006A5B),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF006A5B),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayAppointmentCard(Map<String, dynamic> appointment) {
    final childInfo = appointment['childInfo'] as Map<String, dynamic>? ?? {};
    final parentInfo = appointment['parentInfo'] as Map<String, dynamic>? ?? {};

    final patientName = FieldHelper.getName(childInfo) ??
        FieldHelper.getName(parentInfo) ??
        'Unknown Patient';

    final appointmentTime = appointment['appointmentTime'] ?? '';
    final appointmentType = appointment['appointmentType'] ?? 'Therapy Session';
    final status = appointment['status'] ?? 'confirmed';

    Color statusColor = Colors.green;
    switch (status.toLowerCase()) {
      case 'confirmed':
        statusColor = Colors.green;
        break;
      case 'in_progress':
        statusColor = Colors.orange;
        break;
      case 'completed':
        statusColor = Colors.blue;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                  child: Text(
                    patientName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF006A5B),
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  appointmentTime,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.medical_services,
                    size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  appointmentType,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _viewAppointmentDetails(appointment),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF006A5B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('View Details'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: status.toLowerCase() == 'confirmed'
                        ? () => _markAsInProgress(appointment)
                        : null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF006A5B),
                      side: const BorderSide(color: Color(0xFF006A5B)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      status.toLowerCase() == 'confirmed'
                          ? 'Start Session'
                          : 'In Progress',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyAppointmentCard(Map<String, dynamic> appointment) {
    final childInfo = appointment['childInfo'] as Map<String, dynamic>? ?? {};
    final parentInfo = appointment['parentInfo'] as Map<String, dynamic>? ?? {};

    final patientName = FieldHelper.getName(childInfo) ??
        FieldHelper.getName(parentInfo) ??
        'Unknown Patient';

    final appointmentDate = appointment['appointmentDate'] as Timestamp?;
    final dateStr = appointmentDate != null
        ? DateFormat('MMM dd').format(appointmentDate.toDate())
        : '';
    final dayStr = appointmentDate != null
        ? DateFormat('EEEE').format(appointmentDate.toDate())
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF006A5B),
          child: Text(
            dateStr.split(' ').last, // Day number
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          patientName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('$dayStr • ${appointment['appointmentTime'] ?? ''}'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF006A5B).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            appointment['appointmentType'] ?? 'Therapy',
            style: const TextStyle(
              color: Color(0xFF006A5B),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        onTap: () => _viewAppointmentDetails(appointment),
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
                Text(
                  'Booking Request',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF006A5B),
                  ),
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

            // Child information
            Row(
              children: [
                const Icon(Icons.child_care, size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Child: $childName${childAge.isNotEmpty ? ' ($childAge years)' : ''}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Parent information
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.green),
                const SizedBox(width: 8),
                Text('Parent: $parentName'),
              ],
            ),
            const SizedBox(height: 6),

            // Appointment details
            Row(
              children: [
                const Icon(Icons.calendar_today,
                    size: 16, color: Colors.orange),
                const SizedBox(width: 8),
                Text('Date: $appointmentDateStr'),
              ],
            ),
            const SizedBox(height: 6),

            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.purple),
                const SizedBox(width: 8),
                Text('Time: $appointmentTime'),
              ],
            ),
            const SizedBox(height: 6),

            Row(
              children: [
                const Icon(Icons.medical_services, size: 16, color: Colors.red),
                const SizedBox(width: 8),
                Text('Type: $appointmentType'),
              ],
            ),

            const SizedBox(height: 16),

            if (status == 'pending') ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          _handleRequestAction(requestId, request, 'accept'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Accept'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          _handleRequestAction(requestId, request, 'decline'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Decline'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: status == 'approved'
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: status == 'approved' ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final now = DateTime.now();
    final firstDayOfMonth =
        DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDayOfMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final startingWeekday = firstDayOfMonth.weekday % 7; // Sunday = 0

    List<Widget> calendarDays = [];

    // Add empty cells for days before the first day of the month
    for (int i = 0; i < startingWeekday; i++) {
      calendarDays.add(const SizedBox(width: 35, height: 45));
    }

    // Add days of the month
    for (int day = 1; day <= daysInMonth; day++) {
      final isToday = now.year == _currentMonth.year &&
          now.month == _currentMonth.month &&
          now.day == day;

      final hasAppointments = _monthlyAppointments.containsKey(day) &&
          _monthlyAppointments[day]!.isNotEmpty;

      calendarDays.add(
        GestureDetector(
          onTap: hasAppointments
              ? () => _showDaySchedule(day, _monthlyAppointments[day]!)
              : null,
          child: Container(
            width: 35,
            height: 45,
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isToday
                  ? const Color(0xFF006A5B)
                  : hasAppointments
                      ? const Color(0xFF006A5B).withOpacity(0.3)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  day.toString(),
                  style: TextStyle(
                    color: isToday ? Colors.white : Colors.black,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
                if (hasAppointments)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isToday ? Colors.white : const Color(0xFF006A5B),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        // Day headers
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
              .map((day) => SizedBox(
                    width: 35,
                    child: Text(
                      day,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF006A5B),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),
        // Calendar grid
        Wrap(
          children: calendarDays,
        ),
      ],
    );
  }

  void _showDaySchedule(int day, List<Map<String, dynamic>> appointments) {
    final selectedDate = DateTime(_currentMonth.year, _currentMonth.month, day);
    final formattedDate = DateFormat('MMMM dd, yyyy').format(selectedDate);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Appointments for $formattedDate',
          style: const TextStyle(
            color: Color(0xFF006A5B),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final appointment = appointments[index];
              final childInfo =
                  appointment['childInfo'] as Map<String, dynamic>? ?? {};
              final patientName =
                  FieldHelper.getName(childInfo) ?? 'Unknown Patient';

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF006A5B),
                    child: Text(
                      (index + 1).toString(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(patientName),
                  subtitle: Text(
                    '${appointment['appointmentTime'] ?? ''} • ${appointment['appointmentType'] ?? 'Therapy'}',
                  ),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF006A5B).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      appointment['status']?.toString().toUpperCase() ??
                          'CONFIRMED',
                      style: const TextStyle(
                        color: Color(0xFF006A5B),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _viewAppointmentDetails(appointment);
                  },
                ),
              );
            },
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

  // Helper methods
  Future<List<Map<String, dynamic>>> _getTodayAppointments() async {
    if (_therapistId == null) return [];

    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

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

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting today\'s appointments: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getWeeklyAppointments() async {
    if (_therapistId == null) return [];

    try {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));

      final querySnapshot = await FirebaseFirestore.instance
          .collection('AcceptedBooking')
          .where('serviceProvider.therapistId', isEqualTo: _therapistId)
          .where('appointmentDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
          .where('appointmentDate',
              isLessThanOrEqualTo: Timestamp.fromDate(endOfWeek))
          .orderBy('appointmentDate')
          .orderBy('appointmentTime')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting weekly appointments: $e');
      return [];
    }
  }

  Stream<QuerySnapshot> _getBookingRequestsStream() {
    if (_therapistId == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('Request')
        .where('serviceProvider.therapistId', isEqualTo: _therapistId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  void _handleRequestAction(
      String requestId, Map<String, dynamic> request, String action) async {
    try {
      if (action == 'accept') {
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
              content: Text('Booking request accepted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Decline the request
        await FirebaseFirestore.instance
            .collection('Request')
            .doc(requestId)
            .update({
          'status': 'declined',
          'declinedAt': FieldValue.serverTimestamp(),
          'declinedBy': _therapistId,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Booking request declined'),
              backgroundColor: Colors.orange,
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
          ),
        );
      }
    }
  }

  void _viewAppointmentDetails(Map<String, dynamic> appointment) {
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Patient',
                FieldHelper.getName(appointment['childInfo']) ?? 'Unknown'),
            _buildDetailRow('Parent',
                FieldHelper.getName(appointment['parentInfo']) ?? 'Unknown'),
            _buildDetailRow(
                'Date', _formatAppointmentDate(appointment['appointmentDate'])),
            _buildDetailRow('Time', appointment['appointmentTime'] ?? ''),
            _buildDetailRow(
                'Type', appointment['appointmentType'] ?? 'Therapy Session'),
            _buildDetailRow('Status',
                appointment['status']?.toString().toUpperCase() ?? 'CONFIRMED'),
          ],
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
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

  void _markAsInProgress(Map<String, dynamic> appointment) async {
    try {
      await FirebaseFirestore.instance
          .collection('AcceptedBooking')
          .doc(appointment['id'])
          .update({
        'status': 'in_progress',
        'startedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session started'),
            backgroundColor: Colors.orange,
          ),
        );
      }

      // Refresh the data
      _loadMonthlyAppointments();
    } catch (e) {
      print('Error marking as in progress: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
