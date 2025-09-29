import 'package:shared_preferences/shared_preferences.dart';

/// Utility class for common call service functionality
/// Removes duplicate code across call services
class CallUtility {
  /// Get current user ID from SharedPreferences
  /// Works for both parents (user_id) and clinics (clinic_id)
  static Future<String?> getCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Try different storage keys
      String? userId = prefs.getString('user_id'); // For parents
      if (userId == null) {
        userId = prefs.getString('clinic_id'); // For clinics
      }

      return userId;
    } catch (e) {
      print('CallUtility: Error getting user ID: $e');
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
    // Don't show call if user is the caller
    if (callerId == currentUserId) return false;
    if (createdBy == currentUserId) return false;

    return true;
  }

  /// Print standardized log messages
  static void log(String service, String message) {
    print('$service: $message');
  }
}
