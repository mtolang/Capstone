import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/clinic_schedule_service.dart';
import '../../services/booking_request_service.dart';
import 'clinic_request.dart';

class ClinicBookingTabBar extends StatefulWidget {
  const ClinicBookingTabBar({Key? key}) : super(key: key);

  @override
  State<ClinicBookingTabBar> createState() => _ClinicBookingTabBarState();
}

class _ClinicBookingTabBarState extends State<ClinicBookingTabBar>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _currentMonth = DateTime.now(); // Add calendar month state
  Map<int, List<Map<String, dynamic>>> _monthlyAppointments =
      {}; // Add monthly appointments storage

  final List<Map<String, dynamic>> bookings = [
    {
      'name': 'Joe Alwyn',
      'time': '02:00 - 03:00 PM',
      'color': Colors.teal,
    },
    {
      'name': 'Selena Gomez',
      'time': '03:00 - 04:00 PM',
      'color': Colors.lightGreen,
    },
    {
      'name': 'Lana Del Ray',
      'time': '04:00 - 05:00 PM',
      'color': Colors.blue,
    },
    {
      'name': 'Ed Sheeran',
      'time': '05:00 - 06:00 PM',
      'color': Colors.indigo,
    },
    {
      'name': 'Avril Lavigne',
      'time': '06:00 - 07:00 PM',
      'color': Colors.blueAccent,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMonthlyAppointments(); // Load appointments when the widget initializes
  }

  // Calendar navigation methods
  void _navigateToPreviousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
      _loadMonthlyAppointments(); // Reload appointments when month changes
    });
  }

  void _navigateToNextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
      _loadMonthlyAppointments(); // Reload appointments when month changes
    });
  }

  // Load monthly appointments from AcceptedBooking collection
  Future<void> _loadMonthlyAppointments() async {
    try {
      final clinicId = await _getCurrentClinicId();
      if (clinicId == null) {
        print('❌ No clinic ID found');
        return;
      }

      print('🏥 Loading appointments for clinic: $clinicId');
      print('📅 Month: ${DateFormat('MMMM yyyy').format(_currentMonth)}');

      // Query AcceptedBooking collection for this clinic
      final querySnapshot = await FirebaseFirestore.instance
          .collection('AcceptedBooking')
          .where('clinicId', isEqualTo: clinicId)
          .where('status', isEqualTo: 'confirmed')
          .get();

      print('📦 Found ${querySnapshot.docs.length} total bookings');

      // Group appointments by day
      final Map<int, List<Map<String, dynamic>>> groupedAppointments = {};

      for (var doc in querySnapshot.docs) {
        final data = doc.data();

        // Check if this is a CONTRACT booking
        final originalRequestData = data['originalRequestData'];
        final bookingProcessType = originalRequestData?['bookingProcessType'];

        if (bookingProcessType == 'contract') {
          // CONTRACT BOOKING - Generate recurring events for this month
          print('🔶 CONTRACT found: ${doc.id}');

          final contractInfo = originalRequestData?['contractInfo'];
          if (contractInfo == null) {
            print('   ⚠️  No contractInfo');
            continue;
          }

          final dayOfWeek = contractInfo['dayOfWeek']?.toString();
          final appointmentTime = contractInfo['appointmentTime']?.toString();

          print('   Day: $dayOfWeek, Time: $appointmentTime');

          if (dayOfWeek == null || appointmentTime == null) {
            print('   ⚠️  Missing data');
            continue;
          }

          // Map day names to weekday numbers
          final dayMap = {
            'Monday': 1,
            'Tuesday': 2,
            'Wednesday': 3,
            'Thursday': 4,
            'Friday': 5,
            'Saturday': 6,
            'Sunday': 7,
          };

          final targetWeekday = dayMap[dayOfWeek];
          if (targetWeekday == null) {
            print('   ⚠️  Unknown day: $dayOfWeek');
            continue;
          }

          // Generate events for every matching day in THIS MONTH
          final firstDayOfMonth =
              DateTime(_currentMonth.year, _currentMonth.month, 1);
          final lastDayOfMonth =
              DateTime(_currentMonth.year, _currentMonth.month + 1, 0);

          DateTime currentDate = firstDayOfMonth;
          int eventsAdded = 0;

          while (currentDate
              .isBefore(lastDayOfMonth.add(const Duration(days: 1)))) {
            if (currentDate.weekday == targetWeekday) {
              final dayOfMonth = currentDate.day;

              final childInfo = originalRequestData['childInfo'];
              final appointmentInfo = {
                'patientName': childInfo?['childName'] ?? 'Contract Client',
                'appointmentTime': appointmentTime,
                'appointmentType':
                    contractInfo['appointmentType'] ?? 'Contract Session',
                'isContract': true,
              };

              if (groupedAppointments[dayOfMonth] == null) {
                groupedAppointments[dayOfMonth] = [];
              }
              groupedAppointments[dayOfMonth]!.add(appointmentInfo);
              eventsAdded++;
            }

            currentDate = currentDate.add(const Duration(days: 1));
          }

          print('   ✅ Added $eventsAdded contract events for this month');
        } else {
          // REGULAR ONE-TIME BOOKING
          final appointmentDate =
              (data['appointmentDate'] as Timestamp?)?.toDate();
          if (appointmentDate == null) continue;

          // Check if this appointment is in the current month
          if (appointmentDate.year != _currentMonth.year ||
              appointmentDate.month != _currentMonth.month) {
            continue;
          }

          final dayOfMonth = appointmentDate.day;

          final appointmentInfo = {
            'patientName': data['childName'] ?? data['parentName'] ?? 'Unknown',
            'appointmentTime': data['appointmentTime'] ?? 'Time TBD',
            'appointmentType': data['appointmentType'] ?? 'Therapy Session',
            'isContract': false,
          };

          if (groupedAppointments[dayOfMonth] == null) {
            groupedAppointments[dayOfMonth] = [];
          }
          groupedAppointments[dayOfMonth]!.add(appointmentInfo);
        }
      }

      setState(() {
        _monthlyAppointments = groupedAppointments;
      });

      print('✅ Loaded ${groupedAppointments.length} days with appointments');
    } catch (e) {
      print('❌ Error loading monthly appointments: $e');
    }
  }

  // Helper method to get current clinic ID
  Future<String?> _getCurrentClinicId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('clinic_id');
    } catch (e) {
      print('Error getting clinic ID: $e');
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

    return Column(
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
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
              fontSize: 12,
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
                  blurRadius: 5,
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
            future: AcceptedBookingService.getTodayAcceptedAppointments(),
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
                  child: Text(
                    'Error loading appointments: ${snapshot.error}',
                    style: const TextStyle(
                      color: Colors.red,
                      fontFamily: 'Poppins',
                    ),
                  ),
                );
              }

              final todayAppointments = snapshot.data ?? [];

              if (todayAppointments.isEmpty) {
                return Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.free_breakfast,
                          size: 64,
                          color: Color(0xFF67AFA5),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No appointments today',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF67AFA5),
                            fontFamily: 'Poppins',
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Enjoy your free day!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF67AFA5),
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
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
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Text(
                "That's it for today!",
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF67AFA5),
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
                  blurRadius: 5,
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
                  color: Colors.black.withOpacity(0.08),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Calendar Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF006A5B),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: _navigateToPreviousMonth,
                        icon:
                            const Icon(Icons.chevron_left, color: Colors.white),
                      ),
                      Text(
                        DateFormat('MMMM yyyy').format(_currentMonth),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      IconButton(
                        onPressed: _navigateToNextMonth,
                        icon: const Icon(Icons.chevron_right,
                            color: Colors.white),
                      ),
                    ],
                  ),
                ),

                // Calendar Grid
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Days of week header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children:
                            ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                                .map((day) => SizedBox(
                                      width: 35,
                                      child: Text(
                                        day,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF67AFA5),
                                          fontFamily: 'Poppins',
                                          fontSize: 12,
                                        ),
                                      ),
                                    ))
                                .toList(),
                      ),
                      const SizedBox(height: 10),

                      // Calendar days grid
                      _buildCalendarGrid(),
                    ],
                  ),
                ),
              ],
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
                  color: Colors.black.withOpacity(0.08),
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
                          onPressed: () {
                            Navigator.pushNamed(context, '/clinicschedule');
                          },
                          icon: const Icon(Icons.calendar_view_week, size: 18),
                          label: const Text(
                            'Weekly View',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF006A5B),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, '/cliniceditschedule');
                          },
                          icon: const Icon(Icons.edit_calendar, size: 18),
                          label: const Text(
                            'Edit Schedule',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF67AFA5),
                            foregroundColor: Colors.white,
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
                  blurRadius: 5,
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
          // Weekly View Button
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ClinicRequestScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.calendar_view_week, color: Colors.white),
              label: const Text(
                'View Weekly Schedule',
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
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('Request')
                .orderBy('createdAt',
                    descending: false) // Show oldest requests first
                .snapshots(),
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
                  child: Text(
                    'Error loading requests: ${snapshot.error}',
                    style: const TextStyle(
                      color: Colors.red,
                      fontFamily: 'Poppins',
                    ),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 5,
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
                          'No pending requests',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF67AFA5),
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final requests = snapshot.data!.docs;

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: requests.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final doc = requests[index];
                  final request = doc.data() as Map<String, dynamic>;
                  final requestId = doc.id;

                  return _buildFirebaseRequestCard(requestId, request);
                },
              );
            },
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 120,
                decoration: const BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),
              Expanded(
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
                              request['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Color(0xFF006A5B),
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              request['status'].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.orange,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'For: ${request['childName']}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF67AFA5),
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Color(0xFF67AFA5),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${request['day']}, ${request['date']}',
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
                            Icons.access_time,
                            size: 16,
                            color: Color(0xFF67AFA5),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            request['time'],
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
                            size: 16,
                            color: Color(0xFF67AFA5),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            request['type'],
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
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _handleRequestAction(request, 'decline');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[100],
                      foregroundColor: Colors.red[700],
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Decline',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _handleRequestAction(request, 'accept');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF006A5B),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Accept',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
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

  Widget _buildFirebaseRequestCard(
      String requestId, Map<String, dynamic> request) {
    final createdAt = request['createdAt'] as Timestamp?;
    final requestDate = createdAt != null
        ? DateFormat('MMM dd, yyyy').format(createdAt.toDate())
        : 'Recently';

    // Extract data from the new Firebase structure
    final parentInfo = request['parentInfo'] as Map<String, dynamic>? ?? {};
    final childInfo = request['childInfo'] as Map<String, dynamic>? ?? {};
    final appointmentDetails =
        request['appointmentDetails'] as Map<String, dynamic>? ?? {};

    final parentName = parentInfo['parentName'] ?? 'Unknown Parent';
    final childName = childInfo['childName'] ?? 'Unknown Child';
    final childAge = childInfo['childAge']?.toString() ?? '';

    // Extract appointment date and time
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
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFF006A5B),
                      radius: 25,
                      child: Text(
                        childName.isNotEmpty ? childName[0].toUpperCase() : 'C',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
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
                            'for $childName${childAge.isNotEmpty ? " (${childAge}y)" : ""}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF67AFA5),
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: status == 'pending'
                                ? Colors.orange.withOpacity(0.1)
                                : status == 'approved'
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              color: status == 'pending'
                                  ? Colors.orange
                                  : status == 'approved'
                                      ? Colors.green
                                      : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Requested: $requestDate',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
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
                      '$appointmentDateStr at $appointmentTime',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF67AFA5),
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.medical_services,
                      size: 16,
                      color: Color(0xFF67AFA5),
                    ),
                    const SizedBox(width: 8),
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
                if (parentInfo['parentPhone'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.phone,
                          size: 16,
                          color: Color(0xFF67AFA5),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          parentInfo['parentPhone'],
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
                    child: TextButton(
                      onPressed: () => _handleFirebaseRequestAction(
                          requestId, request, 'decline'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(16),
                          ),
                        ),
                      ),
                      child: const Text(
                        'Decline',
                        style: TextStyle(
                          color: Colors.red,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
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
                    child: TextButton(
                      onPressed: () => _handleFirebaseRequestAction(
                          requestId, request, 'accept'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            bottomRight: Radius.circular(16),
                          ),
                        ),
                      ),
                      child: const Text(
                        'Accept',
                        style: TextStyle(
                          color: Color(0xFF006A5B),
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
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

  void _handleFirebaseRequestAction(
      String requestId, Map<String, dynamic> request, String action) async {
    try {
      // Extract child name from the new structure
      final childInfo = request['childInfo'] as Map<String, dynamic>? ?? {};
      final childName = childInfo['childName'] ?? 'Unknown Child';

      if (action == 'accept') {
        // Get current clinic ID for approval
        final prefs = await SharedPreferences.getInstance();
        final clinicId = prefs.getString('clinic_id') ??
            prefs.getString('user_id') ??
            'unknown';

        // Use the new service to approve and move to AcceptedBooking database
        final success = await BookingRequestService.approveBookingRequest(
          requestId: requestId,
          reviewerId: clinicId,
          additionalNotes: 'Approved via clinic booking system',
        );

        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    '✅ Booking request accepted for $childName and moved to schedule'),
                backgroundColor: const Color(0xFF006A5B),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text('❌ Failed to process booking request for $childName'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        // Use the new service to decline the request
        final prefs = await SharedPreferences.getInstance();
        final clinicId = prefs.getString('clinic_id') ??
            prefs.getString('user_id') ??
            'unknown';

        final success = await BookingRequestService.declineBookingRequest(
          requestId: requestId,
          reviewerId: clinicId,
          reason: 'Declined via clinic booking system',
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
      print('Error in _handleFirebaseRequestAction: $e');
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

  void _handleRequestAction(Map<String, dynamic> request, String action) {
    final message = action == 'accept'
        ? 'Booking request accepted for ${request['childName']}'
        : 'Booking request declined for ${request['childName']}';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            action == 'accept' ? const Color(0xFF006A5B) : Colors.red,
      ),
    );
  }

  Widget _buildTodayAppointmentCard(Map<String, dynamic> appointment) {
    // Parse color from hex string
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
                  appointment['patientName']?.isNotEmpty == true
                      ? appointment['patientName'][0].toUpperCase()
                      : 'P',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
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
                    appointment['patientName'] ?? 'Unknown Patient',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Parent: ${appointment['parentName'] ?? 'Unknown'}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: Color(0xFF67AFA5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        appointment['appointmentTime'] ?? 'Time TBD',
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
                        size: 16,
                        color: Color(0xFF67AFA5),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          appointment['appointmentType'] ?? 'Therapy Session',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF67AFA5),
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (appointment['additionalNotes']?.isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.note,
                          size: 16,
                          color: Color(0xFF67AFA5),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            appointment['additionalNotes'],
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF67AFA5),
                              fontFamily: 'Poppins',
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: appointmentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Today',
                    style: TextStyle(
                      color: Color(0xFF006A5B),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                if (appointment['childAge'] != null &&
                    appointment['childAge'] > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Age: ${appointment['childAge']}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 80,
            decoration: BoxDecoration(
              color: booking['color'],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF006A5B),
                      fontFamily: 'Poppins',
                    ),
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
                        booking['time'],
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF67AFA5),
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF006A5B).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.link,
                              size: 14,
                              color: Color(0xFF006A5B),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Meet Link',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF006A5B),
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
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
      final isToday = day == now.day &&
          _currentMonth.year == now.year &&
          _currentMonth.month == now.month;
      final hasAppointments = _monthlyAppointments.containsKey(day);
      final dayAppointments = _monthlyAppointments[day] ?? [];

      calendarDays.add(
        GestureDetector(
          onTap: () {
            _showDaySchedule(day, dayAppointments);
          },
          child: Container(
            width: 35,
            height: 45,
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isToday
                  ? const Color(0xFF006A5B)
                  : hasAppointments
                      ? const Color(0xFF67AFA5).withOpacity(0.3)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: hasAppointments
                  ? Border.all(color: const Color(0xFF67AFA5), width: 1)
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  day.toString(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    color: isToday
                        ? Colors.white
                        : hasAppointments
                            ? const Color(0xFF006A5B)
                            : Colors.black87,
                    fontFamily: 'Poppins',
                  ),
                ),
                if (hasAppointments)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    width: 16,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isToday ? Colors.white : const Color(0xFF006A5B),
                      borderRadius: BorderRadius.circular(2),
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
        for (int week = 0; week < 6; week++)
          if (week * 7 < calendarDays.length)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _getWeekDays(calendarDays, week),
              ),
            ),
      ],
    );
  }

  // Helper method to get exactly 7 days for each week row
  List<Widget> _getWeekDays(List<Widget> calendarDays, int week) {
    final startIndex = week * 7;
    final endIndex = startIndex + 7;

    List<Widget> weekDays = [];

    for (int i = startIndex; i < endIndex; i++) {
      if (i < calendarDays.length) {
        weekDays.add(calendarDays[i]);
      } else {
        // Add empty cell to fill the row
        weekDays.add(const SizedBox(width: 35, height: 45));
      }
    }

    return weekDays;
  }

  void _showDaySchedule(int day, List<Map<String, dynamic>> appointments) {
    final selectedDate = DateTime(_currentMonth.year, _currentMonth.month, day);
    final formattedDate = DateFormat('MMMM dd, yyyy').format(selectedDate);

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
        content: appointments.isEmpty
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
                    '${appointments.length} appointment${appointments.length > 1 ? 's' : ''}:',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF006A5B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...appointments.map((appointment) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF67AFA5).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF67AFA5).withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.person,
                                    size: 16,
                                    color: Color(0xFF006A5B),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      appointment['patientName'] ??
                                          'Unknown Patient',
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF006A5B),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.schedule,
                                    size: 16,
                                    color: Color(0xFF67AFA5),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    appointment['appointmentTime'] ??
                                        'Time TBD',
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      color: Color(0xFF006A5B),
                                    ),
                                  ),
                                ],
                              ),
                              if (appointment['appointmentType'] != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.medical_services,
                                      size: 16,
                                      color: Color(0xFF67AFA5),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        appointment['appointmentType'],
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 12,
                                          color: Color(0xFF67AFA5),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      )),
                ],
              ),
        actions: [
          if (appointments.isEmpty)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/cliniceditschedule');
              },
              child: const Text(
                'Add Appointment',
                style: TextStyle(
                  color: Color(0xFF006A5B),
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
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
}
