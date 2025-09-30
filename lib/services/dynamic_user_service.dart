import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Dynamic User ID Service
/// Manages user identification based on database document IDs
/// No more static IDs - all IDs come from actual Firebase documents
class DynamicUserService {
  /// Get current user's dynamic ID based on their document in Firebase
  /// For clinic users: returns their document ID from ClinicAcc collection
  /// For parent users: returns their document ID from ParentsAcc collection
  static Future<String?> getCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userType = prefs.getString('user_type');
      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;

      print(
          'DynamicUserService: user_type = $userType, is_logged_in = $isLoggedIn');

      if (!isLoggedIn) {
        print('DynamicUserService: User not logged in');
        return null;
      }

      String? userId;

      if (userType == 'clinic') {
        // For clinic users, get from clinic_id (their document ID in ClinicAcc)
        userId = prefs.getString('clinic_id');
        print('DynamicUserService: Clinic user ID = $userId');

        // Validate this ID exists in ClinicAcc collection
        if (userId != null) {
          final isValid = await _validateClinicId(userId);
          if (!isValid) {
            print(
                'DynamicUserService: Clinic ID $userId not found in database');
            return null;
          }
        }
      } else if (userType == 'parent') {
        // For parent users, get from user_id (their document ID in ParentsAcc)
        userId = prefs.getString('user_id');
        print('DynamicUserService: Parent user ID = $userId');

        // Validate this ID exists in ParentsAcc collection
        if (userId != null) {
          final isValid = await _validateParentId(userId);
          if (!isValid) {
            print(
                'DynamicUserService: Parent ID $userId not found in database');
            return null;
          }
        }
      }

      return userId;
    } catch (e) {
      print('DynamicUserService: Error getting user ID: $e');
      return null;
    }
  }

  /// Get user info (name, type) for display purposes
  static Future<Map<String, dynamic>?> getCurrentUserInfo() async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) return null;

      final prefs = await SharedPreferences.getInstance();
      final userType = prefs.getString('user_type');

      if (userType == 'clinic') {
        final doc = await FirebaseFirestore.instance
            .collection('ClinicAcc')
            .doc(userId)
            .get();

        if (doc.exists) {
          final data = doc.data()!;
          return {
            'id': userId,
            'name':
                data['Clinic_Name'] ?? data['Clinic Name'] ?? 'Unknown Clinic',
            'type': 'clinic',
            'email': data['email'],
          };
        }
      } else if (userType == 'parent') {
        final doc = await FirebaseFirestore.instance
            .collection('ParentsAcc')
            .doc(userId)
            .get();

        if (doc.exists) {
          final data = doc.data()!;
          return {
            'id': userId,
            'name': data['Name'] ?? 'Unknown Parent',
            'type': 'parent',
            'email': data['Email'],
          };
        }
      }

      return null;
    } catch (e) {
      print('DynamicUserService: Error getting user info: $e');
      return null;
    }
  }

  /// Get target user info for call display
  static Future<Map<String, dynamic>?> getTargetUserInfo(
      String targetUserId) async {
    try {
      // Try clinic collection first
      final clinicDoc = await FirebaseFirestore.instance
          .collection('ClinicAcc')
          .doc(targetUserId)
          .get();

      if (clinicDoc.exists) {
        final data = clinicDoc.data()!;
        return {
          'id': targetUserId,
          'name':
              data['Clinic_Name'] ?? data['Clinic Name'] ?? 'Unknown Clinic',
          'type': 'clinic',
          'email': data['email'],
        };
      }

      // Try parent collection
      final parentDoc = await FirebaseFirestore.instance
          .collection('ParentsAcc')
          .doc(targetUserId)
          .get();

      if (parentDoc.exists) {
        final data = parentDoc.data()!;
        return {
          'id': targetUserId,
          'name': data['Name'] ?? 'Unknown Parent',
          'type': 'parent',
          'email': data['Email'],
        };
      }

      return null;
    } catch (e) {
      print('DynamicUserService: Error getting target user info: $e');
      return null;
    }
  }

  /// Validate clinic ID exists in database
  static Future<bool> _validateClinicId(String clinicId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('ClinicAcc')
          .doc(clinicId)
          .get();
      return doc.exists;
    } catch (e) {
      print('DynamicUserService: Error validating clinic ID: $e');
      return false;
    }
  }

  /// Validate parent ID exists in database
  static Future<bool> _validateParentId(String parentId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('ParentsAcc')
          .doc(parentId)
          .get();
      return doc.exists;
    } catch (e) {
      print('DynamicUserService: Error validating parent ID: $e');
      return false;
    }
  }

  /// Clear static fallbacks - forces dynamic ID resolution
  static Future<void> clearStaticFallbacks() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Remove any static fallback IDs
      final keysToRemove = [
        'static_clinic_id',
        'static_parent_id',
        'fallback_id'
      ];
      for (String key in keysToRemove) {
        await prefs.remove(key);
      }

      print('DynamicUserService: Cleared static fallbacks');
    } catch (e) {
      print('DynamicUserService: Error clearing static fallbacks: $e');
    }
  }

  /// Debug method to show current user context
  static Future<void> debugUserContext() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      print('=== DYNAMIC USER CONTEXT DEBUG ===');
      print('Available keys: $keys');
      print('user_type: ${prefs.getString('user_type')}');
      print('is_logged_in: ${prefs.getBool('is_logged_in')}');
      print('clinic_id: ${prefs.getString('clinic_id')}');
      print('user_id: ${prefs.getString('user_id')}');

      final currentUser = await getCurrentUserInfo();
      print('Current user info: $currentUser');
      print('=================================');
    } catch (e) {
      print('DynamicUserService: Debug error: $e');
    }
  }

  /// Debug method to check current authentication state
  static Future<void> debugAuthState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      print('=== DYNAMIC USER SERVICE DEBUG ===');
      print('SharedPreferences contents:');
      print('  user_type: ${prefs.getString('user_type')}');
      print('  clinic_id: ${prefs.getString('clinic_id')}');
      print('  user_id: ${prefs.getString('user_id')}');
      print('  is_logged_in: ${prefs.getBool('is_logged_in')}');
      print('  clinic_email: ${prefs.getString('clinic_email')}');
      print('  user_email: ${prefs.getString('user_email')}');

      final userId = await getCurrentUserId();
      final userInfo = await getCurrentUserInfo();

      print('DynamicUserService results:');
      print('  getCurrentUserId(): $userId');
      print('  getCurrentUserInfo(): $userInfo');
      print('=== END DEBUG ===');
    } catch (e) {
      print('Error in debugAuthState: $e');
    }
  }
}
