import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/accepted_booking_service.dart';
import '../../services/booking_request_service.dart';
import '../../helper/field_helper.dart';
import 'ther_navbar.dart';

class TherapistBookingTabBar extends StatefulWidget {
  const TherapistBookingTabBar({Key? key}) : super(key: key);

  @override
  State<TherapistBookingTabBar> createState() => _TherapistBookingTabBarState();
}

class _TherapistBookingTabBarState extends State<TherapistBookingTabBar>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Map<String, dynamic>>> _appointmentEvents = {};

  final List<Map<String, dynamic>> bookings = [
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
    _selectedDay = DateTime.now();
    _loadAppointmentEvents();
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    final dateKey = DateTime(day.year, day.month, day.day);
    return _appointmentEvents[dateKey] ?? [];
  }

  // Load appointment events from AcceptedBooking collection
  Future<void> _loadAppointmentEvents() async {
    try {
      final therapistId = await _getCurrentTherapistId();
      if (therapistId == null) {
        print('No therapist ID found');
        return;
      }

      // Load appointments for the current month and next month
      final startDate = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
      final endDate = DateTime(_focusedDay.year, _focusedDay.month + 2, 0);

      print('Loading appointments from $startDate to $endDate');

      final querySnapshot = await FirebaseFirestore.instance
          .collection('AcceptedBooking')
          .where('serviceProvider.therapistId', isEqualTo: therapistId)
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
      });

      print('Loaded appointments for ${events.length} days');
    } catch (e) {
      print('Error loading appointment events: $e');
    }
  }

  // Helper method to get current therapist ID
  Future<String?> _getCurrentTherapistId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('therapist_id') ??
          prefs.getString('user_id') ??
          prefs.getString('clinic_id');
    } catch (e) {
      print('Error getting therapist ID: $e');
      return null;
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
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF006A5B),
        elevation: 0,
        title: const Text(
          'Booking Schedule',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Poppins',
          ),
        ),
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              color: Colors.white,
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: const TherapistNavbar(currentPage: 'booking'),
      body: Stack(
        children: [
          // Top ellipse background
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ConstrainedBox(
              constraints: BoxConstraints.expand(height: size.height * 0.30),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF006A5B), Color(0xFF67AFA5)],
                  ),
                ),
                child: Image.asset(
                  'asset/images/Ellipse 1.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(); // Gradient fallback
                  },
                ),
              ),
            ),
          ),
          // Bottom ellipse background
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ConstrainedBox(
              constraints: BoxConstraints.expand(height: size.height * 0.3),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xFF67AFA5), Colors.white],
                  ),
                ),
                child: Image.asset(
                  'asset/images/Ellipse 2.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(); // Gradient fallback
                  },
                ),
              ),
            ),
          ),
          // Main content
          Column(
            children: [
              // Tab bar section
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: const Color(0xFF006A5B),
                    borderRadius: BorderRadius.circular(26),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorPadding: EdgeInsets.zero,
                  labelColor: Colors.white,
                  unselectedLabelColor: const Color(0xFF006A5B),
                  labelStyle: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                    fontSize: 10,
                  ),
                  dividerColor: Colors.transparent,
                  overlayColor: WidgetStateProperty.all(Colors.transparent),
                  splashFactory: NoSplash.splashFactory,
                  tabs: [
                    Tab(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: const Text('Today'),
                      ),
                    ),
                    Tab(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: const Text('Schedule'),
                      ),
                    ),
                    Tab(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: const Text('Request'),
                      ),
                    ),
                  ],
                ),
              ),
              // Tab content
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF006A5B),
        child: const Icon(Icons.calendar_today, color: Colors.white),
        onPressed: () {
          // Navigate to setup schedule page
          Navigator.pushNamed(context, '/therapistsetupschedule');
        },
      ),
    );
  }

  Widget _buildTodayTab(String today) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Add top margin and make text white
          const SizedBox(height: 30), // Top margin
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              today,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF006A5B),
                fontFamily: 'Poppins',
              ),
            ),
          ),
          const SizedBox(height: 20),
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
                  child: Column(
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text('Error: ${snapshot.error}'),
                    ],
                  ),
                );
              }

              final todayAppointments = snapshot.data ?? [];

              if (todayAppointments.isEmpty) {
                return Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Column(
                          children: [
                            Icon(
                              Icons.event_available,
                              size: 64,
                              color: Color(0xFF67AFA5),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No appointments today',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF006A5B),
                                fontFamily: 'Poppins',
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Take some time to prepare for upcoming sessions',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF67AFA5),
                                fontFamily: 'Poppins',
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: todayAppointments.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final appointment = todayAppointments[index];
                  return _buildTodayAppointmentCard(appointment);
                },
              );
            },
          ),
          const SizedBox(height: 30),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Text(
                "That's it for today!",
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF006A5B),
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 100), // Extra space for bottom wave
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
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Text(
              'Schedule Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF006A5B),
                fontFamily: 'Poppins',
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Calendar Widget
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
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
                  });
                  _showDayScheduleDialog(selectedDay);
                },
                onPageChanged: (focusedDay) {
                  setState(() {
                    _focusedDay = focusedDay;
                  });
                  _loadAppointmentEvents(); // Reload data when month changes
                },
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Quick Schedule Actions
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF006A5B),
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _tabController.animateTo(0),
                          icon: const Icon(Icons.today, color: Colors.white),
                          label: const Text(
                            'Today\'s Schedule',
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF006A5B),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _tabController.animateTo(2),
                          icon: const Icon(Icons.schedule, color: Colors.white),
                          label: const Text(
                            'View Requests',
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF67AFA5),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 100), // Extra space for bottom wave
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
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Text(
              'Booking Requests',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF006A5B),
                fontFamily: 'Poppins',
              ),
            ),
          ),
          const SizedBox(height: 20),
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
                  child: Column(
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text('Error: ${snapshot.error}'),
                    ],
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.inbox,
                          size: 64,
                          color: Color(0xFF67AFA5),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No booking requests',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF006A5B),
                            fontFamily: 'Poppins',
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'New booking requests will appear here',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF67AFA5),
                            fontFamily: 'Poppins',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              final allRequests = snapshot.data!.docs;

              // Sort by createdAt in descending order (newest first) in memory
              allRequests.sort((a, b) {
                final aData = a.data() as Map<String, dynamic>;
                final bData = b.data() as Map<String, dynamic>;
                final aCreatedAt = aData['createdAt'] as Timestamp?;
                final bCreatedAt = bData['createdAt'] as Timestamp?;

                if (aCreatedAt == null && bCreatedAt == null) return 0;
                if (aCreatedAt == null) return 1;
                if (bCreatedAt == null) return -1;

                return bCreatedAt.compareTo(aCreatedAt); // Descending order
              });

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: allRequests.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final request = allRequests[index];
                  final requestId = request.id;
                  final requestData = request.data() as Map<String, dynamic>;
                  return _buildRequestCard(requestId, requestData);
                },
              );
            },
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildRequestCard(String requestId, Map<String, dynamic> request) {
    // Extract data from the Firebase structure
    final parentInfo = request['parentInfo'] as Map<String, dynamic>? ?? {};
    final childInfo = request['childInfo'] as Map<String, dynamic>? ?? {};
    final appointmentDetails =
        request['appointmentDetails'] as Map<String, dynamic>? ?? {};

    final parentName = FieldHelper.getName(parentInfo) ?? 'Unknown Parent';
    final childName = FieldHelper.getName(childInfo) ?? 'Unknown Child';
    final childAge = childInfo['childAge']?.toString() ?? '';

    // Extract appointment date and time
    final appointmentTimestamp =
        appointmentDetails['requestedDate'] as Timestamp?;
    final appointmentDateStr = appointmentTimestamp != null
        ? DateFormat('MMM dd, yyyy').format(appointmentTimestamp.toDate())
        : 'TBD';
    final appointmentTime = appointmentDetails['requestedTime'] ?? 'TBD';

    final status = request['status'] ?? 'pending';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
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
                            childName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF006A5B),
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Parent: $parentName',
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: status == 'pending'
                            ? Colors.orange.withOpacity(0.2)
                            : status == 'accepted'
                                ? Colors.green.withOpacity(0.2)
                                : Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: status == 'pending'
                              ? Colors.orange
                              : status == 'accepted'
                                  ? Colors.green
                                  : Colors.red,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Color(0xFF67AFA5),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Date: $appointmentDateStr',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF67AFA5),
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 16,
                      color: Color(0xFF67AFA5),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Time: $appointmentTime',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF67AFA5),
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
                if (childAge.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.child_care,
                          size: 16,
                          color: Color(0xFF67AFA5),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Age: $childAge years',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF67AFA5),
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (status == 'pending')
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Color(0xFFE0E0E0),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () =>
                          _handleRequestAction(requestId, request, 'decline'),
                      icon:
                          const Icon(Icons.close, color: Colors.red, size: 18),
                      label: const Text(
                        'Decline',
                        style: TextStyle(
                          color: Colors.red,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 48,
                    color: const Color(0xFFE0E0E0),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () =>
                          _handleRequestAction(requestId, request, 'accept'),
                      icon: const Icon(Icons.check,
                          color: Color(0xFF006A5B), size: 18),
                      label: const Text(
                        'Accept',
                        style: TextStyle(
                          color: Color(0xFF006A5B),
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            bottomRight: Radius.circular(16),
                          ),
                        ),
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

  void _handleRequestAction(
      String requestId, Map<String, dynamic> request, String action) async {
    try {
      // Extract child name from the structure
      final childInfo = request['childInfo'] as Map<String, dynamic>? ?? {};
      final childName = FieldHelper.getName(childInfo) ?? 'Unknown Child';

      if (action == 'accept') {
        // Get current therapist ID for approval
        final prefs = await SharedPreferences.getInstance();
        final therapistId = prefs.getString('therapist_id') ??
            prefs.getString('user_id') ??
            'unknown';

        // Use AcceptedBookingService to accept the request
        await AcceptedBookingService.acceptBookingRequest(
          requestId: requestId,
          requestData: request,
          approvedById: therapistId,
          assignedTherapistId: therapistId,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '✅ Booking request accepted for $childName and added to schedule'),
              backgroundColor: const Color(0xFF006A5B),
            ),
          );
        }
      } else {
        // Use BookingRequestService to decline the request
        final prefs = await SharedPreferences.getInstance();
        final therapistId = prefs.getString('therapist_id') ??
            prefs.getString('user_id') ??
            'unknown';

        final success = await BookingRequestService.declineBookingRequest(
          requestId: requestId,
          reviewerId: therapistId,
          reason: 'Declined by therapist',
        );

        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Booking request declined for $childName'),
                backgroundColor: Colors.red,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text('❌ Failed to decline booking request for $childName'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Error in _handleRequestAction: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildTodayAppointmentCard(Map<String, dynamic> appointment) {
    // Extract patient information using FieldHelper
    final childInfo = appointment['childInfo'] as Map<String, dynamic>? ?? {};
    final parentInfo = appointment['parentInfo'] as Map<String, dynamic>? ?? {};

    final patientName = FieldHelper.getName(childInfo) ??
        FieldHelper.getName(parentInfo) ??
        appointment['patientName'] ??
        'Unknown Patient';

    final appointmentTime = appointment['appointmentTime'] ?? 'Time TBD';
    final appointmentType = appointment['appointmentType'] ?? 'Therapy Session';
    final childAge = childInfo['childAge']?.toString();

    // Parse color from hex string or use default
    Color appointmentColor = const Color(0xFF006A5B);
    try {
      final colorString = appointment['color'] as String?;
      if (colorString != null) {
        appointmentColor =
            Color(int.parse(colorString.replaceFirst('#', '0xFF')));
      }
    } catch (e) {
      // Use default color if parsing fails
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: appointmentColor,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Center(
                child: Text(
                  patientName.isNotEmpty
                      ? patientName.substring(0, 1).toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patientName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF006A5B),
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: Color(0xFF67AFA5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        appointmentTime,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF67AFA5),
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.medical_services,
                        size: 14,
                        color: Color(0xFF67AFA5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        appointmentType,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF67AFA5),
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF006A5B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'TODAY',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF006A5B),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                if (childAge != null && childAge.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Age: $childAge',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF67AFA5),
                        fontFamily: 'Poppins',
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

  void _showDayScheduleDialog(DateTime selectedDay) {
    final dayAppointments = _getEventsForDay(selectedDay);
    final formattedDate = DateFormat('MMMM dd, yyyy').format(selectedDay);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          formattedDate,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF006A5B),
            fontFamily: 'Poppins',
          ),
        ),
        content: dayAppointments.isEmpty
            ? const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.event_available,
                    size: 48,
                    color: Color(0xFF67AFA5),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No appointments scheduled',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Color(0xFF67AFA5),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${dayAppointments.length} appointment${dayAppointments.length > 1 ? 's' : ''}:',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                      color: Color(0xFF006A5B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...dayAppointments.map((appointment) {
                    final childInfo = appointment['childInfo'] as Map<String, dynamic>? ?? {};
                    final parentInfo = appointment['parentInfo'] as Map<String, dynamic>? ?? {};
                    final patientName = FieldHelper.getName(childInfo) ??
                        FieldHelper.getName(parentInfo) ??
                        'Unknown Patient';
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF006A5B).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF006A5B).withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              patientName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF006A5B),
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${appointment['appointmentTime']} - ${appointment['appointmentType'] ?? 'Therapy Session'}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF67AFA5),
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(
                color: Color(0xFF006A5B),
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  Future<List<Map<String, dynamic>>> _getTodayAppointments() async {
    try {
      final therapistId = await _getCurrentTherapistId();
      if (therapistId == null) return [];

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

      final querySnapshot = await FirebaseFirestore.instance
          .collection('AcceptedBooking')
          .where('serviceProvider.therapistId', isEqualTo: therapistId)
          .where('appointmentDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('appointmentDate',
              isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
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

  Stream<QuerySnapshot> _getBookingRequestsStream() {
    return FirebaseFirestore.instance
        .collection('Request')
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }
}
