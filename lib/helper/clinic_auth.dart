import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ClinicAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Keys for local storage
  static const String _clinicIdKey = 'clinic_id';
  static const String _clinicEmailKey = 'clinic_email';
  static const String _isLoggedInKey = 'is_logged_in';

  // Get current user
  static User? get currentUser => _auth.currentUser;

  // Get auth state stream
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Check if user is logged in from local storage
  static Future<bool> get isLoggedIn async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  // Get stored clinic ID
  static Future<String?> getStoredClinicId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_clinicIdKey);
  }

  // Get stored clinic email
  static Future<String?> getStoredClinicEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_clinicEmailKey);
  }

  // Sign in clinic user with email and password
  static Future<Map<String, dynamic>?> signInClinic({
    required String email,
    required String password,
  }) async {
    try {
      // First, check if clinic exists in ClinicAcc collection with exact field names
      final QuerySnapshot clinicQuery = await _firestore
          .collection('ClinicAcc')
          .where('email', isEqualTo: email.trim())
          .limit(1)
          .get();

      if (clinicQuery.docs.isEmpty) {
        throw 'No clinic found with this email address.';
      }

      final clinicDoc = clinicQuery.docs.first;
      final clinicData = clinicDoc.data() as Map<String, dynamic>;
      final documentId = clinicDoc.id; // This will be CLI01

      // Debug: Print the data to verify field names
      print('Clinic data from Firebase: $clinicData');
      print('Document ID: $documentId');

      // Check if the password matches exactly
      final storedPassword = clinicData['password']?.toString() ?? '';
      if (storedPassword != password) {
        throw 'Invalid email or password.';
      }

      // Store clinic info in local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_clinicIdKey, documentId);
      await prefs.setString(_clinicEmailKey, email.trim());
      await prefs.setBool(_isLoggedInKey, true);
      await prefs.setString('user_type',
          'clinic'); // CRITICAL: Set user type for DynamicUserService

      // Try to sign in with Firebase Auth (optional, for session management)
      try {
        await _auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
          // If user doesn't exist in Firebase Auth, create it
          await _auth.createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );
        }
        // Continue even if Firebase Auth fails, since we have Firestore data
      }

      // Return success with clinic data and document ID
      return {
        'success': true,
        'clinicData': clinicData,
        'clinicId': documentId,
        'message': 'Login successful!',
      };
    } catch (e) {
      throw e.toString();
    }
  } // Register new clinic

  static Future<Map<String, dynamic>?> registerClinic({
    required String email,
    required String password,
    required String clinicName,
    required String userName,
    required String contactNumber,
    required String address,
  }) async {
    try {
      // Check if clinic already exists
      final QuerySnapshot existingClinic = await _firestore
          .collection('ClinicAcc')
          .where('email', isEqualTo: email.trim())
          .limit(1)
          .get();

      if (existingClinic.docs.isNotEmpty) {
        throw 'A clinic with this email already exists.';
      }

      // Create Firebase Auth user
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Update display name
      await userCredential.user?.updateDisplayName(userName);

      // Save clinic data to ClinicAcc collection
      final docRef = await _firestore.collection('ClinicAcc').add({
        'email': email.trim(),
        'password':
            password, // WARNING: Storing plain text passwords is not secure
        'Clinic_Name': clinicName,
        'User_name': userName,
        'Contact_Number': contactNumber,
        'Address': address,
        'uid': userCredential.user?.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'clinicId': docRef.id,
        'user': userCredential.user,
      };
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw e.toString();
    }
  }

  // Get clinic data by email
  static Future<Map<String, dynamic>?> getClinicData(String email) async {
    try {
      final QuerySnapshot clinicQuery = await _firestore
          .collection('ClinicAcc')
          .where('email', isEqualTo: email.trim())
          .limit(1)
          .get();

      if (clinicQuery.docs.isNotEmpty) {
        final clinicDoc = clinicQuery.docs.first;
        return {
          'id': clinicDoc.id,
          ...clinicDoc.data() as Map<String, dynamic>,
        };
      }
      return null;
    } catch (e) {
      throw 'Error fetching clinic data: $e';
    }
  }

  // Update clinic data
  static Future<void> updateClinicData(
      String clinicId, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('ClinicAcc').doc(clinicId).update(data);
    } catch (e) {
      throw 'Error updating clinic data: $e';
    }
  }

  // Sign out and clear local storage
  static Future<void> signOut() async {
    try {
      // Clear local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_clinicIdKey);
      await prefs.remove(_clinicEmailKey);
      await prefs.setBool(_isLoggedInKey, false);
      await prefs.remove('user_type'); // Clear user type as well

      // Sign out from Firebase Auth
      await _auth.signOut();
    } catch (e) {
      throw 'Error signing out. Please try again.';
    }
  }

  // Get clinic data by stored ID
  static Future<Map<String, dynamic>?> getCurrentClinicData() async {
    try {
      final clinicId = await getStoredClinicId();
      if (clinicId == null) return null;

      final DocumentSnapshot clinicDoc =
          await _firestore.collection('ClinicAcc').doc(clinicId).get();

      if (clinicDoc.exists) {
        return {
          'id': clinicDoc.id,
          ...clinicDoc.data() as Map<String, dynamic>,
        };
      }
      return null;
    } catch (e) {
      throw 'Error fetching clinic data: $e';
    }
  }

  // Reset password
  static Future<void> resetPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  // Handle Firebase Auth exceptions
  static String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-email':
        return 'Invalid email address format.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      case 'operation-not-allowed':
        return 'This operation is not allowed. Please contact support.';
      case 'invalid-credential':
        return 'Invalid credentials. Please check your email and password.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return e.message ?? 'An unknown error occurred.';
    }
  }

  // Validate email format
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Validate password strength
  static bool isValidPassword(String password) {
    // At least 6 characters long
    return password.length >= 6;
  }

  // Save clinic registration data to ClinicReg collection
  static Future<Map<String, dynamic>?> saveClinicRegistration({
    required String clinicName,
    required String userName,
    required String email,
    required String contactNumber,
    required String address,
    required String password,
  }) async {
    try {
      // Get all existing documents in ClinicReg collection to find the next available ID
      final QuerySnapshot existingDocs = await _firestore
          .collection('ClinicReg')
          .orderBy(FieldPath.documentId)
          .get();

      // Generate the next document ID
      String nextDocId = 'CLIReg01'; // Default first ID
      if (existingDocs.docs.isNotEmpty) {
        // Extract numbers from existing document IDs and find the highest
        int maxNumber = 0;
        for (var doc in existingDocs.docs) {
          String docId = doc.id;
          if (docId.startsWith('CLIReg')) {
            String numberPart = docId.substring(6); // Remove 'CLIReg' prefix
            int? number = int.tryParse(numberPart);
            if (number != null && number > maxNumber) {
              maxNumber = number;
            }
          }
        }

        // Generate next ID with proper zero padding
        int nextNumber = maxNumber + 1;
        nextDocId = 'CLIReg${nextNumber.toString().padLeft(2, '0')}';
      }

      // Save clinic registration data to ClinicReg collection with generated document ID
      await _firestore.collection('ClinicReg').doc(nextDocId).set({
        'Clinic_Name': clinicName,
        'User_Name': userName,
        'Email': email.trim(),
        'Contact_Number': contactNumber,
        'Address': address,
        'Password':
            password, // Note: Consider encrypting passwords in production
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'documentId': nextDocId,
        'message': 'Clinic registration data saved successfully!',
      };
    } catch (e) {
      throw 'Error saving clinic registration: $e';
    }
  }

  // Save parent registration data to ParentsReg collection
  static Future<Map<String, dynamic>?> saveParentRegistration({
    required String fullName,
    required String userName,
    required String email,
    required String contactNumber,
    required String address,
    required String password,
  }) async {
    try {
      // Get all existing documents in ParentsReg collection to find the next available ID
      final QuerySnapshot existingDocs = await _firestore
          .collection('ParentsReg')
          .orderBy(FieldPath.documentId)
          .get();

      // Generate the next document ID
      String nextDocId = 'PARReg01'; // Default first ID
      if (existingDocs.docs.isNotEmpty) {
        // Extract numbers from existing document IDs and find the highest
        int maxNumber = 0;
        for (var doc in existingDocs.docs) {
          String docId = doc.id;
          if (docId.startsWith('PARReg')) {
            String numberPart = docId.substring(6); // Remove 'PARReg' prefix
            int? number = int.tryParse(numberPart);
            if (number != null && number > maxNumber) {
              maxNumber = number;
            }
          }
        }

        // Generate next ID with proper zero padding
        int nextNumber = maxNumber + 1;
        nextDocId = 'PARReg${nextNumber.toString().padLeft(2, '0')}';
      }

      // Save parent registration data to ParentsReg collection with generated document ID
      await _firestore.collection('ParentsReg').doc(nextDocId).set({
        'Full_Name': fullName,
        'User_Name': userName,
        'Email': email.trim(),
        'Contact_Number': contactNumber,
        'Address': address,
        'Password':
            password, // Note: Consider encrypting passwords in production
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'documentId': nextDocId,
        'message': 'Parent registration data saved successfully!',
      };
    } catch (e) {
      throw 'Error saving parent registration: $e';
    }
  }

  // General registration method for compatibility with register_controller.dart
  static Future<UserCredential?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
    String? clinicName,
    String? phoneNumber,
  }) async {
    try {
      // Create Firebase Auth user
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Update display name
      await userCredential.user?.updateDisplayName(fullName);

      // Note: For now, just create the Firebase Auth user
      // You can extend this to save to appropriate collections based on user type

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred during registration. Please try again.';
    }
  }
}
