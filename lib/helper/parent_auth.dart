import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ParentAuthService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // SharedPreferences keys
  static const String _userIdKey = 'user_id';
  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';
  static const String _userPhoneKey = 'user_phone';
  static const String _userTypeKey = 'user_type';
  static const String _isLoggedInKey = 'is_logged_in';

  /// Sign in parent user with email and password
  /// Checks ParentsReg collection, then moves data to ParentsAcc if successful
  static Future<Map<String, dynamic>?> signInParent({
    required String email,
    required String password,
  }) async {
    try {
      // First, check if parent already exists in ParentsAcc collection (already active)
      final QuerySnapshot existingAccQuery = await _firestore
          .collection('ParentsAcc')
          .where('Email', isEqualTo: email.trim())
          .limit(1)
          .get();

      if (existingAccQuery.docs.isNotEmpty) {
        // Parent already has active account in ParentsAcc
        final accDoc = existingAccQuery.docs.first;
        final accData = accDoc.data() as Map<String, dynamic>;
        final accDocumentId = accDoc.id; // e.g., 'PARAcc01'

        // Check password
        final storedPassword = accData['Password']?.toString() ?? '';
        if (storedPassword != password) {
          throw 'Invalid email or password.';
        }

        // Update last login time
        await _firestore.collection('ParentsAcc').doc(accDocumentId).update({
          'lastLoginAt': FieldValue.serverTimestamp(),
        });

        // Store parent info in local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userIdKey, accDocumentId);
        await prefs.setString(
            _userNameKey, accData['Name'] ?? ''); // From ParentsAcc
        await prefs.setString(_userEmailKey, email.trim());
        await prefs.setString(_userPhoneKey, accData['Contact_Number'] ?? '');
        await prefs.setString(
            _userTypeKey, 'parent'); // CRITICAL: Set user type
        await prefs.setBool(_isLoggedInKey, true);

        print(
            'ParentAuthService: Successfully signed in existing parent: $accDocumentId');
        print('ParentAuthService: Stored user_id: $accDocumentId');
        print('ParentAuthService: Stored user_name: ${accData['Name']}');
        print('ParentAuthService: Stored user_type: parent');

        return {
          'success': true,
          'documentId': accDocumentId,
          'userData': accData,
        };
      }

      // If not in ParentsAcc, check ParentsReg collection for new registrations
      final QuerySnapshot parentQuery = await _firestore
          .collection('ParentsReg')
          .where('Email', isEqualTo: email.trim())
          .limit(1)
          .get();

      if (parentQuery.docs.isEmpty) {
        throw 'No parent account found with this email address.';
      }

      final parentDoc = parentQuery.docs.first;
      final parentData = parentDoc.data() as Map<String, dynamic>;
      final regDocumentId = parentDoc.id; // e.g., 'PARReg01'

      // Check password
      final storedPassword = parentData['Password']?.toString() ?? '';
      if (storedPassword != password) {
        throw 'Invalid email or password.';
      }

      // Check password from ParentsReg
      final regStoredPassword = parentData['Password']?.toString() ?? '';
      if (regStoredPassword != password) {
        throw 'Invalid email or password.';
      }

      // Generate ParentsAcc document ID based on registration ID
      String accDocumentId = regDocumentId.replaceFirst('PARReg', 'PARAcc');

      // Move/copy data from ParentsReg to ParentsAcc with correct field mapping
      await _firestore.collection('ParentsAcc').doc(accDocumentId).set({
        'Name': parentData[
            'Full_Name'], // ParentsReg uses 'Full_Name', ParentsAcc uses 'Name'
        'User_Name': parentData['User_Name'],
        'Email': parentData['Email'],
        'Contact_Number': parentData['Contact_Number'],
        'Address': parentData['Address'],
        'Password': parentData['Password'],
        'createdAt': parentData['createdAt'] ?? FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });

      // Store parent info in local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userIdKey, accDocumentId);
      await prefs.setString(
          _userNameKey, parentData['Full_Name'] ?? ''); // From ParentsReg
      await prefs.setString(_userEmailKey, email.trim());
      await prefs.setString(_userPhoneKey, parentData['Contact_Number'] ?? '');
      await prefs.setString(_userTypeKey, 'parent'); // CRITICAL: Set user type
      await prefs.setBool(_isLoggedInKey, true);

      print(
          'ParentAuthService: Successfully signed in parent from registration: $accDocumentId');
      print('ParentAuthService: Stored user_id: $accDocumentId');
      print('ParentAuthService: Stored user_name: ${parentData['Full_Name']}');
      print('ParentAuthService: Stored user_type: parent');

      return {
        'success': true,
        'documentId': accDocumentId,
        'userData': parentData,
      };
    } catch (e) {
      throw 'Error signing in parent: $e';
    }
  }

  /// Clear all stored authentication data and logout the parent user
  static Future<void> signOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Clear all authentication-related data
      await prefs.remove('user_id');
      await prefs.remove('user_name');
      await prefs.remove('user_email');
      await prefs.remove('user_phone');
      await prefs.remove('user_type');
      await prefs.setBool('is_logged_in', false);

      // Clear any potential fallback IDs to prevent conflicts
      await prefs.remove('parent_id');
      await prefs.remove('current_user_id');
      await prefs.remove('userId');
      await prefs.remove('static_parent_id');
      await prefs.remove('fallback_id');

      // Clear clinic data to prevent cross-user conflicts
      await prefs.remove('clinic_id');
      await prefs.remove('clinic_email');
      await prefs.remove('static_clinic_id');

      print(
          'ParentAuthService: Successfully cleared all authentication data and potential ID conflicts');
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
