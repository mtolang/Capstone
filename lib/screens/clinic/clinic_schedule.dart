import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/schedule_database_service.dart';
import '../../models/time_slot.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ClinicSchedulePage extends StatefulWidget {
  const ClinicSchedulePage({Key? key}) : super(key: key);

  @override
  State<ClinicSchedulePage> createState() => _ClinicSchedulePageState();
}

class _ClinicSchedulePageState extends State<ClinicSchedulePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, List<TimeSlot>> weeklySchedule = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadScheduleData();
  }

  Future<void> _loadScheduleData() async {
    try {
      // Get current therapist ID
      final prefs = await SharedPreferences.getInstance();
      final therapistId =
          prefs.getString('clinic_id') ?? prefs.getString('user_id');

      if (therapistId == null) {
        throw Exception('No therapist ID found');
      }

      // Load schedule from new service
      final scheduleData =
          await ScheduleDatabaseService.loadSchedule(therapistId);

      if (scheduleData != null && scheduleData['weeklySchedule'] != null) {
        final weeklyScheduleData =
            scheduleData['weeklySchedule'] as Map<String, dynamic>;
        final convertedSchedule = _convertFromFirestore(weeklyScheduleData);

        setState(() {
          weeklySchedule = convertedSchedule;
          _isLoading = false;
        });
      } else {
        // Set default schedule if none exists
        setState(() {
          weeklySchedule = _getDefaultSchedule();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading schedule: $e');
      setState(() {
        weeklySchedule = _getDefaultSchedule();
        _isLoading = false;
      });
      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load schedule: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveSchedule() async {
    try {
      // Get current therapist ID
      final prefs = await SharedPreferences.getInstance();
      final therapistId =
          prefs.getString('clinic_id') ?? prefs.getString('user_id');

      if (therapistId == null) {
        throw Exception('No therapist ID found');
      }

      // Convert schedule back to Firebase format
      final firebaseSchedule = _convertToFirestore(weeklySchedule);

      await ScheduleDatabaseService.saveSchedule(
        therapistId: therapistId,
        weeklySchedule: firebaseSchedule,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Schedule saved successfully!'),
            backgroundColor: Color(0xFF006A5B),
          ),
        );
      }
    } catch (e) {
      print('Error saving schedule: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save schedule: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final today = DateFormat('MMMM dd, yyyy').format(DateTime.now());

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF006A5B),
          elevation: 0,
          title: const Text(
            'Therapist Schedule',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Poppins',
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF006A5B),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF006A5B),
        elevation: 0,
        title: const Text(
          'Therapist Schedule',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Poppins',
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Colors.white),
            onPressed: _saveSchedule,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Top wave background
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ConstrainedBox(
              constraints: BoxConstraints.expand(height: size.height * 0.3),
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
                    return Container();
                  },
                ),
              ),
            ),
          ),
          // Bottom wave background
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
                    return Container();
                  },
                ),
              ),
            ),
          ),
          // Main content
          Column(
            children: [
              // Date header with top margin and edit button
              Container(
                margin: const EdgeInsets.only(top: 40, left: 16, right: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      today,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/cliniceditschedule');
                      },
                      icon: const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),

              // Tab bar section
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
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
                    borderRadius: BorderRadius.circular(30),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: const Color(0xFF006A5B),
                  labelStyle: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: const [
                    Tab(text: 'Weekly'),
                    Tab(text: 'Availability'),
                    Tab(text: 'Patients'),
                  ],
                ),
              ),

              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildWeeklyTab(),
                    _buildAvailabilityTab(),
                    _buildPatientsTab(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF006A5B),
        child: const Icon(Icons.schedule, color: Colors.white),
        onPressed: () {
          Navigator.pushNamed(context, '/cliniceditschedule');
        },
      ),
    );
  }

  Widget _buildWeeklyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weekly Schedule Overview',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF006A5B),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 20),
          ...weeklySchedule.entries.map((entry) {
            final day = entry.key;
            final slots = entry.value;
            final availableCount =
                slots.where((slot) => slot.isAvailable).length;
            final totalCount = slots.length;

            return _buildDayOverviewCard(day, availableCount, totalCount,
                slots.first.time, slots.last.time);
          }).toList(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildAvailabilityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Time Slot Availability',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF006A5B),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 20),
          ...weeklySchedule.entries.map((entry) {
            final day = entry.key;
            final slots = entry.value;
            return _buildDayAvailabilityCard(day, slots);
          }).toList(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildPatientsTab() {
    // Get all booked patients
    final bookedPatients = <String, List<String>>{};

    weeklySchedule.forEach((day, slots) {
      slots.where((slot) => !slot.isAvailable).forEach((slot) {
        if (!bookedPatients.containsKey(slot.patientName)) {
          bookedPatients[slot.patientName] = [];
        }
        bookedPatients[slot.patientName]!.add('$day ${slot.time}');
      });
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Patient Schedule',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF006A5B),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 20),
          ...bookedPatients.entries.map((entry) {
            return _buildPatientCard(entry.key, entry.value);
          }).toList(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildDayOverviewCard(
      String day, int available, int total, String startTime, String endTime) {
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
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF006A5B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  day.substring(0, 3).toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF006A5B),
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
                    day,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  Text(
                    '$startTime - $endTime',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: available > 0 ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$available/$total available',
                        style: TextStyle(
                          color: available > 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayAvailabilityCard(String day, List<TimeSlot> slots) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
            Text(
              day,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF006A5B),
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: slots.map((slot) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: slot.isAvailable
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: slot.isAvailable ? Colors.green : Colors.red,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    slot.time,
                    style: TextStyle(
                      color: slot.isAvailable ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                      fontFamily: 'Poppins',
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientCard(String patientName, List<String> schedules) {
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
            CircleAvatar(
              backgroundColor: const Color(0xFF006A5B),
              radius: 25,
              child: Text(
                patientName.isNotEmpty ? patientName[0].toUpperCase() : 'P',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
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
                      fontFamily: 'Poppins',
                    ),
                  ),
                  Text(
                    '${schedules.length} appointment${schedules.length > 1 ? 's' : ''}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () =>
                  _showPatientScheduleDialog(patientName, schedules),
              icon: const Icon(
                Icons.info_outline,
                color: Color(0xFF006A5B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPatientScheduleDialog(String patientName, List<String> schedules) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '$patientName\'s Schedule',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: schedules
              .map((schedule) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.schedule,
                          size: 16,
                          color: Color(0xFF006A5B),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          schedule,
                          style: const TextStyle(fontFamily: 'Poppins'),
                        ),
                      ],
                    ),
                  ))
              .toList(),
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
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/cliniceditschedule');
            },
            child: const Text(
              'Edit',
              style: TextStyle(
                color: Color(0xFF006A5B),
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to convert Firestore data to local schedule format
  Map<String, List<TimeSlot>> _convertFromFirestore(
      Map<String, dynamic> weeklyScheduleData) {
    Map<String, List<TimeSlot>> schedule = {};

    final days = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday'
    ];

    for (String day in days) {
      final dayData = weeklyScheduleData[day] as Map<String, dynamic>?;
      if (dayData != null && dayData['isWorkingDay'] == true) {
        final timeSlots = dayData['timeSlots'] as List<dynamic>? ?? [];
        schedule[_capitalizeFirst(day)] = timeSlots
            .map((slot) => TimeSlot.fromFirestore(slot as Map<String, dynamic>))
            .toList();
      } else {
        schedule[_capitalizeFirst(day)] = [];
      }
    }

    return schedule;
  }

  // Helper method to convert local schedule format to Firestore
  Map<String, dynamic> _convertToFirestore(
      Map<String, List<TimeSlot>> weeklySchedule) {
    Map<String, dynamic> firebaseSchedule = {};

    weeklySchedule.forEach((day, slots) {
      String dayKey = day.toLowerCase();
      firebaseSchedule[dayKey] = {
        'isWorkingDay': slots.isNotEmpty,
        'startTime': slots.isNotEmpty ? slots.first.startTime : '08:00',
        'endTime': slots.isNotEmpty ? slots.last.endTime : '17:00',
        'breakTimes': [
          {
            'startTime': '12:00',
            'endTime': '13:00',
            'breakType': 'lunch',
          }
        ],
        'timeSlots': slots.map((slot) => slot.toFirestore()).toList(),
      };
    });

    return firebaseSchedule;
  }

  // Helper method to capitalize first letter
  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  // Get default schedule structure
  Map<String, List<TimeSlot>> _getDefaultSchedule() {
    return {
      'Monday': _generateDefaultTimeSlots(),
      'Tuesday': _generateDefaultTimeSlots(),
      'Wednesday': _generateDefaultTimeSlots(),
      'Thursday': _generateDefaultTimeSlots(),
      'Friday': _generateDefaultTimeSlots(),
      'Saturday': [],
      'Sunday': [],
    };
  }

  // Generate default time slots for working days
  List<TimeSlot> _generateDefaultTimeSlots() {
    return [
      TimeSlot(
          slotId: 'slot_8',
          time: '8:00 - 9:00 AM',
          startTime: '08:00',
          endTime: '09:00',
          isAvailable: true,
          isBooked: false,
          patientName: '',
          appointmentType: 'therapy',
          notes: ''),
      TimeSlot(
          slotId: 'slot_9',
          time: '9:00 - 10:00 AM',
          startTime: '09:00',
          endTime: '10:00',
          isAvailable: true,
          isBooked: false,
          patientName: '',
          appointmentType: 'therapy',
          notes: ''),
      TimeSlot(
          slotId: 'slot_10',
          time: '10:00 - 11:00 AM',
          startTime: '10:00',
          endTime: '11:00',
          isAvailable: true,
          isBooked: false,
          patientName: '',
          appointmentType: 'therapy',
          notes: ''),
      TimeSlot(
          slotId: 'slot_11',
          time: '11:00 - 12:00 PM',
          startTime: '11:00',
          endTime: '12:00',
          isAvailable: true,
          isBooked: false,
          patientName: '',
          appointmentType: 'therapy',
          notes: ''),
      // 12:00 - 1:00 PM is lunch break
      TimeSlot(
          slotId: 'slot_13',
          time: '1:00 - 2:00 PM',
          startTime: '13:00',
          endTime: '14:00',
          isAvailable: true,
          isBooked: false,
          patientName: '',
          appointmentType: 'therapy',
          notes: ''),
      TimeSlot(
          slotId: 'slot_14',
          time: '2:00 - 3:00 PM',
          startTime: '14:00',
          endTime: '15:00',
          isAvailable: true,
          isBooked: false,
          patientName: '',
          appointmentType: 'therapy',
          notes: ''),
      TimeSlot(
          slotId: 'slot_15',
          time: '3:00 - 4:00 PM',
          startTime: '15:00',
          endTime: '16:00',
          isAvailable: true,
          isBooked: false,
          patientName: '',
          appointmentType: 'therapy',
          notes: ''),
      TimeSlot(
          slotId: 'slot_16',
          time: '4:00 - 5:00 PM',
          startTime: '16:00',
          endTime: '17:00',
          isAvailable: true,
          isBooked: false,
          patientName: '',
          appointmentType: 'therapy',
          notes: ''),
    ];
  }
}
