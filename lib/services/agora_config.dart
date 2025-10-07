/// Agora Configuration
class AgoraConfig {
  // Production Agora App ID - Your official App ID (may require token authentication)
  static const String appId = "c1772b57726f495bbc0b7252677c6116";

  // Test App ID for development (allows testing without tokens)
  static const String testAppId =
      "aab8b8f5a8cd4469a63042fcfafe7063"; // Demo App ID

  // For testing purposes, you can use null token
  // For production, implement token generation on your backend for enhanced security
  static const String? tempToken = null;

  /// Returns the App ID to use
  /// Currently using test App ID to troubleshoot connection issues
  /// This test App ID should work without token authentication
  static String getAppId() {
    // For debugging: always return test App ID first
    print('🔑 AgoraConfig: Using test App ID: $testAppId');
    return testAppId;

    // TODO: Switch to production App ID once connection is working
    // return appId; // Your production App ID
  }

  /// For future token-based authentication (optional but recommended for production)
  static String? getToken() {
    return tempToken; // Currently null for testing without tokens
  }
}
