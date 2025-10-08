import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to handle accepted bookings and time slot reservations
class AcceptedBookingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String ACCEPTED_COLLECTION = 'AcceptedBooking';
  static const String RESERVED_SLOTS_COLLECTION = 'ReservedTimeSlots';

  /// Move approved request to AcceptedBooking collection and reserve time slot
  static Future<String> acceptBookingRequest({
    required String requestId,
    required Map<String, dynamic> requestData,
    required String approvedById,
    String? assignedTherapistId,
  }) async {
    try {
      final batch = _firestore.batch();

      // Create accepted booking document
      final acceptedBookingRef =
          _firestore.collection(ACCEPTED_COLLECTION).doc();
      final bookingId = acceptedBookingRef.id;

      // Prepare accepted booking data
      final acceptedBookingData = {
        // === BOOKING METADATA ===
        'bookingId': bookingId,
        'originalRequestId': requestId,
        'status': 'confirmed', // confirmed, completed, cancelled, rescheduled
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'bookingType': 'single_session',

        // === PATIENT INFORMATION ===
        'patientInfo': {
          'parentId': requestData['parentInfo']['parentId'],
          'parentName': requestData['parentInfo']['parentName'],
          'parentPhone': requestData['parentInfo']['parentPhone'],
          'parentEmail': requestData['parentInfo']['parentEmail'],
          'childName': requestData['childInfo']['childName'],
          'childAge': requestData['childInfo']['childAge'],
          'childGender': requestData['childInfo']['childGender'],
        },

        // === APPOINTMENT DETAILS ===
        'appointmentDetails': {
          'appointmentDate': requestData['appointmentDetails']['requestedDate'],
          'appointmentTime': requestData['appointmentDetails']['requestedTime'],
          'appointmentType': requestData['appointmentDetails']
              ['appointmentType'],
          'duration': requestData['appointmentDetails']['duration'] ?? 60,
          'sessionType':
              requestData['appointmentDetails']['sessionType'] ?? 'individual',
          'timeSlotId': requestData['appointmentDetails']['timeSlotId'],
        },

        // === CLINIC/THERAPIST ASSIGNMENT ===
        'assignmentInfo': {
          'clinicId': requestData['clinicInfo']['clinicId'],
          'therapistId':
              assignedTherapistId ?? requestData['clinicInfo']['therapistId'],
          'assignedBy': approvedById,
          'assignedAt': FieldValue.serverTimestamp(),
          'roomNumber': null, // To be assigned by clinic
          'specialInstructions': requestData['additionalInfo']['notes'] ?? '',
        },

        // === BOOKING SOURCE ===
        'bookingSource': {
          'requestedVia': 'mobile_app',
          'requestedBy': requestData['parentInfo']['parentId'],
          'requestedAt': requestData['createdAt'],
          'approvedBy': approvedById,
          'approvedAt': FieldValue.serverTimestamp(),
        },

        // === CONVENIENCE FIELDS FOR QUERYING ===
        'parentName': requestData['parentInfo']['parentName'],
        'childName': requestData['childInfo']['childName'],
        'appointmentDate': requestData['appointmentDetails']['requestedDate'],
        'appointmentTime': requestData['appointmentDetails']['requestedTime'],
        'appointmentType': requestData['appointmentDetails']['appointmentType'],
        'clinicId': requestData['clinicInfo']['clinicId'],
        'therapistId':
            assignedTherapistId ?? requestData['clinicInfo']['therapistId'],

        // Date strings for easy filtering
        'dateString': _formatDateForQuery(
            (requestData['appointmentDetails']['requestedDate'] as Timestamp)
                .toDate()),
        'dayOfWeek': _getDayOfWeek(
            (requestData['appointmentDetails']['requestedDate'] as Timestamp)
                .toDate()),
      };

      // Add to AcceptedBooking collection
      batch.set(acceptedBookingRef, acceptedBookingData);

      // Reserve the time slot
      await _reserveTimeSlot(
        batch: batch,
        clinicId: requestData['clinicInfo']['clinicId'],
        therapistId:
            assignedTherapistId ?? requestData['clinicInfo']['therapistId'],
        date: (requestData['appointmentDetails']['requestedDate'] as Timestamp)
            .toDate(),
        timeSlot: requestData['appointmentDetails']['requestedTime'],
        timeSlotId: requestData['appointmentDetails']['timeSlotId'],
        bookingId: bookingId,
        patientInfo: acceptedBookingData['patientInfo'] as Map<String, dynamic>,
      );

      // Update original request status
      final requestRef = _firestore.collection('Request').doc(requestId);
      batch.update(requestRef, {
        'status': 'approved',
        'updatedAt': FieldValue.serverTimestamp(),
        'processingInfo.approvedBy': approvedById,
        'processingInfo.approvedAt': FieldValue.serverTimestamp(),
        'acceptedBookingId': bookingId,
      });

      // Commit all changes
      await batch.commit();

      print('Booking accepted successfully. Booking ID: $bookingId');
      return bookingId;
    } catch (e) {
      print('Error accepting booking request: $e');
      throw Exception('Failed to accept booking: $e');
    }
  }

  /// Reserve a time slot to prevent double booking
  static Future<void> _reserveTimeSlot({
    required WriteBatch batch,
    required String clinicId,
    required String? therapistId,
    required DateTime date,
    required String timeSlot,
    required String timeSlotId,
    required String bookingId,
    required Map<String, dynamic> patientInfo,
  }) async {
    final reservedSlotRef =
        _firestore.collection(RESERVED_SLOTS_COLLECTION).doc();

    final reservationData = {
      'reservationId': reservedSlotRef.id,
      'clinicId': clinicId,
      'therapistId': therapistId,
      'date': Timestamp.fromDate(date),
      'timeSlot': timeSlot,
      'timeSlotId': timeSlotId,
      'bookingId': bookingId,
      'patientInfo': patientInfo,
      'status': 'reserved', // reserved, completed, cancelled
      'reservedAt': FieldValue.serverTimestamp(),
      'dateString': _formatDateForQuery(date),
      'dayOfWeek': _getDayOfWeek(date),
    };

    batch.set(reservedSlotRef, reservationData);
  }

  /// Check if a time slot is available
  static Future<bool> isTimeSlotAvailable({
    required String clinicId,
    required String? therapistId,
    required DateTime date,
    required String timeSlot,
  }) async {
    try {
      Query query = _firestore
          .collection(RESERVED_SLOTS_COLLECTION)
          .where('clinicId', isEqualTo: clinicId)
          .where('date', isEqualTo: Timestamp.fromDate(date))
          .where('timeSlot', isEqualTo: timeSlot)
          .where('status', isEqualTo: 'reserved');

      if (therapistId != null) {
        query = query.where('therapistId', isEqualTo: therapistId);
      }

      final snapshot = await query.get();
      return snapshot.docs.isEmpty;
    } catch (e) {
      print('Error checking time slot availability: $e');
      return false; // Assume not available on error for safety
    }
  }

  /// Get accepted bookings for a clinic
  static Stream<QuerySnapshot> getAcceptedBookingsForClinic({
    required String clinicId,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) {
    Query query = _firestore
        .collection(ACCEPTED_COLLECTION)
        .where('clinicId', isEqualTo: clinicId);

    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    if (startDate != null) {
      query = query.where('appointmentDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }

    if (endDate != null) {
      query = query.where('appointmentDate',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }

    return query.orderBy('appointmentDate').snapshots();
  }

  /// Get today's accepted bookings for a clinic
  static Stream<QuerySnapshot> getTodaysBookingsForClinic({
    required String clinicId,
  }) {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

    return _firestore
        .collection(ACCEPTED_COLLECTION)
        .where('clinicId', isEqualTo: clinicId)
        .where('appointmentDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('appointmentDate',
            isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .where('status', whereIn: ['confirmed', 'in_progress'])
        .orderBy('appointmentDate')
        .orderBy('appointmentTime')
        .snapshots();
  }

  /// Get accepted bookings for a specific therapist
  static Stream<QuerySnapshot> getTherapistBookings({
    required String therapistId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    Query query = _firestore
        .collection(ACCEPTED_COLLECTION)
        .where('therapistId', isEqualTo: therapistId);

    if (startDate != null) {
      query = query.where('appointmentDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }

    if (endDate != null) {
      query = query.where('appointmentDate',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }

    return query.orderBy('appointmentDate').snapshots();
  }

  /// Cancel a booking and free up the time slot
  static Future<void> cancelBooking({
    required String bookingId,
    required String cancelledBy,
    String? cancellationReason,
  }) async {
    try {
      final batch = _firestore.batch();

      // Update booking status
      final bookingRef =
          _firestore.collection(ACCEPTED_COLLECTION).doc(bookingId);
      batch.update(bookingRef, {
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
        'cancellationInfo': {
          'cancelledBy': cancelledBy,
          'cancelledAt': FieldValue.serverTimestamp(),
          'reason': cancellationReason ?? 'User cancelled',
        },
      });

      // Free up the reserved time slot
      final reservedSlotsQuery = await _firestore
          .collection(RESERVED_SLOTS_COLLECTION)
          .where('bookingId', isEqualTo: bookingId)
          .get();

      for (final doc in reservedSlotsQuery.docs) {
        batch.update(doc.reference, {
          'status': 'cancelled',
          'cancelledAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      print('Booking cancelled successfully');
    } catch (e) {
      print('Error cancelling booking: $e');
      throw Exception('Failed to cancel booking: $e');
    }
  }

  /// Helper method to format date for queries
  static String _formatDateForQuery(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Helper method to get day of week
  static String _getDayOfWeek(DateTime date) {
    const days = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday'
    ];
    return days[date.weekday % 7];
  }

  /// Get current clinic ID
  static Future<String?> getCurrentClinicId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('clinic_id');
    } catch (e) {
      print('Error getting clinic ID: $e');
      return null;
    }
  }
}
