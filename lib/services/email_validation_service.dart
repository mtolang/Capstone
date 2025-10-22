import 'package:cloud_firestore/cloud_firestore.dart';

class EmailValidationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check if email already exists in any of the account collections
  /// Returns true if email is available (not found in any collection)
  /// Returns false if email already exists
  static Future<bool> isEmailAvailable(String email) async {
    try {
      final String normalizedEmail = email.trim().toLowerCase();
      
      // Check in ParentAcc collection
      final parentQuery = await _firestore
          .collection('ParentAcc')
          .where('Email', isEqualTo: normalizedEmail)
          .limit(1)
          .get();
      
      if (parentQuery.docs.isNotEmpty) {
        return false; // Email found in ParentAcc
      }

      // Check in ClinicAcc collection
      final clinicQuery = await _firestore
          .collection('ClinicAcc')
          .where('Email', isEqualTo: normalizedEmail)
          .limit(1)
          .get();
      
      if (clinicQuery.docs.isNotEmpty) {
        return false; // Email found in ClinicAcc
      }

      // Check in TherapistAcc collection
      final therapistQuery = await _firestore
          .collection('TherapistAcc')
          .where('Email', isEqualTo: normalizedEmail)
          .limit(1)
          .get();
      
      if (therapistQuery.docs.isNotEmpty) {
        return false; // Email found in TherapistAcc
      }

      // Also check TherAcc collection as backup
      final therQuery = await _firestore
          .collection('TherAcc')
          .where('Email', isEqualTo: normalizedEmail)
          .limit(1)
          .get();
      
      if (therQuery.docs.isNotEmpty) {
        return false; // Email found in TherAcc
      }

      return true; // Email is available
    } catch (e) {
      print('Error checking email availability: $e');
      // In case of error, allow registration but log the error
      return true;
    }
  }

  /// Get which collection type the email belongs to
  /// Returns null if email is not found
  static Future<String?> getEmailAccountType(String email) async {
    try {
      final String normalizedEmail = email.trim().toLowerCase();
      
      // Check in ParentAcc collection
      final parentQuery = await _firestore
          .collection('ParentAcc')
          .where('Email', isEqualTo: normalizedEmail)
          .limit(1)
          .get();
      
      if (parentQuery.docs.isNotEmpty) {
        return 'Parent Account';
      }

      // Check in ClinicAcc collection
      final clinicQuery = await _firestore
          .collection('ClinicAcc')
          .where('Email', isEqualTo: normalizedEmail)
          .limit(1)
          .get();
      
      if (clinicQuery.docs.isNotEmpty) {
        return 'Clinic Account';
      }

      // Check in TherapistAcc collection
      final therapistQuery = await _firestore
          .collection('TherapistAcc')
          .where('Email', isEqualTo: normalizedEmail)
          .limit(1)
          .get();
      
      if (therapistQuery.docs.isNotEmpty) {
        return 'Therapist Account';
      }

      // Also check TherAcc collection as backup
      final therQuery = await _firestore
          .collection('TherAcc')
          .where('Email', isEqualTo: normalizedEmail)
          .limit(1)
          .get();
      
      if (therQuery.docs.isNotEmpty) {
        return 'Therapist Account';
      }

      return null; // Email not found
    } catch (e) {
      print('Error getting email account type: $e');
      return null;
    }
  }

  /// Validate email format
  static bool isValidEmailFormat(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email.trim());
  }
}