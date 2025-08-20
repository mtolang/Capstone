import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  static User? get currentUser => _auth.currentUser;

  // Get auth state stream
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Check if user is logged in
  static bool get isLoggedIn => _auth.currentUser != null;

  // Sign in with email and password
  static Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  // Register with email and password
  static Future<UserCredential?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
    String? clinicName,
    String? phoneNumber,
  }) async {
    try {
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Update display name
      await userCredential.user?.updateDisplayName(fullName);

      // Save additional user data to Firestore
      if (userCredential.user != null) {
        await _saveUserData(
          uid: userCredential.user!.uid,
          email: email.trim(),
          fullName: fullName,
          clinicName: clinicName,
          phoneNumber: phoneNumber,
        );
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred during registration. Please try again.';
    }
  }

  // Sign out
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw 'Error signing out. Please try again.';
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

  // Delete account
  static Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Delete user data from Firestore
        await _firestore.collection('users').doc(user.uid).delete();
        // Delete authentication account
        await user.delete();
      }
    } catch (e) {
      throw 'Error deleting account. Please try again.';
    }
  }

  // Save user data to Firestore
  static Future<void> _saveUserData({
    required String uid,
    required String email,
    required String fullName,
    String? clinicName,
    String? phoneNumber,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'fullName': fullName,
        'clinicName': clinicName ?? '',
        'phoneNumber': phoneNumber ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Error saving user data. Please try again.';
    }
  }

  // Get user data from Firestore
  static Future<Map<String, dynamic>?> getUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final DocumentSnapshot doc =
            await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          return doc.data() as Map<String, dynamic>?;
        }
      }
      return null;
    } catch (e) {
      throw 'Error fetching user data. Please try again.';
    }
  }

  // Update user data in Firestore
  static Future<void> updateUserData(Map<String, dynamic> data) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        data['updatedAt'] = FieldValue.serverTimestamp();
        await _firestore.collection('users').doc(user.uid).update(data);
      }
    } catch (e) {
      throw 'Error updating user data. Please try again.';
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

  // Check if current user's email is verified
  static bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  // Send email verification
  static Future<void> sendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } catch (e) {
      throw 'Error sending verification email. Please try again.';
    }
  }

  // Reload user to get updated email verification status
  static Future<void> reloadUser() async {
    try {
      await _auth.currentUser?.reload();
    } catch (e) {
      throw 'Error reloading user data. Please try again.';
    }
  }
}
