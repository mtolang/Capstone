import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../services/firebase_storage_service.dart';

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
      QuerySnapshot clinicQuery;
      String? collectionFound;
      
      // Search in ClinicAcc collection first (accepted clinics)
      print('🔍 Searching for clinic in ClinicAcc collection...');
      
      // Try lowercase email field
      clinicQuery = await _firestore
          .collection('ClinicAcc')
          .where('email', isEqualTo: email.trim())
          .limit(1)
          .get();

      if (clinicQuery.docs.isEmpty) {
        // Try capitalized Email field
        clinicQuery = await _firestore
            .collection('ClinicAcc')
            .where('Email', isEqualTo: email.trim())
            .limit(1)
            .get();
      }

      if (clinicQuery.docs.isNotEmpty) {
        collectionFound = 'ClinicAcc';
        print('✅ Found clinic in ClinicAcc collection');
      } else {
        // If not found in ClinicAcc, search in ClinicReg collection (pending/registered clinics)
        print('🔍 Not found in ClinicAcc, searching in ClinicReg collection...');
        
        // Try lowercase email field
        clinicQuery = await _firestore
            .collection('ClinicReg')
            .where('email', isEqualTo: email.trim())
            .limit(1)
            .get();

        if (clinicQuery.docs.isEmpty) {
          // Try capitalized Email field
          clinicQuery = await _firestore
              .collection('ClinicReg')
              .where('Email', isEqualTo: email.trim())
              .limit(1)
              .get();
        }

        if (clinicQuery.docs.isNotEmpty) {
          collectionFound = 'ClinicReg';
          print('✅ Found clinic in ClinicReg collection');
        }
      }

      if (clinicQuery.docs.isEmpty) {
        print('❌ No clinic found with email: $email');
        throw 'No clinic found with this email address. Please check your email or register first.';
      }

      final clinicDoc = clinicQuery.docs.first;
      final clinicData = clinicDoc.data() as Map<String, dynamic>;
      final documentId = clinicDoc.id;

      // Debug: Print the data to verify field names
      print('📋 Clinic data from Firebase ($collectionFound): $clinicData');
      print('📋 Document ID: $documentId');

      // Check password - try multiple field name variations
      String? storedPassword;
      
      // Try different password field variations
      if (clinicData.containsKey('password')) {
        storedPassword = clinicData['password']?.toString();
      } else if (clinicData.containsKey('Password')) {
        storedPassword = clinicData['Password']?.toString();
      } else if (clinicData.containsKey('PASSWORD')) {
        storedPassword = clinicData['PASSWORD']?.toString();
      }

      print('🔐 Stored password found: ${storedPassword != null}');

      if (storedPassword == null) {
        print('❌ No password field found in document. Available fields: ${clinicData.keys.toList()}');
        throw 'Login configuration error. Please contact support.';
      }

      if (storedPassword != password) {
        print('❌ Password mismatch');
        throw 'Invalid email or password.';
      }

      print('✅ Password verification successful');

      // Store clinic info in local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_clinicIdKey, documentId);
      await prefs.setString(_clinicEmailKey, email.trim());
      await prefs.setBool(_isLoggedInKey, true);
      await prefs.setString('user_type', 'clinic');
      await prefs.setString('clinic_collection', collectionFound!);

      // Try to sign in with Firebase Auth (optional, for session management)
      try {
        await _auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        print('✅ Firebase Auth login successful');
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
          try {
            // If user doesn't exist in Firebase Auth, create it
            await _auth.createUserWithEmailAndPassword(
              email: email.trim(),
              password: password,
            );
            print('✅ Firebase Auth user created');
          } catch (createError) {
            print('⚠️ Firebase Auth user creation failed: $createError');
          }
        } else {
          print('⚠️ Firebase Auth login failed: ${e.message}');
        }
        // Continue even if Firebase Auth fails, since we have Firestore data
      }

      print('🎉 Login process completed successfully');

      // Return success with clinic data and document ID
      return {
        'success': true,
        'clinicData': clinicData,
        'clinicId': documentId,
        'collection': collectionFound,
        'message': 'Login successful!',
      };
    } catch (e) {
      print('💥 Login error: $e');
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
      // Check if clinic already exists - try both lowercase and capitalized fields
      QuerySnapshot existingClinic = await _firestore
          .collection('ClinicAcc')
          .where('email', isEqualTo: email.trim())
          .limit(1)
          .get();

      if (existingClinic.docs.isEmpty) {
        existingClinic = await _firestore
            .collection('ClinicAcc')
            .where('Email', isEqualTo: email.trim())
            .limit(1)
            .get();
      }

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

      // Save clinic data to ClinicAcc collection using capitalized field names to match existing structure
      final docRef = await _firestore.collection('ClinicAcc').add({
        'Email':
            email.trim(), // Use capitalized field to match existing database
        'Password':
            password, // Use capitalized field to match existing database
        'Clinic_Name': clinicName,
        'User_Name': userName,
        'Contact_Number': contactNumber,
        'Address': address,
        'uid': userCredential.user?.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'acceptedAt': FieldValue.serverTimestamp(),
        'acceptedBy': 'System',
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
      // Try lowercase email field first
      QuerySnapshot clinicQuery = await _firestore
          .collection('ClinicAcc')
          .where('email', isEqualTo: email.trim())
          .limit(1)
          .get();

      // If not found, try capitalized Email field
      if (clinicQuery.docs.isEmpty) {
        clinicQuery = await _firestore
            .collection('ClinicAcc')
            .where('Email', isEqualTo: email.trim())
            .limit(1)
            .get();
      }

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
      // Clear all local storage data
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_clinicIdKey);
      await prefs.remove(_clinicEmailKey);
      await prefs.setBool(_isLoggedInKey, false);
      await prefs.remove('user_type'); // Clear user type as well

      // Clear any potential fallback IDs to prevent conflicts
      await prefs.remove('current_user_id');
      await prefs.remove('userId');
      await prefs.remove('static_clinic_id');
      await prefs.remove('fallback_id');

      // Clear parent data to prevent cross-user conflicts
      await prefs.remove('user_id');
      await prefs.remove('user_name');
      await prefs.remove('user_email');
      await prefs.remove('user_phone');
      await prefs.remove('parent_id');
      await prefs.remove('static_parent_id');

      // Sign out from Firebase Auth
      await _auth.signOut();

      print(
          'ClinicAuthService: Successfully cleared all authentication data and potential ID conflicts');
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

  // Enhanced method to save parent registration with file upload
  static Future<Map<String, dynamic>?> saveParentRegistrationWithFile({
    required String fullName,
    required String userName,
    required String email,
    required String contactNumber,
    required String address,
    required String password,
    XFile? governmentIdFile,
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

      // Upload government ID file if provided
      String? documentUrl;
      if (governmentIdFile != null) {
        print(
            '📤 Attempting to upload government ID file: ${governmentIdFile.name}');
        try {
          documentUrl = await FirebaseStorageService.uploadParentDocument(
            file: governmentIdFile,
            parentId: nextDocId,
          );
          if (documentUrl != null) {
            print('✅ File upload successful: $documentUrl');
          } else {
            print('❌ File upload failed: FirebaseStorageService returned null');
          }
        } catch (uploadError) {
          print('❌ Exception during file upload: $uploadError');
          // Continue with registration even if file upload fails
          // The file upload failure will be indicated by documentUrl being null
        }
      } else {
        print('ℹ️ No government ID file provided');
      }

      // Save parent registration data to ParentsReg collection with generated document ID
      Map<String, dynamic> registrationData = {
        'Full_Name': fullName,
        'User_Name': userName,
        'Email': email.trim(),
        'Contact_Number': contactNumber,
        'Address': address,
        'Password':
            password, // Note: Consider encrypting passwords in production
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Add document URL if file was uploaded
      if (documentUrl != null) {
        registrationData['Government_ID_Document'] = documentUrl;
      }

      await _firestore
          .collection('ParentsReg')
          .doc(nextDocId)
          .set(registrationData);

      return {
        'success': true,
        'documentId': nextDocId,
        'message': 'Parent registration data saved successfully!',
        'documentUrl': documentUrl,
      };
    } catch (e) {
      throw 'Error saving parent registration: $e';
    }
  }

  // Enhanced method to save clinic registration with file upload
  static Future<Map<String, dynamic>?> saveClinicRegistrationWithFile({
    required String clinicName,
    required String userName,
    required String email,
    required String contactNumber,
    required String address,
    required String password,
    XFile? documentFile,
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

      // Upload clinic document file if provided
      String? documentUrl;
      if (documentFile != null) {
        documentUrl = await FirebaseStorageService.uploadClinicDocument(
          file: documentFile,
          clinicId: nextDocId,
          documentType: 'registration',
        );
      }

      // Save clinic registration data to ClinicReg collection with generated document ID
      Map<String, dynamic> registrationData = {
        'Clinic_Name': clinicName,
        'User_Name': userName,
        'Email': email.trim(),
        'Contact_Number': contactNumber,
        'Address': address,
        'Password':
            password, // Note: Consider encrypting passwords in production
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Add document URL if file was uploaded
      if (documentUrl != null) {
        registrationData['Registration_Document'] = documentUrl;
      }

      await _firestore
          .collection('ClinicReg')
          .doc(nextDocId)
          .set(registrationData);

      return {
        'success': true,
        'documentId': nextDocId,
        'message': 'Clinic registration data saved successfully!',
        'documentUrl': documentUrl,
      };
    } catch (e) {
      throw 'Error saving clinic registration: $e';
    }
  }

  // Enhanced method to save therapist registration with file upload
  static Future<Map<String, dynamic>?> saveTherapistRegistrationWithFile({
    required String fullName,
    required String userName,
    required String email,
    required String contactNumber,
    required String address,
    required String password,
    XFile? professionalIdFile,
  }) async {
    try {
      // Get all existing documents in TherapistReg collection to find the next available ID
      final QuerySnapshot existingDocs = await _firestore
          .collection('TherapistReg')
          .orderBy(FieldPath.documentId)
          .get();

      // Generate the next document ID
      String nextDocId = 'TherReg01'; // Default first ID
      if (existingDocs.docs.isNotEmpty) {
        // Extract numbers from existing document IDs and find the highest
        int maxNumber = 0;
        for (var doc in existingDocs.docs) {
          String docId = doc.id;
          if (docId.startsWith('TherReg')) {
            String numberPart = docId.substring(7); // Remove 'TherReg' prefix
            int? number = int.tryParse(numberPart);
            if (number != null && number > maxNumber) {
              maxNumber = number;
            }
          }
        }

        // Generate next ID with proper zero padding
        int nextNumber = maxNumber + 1;
        nextDocId = 'TherReg${nextNumber.toString().padLeft(2, '0')}';
      }

      // Upload professional ID file if provided
      String? professionalIdUrl;
      if (professionalIdFile != null) {
        professionalIdUrl =
            await FirebaseStorageService.uploadTherapistDocument(
          file: professionalIdFile,
          therapistId: nextDocId,
          documentType: 'professional_id',
        );
      }

      // Save therapist registration data to TherapistReg collection with generated document ID
      Map<String, dynamic> registrationData = {
        'Full_Name': fullName,
        'User_Name': userName,
        'Email': email.trim(),
        'Contact_Number': contactNumber,
        'Address': address,
        'Password':
            password, // Note: Consider encrypting passwords in production
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Add professional ID URL if file was uploaded
      if (professionalIdUrl != null) {
        registrationData['Professional_ID_Document'] = professionalIdUrl;
      }

      await _firestore
          .collection('TherapistReg')
          .doc(nextDocId)
          .set(registrationData);

      return {
        'success': true,
        'documentId': nextDocId,
        'message': 'Therapist registration data saved successfully!',
        'documentUrl': professionalIdUrl,
      };
    } catch (e) {
      throw 'Error saving therapist registration: $e';
    }
  }
}
