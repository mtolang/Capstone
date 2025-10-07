import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:capstone_2/services/schedule_database_service.dart';
import 'package:capstone_2/screens/parent/parent_booking_process.dart';

class ParentBookingPage extends StatefulWidget {
  final String? clinicId;
  final String? therapistId;

  const ParentBookingPage({
    Key? key,
    this.clinicId,
    this.therapistId,
  }) : super(key: key);

  @override
  State<ParentBookingPage> createState() => _ParentBookingPageState();
}

class _ParentBookingPageState extends State<ParentBookingPage> {
  DateTime selectedDate = DateTime.now();
  DateTime currentMonth = DateTime.now();
  String? selectedTimeSlot;
  Map<String, dynamic>? clinicSchedule;
  bool isLoading = true;
  List<Map<String, dynamic>> availableSlots = [];
  String bookingProcessType = 'single'; // Default to single session

  @override
  void initState() {
    super.initState();
    _loadClinicSchedule();
  }

  Future<void> _loadClinicSchedule() async {
    try {
      setState(() {
        isLoading = true;
      });

      // Use therapistId if provided, otherwise use clinicId
      String scheduleId = widget.therapistId ?? widget.clinicId ?? 'CLI01';

      final schedule = await ScheduleDatabaseService.loadSchedule(scheduleId);

      if (schedule != null) {
        setState(() {
          clinicSchedule = schedule;

          // Extract booking process type from recurring settings
          final recurringSettings =
              schedule['recurringSettings'] as Map<String, dynamic>?;
          if (recurringSettings != null &&
              recurringSettings['bookingProcessType'] != null) {
            bookingProcessType =
                recurringSettings['bookingProcessType'] as String;
          }

          isLoading = false;
        });
        _loadAvailableSlotsForDate(selectedDate);
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading clinic schedule: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _loadAvailableSlotsForDate(DateTime date) {
    if (clinicSchedule == null) return;

    final dayName = _getDayName(date);
    final weeklySchedule =
        clinicSchedule!['weeklySchedule'] as Map<String, dynamic>?;

    if (weeklySchedule != null && weeklySchedule.containsKey(dayName)) {
      final daySchedule = weeklySchedule[dayName] as Map<String, dynamic>;
      final timeSlots =
          List<Map<String, dynamic>>.from(daySchedule['timeSlots'] ?? []);

      setState(() {
        availableSlots = timeSlots
            .where((slot) =>
                slot['isAvailable'] == true && slot['isBooked'] != true)
            .toList();
      });
    } else {
      setState(() {
        availableSlots = [];
      });
    }
  }

  String _getDayName(DateTime date) {
    final days = [
      'sunday',
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday'
    ];
    return days[date.weekday % 7];
  }

  List<Map<String, dynamic>> _getMorningSlots() {
    return availableSlots.where((slot) {
      final startTime = slot['startTime'] as String;
      final hour = int.parse(startTime.split(':')[0]);
      return hour < 12;
    }).toList();
  }

  List<Map<String, dynamic>> _getAfternoonSlots() {
    return availableSlots.where((slot) {
      final startTime = slot['startTime'] as String;
      final hour = int.parse(startTime.split(':')[0]);
      return hour >= 12;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Top wave background
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 120,
              decoration: const BoxDecoration(
                color: Color(0xFF006A5B),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
            ),
          ),

          // Main content
          Column(
            children: [
              // Custom AppBar
              Container(
                padding: const EdgeInsets.only(
                    top: 40, left: 16, right: 16, bottom: 20),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Therapy Clinic Profile',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 40), // For balance
                  ],
                ),
              ),

              // Tab indicator
              Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Profile',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Gallery',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Reviews',
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(color: Color(0xFF006A5B), fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Booking Process Header
              Container(
                padding: const EdgeInsets.all(20),
                child: const Row(
                  children: [
                    Text(
                      'Booking Process',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF006A5B),
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),

              // Main content
              Expanded(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF006A5B),
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Calendar
                            _buildCalendar(),

                            const SizedBox(height: 30),

                            // Morning Session
                            _buildSessionSection(
                              'Morning Session',
                              _getMorningSlots(),
                            ),

                            const SizedBox(height: 20),

                            // Afternoon Session
                            _buildSessionSection(
                              'Afternoon Session',
                              _getAfternoonSlots(),
                            ),

                            const SizedBox(height: 100), // Space for FAB
                          ],
                        ),
                      ),
              ),
            ],
          ),

          // Floating Action Button
          Positioned(
            bottom: 30,
            right: 20,
            child: FloatingActionButton(
              onPressed: () {
                if (selectedTimeSlot != null) {
                  _navigateToBookingForm();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select a time slot'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
              backgroundColor: const Color(0xFF006A5B),
              child: const Icon(
                Icons.arrow_forward,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
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
          // Month/Year header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    currentMonth =
                        DateTime(currentMonth.year, currentMonth.month - 1);
                  });
                },
                icon: const Icon(Icons.chevron_left, color: Color(0xFF006A5B)),
              ),
              Text(
                DateFormat('MMMM yyyy').format(currentMonth),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF006A5B),
                  fontFamily: 'Poppins',
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    currentMonth =
                        DateTime(currentMonth.year, currentMonth.month + 1);
                  });
                },
                icon: const Icon(Icons.chevron_right, color: Color(0xFF006A5B)),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Days of week header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']
                .map((day) => Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      child: Text(
                        day,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                    ))
                .toList(),
          ),

          const SizedBox(height: 10),

          // Calendar grid
          _buildCalendarGrid(),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(currentMonth.year, currentMonth.month, 1);
    final lastDayOfMonth =
        DateTime(currentMonth.year, currentMonth.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday % 7;

    List<Widget> calendarItems = [];

    // Empty cells for days before month starts
    for (int i = 0; i < firstWeekday; i++) {
      calendarItems.add(Container(width: 30, height: 30));
    }

    // Days of the month
    for (int day = 1; day <= lastDayOfMonth.day; day++) {
      final date = DateTime(currentMonth.year, currentMonth.month, day);
      final isSelected = selectedDate.year == date.year &&
          selectedDate.month == date.month &&
          selectedDate.day == date.day;
      final isToday = DateTime.now().year == date.year &&
          DateTime.now().month == date.month &&
          DateTime.now().day == date.day;
      final isPast =
          date.isBefore(DateTime.now().subtract(const Duration(days: 1)));

      calendarItems.add(
        GestureDetector(
          onTap: isPast
              ? null
              : () {
                  setState(() {
                    selectedDate = date;
                  });
                  _loadAvailableSlotsForDate(date);
                },
          child: Container(
            width: 30,
            height: 30,
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF006A5B)
                  : isToday
                      ? const Color(0xFF006A5B).withOpacity(0.3)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(15),
            ),
            alignment: Alignment.center,
            child: Text(
              day.toString(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : isPast
                        ? Colors.grey.shade400
                        : Colors.black87,
              ),
            ),
          ),
        ),
      );
    }

    return Wrap(
      children: calendarItems,
    );
  }

  Widget _buildSessionSection(String title, List<Map<String, dynamic>> slots) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF006A5B),
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 15),
        if (slots.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text(
                'No available slots',
                style: TextStyle(
                  color: Colors.grey,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          )
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: slots.map((slot) => _buildTimeSlotButton(slot)).toList(),
          ),
      ],
    );
  }

  Widget _buildTimeSlotButton(Map<String, dynamic> slot) {
    final startTime = slot['startTime'] as String;
    final endTime = slot['endTime'] as String;
    final timeDisplay = '$startTime - $endTime';
    final slotId = slot['slotId'] as String;
    final isSelected = selectedTimeSlot == slotId;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTimeSlot = isSelected ? null : slotId;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF006A5B) : const Color(0xFF67AFA5),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          timeDisplay,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }

  String _getSelectedSlotTime() {
    final slot = availableSlots.firstWhere(
      (slot) => slot['slotId'] == selectedTimeSlot,
      orElse: () => {},
    );
    if (slot.isNotEmpty) {
      return '${slot['startTime']} - ${slot['endTime']}';
    }
    return '';
  }

  void _navigateToBookingForm() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ParentBookingProcessPage(
          selectedDate: selectedDate,
          selectedTimeSlot: selectedTimeSlot!,
          selectedTime: _getSelectedSlotTime(),
          clinicId: widget.clinicId,
          therapistId: widget.therapistId,
          bookingProcessType:
              bookingProcessType, // Pass the booking process type
        ),
      ),
    ).then((_) {
      // Refresh available slots when returning from booking form
      _loadAvailableSlotsForDate(selectedDate);
      // Clear selection
      setState(() {
        selectedTimeSlot = null;
      });
    });
  }
}
