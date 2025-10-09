import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class ClinicScheduleOverview extends StatefulWidget {
  const ClinicScheduleOverview({Key? key}) : super(key: key);

  @override
  State<ClinicScheduleOverview> createState() => _ClinicScheduleOverviewState();
}

class _ClinicScheduleOverviewState extends State<ClinicScheduleOverview> {
  String? clinicId;
  Map<DateTime, List<Map<String, dynamic>>> bookingEvents = {};
  DateTime currentMonth = DateTime.now();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _getClinicId();
    await _loadAcceptedBookings();
  }

  Future<void> _getClinicId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      clinicId = prefs.getString('clinicId') ?? prefs.getString('clinic_id');
    });
  }

  Future<void> _loadAcceptedBookings() async {
    if (clinicId == null) return;

    try {
      setState(() {
        isLoading = true;
      });

      // Get bookings for current month and surrounding months
      final startDate = DateTime(currentMonth.year, currentMonth.month - 1, 1);
      final endDate = DateTime(currentMonth.year, currentMonth.month + 2, 0);

      final snapshot = await FirebaseFirestore.instance
          .collection('AcceptedBooking')
          .where('clinicId', isEqualTo: clinicId)
          .where('status', isEqualTo: 'confirmed')
          .get();

      final Map<DateTime, List<Map<String, dynamic>>> events = {};

      for (var doc in snapshot.docs) {
        final booking = doc.data();
        
        // Extract appointment date
        dynamic appointmentDate = booking['appointmentDate'];
        DateTime? bookingDate;
        
        if (appointmentDate is Timestamp) {
          bookingDate = appointmentDate.toDate();
        } else if (appointmentDate is String) {
          try {
            bookingDate = DateTime.parse(appointmentDate);
          } catch (e) {
            continue;
          }
        }
        
        if (bookingDate != null) {
          // Normalize to date only
          final dateKey = DateTime(bookingDate.year, bookingDate.month, bookingDate.day);
          
          // Only include dates within our range
          if (dateKey.isAfter(startDate.subtract(Duration(days: 1))) && 
              dateKey.isBefore(endDate.add(Duration(days: 1)))) {
            
            if (events[dateKey] == null) {
              events[dateKey] = [];
            }
            
            events[dateKey]!.add({
              'patientName': booking['patientInfo']?['childName'] ?? 'Unknown',
              'time': booking['appointmentTime'] ?? 'No time',
              'type': booking['appointmentType'] ?? 'Consultation',
            });
          }
        }
      }

      setState(() {
        bookingEvents = events;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading bookings: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _changeMonth(int direction) {
    setState(() {
      currentMonth = DateTime(currentMonth.year, currentMonth.month + direction, 1);
    });
    _loadAcceptedBookings();
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(currentMonth.year, currentMonth.month, 1);
    final startOfWeek = firstDayOfMonth.subtract(Duration(days: firstDayOfMonth.weekday % 7));
    
    final List<Widget> dayWidgets = [];
    
    // Day headers
    final dayHeaders = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    for (String dayName in dayHeaders) {
      dayWidgets.add(
        Container(
          height: 40,
          alignment: Alignment.center,
          child: Text(
            dayName,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF67AFA5),
              fontSize: 14,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      );
    }
    
    // Calendar days
    for (int i = 0; i < 42; i++) { // 6 weeks * 7 days
      final date = startOfWeek.add(Duration(days: i));
      final isCurrentMonth = date.month == currentMonth.month;
      final isToday = DateTime.now().day == date.day && 
                     DateTime.now().month == date.month && 
                     DateTime.now().year == date.year;
      final hasBookings = bookingEvents[date]?.isNotEmpty ?? false;
      
      dayWidgets.add(
        Container(
          height: 50,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200, width: 0.5),
          ),
          child: Stack(
            children: [
              // Day number
              Positioned(
                top: 4,
                left: 4,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isToday 
                        ? const Color(0xFF006A5B)
                        : hasBookings 
                            ? const Color(0xFF67AFA5).withOpacity(0.3)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      color: isCurrentMonth 
                          ? (isToday ? Colors.white : Colors.black87)
                          : Colors.grey.shade400,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
              
              // Booking indicator
              if (hasBookings && isCurrentMonth)
                Positioned(
                  bottom: 4,
                  left: 4,
                  right: 4,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: const Color(0xFF006A5B),
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }
    
    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: dayWidgets,
    );
  }

  Widget _buildQuickStats() {
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);
    final todayBookings = bookingEvents[todayKey]?.length ?? 0;
    
    final thisWeekStart = today.subtract(Duration(days: today.weekday % 7));
    int thisWeekBookings = 0;
    for (int i = 0; i < 7; i++) {
      final day = thisWeekStart.add(Duration(days: i));
      final dayKey = DateTime(day.year, day.month, day.day);
      thisWeekBookings += bookingEvents[dayKey]?.length ?? 0;
    }
    
    final thisMonthBookings = bookingEvents.entries
        .where((entry) => entry.key.month == currentMonth.month && entry.key.year == currentMonth.year)
        .fold(0, (sum, entry) => sum + entry.value.length);

    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard('Today', todayBookings.toString(), Icons.today),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard('This Week', thisWeekBookings.toString(), Icons.view_week),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard('This Month', thisMonthBookings.toString(), Icons.calendar_month),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
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
        children: [
          Icon(
            icon,
            color: const Color(0xFF006A5B),
            size: 20,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF006A5B),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
              fontFamily: 'Poppins',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context).size;
    
    return Scaffold(
      body: Stack(
        children: [
          // Top ellipse background
          Positioned(
            top: -100,
            left: -50,
            right: -50,
            child: Container(
              height: mq.height * 0.4,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF006A5B),
                    Color(0xFF67AFA5),
                  ],
                ),
              ),
              child: Image.asset(
                'asset/images/Ellipse 1.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container();
                },
              ),
            ),
          ),

          // Bottom ellipse background
          Positioned(
            bottom: -100,
            left: -50,
            right: -50,
            child: Container(
              height: mq.height * 0.3,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Color(0xFF67AFA5),
                    Colors.white,
                  ],
                ),
              ),
              child: Image.asset(
                'asset/images/Ellipse 2.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container();
                },
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                      ),
                      const Expanded(
                        child: Text(
                          'Schedule Overview',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Poppins',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                // Quick stats
                _buildQuickStats(),

                // Calendar container
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Calendar header
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: Color(0xFF006A5B),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                onPressed: () => _changeMonth(-1),
                                icon: const Icon(Icons.chevron_left, color: Colors.white),
                              ),
                              Text(
                                DateFormat('MMMM yyyy').format(currentMonth),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              IconButton(
                                onPressed: () => _changeMonth(1),
                                icon: const Icon(Icons.chevron_right, color: Colors.white),
                              ),
                            ],
                          ),
                        ),

                        // Calendar grid
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF006A5B),
                                    ),
                                  )
                                : _buildCalendarGrid(),
                          ),
                        ),
                      ],
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
}
