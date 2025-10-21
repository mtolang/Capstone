import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseTestScreen extends StatefulWidget {
  const FirebaseTestScreen({Key? key}) : super(key: key);

  @override
  State<FirebaseTestScreen> createState() => _FirebaseTestScreenState();
}

class _FirebaseTestScreenState extends State<FirebaseTestScreen> {
  final List<String> _testResults = [];
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _runTests();
  }

  Future<void> _runTests() async {
    setState(() {
      _isRunning = true;
      _testResults.clear();
    });

    _addResult('🔥 Starting Firebase Tests...\n');

    // Test 1: Firestore Connection
    _addResult('📊 Test 1: Firestore Connection');
    try {
      final firestore = FirebaseFirestore.instance;
      await firestore.enableNetwork();
      _addResult('✅ Firestore connection successful\n');
    } catch (e) {
      _addResult('❌ Firestore connection failed: $e\n');
    }

    // Test 2: Journal Collection Access
    _addResult('🗂️ Test 2: Journal Collection Analysis');
    try {
      final allJournals = await FirebaseFirestore.instance
          .collection('Journal')
          .get();
      
      _addResult('✅ Journal collection accessible');
      _addResult('   Total documents: ${allJournals.docs.length}');
      
      if (allJournals.docs.isNotEmpty) {
        final parentIds = <String>{};
        final types = <String>{};
        
        _addResult('\n📄 Document Analysis:');
        for (var doc in allJournals.docs) {
          final data = doc.data();
          
          // Extract parentId
          if (data['parentId'] != null) {
            parentIds.add(data['parentId'].toString());
          }
          
          // Extract type
          if (data['type'] != null) {
            types.add(data['type'].toString());
          }
          
          _addResult('   📄 ${doc.id}:');
          _addResult('      parentId: "${data['parentId']}"');
          _addResult('      type: "${data['type']}"');
          _addResult('      title: "${data['title']}"');
          _addResult('      hasImages: ${(data['images'] as List?)?.isNotEmpty ?? false}');
          _addResult('      hasVideos: ${(data['videos'] as List?)?.isNotEmpty ?? false}');
        }
        
        _addResult('\n📊 Summary:');
        _addResult('   Unique Parent IDs: ${parentIds.length}');
        _addResult('   Parent IDs: ${parentIds.toList()}');
        _addResult('   Journal Types: ${types.toList()}');
      } else {
        _addResult('⚠️ No documents found in Journal collection');
      }
      _addResult('');
    } catch (e) {
      _addResult('❌ Journal collection access failed: $e\n');
    }

    // Test 3: SharedPreferences
    _addResult('💾 Test 3: SharedPreferences Analysis');
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      
      _addResult('✅ SharedPreferences accessible');
      _addResult('   Total keys: ${allKeys.length}');
      
      if (allKeys.isNotEmpty) {
        _addResult('   Stored data:');
        for (var key in allKeys) {
          final value = prefs.get(key);
          _addResult('      $key: "$value" (${value.runtimeType})');
        }
      } else {
        _addResult('   No keys found in SharedPreferences');
      }
      _addResult('');
    } catch (e) {
      _addResult('❌ SharedPreferences access failed: $e\n');
    }

    // Test 4: Parent ID Matching
    _addResult('🔍 Test 4: Parent ID Matching Test');
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedParentId = prefs.getString('parent_id') ??
          prefs.getString('user_id') ??
          prefs.getString('parentId') ??
          prefs.getString('userId') ??
          prefs.getString('clinic_id');
      
      _addResult('   Stored Parent ID: "${storedParentId ?? "null"}"');
      
      if (storedParentId != null) {
        final matchingJournals = await FirebaseFirestore.instance
            .collection('Journal')
            .where('parentId', isEqualTo: storedParentId)
            .get();
        
        _addResult('   Matching journals: ${matchingJournals.docs.length}');
        
        if (matchingJournals.docs.isNotEmpty) {
          for (var doc in matchingJournals.docs) {
            final data = doc.data();
            _addResult('      Found: "${data['title']}" (type: ${data['type']})');
          }
        } else {
          _addResult('      No journals match the stored parent ID');
        }
      }
      _addResult('');
    } catch (e) {
      _addResult('❌ Parent ID matching test failed: $e\n');
    }

    // Test 5: Query Performance
    _addResult('⚡ Test 5: Query Performance Test');
    try {
      final stopwatch = Stopwatch()..start();
      
      final query = await FirebaseFirestore.instance
          .collection('Journal')
          .orderBy('createdAt', descending: true)
          .get();
      
      stopwatch.stop();
      
      _addResult('✅ Query completed successfully');
      _addResult('   Time taken: ${stopwatch.elapsedMilliseconds}ms');
      _addResult('   Documents retrieved: ${query.docs.length}');
      _addResult('');
    } catch (e) {
      _addResult('❌ Query performance test failed: $e\n');
    }

    // Test 6: Write Permission Test
    _addResult('✍️ Test 6: Write Permission Test');
    try {
      final testDoc = FirebaseFirestore.instance
          .collection('_test')
          .doc('connectivity_test_${DateTime.now().millisecondsSinceEpoch}');
      
      await testDoc.set({
        'timestamp': FieldValue.serverTimestamp(),
        'test': 'Firebase connectivity test',
        'success': true,
      });
      
      // Try to read it back
      final readBack = await testDoc.get();
      if (readBack.exists) {
        _addResult('✅ Write/Read test successful');
        
        // Clean up
        await testDoc.delete();
        _addResult('✅ Test document cleaned up');
      }
      _addResult('');
    } catch (e) {
      _addResult('❌ Write permission test failed: $e');
      _addResult('   This might be due to Firestore security rules\n');
    }

    _addResult('🎉 Firebase Tests Completed!');
    
    setState(() {
      _isRunning = false;
    });
  }

  void _addResult(String result) {
    setState(() {
      _testResults.add(result);
    });
    print(result); // Also print to console
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Firebase Test Results',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF006A5B),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isRunning ? null : _runTests,
          ),
        ],
      ),
      body: _isRunning
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF006A5B)),
                  SizedBox(height: 16),
                  Text(
                    'Running Firebase Tests...',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _testResults.length,
              itemBuilder: (context, index) {
                final result = _testResults[index];
                Color textColor = Colors.black87;
                FontWeight fontWeight = FontWeight.normal;
                
                if (result.startsWith('✅')) {
                  textColor = Colors.green;
                  fontWeight = FontWeight.w600;
                } else if (result.startsWith('❌')) {
                  textColor = Colors.red;
                  fontWeight = FontWeight.w600;
                } else if (result.startsWith('⚠️')) {
                  textColor = Colors.orange;
                  fontWeight = FontWeight.w600;
                } else if (result.startsWith('🔥') || 
                          result.startsWith('📊') || 
                          result.startsWith('🗂️') ||
                          result.startsWith('💾') ||
                          result.startsWith('🔍') ||
                          result.startsWith('⚡') ||
                          result.startsWith('✍️')) {
                  textColor = const Color(0xFF006A5B);
                  fontWeight = FontWeight.bold;
                }
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    result,
                    style: TextStyle(
                      fontFamily: 'Courier New', // Monospace for better formatting
                      fontSize: 12,
                      color: textColor,
                      fontWeight: fontWeight,
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: _isRunning
          ? null
          : FloatingActionButton(
              onPressed: _runTests,
              backgroundColor: const Color(0xFF006A5B),
              child: const Icon(Icons.play_arrow, color: Colors.white),
            ),
    );
  }
}