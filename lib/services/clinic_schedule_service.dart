import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ClinicScheduleService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection names
  static const String _schedulesCollection = 'ClinicSchedules';
  static const String _bookingRequestsCollection = 'BookingRequests';

  // Get current clinic ID from storage
  static Future<String?> _getCurrentClinicId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('clinic_id');
  }

  // Save weekly schedule to Firebase
  static Future<void> saveWeeklySchedule(
      Map<String, List<TimeSlot>> weeklySchedule) async {
    try {
      final clinicId = await _getCurrentClinicId();
      if (clinicId == null) {
        throw 'No clinic ID found. Please login again.';
      }

      // Convert TimeSlot objects to maps for Firestore
      final Map<String, dynamic> scheduleData = {};
      weeklySchedule.forEach((day, slots) {
        scheduleData[day] = slots
            .map((slot) => {
                  'time': slot.time,
                  'isAvailable': slot.isAvailable,
                  'patientName': slot.patientName,
                  'patientId': slot.patientId ?? '',
                  'appointmentType': slot.appointmentType ?? '',
                })
            .toList();
      });

      // Save to Firestore with clinic ID as document ID
      await _firestore.collection(_schedulesCollection).doc(clinicId).set({
        'clinicId': clinicId,
        'weeklySchedule': scheduleData,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('Weekly schedule saved successfully');
    } catch (e) {
      print('Error saving weekly schedule: $e');
      throw 'Failed to save schedule: $e';
    }
  }

  // Load weekly schedule from Firebase
  static Future<Map<String, List<TimeSlot>>> loadWeeklySchedule() async {
    try {
      final clinicId = await _getCurrentClinicId();
      if (clinicId == null) {
        throw 'No clinic ID found. Please login again.';
      }

      final doc =
          await _firestore.collection(_schedulesCollection).doc(clinicId).get();

      if (!doc.exists) {
        // Return default schedule if none exists
        return _getDefaultSchedule();
      }

      final data = doc.data() as Map<String, dynamic>;
      final scheduleData = data['weeklySchedule'] as Map<String, dynamic>;

      // Convert back to TimeSlot objects
      final Map<String, List<TimeSlot>> weeklySchedule = {};
      scheduleData.forEach((day, slots) {
        weeklySchedule[day] = (slots as List)
            .map((slot) => TimeSlot(
                  time: slot['time'],
                  isAvailable: slot['isAvailable'],
                  patientName: slot['patientName'] ?? '',
                  patientId: slot['patientId'],
                  appointmentType: slot['appointmentType'],
                ))
            .toList();
      });

      return weeklySchedule;
    } catch (e) {
      print('Error loading weekly schedule: $e');
      // Return default schedule on error
      return _getDefaultSchedule();
    }
  }

  // Update a specific time slot
  static Future<void> updateTimeSlot(
    String day,
    String time, {
    bool? isAvailable,
    String? patientName,
    String? patientId,
    String? appointmentType,
  }) async {
    try {
      final clinicId = await _getCurrentClinicId();
      if (clinicId == null) {
        throw 'No clinic ID found. Please login again.';
      }

      // Load current schedule
      final schedule = await loadWeeklySchedule();

      // Find and update the specific slot
      if (schedule.containsKey(day)) {
        final slots = schedule[day]!;
        for (int i = 0; i < slots.length; i++) {
          if (slots[i].time == time) {
            slots[i] = TimeSlot(
              time: time,
              isAvailable: isAvailable ?? slots[i].isAvailable,
              patientName: patientName ?? slots[i].patientName,
              patientId: patientId ?? slots[i].patientId,
              appointmentType: appointmentType ?? slots[i].appointmentType,
            );
            break;
          }
        }
      }

      // Save updated schedule
      await saveWeeklySchedule(schedule);
    } catch (e) {
      print('Error updating time slot: $e');
      throw 'Failed to update time slot: $e';
    }
  }

  // Save booking request
  static Future<void> saveBookingRequest({
    required String parentName,
    required String childName,
    required String requestedDay,
    required String requestedTime,
    required String appointmentType,
    required String parentId,
  }) async {
    try {
      final clinicId = await _getCurrentClinicId();
      if (clinicId == null) {
        throw 'No clinic ID found. Please login again.';
      }

      await _firestore.collection(_bookingRequestsCollection).add({
        'clinicId': clinicId,
        'parentId': parentId,
        'parentName': parentName,
        'childName': childName,
        'requestedDay': requestedDay,
        'requestedTime': requestedTime,
        'appointmentType': appointmentType,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('Booking request saved successfully');
    } catch (e) {
      print('Error saving booking request: $e');
      throw 'Failed to save booking request: $e';
    }
  }

  // Get booking requests for current clinic
  static Stream<QuerySnapshot> getBookingRequests() {
    return _firestore
        .collection(_bookingRequestsCollection)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Accept booking request
  static Future<void> acceptBookingRequest(
      String requestId, Map<String, dynamic> requestData) async {
    try {
      // Update request status
      await _firestore
          .collection(_bookingRequestsCollection)
          .doc(requestId)
          .update({
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      // Update schedule slot
      await updateTimeSlot(
        requestData['requestedDay'],
        requestData['requestedTime'],
        isAvailable: false,
        patientName: requestData['childName'],
        patientId: requestData['parentId'],
        appointmentType: requestData['appointmentType'],
      );

      print('Booking request accepted successfully');
    } catch (e) {
      print('Error accepting booking request: $e');
      throw 'Failed to accept booking request: $e';
    }
  }

  // Decline booking request
  static Future<void> declineBookingRequest(String requestId) async {
    try {
      await _firestore
          .collection(_bookingRequestsCollection)
          .doc(requestId)
          .update({
        'status': 'declined',
        'declinedAt': FieldValue.serverTimestamp(),
      });

      print('Booking request declined successfully');
    } catch (e) {
      print('Error declining booking request: $e');
      throw 'Failed to decline booking request: $e';
    }
  }

  // Get today's appointments
  static Future<List<Map<String, dynamic>>> getTodayAppointments() async {
    try {
      final schedule = await loadWeeklySchedule();
      final today = DateTime.now();
      final dayName = _getDayName(today.weekday);

      final todaySlots = schedule[dayName] ?? [];

      return todaySlots
          .where((slot) => !slot.isAvailable && slot.patientName.isNotEmpty)
          .map((slot) => {
                'time': slot.time,
                'patientName': slot.patientName,
                'appointmentType': slot.appointmentType ?? 'Therapy Session',
              })
          .toList();
    } catch (e) {
      print('Error getting today\'s appointments: $e');
      return [];
    }
  }

  // Helper method to get day name from weekday number
  static String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return 'Monday';
    }
  }

  // Get default schedule structure
  static Map<String, List<TimeSlot>> _getDefaultSchedule() {
    final Map<String, List<TimeSlot>> defaultSchedule = {};

    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
    final times = [
      '8:00 AM',
      '9:00 AM',
      '10:00 AM',
      '11:00 AM',
      '1:00 PM',
      '2:00 PM',
      '3:00 PM',
      '4:00 PM'
    ];

    for (String day in days) {
      defaultSchedule[day] = times
          .map((time) => TimeSlot(
                time: time,
                isAvailable: true,
                patientName: '',
              ))
          .toList();
    }

    return defaultSchedule;
  }
}

// Enhanced TimeSlot class to match Firebase structure
class TimeSlot {
  final String time;
  final bool isAvailable;
  final String patientName;
  final String? patientId;
  final String? appointmentType;

  TimeSlot({
    required this.time,
    required this.isAvailable,
    required this.patientName,
    this.patientId,
    this.appointmentType,
  });

  // Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'time': time,
      'isAvailable': isAvailable,
      'patientName': patientName,
      'patientId': patientId ?? '',
      'appointmentType': appointmentType ?? '',
    };
  }

  // Create from map (Firestore data)
  factory TimeSlot.fromMap(Map<String, dynamic> map) {
    return TimeSlot(
      time: map['time'] ?? '',
      isAvailable: map['isAvailable'] ?? true,
      patientName: map['patientName'] ?? '',
      patientId: map['patientId'],
      appointmentType: map['appointmentType'],
    );
  }
}
