import 'package:kindora/services/dynamic_user_service.dart';

/// User ID Validation Service
/// Ensures all user IDs are valid before operations
class UserIdValidator {
  /// Validate that a user ID is not empty and exists in database
  static Future<bool> isValidUserId(String? userId) async {
    if (userId == null || userId.isEmpty) {
      return false;
    }

    final userInfo = await DynamicUserService.getTargetUserInfo(userId);
    return userInfo != null;
  }

  /// Get a safe user ID with fallback to current user
  static Future<String?> getSafeUserId(String? providedUserId) async {
    // First try the provided ID
    if (await isValidUserId(providedUserId)) {
      return providedUserId;
    }

    // Fallback to current user ID
    final currentUserId = await DynamicUserService.getCurrentUserId();
    if (await isValidUserId(currentUserId)) {
      return currentUserId;
    }

    // No valid ID found
    return null;
  }

  /// Validate that two user IDs are different (prevent self-calling)
  static bool areDifferentUsers(String? userId1, String? userId2) {
    if (userId1 == null || userId2 == null) return false;
    if (userId1.isEmpty || userId2.isEmpty) return false;
    return userId1 != userId2;
  }

  /// Get error message for invalid user scenario
  static String getValidationError(
      String? currentUserId, String? targetUserId) {
    if (currentUserId == null || currentUserId.isEmpty) {
      return 'Current user not identified. Please log in again.';
    }

    if (targetUserId == null || targetUserId.isEmpty) {
      return 'Target user not specified. Please select a user to call.';
    }

    if (currentUserId == targetUserId) {
      return 'Cannot call yourself.';
    }

    return 'Invalid user configuration.';
  }
}
