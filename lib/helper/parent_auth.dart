import 'package:shared_preferences/shared_preferences.dart';

class ParentAuthService {
  /// Clear all stored authentication data and logout the parent user
  static Future<void> signOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Clear all authentication-related data
      await prefs.remove('user_id');
      await prefs.remove('user_name');
      await prefs.remove('user_email');
      await prefs.remove('user_type');
      await prefs.setBool('is_logged_in', false);

      print('ParentAuthService: Successfully cleared all authentication data');
    } catch (e) {
      print('ParentAuthService: Error during logout: $e');
      throw e;
    }
  }

  /// Check if parent user is currently logged in
  static Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      final userType = prefs.getString('user_type');
      final userId = prefs.getString('user_id');

      return isLoggedIn && userType == 'parent' && userId != null;
    } catch (e) {
      print('ParentAuthService: Error checking login status: $e');
      return false;
    }
  }

  /// Get current parent user ID
  static Future<String?> getCurrentParentId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userType = prefs.getString('user_type');

      if (userType == 'parent') {
        return prefs.getString('user_id');
      }
      return null;
    } catch (e) {
      print('ParentAuthService: Error getting parent ID: $e');
      return null;
    }
  }
}
