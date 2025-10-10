import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'lib/firebase_options.dart';

void main() async {
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Test therapist login
  await testTherapistLogin();
}

Future<void> testTherapistLogin() async {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  print('=== Therapist Authentication Test ===');

  // Test credentials from your Firebase data
  String email = 'r@gmail.com'; // Email from your screenshot
  String password = '654321'; // Password from your screenshot

  try {
    print('Attempting to sign in with: $email');

    // Try to sign in
    UserCredential result = await auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    print('✅ Sign in successful!');
    print('User ID: ${result.user?.uid}');
    print('Email: ${result.user?.email}');

    // Check if user data exists in Firestore
    DocumentSnapshot therapistDoc =
        await firestore.collection('TherapistAcc').doc(result.user!.uid).get();

    if (therapistDoc.exists) {
      print('✅ Therapist data found in Firestore');
      print('Data: ${therapistDoc.data()}');
    } else {
      print('❌ No therapist data found in Firestore for this user');

      // Check if there's a document with a different ID
      QuerySnapshot allTherapists = await firestore
          .collection('TherapistAcc')
          .where('Email', isEqualTo: email)
          .get();

      if (allTherapists.docs.isNotEmpty) {
        print('📋 Found therapist data with email but different document ID:');
        for (var doc in allTherapists.docs) {
          print('Document ID: ${doc.id}');
          print('Data: ${doc.data()}');
        }
      }
    }

    await auth.signOut();
  } on FirebaseAuthException catch (e) {
    print('❌ Authentication failed: ${e.code}');
    print('Message: ${e.message}');

    if (e.code == 'user-not-found') {
      print('\n🔧 The user does not exist in Firebase Authentication.');
      print('This means the account was not created properly.');
      print(
          'Would you like to create the account? (This should be done through registration)');

      // Optionally create the account (for testing purposes)
      await createTestTherapistAccount(email, password);
    }
  } catch (e) {
    print('❌ Unexpected error: $e');
  }
}

Future<void> createTestTherapistAccount(String email, String password) async {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  try {
    print('\n🔧 Creating test therapist account...');

    // Create user in Firebase Authentication
    UserCredential result = await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    print('✅ Firebase Auth account created with ID: ${result.user?.uid}');

    // Now link the existing Firestore data to this Auth user
    // First, get the existing Firestore data
    QuerySnapshot existingData = await firestore
        .collection('TherapistAcc')
        .where('Email', isEqualTo: email)
        .get();

    if (existingData.docs.isNotEmpty) {
      var therapistData =
          existingData.docs.first.data() as Map<String, dynamic>;

      // Create new document with the Auth UID
      await firestore
          .collection('TherapistAcc')
          .doc(result.user!.uid)
          .set(therapistData);

      print('✅ Linked existing Firestore data to new Auth account');

      // Delete the old document if it has a different ID
      if (existingData.docs.first.id != result.user!.uid) {
        await existingData.docs.first.reference.delete();
        print('🗑️ Removed old Firestore document');
      }
    }

    await auth.signOut();
    print('✅ Account creation completed and signed out');
  } catch (e) {
    print('❌ Failed to create account: $e');
  }
}
