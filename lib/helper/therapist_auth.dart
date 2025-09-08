import 'package:firebase_auth/firebase_auth.dart';

class TherapistAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Sign out user
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  // Get current user
  static User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Check if user is signed in
  static bool isSignedIn() {
    return _auth.currentUser != null;
  }
}
