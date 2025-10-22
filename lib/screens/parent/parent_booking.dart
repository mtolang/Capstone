import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kindora/services/schedule_database_service.dart';
import 'package:kindora/screens/parent/parent_booking_process.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  Set<String> bookedSlotIds = {}; // Track booked slot IDs for selected date

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

      if (widget.therapistId != null) {
        // Load therapist schedule from schedules collection
        await _loadTherapistSchedule(widget.therapistId!);
      } else if (widget.clinicId != null) {
        // Load clinic schedule using existing method
        await _loadClinicScheduleData(widget.clinicId!);
      } else {
        print('❌ No therapist ID or clinic ID provided');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading schedule: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Load therapist schedule from schedules collection
  Future<void> _loadTherapistSchedule(String therapistId) async {
    try {
      print('🔍 Loading therapist schedule for: $therapistId');
      
      // Query schedules collection where ther_id matches therapistId
      final querySnapshot = await FirebaseFirestore.instance
          .collection('schedules')
          .where('ther_id', isEqualTo: therapistId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final scheduleDoc = querySnapshot.docs.first;
        final scheduleData = scheduleDoc.data();
        
        print('✅ Found therapist schedule: ${scheduleData.keys}');
        
        // Convert therapist schedule format to match booking page expectations
        final convertedSchedule = _convertTherapistScheduleFormat(scheduleData);
        
        setState(() {
          clinicSchedule = convertedSchedule;
          bookingProcessType = 'single'; // Default for therapists
          isLoading = false;
        });
        
        _loadAvailableSlotsForDate(selectedDate);
      } else {
        print('❌ No schedule found for therapist: $therapistId');
        setState(() {
          isLoading = false;
        });
        
        // Show error message to user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No schedule found for therapist $therapistId'),
              backgroundColor: Colors.orange,
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () => _loadTherapistSchedule(therapistId),
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error loading therapist schedule: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Load clinic schedule using existing method
  Future<void> _loadClinicScheduleData(String clinicId) async {
    try {
      print('🔍 Loading clinic schedule for: $clinicId');
      
      final schedule = await ScheduleDatabaseService.loadSchedule(clinicId);

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
        
        // Show error message to user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No schedule found for clinic $clinicId'),
              backgroundColor: Colors.orange,
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () => _loadClinicScheduleData(clinicId),
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error loading clinic schedule: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Convert therapist schedule format to match booking page expectations
  Map<String, dynamic> _convertTherapistScheduleFormat(Map<String, dynamic> therapistSchedule) {
    final selectedDays = therapistSchedule['selectedDays'] as Map<String, dynamic>? ?? {};
    final slotDurationMinutes = therapistSchedule['slotDurationMinutes'] as int? ?? 60;
    
    // Convert selectedDays to weeklySchedule format
    Map<String, dynamic> weeklySchedule = {};
    
    selectedDays.forEach((dayKey, isSelected) {
      if (isSelected == true) {
        // Generate time slots for available days
        weeklySchedule[dayKey.toLowerCase()] = {
          'isAvailable': true,
          'timeSlots': _generateTimeSlots(slotDurationMinutes),
        };
      }
    });
    
    return {
      'therapistId': therapistSchedule['ther_id'],
      'slotDurationMinutes': slotDurationMinutes,
      'weekendBooking': therapistSchedule['weekendBooking'] ?? false,
      'weeklySchedule': weeklySchedule,
      'recurringSettings': {
        'bookingProcessType': 'single', // Default for therapists
      },
    };
  }

  // Generate time slots for therapist schedule
  List<Map<String, dynamic>> _generateTimeSlots(int durationMinutes) {
    List<Map<String, dynamic>> slots = [];
    
    // Generate slots from 8:00 AM to 6:00 PM
    for (int hour = 8; hour < 18; hour++) {
      final startTime = '${hour.toString().padLeft(2, '0')}:00';
      final endHour = hour + (durationMinutes ~/ 60);
      final endMinutes = durationMinutes % 60;
      final endTime = '${endHour.toString().padLeft(2, '0')}:${endMinutes.toString().padLeft(2, '0')}';
      
      slots.add({
        'slotId': 'slot_${hour}_00',
        'startTime': startTime,
        'endTime': endTime,
        'isAvailable': true,
        'isBooked': false,
        'maxPatients': 1,
        'currentPatients': 0,
      });
    }
    
    return slots;
  }

  void _loadAvailableSlotsForDate(DateTime date) async {
    if (clinicSchedule == null) {
      print('❌ No clinic schedule available');
      return;
    }

    final dayName = _getDayName(date);
    print('🔍 Loading slots for $dayName (${DateFormat('MMM dd, yyyy').format(date)})');
    
    final weeklySchedule =
        clinicSchedule!['weeklySchedule'] as Map<String, dynamic>?;

    if (weeklySchedule != null && weeklySchedule.containsKey(dayName)) {
      final daySchedule = weeklySchedule[dayName] as Map<String, dynamic>;
      final timeSlots =
          List<Map<String, dynamic>>.from(daySchedule['timeSlots'] ?? []);

      print('📅 Found ${timeSlots.length} time slots for $dayName');

      // Load booked slots for this date
      await _loadBookedSlotsForDate(date);

      final availableSlotsList = timeSlots
          .where((slot) =>
              slot['isAvailable'] == true && 
              slot['isBooked'] != true &&
              !bookedSlotIds.contains(slot['startTime'] ?? slot['slotId']))
          .toList();

      setState(() {
        availableSlots = availableSlotsList;
      });

      print('✅ ${availableSlots.length} available slots after filtering');
    } else {
      print('❌ No schedule found for $dayName');
      setState(() {
        availableSlots = [];
      });
    }
  }

  // Check AcceptedBooking database for booked slots on this date
  Future<void> _loadBookedSlotsForDate(DateTime date) async {
    try {
      final Set<String> booked = {};

      // Get day of week for contract checking
      final dayOfWeek = DateFormat('EEEE').format(date); // e.g., "Monday"

      // Query AcceptedBooking collection based on whether it's clinic or therapist
      QuerySnapshot snapshot;

      if (widget.therapistId != null) {
        // For therapists, query using serviceProvider.therapistId
        snapshot = await FirebaseFirestore.instance
            .collection('AcceptedBooking')
            .where('serviceProvider.therapistId', isEqualTo: widget.therapistId)
            .where('status', isEqualTo: 'confirmed')
            .get();
      } else if (widget.clinicId != null) {
        // For clinics, query using clinicId
        snapshot = await FirebaseFirestore.instance
            .collection('AcceptedBooking')
            .where('clinicId', isEqualTo: widget.clinicId)
            .where('status', isEqualTo: 'confirmed')
            .get();
      } else {
        return;
      }

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) continue;

        final originalRequestData =
            data['originalRequestData'] as Map<String, dynamic>?;
        final bookingProcessType = originalRequestData?['bookingProcessType'];

        if (bookingProcessType == 'contract') {
          // CONTRACT BOOKING - Check if it applies to this day of week
          final contractInfo =
              originalRequestData?['contractInfo'] as Map<String, dynamic>?;
          final contractDayOfWeek = contractInfo?['dayOfWeek'];
          final contractTime = contractInfo?['appointmentTime'];

          if (contractDayOfWeek == dayOfWeek && contractTime != null) {
            // This contract blocks this time slot every week
            booked.add(contractTime);
            print('🔶 Contract blocks $dayOfWeek at $contractTime');
          }
        } else {
          // REGULAR BOOKING - Check if it's on this specific date
          final appointmentDate =
              (data['appointmentDate'] as Timestamp?)?.toDate();
          if (appointmentDate != null &&
              appointmentDate.year == date.year &&
              appointmentDate.month == date.month &&
              appointmentDate.day == date.day) {
            final time = data['appointmentTime'];
            if (time != null) {
              booked.add(time);
              print(
                  '📅 Regular booking blocks ${DateFormat('MMM dd').format(date)} at $time');
            }
          }
        }
      }

      setState(() {
        bookedSlotIds = booked;
      });

      print(
          '✅ Found ${booked.length} booked slots for ${DateFormat('MMM dd, yyyy').format(date)}');
    } catch (e) {
      print('❌ Error loading booked slots: $e');
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
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            widget.therapistId != null 
                                ? 'Therapist Booking' 
                                : 'Clinic Booking',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (widget.therapistId != null || widget.clinicId != null)
                            Text(
                              'ID: ${widget.therapistId ?? widget.clinicId}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontFamily: 'Poppins',
                              ),
                              textAlign: TextAlign.center,
                            ),
                        ],
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
                            // Booking Information Section
                            _buildBookingInfoSection(),

                            const SizedBox(height: 20),

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
    final daysInMonth = lastDayOfMonth.day;

    List<Widget> calendarDays = [];

    // Empty cells for days before month starts
    for (int i = 0; i < firstWeekday; i++) {
      calendarDays.add(const SizedBox(width: 30, height: 30));
    }

    // Days of the month
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(currentMonth.year, currentMonth.month, day);
      final isSelected = selectedDate.year == date.year &&
          selectedDate.month == date.month &&
          selectedDate.day == date.day;
      final isToday = DateTime.now().year == date.year &&
          DateTime.now().month == date.month &&
          DateTime.now().day == date.day;
      final isPast =
          date.isBefore(DateTime.now().subtract(const Duration(days: 1)));

      calendarDays.add(
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

    // Build rows with exactly 7 days each
    return Column(
      children: [
        for (int week = 0; week < 6; week++)
          if (week * 7 < calendarDays.length)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
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
        weekDays.add(const SizedBox(width: 30, height: 30));
      }
    }

    return weekDays;
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

    // Check if this time slot is booked
    final isBooked = bookedSlotIds.contains(timeDisplay);

    return GestureDetector(
      onTap: isBooked
          ? null
          : () {
              setState(() {
                selectedTimeSlot = isSelected ? null : slotId;
              });
            },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isBooked
              ? Colors.grey.shade300
              : isSelected
                  ? const Color(0xFF004D40) // Darker green when selected
                  : const Color(0xFF00897B), // Much greener color
          borderRadius: BorderRadius.circular(20),
          boxShadow: isBooked
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isBooked)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(
                  Icons.lock,
                  size: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            Text(
              timeDisplay,
              style: TextStyle(
                color: isBooked ? Colors.grey.shade600 : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
                decoration: isBooked ? TextDecoration.lineThrough : null,
              ),
            ),
          ],
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

  Widget _buildBookingInfoSection() {
    if (clinicSchedule == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange[300]!),
        ),
        child: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange[700], size: 20),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'No schedule available for this provider.',
                style: TextStyle(
                  color: Colors.black87,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Get available days from schedule
    final weeklySchedule = clinicSchedule!['weeklySchedule'] as Map<String, dynamic>? ?? {};
    final availableDays = weeklySchedule.keys.where((day) {
      final daySchedule = weeklySchedule[day] as Map<String, dynamic>?;
      return daySchedule != null && daySchedule['isAvailable'] == true;
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF006A5B).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF006A5B).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                widget.therapistId != null ? Icons.person : Icons.business,
                color: const Color(0xFF006A5B),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                widget.therapistId != null 
                    ? 'Therapist Booking' 
                    : 'Clinic Booking',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF006A5B),
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (clinicSchedule!['slotDurationMinutes'] != null)
            Text(
              'Session Duration: ${clinicSchedule!['slotDurationMinutes']} minutes',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontFamily: 'Poppins',
              ),
            ),
          if (availableDays.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Available Days: ${availableDays.map((day) => _capitalizeFirst(day)).join(', ')}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontFamily: 'Poppins',
              ),
            ),
          ],
          if (bookingProcessType != 'single') ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Booking Type: ${_capitalizeFirst(bookingProcessType)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue[800],
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
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
