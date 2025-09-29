import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Complete Schedule Database Collection Service
///
/// This service handles all schedule-related operations for therapists/clinics
/// Collection: 'schedules'
///
/// Document Structure:
/// - scheduleId: Document ID (same as therapistId)
/// - therapistId: Reference to therapist
/// - clinicId: Reference to clinic
/// - weeklySchedule: Complete weekly schedule with time slots
/// - constraints: Booking rules and limitations
/// - statistics: Real-time schedule statistics
/// - exceptions: Special dates (holidays, unavailable days)
/// - recurringSettings: Settings for recurring appointments

class ScheduleDatabaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String COLLECTION_NAME = 'schedules';

  /// Save complete schedule to Firebase
  static Future<void> saveSchedule({
    required String therapistId,
    required Map<String, dynamic> weeklySchedule,
    Map<String, dynamic>? constraints,
    List<Map<String, dynamic>>? exceptions,
    Map<String, dynamic>? recurringSettings,
  }) async {
    try {
      final scheduleDoc = {
        // === PRIMARY IDENTIFIERS ===
        'scheduleId': therapistId,
        'therapistId': therapistId,
        'clinicId':
            therapistId, // Can be different if therapist works at multiple clinics

        // === METADATA ===
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdBy': therapistId,
        'lastModifiedBy': therapistId,
        'version': 1, // For tracking schedule versions

        // === SCHEDULE CONFIGURATION ===
        'scheduleType': 'weekly', // 'weekly', 'monthly', 'custom'
        'effectiveDate':
            FieldValue.serverTimestamp(), // When this schedule starts
        'expiryDate': null, // When this schedule ends (null = indefinite)
        'isActive': true,
        'isPublished': true, // Whether patients can see and book

        // === WEEKLY SCHEDULE DATA ===
        'weeklySchedule': weeklySchedule,

        // === BOOKING CONSTRAINTS ===
        'constraints': constraints ??
            {
              'maxPatientsPerDay': 8,
              'maxPatientsPerSlot': 1, // Usually 1 for therapy sessions
              'slotDurationMinutes': 60,
              'bufferTimeMinutes': 15, // Time between appointments
              'advanceBookingDays': 30, // How far in advance can patients book
              'cancellationHours': 24, // Minimum notice for cancellation
              'rescheduleHours': 48, // Minimum notice for rescheduling
              'sameDayBooking': false, // Allow same-day bookings
              'weekendBooking': false, // Allow weekend bookings
            },

        // === SPECIAL DATES AND EXCEPTIONS ===
        'exceptions': exceptions ?? [],
        /* Exception structure:
        {
          'date': Timestamp, // Specific date
          'type': 'holiday|vacation|sick|custom',
          'reason': 'Christmas Day|Personal',
          'isWorkingDay': false,
          'customSchedule': null, // Custom schedule for that day if working
        }
        */

        // === RECURRING APPOINTMENT SETTINGS ===
        'recurringSettings': recurringSettings ??
            {
              'allowRecurring': true,
              'maxRecurringWeeks': 52, // Maximum contract length (1 year)
              'defaultRecurrenceType':
                  'weekly', // 'weekly', 'biweekly', 'monthly'
              'maxRecurringAppointments': 50, // Total appointments per contract
              'requireContractApproval': true,
            },

        // === NOTIFICATION SETTINGS ===
        'notifications': {
          'emailReminders': true,
          'smsReminders': true,
          'reminderHours': [24, 2], // Send reminders 24h and 2h before
          'confirmationRequired': true,
        },

        // === PRICING INFORMATION ===
        'pricing': {
          'sessionPrice': 0.0, // Price per session
          'currency': 'USD',
          'acceptsInsurance': false,
          'paymentMethods': ['cash', 'card'],
        },

        // === STATISTICS (Auto-calculated) ===
        'statistics': _calculateStatistics(weeklySchedule),

        // === THERAPIST INFORMATION ===
        'therapistInfo': {
          'specializations': [], // To be filled by therapist profile
          'languages': [], // Languages spoken
          'experience': '', // Years of experience
        },
      };

      await _firestore
          .collection(COLLECTION_NAME)
          .doc(therapistId)
          .set(scheduleDoc, SetOptions(merge: true));

      print('Schedule saved successfully for therapist: $therapistId');
    } catch (e) {
      print('Error saving schedule: $e');
      throw Exception('Failed to save schedule: $e');
    }
  }

  /// Load complete schedule from Firebase
  static Future<Map<String, dynamic>?> loadSchedule(String therapistId) async {
    try {
      final doc =
          await _firestore.collection(COLLECTION_NAME).doc(therapistId).get();

      if (doc.exists) {
        return doc.data();
      } else {
        return null; // No schedule found
      }
    } catch (e) {
      print('Error loading schedule: $e');
      throw Exception('Failed to load schedule: $e');
    }
  }

  /// Book a specific time slot
  static Future<void> bookTimeSlot({
    required String therapistId,
    required String day, // 'monday', 'tuesday', etc.
    required String slotId,
    required String patientId,
    required String patientName,
    required String carerId, // Parent/guardian ID
    required String appointmentType,
    String? notes,
    bool isRecurring = false,
    String? recurringGroupId,
  }) async {
    try {
      final docRef = _firestore.collection(COLLECTION_NAME).doc(therapistId);

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);

        if (!doc.exists) {
          throw Exception('Schedule not found');
        }

        final data = Map<String, dynamic>.from(doc.data()!);
        final weeklySchedule =
            Map<String, dynamic>.from(data['weeklySchedule']);
        final daySchedule = Map<String, dynamic>.from(weeklySchedule[day]);
        final timeSlots =
            List<Map<String, dynamic>>.from(daySchedule['timeSlots']);

        // Find and update the specific slot
        bool slotFound = false;
        for (int i = 0; i < timeSlots.length; i++) {
          if (timeSlots[i]['slotId'] == slotId) {
            if (timeSlots[i]['isBooked'] == true) {
              throw Exception('Time slot is already booked');
            }

            timeSlots[i] = {
              ...timeSlots[i],
              'isAvailable': false,
              'isBooked': true,
              'patientId': patientId,
              'patientName': patientName,
              'carerId': carerId,
              'appointmentType': appointmentType,
              'notes': notes ?? '',
              'bookedAt': FieldValue.serverTimestamp(),
              'isRecurring': isRecurring,
              'recurringGroupId': recurringGroupId,
              'status':
                  'scheduled', // 'scheduled', 'confirmed', 'completed', 'cancelled'
            };
            slotFound = true;
            break;
          }
        }

        if (!slotFound) {
          throw Exception('Time slot not found');
        }

        daySchedule['timeSlots'] = timeSlots;
        weeklySchedule[day] = daySchedule;

        // Update statistics
        final updatedStats = _calculateStatistics(weeklySchedule);

        transaction.update(docRef, {
          'weeklySchedule': weeklySchedule,
          'statistics': updatedStats,
          'updatedAt': FieldValue.serverTimestamp(),
          'lastModifiedBy': patientId,
        });
      });

      print('Time slot booked successfully');
    } catch (e) {
      print('Error booking time slot: $e');
      throw Exception('Failed to book time slot: $e');
    }
  }

  /// Cancel a booking
  static Future<void> cancelBooking({
    required String therapistId,
    required String day,
    required String slotId,
    required String cancellationReason,
    required String cancelledBy, // User ID who cancelled
  }) async {
    try {
      final docRef = _firestore.collection(COLLECTION_NAME).doc(therapistId);

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);

        if (!doc.exists) {
          throw Exception('Schedule not found');
        }

        final data = Map<String, dynamic>.from(doc.data()!);
        final weeklySchedule =
            Map<String, dynamic>.from(data['weeklySchedule']);
        final daySchedule = Map<String, dynamic>.from(weeklySchedule[day]);
        final timeSlots =
            List<Map<String, dynamic>>.from(daySchedule['timeSlots']);

        // Find and update the specific slot
        bool slotFound = false;
        for (int i = 0; i < timeSlots.length; i++) {
          if (timeSlots[i]['slotId'] == slotId) {
            timeSlots[i] = {
              ...timeSlots[i],
              'isAvailable': true,
              'isBooked': false,
              'patientId': null,
              'patientName': null,
              'carerId': null,
              'appointmentType': 'therapy',
              'notes': '',
              'status': 'cancelled',
              'cancelledAt': FieldValue.serverTimestamp(),
              'cancellationReason': cancellationReason,
              'cancelledBy': cancelledBy,
            };
            slotFound = true;
            break;
          }
        }

        if (!slotFound) {
          throw Exception('Booking not found');
        }

        daySchedule['timeSlots'] = timeSlots;
        weeklySchedule[day] = daySchedule;

        // Update statistics
        final updatedStats = _calculateStatistics(weeklySchedule);

        transaction.update(docRef, {
          'weeklySchedule': weeklySchedule,
          'statistics': updatedStats,
          'updatedAt': FieldValue.serverTimestamp(),
          'lastModifiedBy': cancelledBy,
        });
      });

      print('Booking cancelled successfully');
    } catch (e) {
      print('Error cancelling booking: $e');
      throw Exception('Failed to cancel booking: $e');
    }
  }

  /// Get available time slots for a specific day
  static Future<List<Map<String, dynamic>>> getAvailableSlots({
    required String therapistId,
    required String day,
  }) async {
    try {
      final schedule = await loadSchedule(therapistId);
      if (schedule == null) return [];

      final weeklySchedule =
          schedule['weeklySchedule'] as Map<String, dynamic>?;
      if (weeklySchedule == null) return [];

      final daySchedule = weeklySchedule[day] as Map<String, dynamic>?;
      if (daySchedule == null || daySchedule['isWorkingDay'] != true) return [];

      final timeSlots = daySchedule['timeSlots'] as List<dynamic>? ?? [];

      return timeSlots
          .where((slot) =>
              slot['isAvailable'] == true && slot['isBooked'] == false)
          .map((slot) => Map<String, dynamic>.from(slot))
          .toList();
    } catch (e) {
      print('Error getting available slots: $e');
      return [];
    }
  }

  /// Get today's appointments for a therapist
  static Future<List<Map<String, dynamic>>> getTodaysAppointments(
      String therapistId) async {
    try {
      final today = DateTime.now();
      final dayName = _getDayName(today.weekday).toLowerCase();

      final schedule = await loadSchedule(therapistId);
      if (schedule == null) return [];

      final weeklySchedule =
          schedule['weeklySchedule'] as Map<String, dynamic>?;
      if (weeklySchedule == null) return [];

      final daySchedule = weeklySchedule[dayName] as Map<String, dynamic>?;
      if (daySchedule == null) return [];

      final timeSlots = daySchedule['timeSlots'] as List<dynamic>? ?? [];

      return timeSlots
          .where((slot) => slot['isBooked'] == true)
          .map((slot) => Map<String, dynamic>.from(slot))
          .toList();
    } catch (e) {
      print('Error getting today\'s appointments: $e');
      return [];
    }
  }

  /// Add an exception date (holiday, vacation, etc.)
  static Future<void> addException({
    required String therapistId,
    required DateTime date,
    required String type, // 'holiday', 'vacation', 'sick', 'custom'
    required String reason,
    bool isWorkingDay = false,
    Map<String, dynamic>? customSchedule,
  }) async {
    try {
      final docRef = _firestore.collection(COLLECTION_NAME).doc(therapistId);

      final exception = {
        'date': Timestamp.fromDate(date),
        'type': type,
        'reason': reason,
        'isWorkingDay': isWorkingDay,
        'customSchedule': customSchedule,
        'addedAt': FieldValue.serverTimestamp(),
      };

      await docRef.update({
        'exceptions': FieldValue.arrayUnion([exception]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('Exception added successfully');
    } catch (e) {
      print('Error adding exception: $e');
      throw Exception('Failed to add exception: $e');
    }
  }

  /// Calculate statistics from weekly schedule
  static Map<String, dynamic> _calculateStatistics(
      Map<String, dynamic> weeklySchedule) {
    int totalSlots = 0;
    int bookedSlots = 0;
    int workingDays = 0;
    Set<String> uniquePatients = {};

    weeklySchedule.forEach((day, dayData) {
      if (dayData['isWorkingDay'] == true) {
        workingDays++;
        List<dynamic> timeSlots = dayData['timeSlots'] ?? [];
        totalSlots += timeSlots.length;

        for (var slot in timeSlots) {
          if (slot['isBooked'] == true) {
            bookedSlots++;
            final patientId = slot['patientId'];
            if (patientId != null && patientId.toString().isNotEmpty) {
              uniquePatients.add(patientId);
            }
          }
        }
      }
    });

    final availableSlots = totalSlots - bookedSlots;
    final bookingRate = totalSlots > 0 ? (bookedSlots / totalSlots * 100) : 0.0;

    return {
      'totalSlots': totalSlots,
      'bookedSlots': bookedSlots,
      'availableSlots': availableSlots,
      'workingDays': workingDays,
      'totalPatients': uniquePatients.length,
      'bookingRate': bookingRate.round(),
      'averageSlotsPerDay':
          workingDays > 0 ? (totalSlots / workingDays).round() : 0,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }

  /// Helper method to get day name from weekday number
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

  /// Get current therapist ID from shared preferences
  static Future<String?> getCurrentTherapistId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('clinic_id') ?? prefs.getString('user_id');
    } catch (e) {
      print('Error getting therapist ID: $e');
      return null;
    }
  }

  /// Stream to listen for real-time schedule updates
  static Stream<DocumentSnapshot> getScheduleStream(String therapistId) {
    return _firestore.collection(COLLECTION_NAME).doc(therapistId).snapshots();
  }

  /// Search for available therapists by specialization and time
  static Future<List<Map<String, dynamic>>> findAvailableTherapists({
    required String day,
    required String timeSlot,
    List<String>? specializations,
  }) async {
    try {
      Query query = _firestore.collection(COLLECTION_NAME);

      // Add filters
      query = query.where('isActive', isEqualTo: true);
      query = query.where('isPublished', isEqualTo: true);

      final querySnapshot = await query.get();
      List<Map<String, dynamic>> availableTherapists = [];

      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final weeklySchedule = data['weeklySchedule'] as Map<String, dynamic>?;

        if (weeklySchedule != null) {
          final daySchedule =
              weeklySchedule[day.toLowerCase()] as Map<String, dynamic>?;

          if (daySchedule != null && daySchedule['isWorkingDay'] == true) {
            final timeSlots = daySchedule['timeSlots'] as List<dynamic>? ?? [];

            // Check if requested time slot is available
            bool hasAvailableSlot = timeSlots.any((slot) =>
                slot['startTime'] == timeSlot &&
                slot['isAvailable'] == true &&
                slot['isBooked'] == false);

            if (hasAvailableSlot) {
              availableTherapists.add({
                'therapistId': doc.id,
                'scheduleData': data,
              });
            }
          }
        }
      }

      return availableTherapists;
    } catch (e) {
      print('Error finding available therapists: $e');
      return [];
    }
  }
}
