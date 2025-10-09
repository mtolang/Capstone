/// Utility class to manage call states and prevent auto-logout during active calls
class CallStateManager {
  static bool _isCallActive = false;
  static bool _isScreenSharing = false;
  
  /// Check if any call is currently active
  static bool isCallActive() => _isCallActive;
  
  /// Check if screen sharing is active
  static bool isScreenSharing() => _isScreenSharing;
  
  /// Check if user should not be auto-logged out
  /// Returns true if user is in call, screen sharing, or any critical session
  static bool shouldPreventAutoLogout() {
    return _isCallActive || _isScreenSharing;
  }
  
  /// Set call state
  static void setCallActive(bool active) {
    _isCallActive = active;
    print('📞 CallStateManager: Call active state changed to: $active');
  }
  
  /// Set screen sharing state
  static void setScreenSharing(bool sharing) {
    _isScreenSharing = sharing;
    print('📱 CallStateManager: Screen sharing state changed to: $sharing');
  }
  
  /// Reset all states (call this on app restart or major state changes)
  static void resetStates() {
    _isCallActive = false;
    _isScreenSharing = false;
    print('🔄 CallStateManager: All states reset');
  }
  
  /// Get current status for debugging
  static Map<String, bool> getCurrentStatus() {
    return {
      'isCallActive': _isCallActive,
      'isScreenSharing': _isScreenSharing,
      'shouldPreventAutoLogout': shouldPreventAutoLogout(),
    };
  }
}
