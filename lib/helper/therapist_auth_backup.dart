import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TherapistAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TherapistAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Keys for local storage
  static const String _therapistIdKey = 'therapist_id';
  static const String _therapistEmailKey = 'therapist_email';
  static const String _isLoggedInKey = 'is_logged_in';

  // Email validation
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Password validation - Allow any password length since we're not using Firebase Auth
  static bool isValidPassword(String password) {
    return password.isNotEmpty; // Accept any non-empty password
  }

  // Check if user is logged in from local storage
  static Future<bool> get isLoggedIn async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  // Get stored therapist ID
  static Future<String?> getStoredTherapistId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_therapistIdKey);
  }

  // Get stored therapist email
  static Future<String?> getStoredTherapistEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_therapistEmailKey);
  }

  // Sign in therapist with direct Firestore authentication (like clinic login)
  static Future<Map<String, dynamic>?> signInTherapist({
    required String email,
    required String password,
  }) async {
    try {
      print('🔍 Attempting to sign in therapist with email: $email');
      
      // First, check TherapistAcc collection with Email field
      QuerySnapshot therapistQuery = await _firestore
          .collection('TherapistAcc')
          .where('Email', isEqualTo: email.trim())
          .limit(1)
          .get();

      print('📋 TherapistAcc collection check: Found ${therapistQuery.docs.length} documents');

      // If not found in TherapistAcc, check TherAcc collection
      if (therapistQuery.docs.isEmpty) {
        print('🔍 Searching in TherAcc collection...');
        therapistQuery = await _firestore
            .collection('TherAcc')
            .where('Email', isEqualTo: email.trim())
            .limit(1)
            .get();
        print('📋 TherAcc collection check: Found ${therapistQuery.docs.length} documents');
      }

      if (therapistQuery.docs.isEmpty) {
        throw Exception('No therapist found with this email address.');
      }

      final therapistDoc = therapistQuery.docs.first;
      final therapistData = therapistDoc.data() as Map<String, dynamic>;
      final documentId = therapistDoc.id;

      // Debug: Print the data to verify field names
      print('� Therapist data from Firebase: $therapistData');
      print('📋 Document ID: $documentId');

      // Check if the password matches exactly
      final storedPassword = therapistData['Password']?.toString() ?? '';
      print('� Stored password: $storedPassword');
      print('🔐 Entered password: $password');
      
      if (storedPassword != password) {
        throw Exception('Invalid email or password.');
      }

      // Store therapist info in local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_therapistIdKey, documentId);
      await prefs.setString(_therapistEmailKey, email.trim());
      await prefs.setBool(_isLoggedInKey, true);
      await prefs.setString('user_type', 'therapist');

      // Store additional therapist details
      if (therapistData['Full_Name'] != null) {
        await prefs.setString('therapist_name', therapistData['Full_Name']);
      } else if (therapistData['Name'] != null) {
        await prefs.setString('therapist_name', therapistData['Name']);
      }
      
      if (therapistData['Contact_Number'] != null) {
        await prefs.setString('therapist_contact', therapistData['Contact_Number']);
      }

      // Try to sign in with Firebase Auth (optional, for session management)
      try {
        await _auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        print('✅ Firebase Auth sign in successful');
      } on FirebaseAuthException catch (e) {
        print('⚠️ Firebase Auth failed: ${e.code}');
        if (e.code == 'user-not-found') {
          // If user doesn't exist in Firebase Auth, create it
          try {
            await _auth.createUserWithEmailAndPassword(
              email: email.trim(),
              password: password,
            );
            print('✅ Created Firebase Auth account');
          } catch (createError) {
            print('⚠️ Failed to create Firebase Auth account: $createError');
          }
        }
        // Continue even if Firebase Auth fails, since we have Firestore data
      }

      print('✅ Therapist login successful');
      // Return success with therapist data and document ID
      return {
        'success': true,
        'therapistData': therapistData,
        'therapistId': documentId,
        'user': _auth.currentUser, // May be null if Firebase Auth failed
      };

    } catch (e) {
      print('❌ Therapist login failed: $e');
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // Get therapist data from Firestore
  static Future<Map<String, dynamic>?> getTherapistData(String uid) async {
    try {
      print('🔍 Looking for therapist data with UID: $uid');
      
      // Check TherapistAcc collection first
      DocumentSnapshot therapistDoc = await _firestore
          .collection('TherapistAcc')
          .doc(uid)
          .get();

      print('📋 TherapistAcc collection check: ${therapistDoc.exists ? 'Found' : 'Not found'}');
      
      if (therapistDoc.exists) {
        print('✅ Found in TherapistAcc collection');
        return therapistDoc.data() as Map<String, dynamic>?;
      }

      // If not found in TherapistAcc, check TherAcc collection
      therapistDoc = await _firestore
          .collection('TherAcc')
          .doc(uid)
          .get();

      print('📋 TherAcc collection check: ${therapistDoc.exists ? 'Found' : 'Not found'}');

      if (therapistDoc.exists) {
        print('✅ Found in TherAcc collection');
        return therapistDoc.data() as Map<String, dynamic>?;
      }

      // If not found by UID, try to find by email
      print('🔍 Searching by email in both collections...');
      
      // Get all docs and check if any match the current user's email
      final currentUser = _auth.currentUser;
      if (currentUser?.email != null) {
        print('📧 Searching for email: ${currentUser!.email}');
        
        // Search TherapistAcc by email
        QuerySnapshot emailQuery = await _firestore
            .collection('TherapistAcc')
            .where('Email', isEqualTo: currentUser.email)
            .get();
            
        if (emailQuery.docs.isNotEmpty) {
          print('✅ Found therapist by email in TherapistAcc');
          print('🔄 Document ID mismatch - Auth UID: $uid, Firestore Doc ID: ${emailQuery.docs.first.id}');
          return emailQuery.docs.first.data() as Map<String, dynamic>?;
        }
        
        // Search TherAcc by email
        emailQuery = await _firestore
            .collection('TherAcc')
            .where('Email', isEqualTo: currentUser.email)
            .get();
            
        if (emailQuery.docs.isNotEmpty) {
          print('✅ Found therapist by email in TherAcc');
          print('🔄 Document ID mismatch - Auth UID: $uid, Firestore Doc ID: ${emailQuery.docs.first.id}');
          return emailQuery.docs.first.data() as Map<String, dynamic>?;
        }
      }

      print('❌ No therapist data found in any collection');
      return null;
    } catch (e) {
      print('❌ Error getting therapist data: $e');
      return null;
    }
  }

  // Store therapist info in SharedPreferences
  static Future<void> _storeTherapistInfo(String uid, Map<String, dynamic> therapistData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('therapist_id', uid);
      await prefs.setString('user_id', uid);
      await prefs.setString('user_type', 'therapist');
      
      // Store therapist details
      if (therapistData['Full_Name'] != null) {
        await prefs.setString('therapist_name', therapistData['Full_Name']);
      } else if (therapistData['Name'] != null) {
        await prefs.setString('therapist_name', therapistData['Name']);
      }
      
      if (therapistData['Email'] != null) {
        await prefs.setString('therapist_email', therapistData['Email']);
      }
      
      if (therapistData['Contact_Number'] != null) {
        await prefs.setString('therapist_contact', therapistData['Contact_Number']);
      }
      
      print('Therapist info stored successfully');
    } catch (e) {
      print('Error storing therapist info: $e');
    }
  }

  // Reset password
  static Future<void> resetPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          throw Exception('No account found with this email address.');
        case 'invalid-email':
          throw Exception('Invalid email address format.');
        default:
          throw Exception('Password reset failed: ${e.message}');
      }
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  // Sign out user
  static Future<void> signOut() async {
    try {
      // Clear stored data
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('therapist_id');
      await prefs.remove('user_id');
      await prefs.remove('user_type');
      await prefs.remove('therapist_name');
      await prefs.remove('therapist_email');
      await prefs.remove('therapist_contact');
      
      // Sign out from Firebase
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

  // Get stored therapist info
  static Future<Map<String, String?>> getStoredTherapistInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'therapist_id': prefs.getString('therapist_id'),
        'therapist_name': prefs.getString('therapist_name'),
        'therapist_email': prefs.getString('therapist_email'),
        'therapist_contact': prefs.getString('therapist_contact'),
        'user_type': prefs.getString('user_type'),
      };
    } catch (e) {
      print('Error getting stored therapist info: $e');
      return {};
    }
  }
}
