import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kindora/screens/parent/parent_navbar.dart';
import 'package:kindora/helper/field_helper.dart';

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

      print('🔍 Loading accepted bookings for parent: $_parentId');
      print('📅 Date range: $startOfMonth to $endOfMonth');

      // Get parent credentials
      final prefs = await SharedPreferences.getInstance();
      final parentEmail = prefs.getString('parent_email') ?? prefs.getString('parentEmail');
      
      // DEBUG: Print all stored preferences
      print('🔐 DEBUG - All SharedPreferences keys:');
      final allKeys = prefs.getKeys();
      for (String key in allKeys) {
        final value = prefs.get(key);
        print('   $key: $value');
      }
      
      print('🎯 Using parentEmail: $parentEmail');
      print('🎯 Using parentId: $_parentId');

      // Query for appointments where parent matches
      // Try multiple parent field variations to catch all appointments
      List<QuerySnapshot> queryResults = [];

      // 1. Query Request collection for confirmed appointments (NO DATE FILTERING)
      if (parentEmail != null) {
        try {
          final requestQuery = await FirebaseFirestore.instance
              .collection('Request')
              .where('parentEmail', isEqualTo: parentEmail)
              .get(); // Remove status filter temporarily to see all requests
          
          queryResults.add(requestQuery);
          print('✅ Found ${requestQuery.docs.length} requests using parentEmail: $parentEmail');
          
          // Debug: Print each document
          for (var doc in requestQuery.docs) {
            final data = doc.data();
            print('🔍 Request doc: ${doc.id}');
            print('   - parentEmail: ${data['parentEmail']}');
            print('   - status: ${data['status']}');
            print('   - patientName: ${data['patientName']}');
            print('   - updatedAt: ${data['updatedAt']}');
          }
        } catch (e) {
          print('⚠️ Request query failed: $e');
        }
      }

      // Try with different email field variations
      final storedEmails = [
        prefs.getString('parent_email'),
        prefs.getString('parentEmail'),
        prefs.getString('email'),
        'test@gmail.com' // Direct match for your data
      ];

      for (String? email in storedEmails) {
        if (email != null && email != parentEmail) {
          try {
            final requestQuery = await FirebaseFirestore.instance
                .collection('Request')
                .where('parentEmail', isEqualTo: email)
                .get();
            
            if (requestQuery.docs.isNotEmpty) {
              queryResults.add(requestQuery);
              print('✅ Found ${requestQuery.docs.length} requests using email: $email');
            }
          } catch (e) {
            print('⚠️ Request query failed for email $email: $e');
          }
        }
      }

      // Also try querying Request by parentId if not "unknown"
      if (_parentId != null && _parentId != 'unknown') {
        try {
          final requestQuery2 = await FirebaseFirestore.instance
              .collection('Request')
              .where('parentId', isEqualTo: _parentId)
              .get();
          
          if (requestQuery2.docs.isNotEmpty) {
            queryResults.add(requestQuery2);
            print('✅ Found ${requestQuery2.docs.length} requests using parentId: $_parentId');
          }
        } catch (e) {
          print('⚠️ Request query 2 failed: $e');
        }
      }

      // 2. Query AcceptedBooking collection with different parent field structures
      final parentIdQueries = [
        'parentInfo.parentId',
        'originalRequestData.parentInfo.parentId', 
        'parentId',
        'childInfo.parentId'
      ];

      for (String parentField in parentIdQueries) {
        try {
          final querySnapshot = await FirebaseFirestore.instance
              .collection('AcceptedBooking')
              .where(parentField, isEqualTo: _parentId)
              .where('appointmentDate',
                  isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
              .where('appointmentDate',
                  isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
              .get();
          
          if (querySnapshot.docs.isNotEmpty) {
            queryResults.add(querySnapshot);
            print('✅ Found ${querySnapshot.docs.length} accepted bookings using field: $parentField');
          }
        } catch (e) {
          print('⚠️ AcceptedBooking query failed for field $parentField: $e');
          // Continue with other field attempts
        }
      }
      
      if (parentEmail != null) {
        try {
          final emailQuery = await FirebaseFirestore.instance
              .collection('AcceptedBooking')
              .where('parentInfo.email', isEqualTo: parentEmail)
              .where('appointmentDate',
                  isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
              .where('appointmentDate',
                  isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
              .get();
          
          if (emailQuery.docs.isNotEmpty) {
            queryResults.add(emailQuery);
            print('✅ Found ${emailQuery.docs.length} accepted bookings using parent email');
          }
        } catch (e) {
          print('⚠️ AcceptedBooking email query failed: $e');
        }
      }

      // Combine all results and remove duplicates
      Set<String> seenIds = {};
      List<Map<String, dynamic>> allBookings = [];

      for (QuerySnapshot querySnapshot in queryResults) {
        for (var doc in querySnapshot.docs) {
          String uniqueId = '${doc.reference.parent.id}_${doc.id}';
          if (!seenIds.contains(uniqueId)) {
            seenIds.add(uniqueId);
            final data = doc.data() as Map<String, dynamic>;
            
            // Add metadata to identify source collection
            final processedData = {
              'id': doc.id,
              'collectionType': doc.reference.parent.id,
              ...data,
            };

            // For Request collection, extract date from updatedAt or timeSlotId
            if (doc.reference.parent.id == 'Request') {
              // Convert updatedAt to appointmentDate for consistency
              if (data['updatedAt'] != null) {
                if (data['updatedAt'] is Timestamp) {
                  processedData['appointmentDate'] = data['updatedAt'];
                } else if (data['updatedAt'] is String) {
                  try {
                    final dateTime = DateTime.parse(data['updatedAt']);
                    processedData['appointmentDate'] = Timestamp.fromDate(dateTime);
                  } catch (e) {
                    print('⚠️ Failed to parse updatedAt: ${data['updatedAt']}');
                  }
                }
              }
              
              // Set appointment details for Request collection
              processedData['appointmentType'] = data['submissionMethod'] ?? 'Appointment';
              processedData['appointmentTime'] = 'Scheduled';
              processedData['patientName'] = data['patientName'];
              processedData['parentName'] = data['parentName'];
              processedData['parentPhone'] = data['parentPhone'];
            }
            
            allBookings.add(processedData);
            
            // Debug print the booking structure
            print('📋 Booking ${doc.id} from ${doc.reference.parent.id}:');
            print('  - appointmentDate: ${processedData['appointmentDate']}');
            print('  - appointmentTime: ${processedData['appointmentTime']}');
            print('  - appointmentType: ${processedData['appointmentType']}');
            print('  - patientName: ${processedData['patientName']}');
            print('  - status: ${processedData['status']}');
          }
        }
      }

      setState(() {
        _acceptedBookings = allBookings;
      });

      print('📊 Total unique appointments loaded: ${allBookings.length}');
      
      // EMERGENCY DEBUG: If no appointments found, try to get ALL Request documents
      if (allBookings.isEmpty) {
        print('🚨 NO APPOINTMENTS FOUND! Trying emergency fallback...');
        try {
          final allRequests = await FirebaseFirestore.instance
              .collection('Request')
              .limit(10)
              .get();
          
          print('🔍 Total Request documents in Firebase: ${allRequests.docs.length}');
          for (var doc in allRequests.docs) {
            final data = doc.data();
            print('📋 Request ${doc.id}:');
            print('   - parentEmail: ${data['parentEmail']}');
            print('   - parentId: ${data['parentId']}');
            print('   - patientName: ${data['patientName']}');
            print('   - status: ${data['status']}');
            
            // Add this document to show something
            final processedData = {
              'id': doc.id,
              'collectionType': 'Request',
              'appointmentDate': data['updatedAt'] ?? Timestamp.now(),
              'appointmentType': data['submissionMethod'] ?? 'Appointment',
              'appointmentTime': 'Scheduled',
              'patientName': data['patientName'],
              'parentName': data['parentName'],
              'parentPhone': data['parentPhone'],
              'status': data['status'] ?? 'pending',
              ...data,
            };
            allBookings.add(processedData);
          }
          
          setState(() {
            _acceptedBookings = allBookings;
          });
          
          print('🆘 Emergency fallback added ${allRequests.docs.length} appointments');
        } catch (e) {
          print('❌ Emergency fallback failed: $e');
        }
      }
    } catch (e) {
      print('❌ Error loading accepted bookings: $e');
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

            // Show appointments for selected date with detailed information
            if (selectedBookings.isNotEmpty) ...[
              ...selectedBookings.map((booking) => _buildAppointmentCard(booking)),
            ] else ...[
              // No appointments message
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.event_busy,
                      color: Colors.grey[400],
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No appointments scheduled',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Select a date with appointments to view details',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontFamily: 'Poppins',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],

            // Show additional therapist/clinic message if available
            if (_selectedDateMessage != null) ...[
              const SizedBox(height: 16),
              const Text(
                'Additional Message from Provider:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF006A5B),
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 8),
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
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> booking) {
    // Get provider information - handle both Request and AcceptedBooking collections
    String providerName = 'Provider';
    String providerType = 'Provider';
    
    if (booking['collectionType'] == 'Request') {
      // Handle Request collection data structure
      final submissionMethod = booking['submissionMethod']?.toString() ?? '';
      
      if (submissionMethod.toLowerCase().contains('clinic') || booking['clinicId'] != null) {
        providerType = 'Clinic';
        providerName = 'Medical Clinic';
      } else if (booking['therapistId'] != null) {
        providerType = 'Therapist';
        providerName = 'Licensed Therapist';
      } else {
        // Default based on submission method
        if (submissionMethod.toLowerCase().contains('therapy')) {
          providerType = 'Therapist';
          providerName = 'Licensed Therapist';
        } else {
          providerType = 'Clinic';
          providerName = 'Medical Clinic';
        }
      }
    } else {
      // Handle AcceptedBooking collection data structure
      final clinicId = booking['clinicId'];
      final serviceProvider = booking['serviceProvider'] as Map<String, dynamic>?;
      
      if (clinicId != null && clinicId.toString().isNotEmpty) {
        providerType = 'Clinic';
        providerName = serviceProvider?['clinicName'] ?? 
                      booking['clinicName'] ?? 
                      'Clinic ($clinicId)';
      } else if (serviceProvider?['therapistId'] != null || 
                 serviceProvider?['therapistName'] != null) {
        providerType = 'Therapist';
        providerName = serviceProvider?['therapistName'] ?? 
                      booking['therapistName'] ?? 
                      'Therapist';
      } else {
        // Fallback - try to determine from available data
        if (booking['therapistId'] != null) {
          providerType = 'Therapist';
          providerName = booking['therapistName'] ?? 'Therapist';
        }
      }
    }
    
    // Get child information - handle different data structures
    String childName = 'Child';
    String childAge = '';
    String childGender = '';
    
    if (booking['collectionType'] == 'Request') {
      // For Request collection, child info is in patientName
      childName = booking['patientName'] ?? 'Patient';
    } else {
      // For AcceptedBooking collection
      if (booking['childName'] != null) {
        childName = booking['childName'];
      } else {
        childName = FieldHelper.getChildName(booking) ?? 'Child';
      }
      
      if (booking['childAge'] != null) {
        childAge = booking['childAge'].toString();
      }
      
      if (booking['childGender'] != null) {
        childGender = booking['childGender'];
      }
    }
    
    // Get appointment details
    final appointmentTime = booking['appointmentTime'] ?? 'Scheduled';
    final appointmentType = booking['appointmentType'] ?? booking['submissionMethod'] ?? 'Consultation';
    final bookingType = booking['bookingType'] ?? 'single_session';
    final status = booking['status'] ?? 'confirmed';
    final additionalNotes = booking['additionalNotes'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF006A5B).withOpacity(0.05),
            const Color(0xFF67AFA5).withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF006A5B).withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF006A5B).withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with appointment type and status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      appointmentType.toLowerCase().contains('therapy') 
                          ? Icons.healing 
                          : appointmentType.toLowerCase().contains('consultation')
                              ? Icons.medical_services
                              : Icons.event,
                      color: const Color(0xFF006A5B),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        appointmentType,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF006A5B),
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: status.toLowerCase() == 'confirmed' || status.toLowerCase() == 'approved'
                      ? Colors.green.withOpacity(0.1)
                      : status.toLowerCase() == 'pending'
                          ? Colors.orange.withOpacity(0.1)
                          : Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: status.toLowerCase() == 'confirmed' || status.toLowerCase() == 'approved'
                        ? Colors.green 
                        : status.toLowerCase() == 'pending'
                            ? Colors.orange
                            : Colors.blue,
                    width: 1,
                  ),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: status.toLowerCase() == 'confirmed' || status.toLowerCase() == 'approved'
                        ? Colors.green 
                        : status.toLowerCase() == 'pending'
                            ? Colors.orange
                            : Colors.blue,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Time information
          Row(
            children: [
              const Icon(
                Icons.access_time,
                color: Color(0xFF67AFA5),
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  booking['startTime'] != null && booking['endTime'] != null
                      ? _getAppointmentDuration(booking)
                      : appointmentTime,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF006A5B),
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Provider information
          Row(
            children: [
              Icon(
                providerType == 'Clinic' ? Icons.local_hospital : Icons.person,
                color: const Color(0xFF67AFA5),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                '$providerType: ',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF67AFA5),
                  fontFamily: 'Poppins',
                ),
              ),
              Expanded(
                child: Text(
                  providerName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF006A5B),
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Child information
          Row(
            children: [
              const Icon(
                Icons.child_care,
                color: Color(0xFF67AFA5),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Patient: ',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF67AFA5),
                  fontFamily: 'Poppins',
                ),
              ),
              Expanded(
                child: Text(
                  childName + 
                  (childAge.isNotEmpty ? ' (Age: $childAge)' : '') +
                  (childGender.isNotEmpty ? ' - $childGender' : ''),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF006A5B),
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
          
          // Booking type information
          if (bookingType != 'single_session') ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.repeat,
                  color: Color(0xFF67AFA5),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Booking Type: ',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF67AFA5),
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  bookingType.replaceAll('_', ' ').toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF006A5B),
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ],
          
          // Additional notes if available
          if (additionalNotes != null && additionalNotes.toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.note,
                  color: Color(0xFF67AFA5),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    additionalNotes.toString(),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF006A5B),
                      fontFamily: 'Poppins',
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(String timeString) {
    try {
      // Handle different time formats
      if (timeString.contains(':')) {
        final parts = timeString.split(':');
        if (parts.length >= 2) {
          final hour = int.tryParse(parts[0]) ?? 0;
          final minute = int.tryParse(parts[1]) ?? 0;
          final time = DateTime(2024, 1, 1, hour, minute);
          return DateFormat('h:mm a').format(time);
        }
      }
      return timeString;
    } catch (e) {
      return timeString;
    }
  }

  String _getAppointmentDuration(Map<String, dynamic> data) {
    final startTime = data['startTime']?.toString() ?? '';
    final endTime = data['endTime']?.toString() ?? '';
    
    if (startTime.isNotEmpty && endTime.isNotEmpty) {
      return '${_formatTime(startTime)} - ${_formatTime(endTime)}';
    } else if (startTime.isNotEmpty) {
      return 'Starting at ${_formatTime(startTime)}';
    }
    return 'Time not specified';
  }
}
