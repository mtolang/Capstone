import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage user session and auto-logout functionality
class SessionManager {
  static DateTime? _lastActivityTime;
  static GlobalKey<NavigatorState>? _navigatorKey;

  /// Initialize the session manager with navigator key
  static void initialize(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
    _lastActivityTime = DateTime.now();
  }

  /// Update user activity to reset the auto-logout timer
  /// Call this method whenever user interacts with the app
  static void updateUserActivity() {
    _lastActivityTime = DateTime.now();
    debugPrint('User activity updated: $_lastActivityTime');
  }

  /// Get the last activity time
  static DateTime? get lastActivityTime => _lastActivityTime;

  /// Get the current auto-logout duration (1 hour)
  static Duration get autoLogoutDuration => const Duration(hours: 1);

  /// Check if user should be logged out due to inactivity
  static bool shouldAutoLogout() {
    if (_lastActivityTime == null) return false;

    final now = DateTime.now();
    final inactiveDuration = now.difference(_lastActivityTime!);
    return inactiveDuration >= autoLogoutDuration;
  }

  /// Check if user is currently in an active call (prevents auto-logout)
  static Future<bool> isUserInActiveCall() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('is_in_call') ?? false;
    } catch (e) {
      debugPrint('Error checking call state: $e');
      return false;
    }
  }

  /// Set the user's call status
  static Future<void> setCallStatus(bool isInCall) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_in_call', isInCall);
      debugPrint('Call status updated: $isInCall');

      // Update activity time when call starts to prevent logout during call
      if (isInCall) {
        updateUserActivity();
      }
    } catch (e) {
      debugPrint('Error setting call status: $e');
    }
  }

  /// Clear all stored user IDs (used during logout)
  static Future<void> clearStoredUserIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove('user_id');
      await prefs.remove('clinic_id');
      await prefs.remove('therapist_id');
      await prefs.remove('parent_id');
      await prefs.remove('current_user_id');
      await prefs.remove('userId');
      await prefs.remove('static_clinic_id');
      await prefs.remove('static_parent_id');
      await prefs.remove('fallback_id');
      await prefs.remove('is_logged_in');
      await prefs.remove('user_type');
      await prefs.remove('is_in_call');

      debugPrint('All stored user IDs cleared successfully');
    } catch (e) {
      debugPrint('Error clearing stored user IDs: $e');
    }
  }

  /// Force logout immediately (can be called from any part of the app)
  static Future<void> forceLogout({String reason = 'Manual logout'}) async {
    try {
      await clearStoredUserIds();

      if (_navigatorKey?.currentContext != null) {
        Navigator.of(_navigatorKey!.currentContext!).pushNamedAndRemoveUntil(
          '/login_as',
          (route) => false,
        );

        ScaffoldMessenger.of(_navigatorKey!.currentContext!).showSnackBar(
          SnackBar(
            content: Text('Logged out: $reason'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      debugPrint('Force logout completed: $reason');
    } catch (e) {
      debugPrint('Error during force logout: $e');
    }
  }
}
