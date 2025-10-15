import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/schedule_database_service.dart';

class TherapistEditSchedulePage extends StatefulWidget {
  const TherapistEditSchedulePage({Key? key}) : super(key: key);

  @override
  State<TherapistEditSchedulePage> createState() =>
      _TherapistEditSchedulePageState();
}

class _TherapistEditSchedulePageState extends State<TherapistEditSchedulePage> {
  final Map<String, Map<String, dynamic>> weeklySchedule = {
    'Monday': {'startTime': '08:00', 'endTime': '17:00', 'isActive': true},
    'Tuesday': {'startTime': '08:00', 'endTime': '17:00', 'isActive': true},
    'Wednesday': {'startTime': '08:00', 'endTime': '17:00', 'isActive': true},
    'Thursday': {'startTime': '08:00', 'endTime': '17:00', 'isActive': true},
    'Friday': {'startTime': '08:00', 'endTime': '17:00', 'isActive': true},
    'Saturday': {'startTime': '09:00', 'endTime': '15:00', 'isActive': false},
    'Sunday': {'startTime': '09:00', 'endTime': '15:00', 'isActive': false},
  };

  String? _therapistId;
  bool _isLoading = false;
  bool _isLoadingSchedule = true;
  String _bookingProcessType = 'single'; // 'single' or 'contract'

  @override
  void initState() {
    super.initState();
    _loadTherapistId();
  }

  Future<void> _loadTherapistId() async {
    final prefs = await SharedPreferences.getInstance();
    final therapistId = prefs.getString('therapist_id') ??
        prefs.getString('user_id') ??
        prefs.getString('clinic_id');

    setState(() {
      _therapistId = therapistId;
    });

    // Load existing schedule if available
    if (therapistId != null) {
      await _loadExistingSchedule(therapistId);
    }
  }

