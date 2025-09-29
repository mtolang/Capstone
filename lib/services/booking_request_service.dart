import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Comprehensive Booking Request Service
///
/// This service handles saving detailed booking requests to the 'Request' collection
/// for clinic-side organization and management
class BookingRequestService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String COLLECTION_NAME = 'Request';

  /// Save comprehensive booking request to Firebase 'Request' collection
  static Future<String> saveBookingRequest({
    // Parent Information
    required String parentName,
    required String parentPhone,
    required String parentEmail,
    required String parentId,

    // Child Information
    required String childName,
    required int childAge,
    required String childGender,

    // Appointment Information
    required DateTime appointmentDate,
    required String appointmentTime,
    required String timeSlotId,
    required String appointmentType,

    // Additional Information
    String? additionalNotes,

    // Clinic/Therapist Information
    String? clinicId,
    String? therapistId,
  }) async {
    try {
      // Generate a unique request ID
      final requestRef = _firestore.collection(COLLECTION_NAME).doc();
      final requestId = requestRef.id;

      // Prepare comprehensive request data
      final requestData = {
        // === REQUEST METADATA ===
        'requestId': requestId,
        'status': 'pending', // pending, approved, declined, cancelled
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'requestType': 'appointment_booking',
        'priority': 'normal', // normal, urgent, high

        // === PARENT INFORMATION ===
        'parentInfo': {
          'parentId': parentId,
          'parentName': parentName.trim(),
          'parentPhone': parentPhone.trim(),
          'parentEmail': parentEmail.trim().toLowerCase(),
          'role': 'primary_guardian',
        },

        // === CHILD INFORMATION ===
        'childInfo': {
          'childName': childName.trim(),
          'childAge': childAge,
          'childGender': childGender,
          'patientId': null, // Will be assigned if request is approved
        },

        // === APPOINTMENT DETAILS ===
        'appointmentDetails': {
          'requestedDate': Timestamp.fromDate(appointmentDate),
          'requestedTime': appointmentTime,
          'timeSlotId': timeSlotId,
          'appointmentType': appointmentType,
          'duration': 60, // Default 60 minutes
          'sessionType': 'individual', // individual, group
        },

        // === CLINIC/THERAPIST INFORMATION ===
        'clinicInfo': {
          'clinicId': clinicId ?? await _getDefaultClinicId(),
          'therapistId': therapistId,
          'assignedTherapist': null, // Will be assigned by clinic
        },

        // === ADDITIONAL INFORMATION ===
        'additionalInfo': {
          'notes': additionalNotes?.trim() ?? '',
          'specialRequests': [],
          'medicalConditions': [],
          'previousTherapy': false,
          'referralSource': 'parent_app',
        },

        // === SYSTEM INFORMATION ===
        'systemInfo': {
          'platform': 'mobile_app',
          'appVersion': '1.0.0',
          'requestSource': 'parent_booking_form',
          'ipAddress': null,
          'deviceInfo': null,
        },

        // === PROCESSING INFORMATION ===
        'processingInfo': {
          'reviewedBy': null,
          'reviewedAt': null,
          'approvedBy': null,
          'approvedAt': null,
          'declinedBy': null,
          'declinedAt': null,
          'declineReason': null,
          'rescheduleCount': 0,
          'lastRescheduleAt': null,
        },

        // === COMMUNICATION LOG ===
        'communicationLog': [],
        /* Communication log structure:
        {
          'timestamp': Timestamp,
          'type': 'email|sms|phone|in_app',
          'direction': 'outgoing|incoming',
          'recipient': 'parent|clinic|therapist',
          'subject': 'string',
          'message': 'string',
          'status': 'sent|delivered|read|failed',
        }
        */

        // === CONVENIENCE FIELDS FOR QUERYING ===
        'parentName': parentName.trim(),
        'childName': childName.trim(),
        'appointmentDate': Timestamp.fromDate(appointmentDate),
        'appointmentType': appointmentType,
        'requestedDateString': _formatDateForQuery(appointmentDate),
        'requestedTimeString': appointmentTime,
        'ageGroup': _determineAgeGroup(childAge),
        'searchKeywords': _generateSearchKeywords(
          parentName: parentName,
          childName: childName,
          appointmentType: appointmentType,
        ),
      };

      // Save to Firebase
      await requestRef.set(requestData);

      print('Comprehensive booking request saved successfully');
      print('Request ID: $requestId');

      return requestId;
    } catch (e) {
      print('Error saving booking request: $e');
      throw Exception('Failed to save booking request: $e');
    }
  }

  /// Get default clinic ID from SharedPreferences or use fallback
  static Future<String> _getDefaultClinicId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('clinic_id') ?? 'CLI01'; // Fallback to CLI01
    } catch (e) {
      return 'CLI01'; // Default fallback
    }
  }

  /// Format date for easy querying (YYYY-MM-DD)
  static String _formatDateForQuery(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Determine age group for categorization
  static String _determineAgeGroup(int age) {
    if (age <= 3) return 'early_childhood'; // 0-3 years
    if (age <= 6) return 'preschool'; // 4-6 years
    if (age <= 12) return 'school_age'; // 7-12 years
    if (age <= 18) return 'adolescent'; // 13-18 years
    return 'adult'; // 18+ years
  }

  /// Generate search keywords for easy filtering
  static List<String> _generateSearchKeywords({
    required String parentName,
    required String childName,
    required String appointmentType,
  }) {
    final keywords = <String>[];

    // Add parent name parts
    keywords.addAll(parentName.toLowerCase().split(' '));

    // Add child name parts
    keywords.addAll(childName.toLowerCase().split(' '));

    // Add appointment type parts
    keywords.addAll(appointmentType.toLowerCase().split(' '));

    // Remove empty strings and duplicates
    return keywords.where((k) => k.isNotEmpty).toSet().toList();
  }

  /// Get booking requests stream for clinic dashboard
  static Stream<QuerySnapshot> getBookingRequestsStream({
    String? status,
    String? clinicId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    Query query = _firestore.collection(COLLECTION_NAME);

    // Filter by status
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    // Filter by clinic
    if (clinicId != null) {
      query = query.where('clinicInfo.clinicId', isEqualTo: clinicId);
    }

    // Filter by date range
    if (startDate != null) {
      query = query.where('appointmentDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }
    if (endDate != null) {
      query = query.where('appointmentDate',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }

    // Order by creation date (newest first)
    query = query.orderBy('createdAt', descending: true);

    return query.snapshots();
  }

  /// Update request status
  static Future<void> updateRequestStatus({
    required String requestId,
    required String status,
    String? reviewerId,
    String? reason,
  }) async {
    try {
      final updateData = {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Add processing information based on status
      switch (status) {
        case 'approved':
          if (reviewerId != null) {
            updateData['processingInfo.approvedBy'] = reviewerId;
          }
          updateData['processingInfo.approvedAt'] =
              FieldValue.serverTimestamp();
          break;
        case 'declined':
          if (reviewerId != null) {
            updateData['processingInfo.declinedBy'] = reviewerId;
          }
          updateData['processingInfo.declinedAt'] =
              FieldValue.serverTimestamp();
          if (reason != null) {
            updateData['processingInfo.declineReason'] = reason;
          }
          break;
        case 'reviewed':
          if (reviewerId != null) {
            updateData['processingInfo.reviewedBy'] = reviewerId;
          }
          updateData['processingInfo.reviewedAt'] =
              FieldValue.serverTimestamp();
          break;
      }

      await _firestore
          .collection(COLLECTION_NAME)
          .doc(requestId)
          .update(updateData);

      print('Request status updated successfully: $requestId -> $status');
    } catch (e) {
      print('Error updating request status: $e');
      throw Exception('Failed to update request status: $e');
    }
  }

  /// Add communication log entry
  static Future<void> addCommunicationLog({
    required String requestId,
    required String type,
    required String direction,
    required String recipient,
    required String subject,
    required String message,
    String status = 'sent',
  }) async {
    try {
      final logEntry = {
        'timestamp': FieldValue.serverTimestamp(),
        'type': type,
        'direction': direction,
        'recipient': recipient,
        'subject': subject,
        'message': message,
        'status': status,
      };

      await _firestore.collection(COLLECTION_NAME).doc(requestId).update({
        'communicationLog': FieldValue.arrayUnion([logEntry]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('Communication log added successfully');
    } catch (e) {
      print('Error adding communication log: $e');
      throw Exception('Failed to add communication log: $e');
    }
  }

  /// Get request by ID
  static Future<Map<String, dynamic>?> getRequestById(String requestId) async {
    try {
      final doc =
          await _firestore.collection(COLLECTION_NAME).doc(requestId).get();

      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('Error getting request by ID: $e');
      throw Exception('Failed to get request: $e');
    }
  }
}
