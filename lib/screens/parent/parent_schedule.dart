import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kindora/screens/parent/parent_navbar.dart';

class ParentSchedulePage extends StatefulWidget {
  const ParentSchedulePage({Key? key}) : super(key: key);

  @override
  State<ParentSchedulePage> createState() => _ParentSchedulePageState();
}

class _ParentSchedulePageState extends State<ParentSchedulePage> {
  DateTime _currentMonth = DateTime.now();
  DateTime _selectedDate = DateTime.now();
  String? _parentId;
  List<Map<String, dynamic>> _acceptedBookings = [];
  Map<String, dynamic>? _selectedDateMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadParentId();
  }

  Future<void> _loadParentId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _parentId = prefs.getString('parent_id') ?? prefs.getString('user_id');
    });

    if (_parentId != null) {
      await _loadAcceptedBookings();
      await _loadScheduleMessage(_selectedDate);
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadAcceptedBookings() async {
    if (_parentId == null) return;

    try {
      final startOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
      final endOfMonth =
          DateTime(_currentMonth.year, _currentMonth.month + 1, 0);

      final querySnapshot = await FirebaseFirestore.instance
          .collection('AcceptedBooking')
          .where('parentInfo.parentId', isEqualTo: _parentId)
          .where('appointmentDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('appointmentDate',
              isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .get();

      setState(() {
        _acceptedBookings = querySnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            ...data,
          };
        }).toList();
      });
    } catch (e) {
      print('Error loading accepted bookings: $e');
    }
  }

  Future<void> _loadScheduleMessage(DateTime date) async {
    try {
      final dateString = DateFormat('yyyy-MM-dd').format(date);

      // Get clinic/therapist ID from the first accepted booking
      String? clinicId;
      String? therapistId;

      if (_acceptedBookings.isNotEmpty) {
        final booking = _acceptedBookings.first;
        clinicId = booking['serviceProvider']?['clinicId'];
        therapistId = booking['serviceProvider']?['therapistId'];
      }

      if (clinicId == null && therapistId == null) return;

      final querySnapshot = await FirebaseFirestore.instance
          .collection('ScheduleMessage')
          .where('date', isEqualTo: dateString)
          .where(clinicId != null ? 'clinicId' : 'therapistId',
              isEqualTo: clinicId ?? therapistId)
          .limit(1)
          .get();

      setState(() {
        _selectedDateMessage = querySnapshot.docs.isNotEmpty
            ? querySnapshot.docs.first.data()
            : null;
      });
    } catch (e) {
      print('Error loading schedule message: $e');
    }
  }

  void _navigateToPreviousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
    _loadAcceptedBookings();
  }

  void _navigateToNextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
    _loadAcceptedBookings();
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    _loadScheduleMessage(date);
  }

  List<Map<String, dynamic>> _getBookingsForDate(DateTime date) {
    final dateString = DateFormat('yyyy-MM-dd').format(date);
    return _acceptedBookings.where((booking) {
      final bookingDate = (booking['appointmentDate'] as Timestamp).toDate();
      final bookingDateString = DateFormat('yyyy-MM-dd').format(bookingDate);
      return bookingDateString == dateString;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      drawer: const ParentNavbar(),
      appBar: AppBar(
        backgroundColor: const Color(0xFF006A5B),
        elevation: 0,
        title: const Text(
          'My Schedule',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Poppins',
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // Background
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
                  errorBuilder: (context, error, stackTrace) => Container(),
                ),
              ),
            ),
          ),

          // Main content
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          else
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // Calendar Widget
                  _buildCalendarWidget(),

                  const SizedBox(height: 20),

                  // Schedule Message Section
                  _buildScheduleMessageSection(),

                  const SizedBox(height: 100),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCalendarWidget() {
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
                  icon: const Icon(Icons.chevron_left, color: Colors.white),
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
                  icon: const Icon(Icons.chevron_right, color: Colors.white),
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
                  children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
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
    );
  }

  Widget _buildCalendarGrid() {
    final now = DateTime.now();
    final firstDayOfMonth =
        DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDayOfMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final startingWeekday = firstDayOfMonth.weekday % 7;

    List<Widget> calendarDays = [];

    // Add empty cells for days before the first day of the month
    for (int i = 0; i < startingWeekday; i++) {
      calendarDays.add(const SizedBox(width: 35, height: 45));
    }

    // Add days of the month
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, day);
      final isToday = day == now.day &&
          _currentMonth.year == now.year &&
          _currentMonth.month == now.month;
      final isSelected = day == _selectedDate.day &&
          _currentMonth.year == _selectedDate.year &&
          _currentMonth.month == _selectedDate.month;
      final bookings = _getBookingsForDate(date);
      final hasBookings = bookings.isNotEmpty;

      calendarDays.add(
        GestureDetector(
          onTap: () => _selectDate(date),
          child: Container(
            width: 35,
            height: 45,
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF006A5B)
                  : isToday
                      ? const Color(0xFF67AFA5)
                      : hasBookings
                          ? const Color(0xFF67AFA5).withOpacity(0.3)
                          : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: hasBookings && !isSelected && !isToday
                  ? Border.all(color: const Color(0xFF67AFA5), width: 1)
                  : null,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    day.toString(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected || isToday
                          ? Colors.white
                          : hasBookings
                              ? const Color(0xFF006A5B)
                              : Colors.black54,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  if (hasBookings)
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isSelected || isToday
                            ? Colors.white
                            : const Color(0xFF006A5B),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: calendarDays,
    );
  }

  Widget _buildScheduleMessageSection() {
    final selectedBookings = _getBookingsForDate(_selectedDate);

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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.event_note,
                  color: Color(0xFF006A5B),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  DateFormat('EEEE, MMMM dd, yyyy').format(_selectedDate),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF006A5B),
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Show appointments for selected date
            if (selectedBookings.isNotEmpty) ...[
              const Text(
                'Your Appointments:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF006A5B),
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 8),
              ...selectedBookings
                  .map((booking) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF67AFA5).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF67AFA5).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              color: Color(0xFF006A5B),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              booking['appointmentTime'] ?? 'Time TBD',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF006A5B),
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                booking['appointmentType'] ?? 'Therapy Session',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF006A5B),
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
              const SizedBox(height: 16),
            ],

            // Show therapist/clinic message
            const Text(
              'Message from Therapist/Clinic:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF006A5B),
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),

            if (_selectedDateMessage != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF006A5B).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF006A5B).withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_selectedDateMessage!['title'] != null) ...[
                      Text(
                        _selectedDateMessage!['title'],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF006A5B),
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (_selectedDateMessage!['startTime'] != null &&
                        _selectedDateMessage!['endTime'] != null) ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule,
                            color: Color(0xFFE74C3C),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Unavailable: ${_selectedDateMessage!['startTime']} - ${_selectedDateMessage!['endTime']}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFFE74C3C),
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (_selectedDateMessage!['details'] != null)
                      Text(
                        _selectedDateMessage!['details'],
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF006A5B),
                          fontFamily: 'Poppins',
                        ),
                      ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.3),
                  ),
                ),
                child: const Text(
                  'No message for this date.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontFamily: 'Poppins',
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
