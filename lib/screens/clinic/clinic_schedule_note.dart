import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ClinicScheduleNotePage extends StatefulWidget {
  const ClinicScheduleNotePage({Key? key}) : super(key: key);

  @override
  State<ClinicScheduleNotePage> createState() => _ClinicScheduleNotePageState();
}

class _ClinicScheduleNotePageState extends State<ClinicScheduleNotePage> {
  DateTime _currentMonth = DateTime.now();
  String? _clinicId;
  String? _therapistId;
  Map<String, dynamic> _scheduleMessages = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _clinicId = prefs.getString('clinic_id');
      _therapistId = prefs.getString('user_id');
    });

    await _loadScheduleMessages();

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadScheduleMessages() async {
    if (_clinicId == null && _therapistId == null) return;

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('ScheduleMessage')
          .where(_clinicId != null ? 'clinicId' : 'therapistId',
              isEqualTo: _clinicId ?? _therapistId)
          .get();

      setState(() {
        _scheduleMessages = {};
        for (var doc in querySnapshot.docs) {
          final data = doc.data();
          _scheduleMessages[data['date']] = {
            'id': doc.id,
            ...data,
          };
        }
      });
    } catch (e) {
      print('Error loading schedule messages: $e');
    }
  }

  void _navigateToPreviousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
    _loadScheduleMessages();
  }

  void _navigateToNextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
    _loadScheduleMessages();
  }

  void _selectDate(DateTime date) {
    _showScheduleMessageForm(date);
  }

  void _showScheduleMessageForm(DateTime date) {
    final dateString = DateFormat('yyyy-MM-dd').format(date);
    final existingMessage = _scheduleMessages[dateString];

    final titleController = TextEditingController(
      text: existingMessage?['title'] ?? '',
    );
    final detailsController = TextEditingController(
      text: existingMessage?['details'] ?? '',
    );
    final startTimeController = TextEditingController(
      text: existingMessage?['startTime'] ?? '',
    );
    final endTimeController = TextEditingController(
      text: existingMessage?['endTime'] ?? '',
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Schedule Note',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF006A5B),
                  fontFamily: 'Poppins',
                ),
              ),
              Text(
                DateFormat('EEEE, MMMM dd, yyyy').format(date),
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF67AFA5),
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title Field
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    labelStyle: TextStyle(
                      color: Color(0xFF67AFA5),
                      fontFamily: 'Poppins',
                    ),
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF006A5B)),
                    ),
                  ),
                  style: const TextStyle(fontFamily: 'Poppins'),
                ),

                const SizedBox(height: 16),

                // Time Fields Row
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: startTimeController,
                        decoration: const InputDecoration(
                          labelText: 'Start Time (Optional)',
                          hintText: '09:00',
                          labelStyle: TextStyle(
                            color: Color(0xFF67AFA5),
                            fontFamily: 'Poppins',
                            fontSize: 12,
                          ),
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontFamily: 'Poppins',
                          ),
                          border: OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF006A5B)),
                          ),
                        ),
                        style: const TextStyle(fontFamily: 'Poppins'),
                        onTap: () => _selectTime(context, startTimeController),
                        readOnly: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: endTimeController,
                        decoration: const InputDecoration(
                          labelText: 'End Time (Optional)',
                          hintText: '17:00',
                          labelStyle: TextStyle(
                            color: Color(0xFF67AFA5),
                            fontFamily: 'Poppins',
                            fontSize: 12,
                          ),
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontFamily: 'Poppins',
                          ),
                          border: OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF006A5B)),
                          ),
                        ),
                        style: const TextStyle(fontFamily: 'Poppins'),
                        onTap: () => _selectTime(context, endTimeController),
                        readOnly: true,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Details Field
                TextField(
                  controller: detailsController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Details/Message',
                    labelStyle: TextStyle(
                      color: Color(0xFF67AFA5),
                      fontFamily: 'Poppins',
                    ),
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF006A5B)),
                    ),
                  ),
                  style: const TextStyle(fontFamily: 'Poppins'),
                ),

                const SizedBox(height: 12),

                // Info text
                if (startTimeController.text.isNotEmpty ||
                    endTimeController.text.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE74C3C).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFE74C3C).withOpacity(0.3),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Color(0xFFE74C3C),
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Time range indicates when you will be unavailable.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFFE74C3C),
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
          actions: [
            if (existingMessage != null)
              TextButton(
                onPressed: () {
                  _deleteScheduleMessage(existingMessage['id']);
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(
                    color: Colors.red,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFF67AFA5),
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _saveScheduleMessage(
                  date,
                  titleController.text,
                  detailsController.text,
                  startTimeController.text,
                  endTimeController.text,
                  existingMessage?['id'],
                );
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006A5B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Save',
                style: TextStyle(fontFamily: 'Poppins'),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectTime(
      BuildContext context, TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      final formattedTime =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      controller.text = formattedTime;
    }
  }

  Future<void> _saveScheduleMessage(
    DateTime date,
    String title,
    String details,
    String startTime,
    String endTime,
    String? existingId,
  ) async {
    if (title.trim().isEmpty && details.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a title or details.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final dateString = DateFormat('yyyy-MM-dd').format(date);
      final messageData = {
        'date': dateString,
        'title': title.trim(),
        'details': details.trim(),
        'startTime': startTime.trim().isNotEmpty ? startTime.trim() : null,
        'endTime': endTime.trim().isNotEmpty ? endTime.trim() : null,
        'clinicId': _clinicId,
        'therapistId': _therapistId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (existingId != null) {
        // Update existing message
        await FirebaseFirestore.instance
            .collection('ScheduleMessage')
            .doc(existingId)
            .update(messageData);
      } else {
        // Create new message
        await FirebaseFirestore.instance
            .collection('ScheduleMessage')
            .add(messageData);
      }

      await _loadScheduleMessages();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Schedule message saved successfully!'),
            backgroundColor: Color(0xFF006A5B),
          ),
        );
      }
    } catch (e) {
      print('Error saving schedule message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteScheduleMessage(String messageId) async {
    try {
      await FirebaseFirestore.instance
          .collection('ScheduleMessage')
          .doc(messageId)
          .delete();

      await _loadScheduleMessages();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Schedule message deleted successfully!'),
            backgroundColor: Color(0xFF006A5B),
          ),
        );
      }
    } catch (e) {
      print('Error deleting schedule message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
          'Schedule Notes',
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

                  // Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          spreadRadius: 1,
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Color(0xFF006A5B),
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Click on any date to add or edit schedule notes for your patients.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF006A5B),
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Calendar Widget
                  _buildCalendarWidget(),

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
      final dateString = DateFormat('yyyy-MM-dd').format(date);
      final isToday = day == now.day &&
          _currentMonth.year == now.year &&
          _currentMonth.month == now.month;
      final hasMessage = _scheduleMessages.containsKey(dateString);

      calendarDays.add(
        GestureDetector(
          onTap: () => _selectDate(date),
          child: Container(
            width: 35,
            height: 45,
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isToday
                  ? const Color(0xFF006A5B)
                  : hasMessage
                      ? const Color(0xFF67AFA5).withOpacity(0.3)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: hasMessage && !isToday
                  ? Border.all(color: const Color(0xFF67AFA5), width: 1)
                  : Border.all(color: Colors.grey.withOpacity(0.3), width: 0.5),
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
                      color: isToday
                          ? Colors.white
                          : hasMessage
                              ? const Color(0xFF006A5B)
                              : Colors.black54,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  if (hasMessage)
                    Container(
                      width: 4,
                      height: 4,
                      margin: const EdgeInsets.only(top: 2),
                      decoration: BoxDecoration(
                        color: isToday ? Colors.white : const Color(0xFF006A5B),
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
}
