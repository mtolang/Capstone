import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FixTherapistAccountPage extends StatefulWidget {
  const FixTherapistAccountPage({super.key});

  @override
  State<FixTherapistAccountPage> createState() =>
      _FixTherapistAccountPageState();
}

class _FixTherapistAccountPageState extends State<FixTherapistAccountPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  String _status = 'Ready to fix therapist accounts';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fix Therapist Accounts'),
        backgroundColor: const Color(0xFF006A5B),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Therapist Account Fix Tool',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This tool will:',
                      style: TextStyle(fontSize: 14),
                    ),
                    const Text('• Find therapist accounts in Firestore'),
                    const Text('• Create corresponding Firebase Auth accounts'),
                    const Text('• Link them properly for login'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _fixTherapistAccounts,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006A5B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Fix Therapist Accounts'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Text(
                      _status,
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fixTherapistAccounts() async {
    setState(() {
      _isLoading = true;
      _status = 'Starting therapist account fix...\n';
    });

    try {
      // Get all therapist accounts from Firestore
      _updateStatus('Fetching therapist accounts from Firestore...');

      QuerySnapshot therapistQuery =
          await _firestore.collection('TherapistAcc').get();

      _updateStatus(
          'Found ${therapistQuery.docs.length} therapist accounts in TherapistAcc collection');

      for (QueryDocumentSnapshot doc in therapistQuery.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String email = data['Email'] ?? '';
        String password = data['Password'] ?? '';

        if (email.isEmpty || password.isEmpty) {
          _updateStatus('Skipping ${doc.id} - missing email or password');
          continue;
        }

        _updateStatus('\n--- Processing ${doc.id} ---');
        _updateStatus('Email: $email');

        try {
          // Try to create the account first (if it doesn't exist)
          _updateStatus('Attempting to create Firebase Auth account...');

          UserCredential result = await _auth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );

          String authUID = result.user!.uid;
          _updateStatus(
              '✅ Created new Firebase Auth account with UID: $authUID');

          // Copy data to new document with correct UID
          await _firestore.collection('TherapistAcc').doc(authUID).set(data);
          _updateStatus('✅ Created Firestore document with correct UID');

          // Delete old document if it has a different ID
          if (doc.id != authUID) {
            await doc.reference.delete();
            _updateStatus('🗑️ Deleted old document');
          }

          await _auth.signOut();
        } on FirebaseAuthException catch (authError) {
          if (authError.code == 'email-already-in-use') {
            _updateStatus('✅ User already exists in Firebase Auth');

            // Try to sign in to get the UID
            try {
              UserCredential result = await _auth.signInWithEmailAndPassword(
                  email: email, password: password);

              String authUID = result.user!.uid;
              _updateStatus('Auth UID: $authUID');

              if (doc.id != authUID) {
                _updateStatus('🔄 Document ID mismatch, fixing...');

                // Copy data to new document with correct UID
                await _firestore
                    .collection('TherapistAcc')
                    .doc(authUID)
                    .set(data);
                _updateStatus('✅ Created new document with correct UID');

                // Delete old document
                await doc.reference.delete();
                _updateStatus('🗑️ Deleted old document');
              } else {
                _updateStatus('✅ Document ID matches Auth UID');
              }

              await _auth.signOut();
            } catch (e) {
              _updateStatus('❌ Sign in failed: $e');
            }
          } else {
            _updateStatus('❌ Auth error: ${authError.message}');
          }
        } catch (e) {
          _updateStatus('❌ Error processing ${doc.id}: $e');
        }
      }

      _updateStatus('\n🎉 Therapist account fix completed!');
      _updateStatus(
          'You can now try logging in with your therapist credentials.');
    } catch (e) {
      _updateStatus('❌ Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateStatus(String message) {
    setState(() {
      _status += '$message\n';
    });
  }
}