  Future<void> _loadExistingSchedule(String therapistId) async {
    try {
      final existingSchedule =
          await ScheduleDatabaseService.loadSchedule(therapistId);

      if (existingSchedule != null &&
          existingSchedule['weeklySchedule'] != null) {
        final weekly =
            existingSchedule['weeklySchedule'] as Map<String, dynamic>;

        setState(() {
          // Convert Firebase format back to UI format
          weeklySchedule.forEach((day, _) {
            final dayKey = day.toLowerCase();
            if (weekly.containsKey(dayKey)) {
              final dayData = weekly[dayKey] as Map<String, dynamic>;
              weeklySchedule[day] = {
                'startTime': dayData['startTime'] ?? '08:00',
                'endTime': dayData['endTime'] ?? '17:00',
                'isActive': dayData['isWorkingDay'] ?? true,
              };
            }
          });

          // Load booking process type from recurringSettings
          final recurringSettings =
              existingSchedule['recurringSettings'] as Map<String, dynamic>?;
          if (recurringSettings != null &&
              recurringSettings['bookingProcessType'] != null) {
            _bookingProcessType =
                recurringSettings['bookingProcessType'] as String;
          }

          _isLoadingSchedule = false;
        });

        print('Loaded existing schedule for therapist: $therapistId');
        print('Booking process type: $_bookingProcessType');
      } else {
        setState(() {
          _isLoadingSchedule = false;
        });
        print('No existing schedule found, using defaults');
      }
    } catch (e) {
      setState(() {
        _isLoadingSchedule = false;
      });
      print('Error loading existing schedule: $e');
      // Continue with default schedule if loading fails
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF006A5B),
        elevation: 0,
        title: const Text(
          'Edit My Schedule',
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
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveSchedule,
              child: const Text(
                'Save',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
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
              constraints: BoxConstraints.expand(height: size.height * 0.30),
              child: Container(
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
                    colors: [
                      Color(0xFF67AFA5),
                      Colors.white,
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Main content
          _isLoadingSchedule
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: Color(0xFF006A5B),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Loading your schedule...',
                          style: TextStyle(
                            color: Color(0xFF006A5B),
                            fontSize: 16,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

                      // Header text
                      const Center(
                        child: Text(
                          'Manage Your Availability',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Poppins',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Center(
                        child: Text(
                          'Set your working hours and booking preferences',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                            fontFamily: 'Poppins',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Booking Type Selection
                      _buildBookingProcessCard(),

                      const SizedBox(height: 20),

                      // Weekly Schedule
                      ...weeklySchedule.entries.map(
                        (entry) =>
                            _buildDayScheduleCard(entry.key, entry.value),
                      ),

                      const SizedBox(
                          height:
                              100), // Extra space for floating action button
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildDayScheduleCard(String day, Map<String, dynamic> schedule) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                Switch(
                  value: schedule['isActive'],
                  onChanged: (value) {
                    setState(() {
                      weeklySchedule[day]!['isActive'] = value;
                    });
                  },
                  activeColor: const Color(0xFF006A5B),
                ),
              ],
            ),
            if (schedule['isActive']) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTimeSelector(
                      'Start Time',
                      schedule['startTime'],
                      (time) {
                        setState(() {
                          weeklySchedule[day]!['startTime'] = time;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTimeSelector(
                      'End Time',
                      schedule['endTime'],
                      (time) {
                        setState(() {
                          weeklySchedule[day]!['endTime'] = time;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector(
      String label, String currentTime, Function(String) onTimeChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF67AFA5),
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _selectTime(currentTime, onTimeChanged),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF67AFA5)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  currentTime,
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'Poppins',
                  ),
                ),
                const Icon(
                  Icons.access_time,
                  color: Color(0xFF67AFA5),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectTime(
      String currentTime, Function(String) onTimeChanged) async {
    final List<String> timeParts = currentTime.split(':');
    final TimeOfDay initialTime = TimeOfDay(
      hour: int.parse(timeParts[0]),
      minute: int.parse(timeParts[1]),
    );

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      final String formattedTime =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      onTimeChanged(formattedTime);
    }
  }

  void _saveSchedule() async {
    if (_therapistId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to identify therapist. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('Saving schedule for therapist: $_therapistId');
      print('Weekly schedule data: $weeklySchedule');

      // Use the ScheduleDatabaseService
      await ScheduleDatabaseService.saveSchedule(
        therapistId: _therapistId!,
        weeklySchedule: _convertToFirebaseFormat(),
        constraints: {
          'maxPatientsPerDay': 8,
          'maxPatientsPerSlot': 1,
          'slotDurationMinutes': 60,
          'bufferTimeMinutes': 15,
          'advanceBookingDays': 30,
          'cancellationHours': 24,
          'rescheduleHours': 48,
          'sameDayBooking': false,
          'weekendBooking': false,
        },
        exceptions: [],
        recurringSettings: {
          'allowRecurring': _bookingProcessType == 'contract',
          'maxRecurringWeeks': _bookingProcessType == 'contract' ? 52 : 1,
          'defaultRecurrenceType':
              _bookingProcessType == 'contract' ? 'weekly' : 'none',
          'maxRecurringAppointments':
              _bookingProcessType == 'contract' ? 50 : 1,
          'requireContractApproval': _bookingProcessType == 'contract',
          'bookingProcessType': _bookingProcessType,
          'contractDescription': _bookingProcessType == 'contract'
              ? 'When you book a time slot, it becomes your regular weekly appointment until you choose to end it.'
              : 'Book individual therapy sessions as needed.',
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Schedule saved successfully! Booking type: ${_bookingProcessType == 'contract' ? 'Contract Design' : 'Single Session'}. Patients can now book appointments.'),
            backgroundColor: const Color(0xFF006A5B),
            duration: const Duration(seconds: 4),
          ),
        );
        Navigator.pop(
            context, true); // Return true to indicate changes were saved
      }
    } catch (e) {
      print('Error saving schedule: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save schedule: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Map<String, dynamic> _convertToFirebaseFormat() {
    Map<String, dynamic> firebaseSchedule = {};

    weeklySchedule.forEach((day, schedule) {
      String dayKey = day.toLowerCase();
      firebaseSchedule[dayKey] = {
        'isWorkingDay': schedule['isActive'],
        'startTime': schedule['startTime'],
        'endTime': schedule['endTime'],
        'breakTimes': [
          {
            'startTime': '12:00',
            'endTime': '13:00',
            'breakType': 'lunch',
          }
        ],
        'timeSlots': schedule['isActive']
            ? _generateTimeSlots(
                schedule['startTime'],
                schedule['endTime'],
              )
            : [],
      };
    });

    return firebaseSchedule;
  }

  List<Map<String, dynamic>> _generateTimeSlots(
      String startTime, String endTime) {
    List<Map<String, dynamic>> slots = [];

    final startHour = int.parse(startTime.split(':')[0]);
    final endHour = int.parse(endTime.split(':')[0]);

    for (int hour = startHour; hour < endHour; hour++) {
      // Skip lunch hour (12:00-13:00)
      if (hour == 12) continue;

      slots.add({
        'slotId': 'slot_${hour}_00',
        'startTime': '${hour.toString().padLeft(2, '0')}:00',
        'endTime': '${(hour + 1).toString().padLeft(2, '0')}:00',
        'isAvailable': true,
        'isBooked': false,
        'patientId': null,
        'patientName': null,
        'appointmentType': 'therapy',
        'notes': '',
        'bookedAt': null,
        'cancelledAt': null,
      });
    }

    return slots;
  }

  Widget _buildBookingProcessCard() {
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
            const Text(
              'Select Booking Type',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF006A5B),
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Choose how patients can book appointments with you:',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF67AFA5),
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 20),

            // Single Session Button
            _buildBookingTypeButton(
              type: 'single',
              title: 'Single Session Booking',
              description:
                  'Patients book individual sessions.\nEach appointment is separate.',
              icon: Icons.event_note,
              isSelected: _bookingProcessType == 'single',
            ),

            const SizedBox(height: 16),

            // Contract Design Button
            _buildBookingTypeButton(
              type: 'contract',
              title: 'Contract Design (Weekly)',
              description:
                  'Patients book recurring weekly slots.\nOngoing therapy commitment.',
              icon: Icons.repeat,
              isSelected: _bookingProcessType == 'contract',
            ),

            const SizedBox(height: 16),

            // Information box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF006A5B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF006A5B).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Color(0xFF006A5B),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _bookingProcessType == 'contract'
                          ? 'Contract booking allows patients to secure regular weekly slots for ongoing therapy.'
                          : 'Single session booking allows patients to book individual appointments as needed.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF006A5B),
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingTypeButton({
    required String type,
    required String title,
    required String description,
    required IconData icon,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _bookingProcessType = type;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF006A5B).withOpacity(0.1)
              : Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF006A5B)
                : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF006A5B)
                    : Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[600],
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? const Color(0xFF006A5B)
                          : Colors.grey[700],
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected
                          ? const Color(0xFF67AFA5)
                          : Colors.grey[600],
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF006A5B),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
