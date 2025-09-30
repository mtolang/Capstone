import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Utility class for common call service functionality
/// Removes duplicate code across call services
class CallUtility {
  /// Get current user ID from SharedPreferences with enhanced detection
  /// Works for both parents (user_id) and clinics (clinic_id)
  static Future<String?> getCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Debug: Print all available keys
      final keys = prefs.getKeys();
      print('CallUtility: Available SharedPreferences keys: $keys');

      // Check user type first to determine which ID to use
      final currentUserType = prefs.getString('user_type');
      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      print(
          'CallUtility: user_type = $currentUserType, is_logged_in = $isLoggedIn');

      String? userId;

      // Use user type to determine correct ID source
      if (currentUserType == 'clinic' && isLoggedIn) {
        // For clinic users, prioritize clinic_id
        userId = prefs.getString('clinic_id');
        print('CallUtility: clinic_id (for clinic user) = $userId');
      } else if (currentUserType == 'parent' && isLoggedIn) {
        // For parent users, use user_id
        userId = prefs.getString('user_id');
        print('CallUtility: user_id (for parent user) = $userId');
      } else {
        // Fallback: try both if user type is unclear
        print('CallUtility: User type unclear, trying both ID sources...');

        userId = prefs.getString('clinic_id'); // Try clinic first
        print('CallUtility: clinic_id (fallback) = $userId');

        if (userId == null) {
          userId = prefs.getString('user_id'); // Then try parent
          print('CallUtility: user_id (fallback) = $userId');
        }
      }

      if (userId == null) {
        // Try other possible keys as fallback
        userId = prefs.getString('current_user_id');
        print('CallUtility: current_user_id (fallback) = $userId');
      }

      if (userId == null) {
        userId = prefs.getString('userId');
        print('CallUtility: userId (fallback) = $userId');
      }

      // If still null, try to get from login state
      if (userId == null) {
        final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
        final userEmail = prefs.getString('user_email');
        print(
            'CallUtility: Login state - logged in: $isLoggedIn, email: $userEmail');

        if (isLoggedIn && userEmail != null) {
          // Try to find user ID by email in database
          userId = await _findUserIdByEmail(userEmail);
          print('CallUtility: Found user ID by email: $userId');
        }
      }

      print('CallUtility: Final resolved user ID = $userId');

      if (userId == null) {
        print(
            'CallUtility: WARNING - No user ID found in any storage location');
        print('CallUtility: Available keys were: $keys');
      }

      return userId;
    } catch (e) {
      print('CallUtility: ERROR getting user ID: $e');
      return null;
    }
  }

  /// Find user ID by email from database
  static Future<String?> _findUserIdByEmail(String email) async {
    try {
      // Search in ParentsAcc first
      final parentQuery = await FirebaseFirestore.instance
          .collection('ParentsAcc')
          .where('Email', isEqualTo: email)
          .limit(1)
          .get();

      if (parentQuery.docs.isNotEmpty) {
        return parentQuery.docs.first.id;
      }

      // Search in ClinicAcc
      final clinicQuery = await FirebaseFirestore.instance
          .collection('ClinicAcc')
          .where('Email', isEqualTo: email)
          .limit(1)
          .get();

      if (clinicQuery.docs.isNotEmpty) {
        return clinicQuery.docs.first.id;
      }

      return null;
    } catch (e) {
      print('CallUtility: Error finding user by email: $e');
      return null;
    }
  }

  /// Validate if call should be shown to user
  /// Prevents showing calls to the caller themselves
  static bool shouldShowCall({
    required String currentUserId,
    required String callerId,
    String? createdBy,
  }) {
    print(
        'CallUtility: Checking shouldShowCall - Current: $currentUserId, Caller: $callerId, CreatedBy: $createdBy');

    // Don't show call if user is the caller
    if (callerId == currentUserId) {
      print('CallUtility: Blocking call - user is the caller');
      return false;
    }
    if (createdBy != null && createdBy == currentUserId) {
      print('CallUtility: Blocking call - user created the call');
      return false;
    }

    // Additional validation to ensure we have valid IDs
    if (currentUserId.isEmpty || callerId.isEmpty) {
      print('CallUtility: Blocking call - invalid user IDs');
      return false;
    }

    print('CallUtility: Call allowed to show');
    return true;
  }

  /// Print standardized log messages
  static void log(String service, String message) {
    print('$service: $message');
  }
}
