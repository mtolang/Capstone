import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'lib/firebase_options.dart';

/// Comprehensive Firebase connection and data test
/// Run this with: dart run test_firebase_connection.dart
void main() async {
  print('🔥 Starting Firebase Connection Test...\n');

  try {
    // Test 1: Firebase Initialization
    print('📱 Test 1: Firebase Initialization');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully\n');

    // Test 2: Firestore Connection
    print('📊 Test 2: Firestore Connection');
    final firestore = FirebaseFirestore.instance;
    
    // Enable network (in case it was disabled)
    await firestore.enableNetwork();
    print('✅ Firestore network enabled\n');

    // Test 3: Basic Collection Access
    print('🗂️ Test 3: Basic Collection Access');
    try {
      final collections = await firestore.collection('Journal').limit(1).get();
      print('✅ Successfully accessed Journal collection');
      print('   Collection exists: ${collections.docs.isNotEmpty}');
      print('   Document count (sample): ${collections.docs.length}\n');
    } catch (e) {
      print('❌ Error accessing Journal collection: $e\n');
    }

    // Test 4: Detailed Journal Collection Analysis
    print('📋 Test 4: Journal Collection Analysis');
    try {
      final allJournals = await firestore.collection('Journal').get();
      print('✅ Retrieved all journals');
      print('   Total documents: ${allJournals.docs.length}');
      
      if (allJournals.docs.isNotEmpty) {
        print('\n📄 Journal Documents Analysis:');
        
        // Analyze each document
        final parentIds = <String>{};
        final types = <String>{};
        final fieldAnalysis = <String, int>{};
        
        for (var doc in allJournals.docs) {
          final data = doc.data();
          
          print('   📄 Document ID: ${doc.id}');
          print('      Fields: ${data.keys.toList()}');
          
          // Track field usage
          for (var field in data.keys) {
            fieldAnalysis[field] = (fieldAnalysis[field] ?? 0) + 1;
          }
          
          // Extract parentId
          if (data['parentId'] != null) {
            parentIds.add(data['parentId'].toString());
            print('      parentId: "${data['parentId']}"');
          } else {
            print('      parentId: null');
          }
          
          // Extract type
          if (data['type'] != null) {
            types.add(data['type'].toString());
            print('      type: "${data['type']}"');
          } else {
            print('      type: null');
          }
          
          // Extract other key fields
          print('      title: "${data['title'] ?? 'null'}"');
          print('      createdAt: ${data['createdAt']}');
          print('');
        }
        
        print('📊 Summary Statistics:');
        print('   Unique Parent IDs: ${parentIds.length}');
        print('   Parent IDs: ${parentIds.toList()}');
        print('   Journal Types: ${types.toList()}');
        print('   Field Usage:');
        fieldAnalysis.forEach((field, count) {
          print('      $field: $count/${allJournals.docs.length} documents');
        });
      } else {
        print('⚠️ No documents found in Journal collection');
      }
      print('');
    } catch (e) {
      print('❌ Error analyzing Journal collection: $e\n');
    }

    // Test 5: SharedPreferences Analysis
    print('💾 Test 5: SharedPreferences Analysis');
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      
      print('✅ SharedPreferences accessible');
      print('   Total keys stored: ${allKeys.length}');
      
      if (allKeys.isNotEmpty) {
        print('   Stored keys and values:');
        for (var key in allKeys) {
          final value = prefs.get(key);
          print('      $key: $value (${value.runtimeType})');
        }
      } else {
        print('   No keys found in SharedPreferences');
      }
      print('');
    } catch (e) {
      print('❌ Error accessing SharedPreferences: $e\n');
    }

    // Test 6: Specific Query Tests
    print('🔍 Test 6: Specific Query Tests');
    
    // Test query with parentId filter
    final testParentIds = ['ParAcc02', 'parent_001', 'user_123'];
    
    for (var testId in testParentIds) {
      try {
        final query = await firestore
            .collection('Journal')
            .where('parentId', isEqualTo: testId)
            .get();
        
        print('   Query for parentId "$testId": ${query.docs.length} results');
        
        if (query.docs.isNotEmpty) {
          for (var doc in query.docs) {
            final data = doc.data();
            print('      Found: "${data['title']}" (type: ${data['type']})');
          }
        }
      } catch (e) {
        print('   Query for parentId "$testId" failed: $e');
      }
    }
    print('');

    // Test 7: Write Test (if permissions allow)
    print('✍️ Test 7: Write Permissions Test');
    try {
      final testDoc = firestore.collection('_test').doc('connectivity_test');
      await testDoc.set({
        'timestamp': FieldValue.serverTimestamp(),
        'test': 'Firebase connectivity test',
        'success': true,
      });
      
      // Try to read it back
      final readBack = await testDoc.get();
      if (readBack.exists) {
        print('✅ Write/Read test successful');
        
        // Clean up test document
        await testDoc.delete();
        print('✅ Test document cleaned up');
      }
    } catch (e) {
      print('❌ Write test failed: $e');
      print('   This might be due to Firestore security rules');
    }
    print('');

    // Test 8: Network Connectivity
    print('🌐 Test 8: Network Connectivity Test');
    try {
      // Try to access Firestore settings
      final settings = firestore.settings;
      print('✅ Firestore settings accessible');
      print('   Host: ${settings.host}');
      print('   SSL Enabled: ${settings.sslEnabled}');
      print('   Persistence Enabled: ${settings.persistenceEnabled}');
      print('   Cache Size: ${settings.cacheSizeBytes}');
    } catch (e) {
      print('❌ Network connectivity issue: $e');
    }
    print('');

    // Test 9: Security Rules Test
    print('🔒 Test 9: Security Rules Test');
    try {
      // Try to access a collection that might have different rules
      final testCollections = ['Journal', 'ParentsAcc', 'AcceptedBooking'];
      
      for (var collection in testCollections) {
        try {
          final query = await firestore.collection(collection).limit(1).get();
          print('   $collection: ✅ Accessible (${query.docs.length} docs)');
        } catch (e) {
          print('   $collection: ❌ Access denied ($e)');
        }
      }
    } catch (e) {
      print('❌ Security rules test failed: $e');
    }
    print('');

    print('🎉 Firebase Connection Test Completed Successfully!');
    print('   Check the results above for any issues or configuration problems.');

  } catch (e) {
    print('💥 Fatal Error: $e');
    print('   This indicates a serious Firebase configuration issue.');
  }
}