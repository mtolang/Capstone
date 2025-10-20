import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TherapistSetupSchedulePage extends StatefulWidget {
  const TherapistSetupSchedulePage({Key? key}) : super(key: key);

  @override
  State<TherapistSetupSchedulePage> createState() =>
      _TherapistSetupSchedulePageState();
}

class _TherapistSetupSchedulePageState
    extends State<TherapistSetupSchedulePage> {
  String? _therapistId;
  bool _isLoading = true;
  bool _isSaving = false;

  // Days of the week
  final List<String> _daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  // Selected days
  Map<String, bool> _selectedDays = {
    'Monday': false,
    'Tuesday': false,
    'Wednesday': false,
    'Thursday': false,
    'Friday': false,
    'Saturday': false,
    'Sunday': false,
  };

  // Time slots for each day
  Map<String, List<TimeSlot>> _dayTimeSlots = {
    'Monday': [],
    'Tuesday': [],
    'Wednesday': [],
    'Thursday': [],
    'Friday': [],
    'Saturday': [],
    'Sunday': [],
  };

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _getTherapistId();
    await _loadExistingSchedule();
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

  Future<void> _loadExistingSchedule() async {
    if (_therapistId == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('schedules')
          .doc(_therapistId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;

        setState(() {
          // Load selected days
          if (data['selectedDays'] != null) {
            final savedDays = data['selectedDays'] as Map<String, dynamic>;
            savedDays.forEach((day, isSelected) {
              _selectedDays[day] = isSelected as bool;
            });
          }

          // Load time slots
          if (data['timeSlots'] != null) {
            final savedSlots = data['timeSlots'] as Map<String, dynamic>;
            savedSlots.forEach((day, slots) {
              final slotList = (slots as List)
                  .map((slot) => TimeSlot(
                        startTime: TimeOfDay(
                          hour: slot['startHour'],
                          minute: slot['startMinute'],
                        ),
                        endTime: TimeOfDay(
                          hour: slot['endHour'],
                          minute: slot['endMinute'],
                        ),
                      ))
                  .toList();
              _dayTimeSlots[day] = slotList;
            });
          }
        });
      }
    } catch (e) {
      print('Error loading existing schedule: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Top ellipse background
          Positioned(
            top: -100,
            left: -50,
            right: -50,
            child: Container(
              height: mq.height * 0.6,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF006A5B),
                    Color(0xFF67AFA5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
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
              height: mq.height * 0.5,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF67AFA5),
                    Color(0xFF006A5B),
                  ],
                  begin: Alignment.bottomRight,
                  end: Alignment.topLeft,
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
                // Custom AppBar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const Expanded(
                        child: Text(
                          'Setup Availability',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48), // Balance the back button
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Main content
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Instructions card
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          color: const Color(0xFF006A5B),
                                          size: 24,
                                        ),
                                        const SizedBox(width: 12),
                                        const Text(
                                          'Setup Your Availability',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF006A5B),
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Select the days you are available and add time slots for each day. Clients will be able to book appointments during these times.',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 30),

                              // Days selection
                              const Text(
                                'Select Available Days',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Days list
                              ..._daysOfWeek.map((day) => _buildDayCard(day)),

                              const SizedBox(height: 30),

                              // Save button
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _isSaving ? null : _saveSchedule,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF006A5B),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 4,
                                  ),
                                  child: _isSaving
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.save, size: 24),
                                            SizedBox(width: 12),
                                            Text(
                                              'Save Schedule',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'Poppins',
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),

                              const SizedBox(height: 40),
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

  Widget _buildDayCard(String day) {
    final isSelected = _selectedDays[day] ?? false;
    final timeSlots = _dayTimeSlots[day] ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? const Color(0xFF006A5B) : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
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
          // Day header
          InkWell(
            onTap: () {
              setState(() {
                _selectedDays[day] = !isSelected;
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Checkbox
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF006A5B)
                          : Colors.transparent,
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF006A5B)
                            : Colors.grey[400]!,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 16,
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),

                  // Day name
                  Expanded(
                    child: Text(
                      day,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected
                            ? const Color(0xFF006A5B)
                            : Colors.black87,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),

                  // Time slot count
                  if (isSelected && timeSlots.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF006A5B).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${timeSlots.length} slot${timeSlots.length > 1 ? 's' : ''}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF006A5B),
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),

                  const SizedBox(width: 8),

                  // Expand icon
                  if (isSelected)
                    Icon(
                      Icons.expand_more,
                      color: Colors.grey[600],
                    ),
                ],
              ),
            ),
          ),

          // Time slots section (shown when day is selected)
          if (isSelected) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Time Slots',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF006A5B),
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Time slot list
                  if (timeSlots.isNotEmpty)
                    ...timeSlots.asMap().entries.map((entry) {
                      final index = entry.key;
                      final slot = entry.value;
                      return _buildTimeSlotItem(day, index, slot);
                    }),

                  // Add time slot button
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => _addTimeSlot(day),
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('Add Time Slot'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF006A5B),
                      side: const BorderSide(color: Color(0xFF006A5B)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeSlotItem(String day, int index, TimeSlot slot) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF006A5B).withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF006A5B).withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.access_time,
            color: Color(0xFF006A5B),
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            '${_formatTime(slot.startTime)} - ${_formatTime(slot.endTime)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF006A5B),
              fontFamily: 'Poppins',
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => _editTimeSlot(day, index, slot),
            icon: const Icon(Icons.edit, size: 18),
            color: const Color(0xFF006A5B),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _removeTimeSlot(day, index),
            icon: const Icon(Icons.delete, size: 18),
            color: Colors.red,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _addTimeSlot(String day) async {
    final result = await _showTimeSlotDialog(day, null, null);
    if (result != null) {
      setState(() {
        _dayTimeSlots[day]?.add(result);
      });
    }
  }

  Future<void> _editTimeSlot(
      String day, int index, TimeSlot currentSlot) async {
    final result = await _showTimeSlotDialog(day, currentSlot, index);
    if (result != null) {
      setState(() {
        _dayTimeSlots[day]?[index] = result;
      });
    }
  }

  void _removeTimeSlot(String day, int index) {
    setState(() {
      _dayTimeSlots[day]?.removeAt(index);
    });
  }

  Future<TimeSlot?> _showTimeSlotDialog(
      String day, TimeSlot? existingSlot, int? index) async {
    TimeOfDay startTime =
        existingSlot?.startTime ?? const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime =
        existingSlot?.endTime ?? const TimeOfDay(hour: 10, minute: 0);

    return showDialog<TimeSlot>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          existingSlot == null ? 'Add Time Slot' : 'Edit Time Slot',
          style: const TextStyle(
            color: Color(0xFF006A5B),
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                day,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 24),

              // Start time
              InkWell(
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: startTime,
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: Color(0xFF006A5B),
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (time != null) {
                    setDialogState(() {
                      startTime = time;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, color: Color(0xFF006A5B)),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Start Time',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatTime(startTime),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF006A5B),
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // End time
              InkWell(
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: endTime,
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: Color(0xFF006A5B),
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (time != null) {
                    setDialogState(() {
                      endTime = time;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, color: Color(0xFF006A5B)),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'End Time',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatTime(endTime),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF006A5B),
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
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // Validate time range
              final startMinutes = startTime.hour * 60 + startTime.minute;
              final endMinutes = endTime.hour * 60 + endTime.minute;

              if (endMinutes <= startMinutes) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('End time must be after start time'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(
                context,
                TimeSlot(startTime: startTime, endTime: endTime),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006A5B),
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'Save',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSchedule() async {
    if (_therapistId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to save: Therapist ID not found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if at least one day is selected
    if (!_selectedDays.values.contains(true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one available day'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check if selected days have time slots
    bool hasTimeSlots = false;
    for (var day in _daysOfWeek) {
      if (_selectedDays[day] == true) {
        if (_dayTimeSlots[day]?.isEmpty ?? true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please add time slots for $day'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
        hasTimeSlots = true;
      }
    }

    if (!hasTimeSlots) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add time slots for selected days'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Prepare time slots data for Firebase
      final Map<String, dynamic> timeSlotsData = {};
      _dayTimeSlots.forEach((day, slots) {
        if (_selectedDays[day] == true) {
          timeSlotsData[day] = slots
              .map((slot) => {
                    'startHour': slot.startTime.hour,
                    'startMinute': slot.startTime.minute,
                    'endHour': slot.endTime.hour,
                    'endMinute': slot.endTime.minute,
                  })
              .toList();
        }
      });

      // Save to Firebase schedules collection
      await FirebaseFirestore.instance
          .collection('schedules')
          .doc(_therapistId)
          .set({
        'ther_id': _therapistId,
        'clinicId': _therapistId, // Keep for compatibility
        'selectedDays': _selectedDays,
        'timeSlots': timeSlotsData,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': _therapistId,
        'constraints': {
          'advanceBookingDays': 30,
          'bufferTimeMinutes': 15,
          'cancellationHours': 24,
          'maxPatientsPerDay': 8,
          'maxPatientsPerSlot': 1,
          'rescheduleHours': 48,
          'sameDayBooking': false,
          'slotDurationMinutes': 60,
          'weekendBooking': false,
        },
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Schedule saved successfully!'),
            backgroundColor: Color(0xFF006A5B),
          ),
        );

        // Return true to indicate schedule was updated
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('Error saving schedule: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving schedule: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}

class TimeSlot {
  final TimeOfDay startTime;
  final TimeOfDay endTime;

  TimeSlot({
    required this.startTime,
    required this.endTime,
  });
}
