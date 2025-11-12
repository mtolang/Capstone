import 'package:flutter/material.dart';
import 'package:kindora/screens/parent/parent_navbar.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:io';
import 'kindora_camera_screen.dart';

// Materials Service for parent access to therapy-specific materials
class ParentMaterialsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _materialsCollection = 'Materials';
  static const String _clinicMaterialsCollection = 'ClinicMaterials';
  static const String _bookingsCollection = 'AcceptedBooking';

  // Get materials based on therapy types from AcceptedBooking and filter by clinic
  static Stream<QuerySnapshot> getMaterialsByTherapyType(String parentId, {String? clinicId}) {
    return _firestore
        .collection(_bookingsCollection)
        .where('parentInfo.parentId', isEqualTo: parentId) // Updated to nested field
        .snapshots();
  }

  // Get materials for specific therapy type that were shared with this parent
  static Stream<QuerySnapshot> getTherapyMaterials(String therapyType, {String? clinicId, String? parentId}) {
    print('🎯 Querying Materials collection for shared materials');
    print('   - therapy: $therapyType');
    print('   - parentId: $parentId');
    print('   - clinicId: $clinicId');
    
    Query query = _firestore
        .collection(_materialsCollection);
    
    // Filter by category/therapy type
    if (therapyType.toLowerCase() != 'all') {
      query = query.where('category', isEqualTo: therapyType.toLowerCase());
    }
    
    // Filter by parentId if provided (most important filter)
    if (parentId != null && parentId.isNotEmpty) {
      query = query.where('parentId', isEqualTo: parentId);
    }
    
    // Filter by clinicId if provided
    if (clinicId != null && clinicId.isNotEmpty) {
      query = query.where('clinicId', isEqualTo: clinicId);
    }
    
    // Only show active materials
    query = query.where('isActive', isEqualTo: true);
    
    return query.snapshots();
  }

  // Search materials by title or tags for specific therapy type and clinic
  static Stream<QuerySnapshot> searchTherapyMaterials(String therapyType, String searchTerm, {String? clinicId}) {
    // If clinicId is provided, search in ClinicMaterials collection
    if (clinicId != null && clinicId.isNotEmpty) {
      return _firestore
          .collection(_clinicMaterialsCollection)
          .where('category', isEqualTo: therapyType.toLowerCase())
          .where('clinicId', isEqualTo: clinicId)
          .where('tags', arrayContains: searchTerm.toLowerCase())
          .where('isActive', isEqualTo: true)
          // Removed orderBy to avoid composite index requirement
          .snapshots();
    }
    
    // Fallback to Materials collection
    Query query = _firestore
        .collection(_materialsCollection)
        .where('category', isEqualTo: therapyType.toLowerCase())
        .where('tags', arrayContains: searchTerm.toLowerCase())
        .where('isActive', isEqualTo: true);
    
    return query
        .orderBy('uploadedAt', descending: true)
        .snapshots();
  }

  // Increment download count - tries both collections
  static Future<void> incrementDownloadCount(String materialId) async {
    try {
      // Try ClinicMaterials first
      final clinicDoc = await _firestore.collection(_clinicMaterialsCollection).doc(materialId).get();
      if (clinicDoc.exists) {
        await _firestore.collection(_clinicMaterialsCollection).doc(materialId).update({
          'downloadCount': FieldValue.increment(1),
          'lastDownloaded': FieldValue.serverTimestamp(),
        });
        return;
      }
      
      // Fallback to Materials collection
      await _firestore.collection(_materialsCollection).doc(materialId).update({
        'downloadCount': FieldValue.increment(1),
        'lastDownloaded': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error incrementing download count: $e');
    }
  }
}

class MaterialsPage extends StatefulWidget {
  const MaterialsPage({super.key});

  @override
  State<MaterialsPage> createState() => _MaterialsPageState();
}

class _MaterialsPageState extends State<MaterialsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedTherapyType = 'All';
  String _parentId = '';
  String _clinicId = ''; // Add clinic ID variable
  List<String> _availableTherapyTypes = ['All'];

  // Material Categories
  List<Map<String, dynamic>> _materialCategories = [
    {
      'title': 'Motor',
      'subtitle': 'Fine & Gross Motor Skills',
      'icon': Icons.accessibility_new,
      'color': const Color(0xFF48BB78),
      'count': 0,
    },
    {
      'title': 'Speech',
      'subtitle': 'Speech & Language Therapy',
      'icon': Icons.record_voice_over,
      'color': const Color(0xFF4A90E2),
      'count': 0,
    },
    {
      'title': 'Cognitive',
      'subtitle': 'Cognitive Development',
      'icon': Icons.psychology,
      'color': const Color(0xFF9F7AEA),
      'count': 0,
    },
    {
      'title': 'General',
      'subtitle': 'General Resources',
      'icon': Icons.folder_open,
      'color': const Color(0xFFED8936),
      'count': 0,
    },
  ];

  // YouTube API configuration with new API key
  static const String _youtubeApiKey =
      'AIzaSyDQaMiBpfKXc5JlPckBYtQRRkLmrdRv0jo';
  static const String _youtubeBaseUrl =
      'https://www.googleapis.com/youtube/v3/search';
  List<Map<String, dynamic>> _youtubeVideos = [];
  bool _loadingYouTubeVideos = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _fetchYouTubeVideos();
    _testFirestoreConnection(); // Add test
  }

  // Initialize data in the correct order
  Future<void> _initializeData() async {
    await _loadParentId();
    await _loadParentClinicId();
  }

  // Test Firestore connection
  Future<void> _testFirestoreConnection() async {
    print('=== FIRESTORE CONNECTION TEST ===');
    try {
      // Test 1: Check all ClinicMaterials
      final allClinicMaterials = await FirebaseFirestore.instance
          .collection('ClinicMaterials')
          .limit(10)
          .get();
      
      print('📚 Total ClinicMaterials documents: ${allClinicMaterials.docs.length}');
      for (var doc in allClinicMaterials.docs) {
        final data = doc.data();
        print('  - ${data['clinicId']}: ${data['title']} (${data['category']})');
      }
      
      // Test 2: Specifically check CLI03 materials
      final cli03Materials = await FirebaseFirestore.instance
          .collection('ClinicMaterials')
          .where('clinicId', isEqualTo: 'CLI03')
          .get();
      
      print('🏥 CLI03 materials: ${cli03Materials.docs.length}');
      for (var doc in cli03Materials.docs) {
        final data = doc.data();
        print('  - CLI03 Material: ${data['title']} | Category: ${data['category']} | Active: ${data['isActive']}');
      }
      
      // Test 3: Check motor therapy materials for CLI03 (Physical Therapy might map to motor)
      final motorMaterials = await FirebaseFirestore.instance
          .collection('ClinicMaterials')
          .where('clinicId', isEqualTo: 'CLI03')
          .where('category', isEqualTo: 'motor')
          .get();
      
      print('🦾 CLI03 motor materials: ${motorMaterials.docs.length}');
      for (var doc in motorMaterials.docs) {
        final data = doc.data();
        print('  - Motor Material: ${data['title']} | Active: ${data['isActive']}');
      }
      
    } catch (e) {
      print('🔥 Firestore test error: $e');
    }
  }

  Future<void> _loadParentId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    final parentId = prefs.getString('parent_id');
    
    print('🔍 Debug parent ID loading:');
    print('  - user_id from prefs: $userId');
    print('  - parent_id from prefs: $parentId');
    
    String finalParentId = userId ?? parentId ?? '';
    print('✅ Final parent ID set to: $finalParentId');
    
    setState(() {
      _parentId = finalParentId;
      _clinicId = ''; // Reset clinic ID for new user
    });
    
    print('✅ Final parent ID set to: $_parentId');
    
    if (_parentId.isEmpty) {
      print('❌ No parent ID found in SharedPreferences');
    }
  }

  // Get current user's email for booking lookup
  Future<String?> _getCurrentUserEmail() async {
    try {
      // First try Firebase Auth
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null && firebaseUser.email != null) {
        print('📧 Got email from Firebase Auth: ${firebaseUser.email}');
        return firebaseUser.email;
      }
      
      // Fallback to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final storedEmail = prefs.getString('user_email') ?? prefs.getString('email');
      if (storedEmail != null) {
        print('📧 Got email from SharedPreferences: $storedEmail');
        return storedEmail;
      }
      
      print('❌ No email found in Firebase Auth or SharedPreferences');
      return null;
    } catch (e) {
      print('❌ Error getting current user email: $e');
      return null;
    }
  }

  // Load clinic ID from parent's accepted bookings
  Future<void> _loadParentClinicId() async {
    if (_parentId.isEmpty) return;
    
    try {
      print('🏥 Loading clinic ID for parent: $_parentId');
      
      // Clear any stored clinic ID to ensure fresh lookup
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('clinic_id');
      
      // Reset clinic ID for this parent
      setState(() {
        _clinicId = '';
      });
      
      // First, let's see ALL bookings for this parent to debug
      final allBookingsSnapshot = await FirebaseFirestore.instance
          .collection('AcceptedBooking')
          .where('parentInfo.parentId', isEqualTo: _parentId) // Updated to nested field
          .get();
      
      print('📊 Total bookings found for $_parentId: ${allBookingsSnapshot.docs.length}');
      
      // If no bookings found, let's check if there are ANY bookings with current user's email
      if (allBookingsSnapshot.docs.isEmpty) {
        print('🔍 Searching for bookings by email...');
        
        // Get current user's email dynamically
        final currentUserEmail = await _getCurrentUserEmail();
        if (currentUserEmail == null) {
          print('❌ No email found for current user');
          return;
        }
        
        print('🔍 Looking up bookings for email: $currentUserEmail');
        
        // Check if parentId might be stored differently
        final altBookings1 = await FirebaseFirestore.instance
            .collection('AcceptedBooking')
            .where('parentEmail', isEqualTo: currentUserEmail)
            .get();
        print('📧 Bookings by email: ${altBookings1.docs.length}');
        
        // If found by email, use that booking
        if (altBookings1.docs.isNotEmpty) {
          final emailBookingData = altBookings1.docs.first.data();
          final clinicId = emailBookingData['clinicId'] as String?;
          final approvedBy = emailBookingData['approvedBy'] as String?;
          final appointmentType = emailBookingData['appointmentType'] as String?;
          
          print('📧 Found booking by email:');
          print('  - clinicId: $clinicId');
          print('  - approvedBy: $approvedBy');  
          print('  - appointmentType: $appointmentType');
          
          // Use the clinic ID from email-based booking
          String? finalClinicId;
          if (clinicId != null && clinicId.isNotEmpty && clinicId != 'unknown') {
            finalClinicId = clinicId;
          } else if (approvedBy != null && approvedBy.startsWith('CLI')) {
            finalClinicId = approvedBy;
          }
          
          if (finalClinicId != null) {
            setState(() {
              _clinicId = finalClinicId!;
            });
            print('✅ Found clinic ID via email: $_clinicId for parent: $_parentId');
            print('📚 Appointment type: $appointmentType');
            return; // Exit early since we found the booking
          }
        } else {
          print('❌ No bookings found for email: $currentUserEmail');
        }
        
        // Check if it's in a nested field
        final altBookings2 = await FirebaseFirestore.instance
            .collection('AcceptedBooking')
            .where('parentInfo.parentId', isEqualTo: _parentId)
            .get();
        print('🏗️ Bookings by parentInfo.parentId: ${altBookings2.docs.length}');
        
        // Get a few random bookings to see the structure
        final sampleBookings = await FirebaseFirestore.instance
            .collection('AcceptedBooking')
            .limit(3)
            .get();
        
        print('📋 Sample booking structures:');
        for (var doc in sampleBookings.docs) {
          final data = doc.data();
          print('  📄 Booking ${doc.id}:');
          print('    - All keys: ${data.keys.toList()}');
          if (data.containsKey('parentId')) print('    - parentId: ${data['parentId']}');
          if (data.containsKey('parentEmail')) print('    - parentEmail: ${data['parentEmail']}');
          if (data.containsKey('parentInfo')) print('    - parentInfo: ${data['parentInfo']}');
          if (data.containsKey('clinicId')) print('    - clinicId: ${data['clinicId']}');
          if (data.containsKey('appointmentType')) print('    - appointmentType: ${data['appointmentType']}');
          print('    ---');
        }
      }
      
      for (var doc in allBookingsSnapshot.docs) {
        final data = doc.data();
        print('  - Booking ID: ${doc.id}');
        print('  - Parent ID: ${data['parentId']}');
        print('  - Clinic ID: ${data['clinicId']}');
        print('  - Approved By: ${data['approvedBy']}');
        print('  - Appointment Type: ${data['appointmentType']}');
        print('  - Status: ${data['status']}');
        print('  - All fields: ${data.keys.toList()}');
        print('  ---');
      }
      
      // Query AcceptedBooking collection for this parent's clinic - try without status filter first
      final bookingSnapshot = await FirebaseFirestore.instance
          .collection('AcceptedBooking')
          .where('parentInfo.parentId', isEqualTo: _parentId) // Changed to nested field
          .limit(1) // Just need one booking to get the clinic
          .get();
      
      if (bookingSnapshot.docs.isNotEmpty) {
        final bookingData = bookingSnapshot.docs.first.data();
        final clinicId = bookingData['clinicId'] as String?;
        final approvedBy = bookingData['approvedBy'] as String?;
        final appointmentType = bookingData['appointmentType'] as String?;
        
        print('📋 First booking data:');
        print('  - clinicId: $clinicId');
        print('  - approvedBy: $approvedBy');
        print('  - appointmentType: $appointmentType');
        
        // Use clinicId if available, otherwise try approvedBy
        String? finalClinicId;
        if (clinicId != null && clinicId.isNotEmpty && clinicId != 'unknown') {
          finalClinicId = clinicId;
        } else if (approvedBy != null && approvedBy.startsWith('CLI')) {
          finalClinicId = approvedBy;
        }
        
        if (finalClinicId != null) {
          setState(() {
            _clinicId = finalClinicId!;
          });
          print('✅ Found clinic ID: $_clinicId for parent: $_parentId');
          print('📚 Appointment type: $appointmentType');
        } else {
          print('⚠️ Could not determine clinic ID from booking data');
        }
      } else {
        print('❌ No bookings found for parent: $_parentId using nested query');
        
        // Fallback: try direct parentId field
        final fallbackBookingSnapshot = await FirebaseFirestore.instance
            .collection('AcceptedBooking')
            .where('parentId', isEqualTo: _parentId)
            .limit(1)
            .get();
            
        if (fallbackBookingSnapshot.docs.isNotEmpty) {
          final bookingData = fallbackBookingSnapshot.docs.first.data();
          final clinicId = bookingData['clinicId'] as String?;
          final approvedBy = bookingData['approvedBy'] as String?;
          
          if (clinicId != null && clinicId.isNotEmpty) {
            setState(() {
              _clinicId = clinicId;
            });
            print('✅ Found clinic ID via fallback: $_clinicId');
          } else if (approvedBy != null && approvedBy.startsWith('CLI')) {
            setState(() {
              _clinicId = approvedBy;
            });
            print('✅ Found clinic ID via approvedBy fallback: $_clinicId');
          }
        } else {
          print('❌ No bookings found in either nested or direct field queries');
          // Check if stored in SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          final storedClinicId = prefs.getString('clinic_id');
          if (storedClinicId != null && storedClinicId.isNotEmpty) {
            setState(() {
              _clinicId = storedClinicId;
            });
            print('✅ Using stored clinic ID: $_clinicId');
          }
        }
      }
    } catch (e) {
      print('❌ Error loading clinic ID: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchYouTubeVideos() async {
    setState(() {
      _loadingYouTubeVideos = true;
    });

    try {
      String searchQuery = 'child development therapy';
      if (_selectedTherapyType != 'All') {
        searchQuery = '$_selectedTherapyType child development therapy';
      }

      print('Fetching YouTube videos for: $searchQuery');

      final response = await http.get(
        Uri.parse(
          '$_youtubeBaseUrl?part=snippet&q=${Uri.encodeComponent(searchQuery)}&type=video&maxResults=3&key=$_youtubeApiKey',
        ),
      );

      print('YouTube API Response Status: ${response.statusCode}');
      print('YouTube API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['items'] != null && data['items'].isNotEmpty) {
          setState(() {
            _youtubeVideos = List<Map<String, dynamic>>.from(
              data['items'].map((item) => {
                    'id': item['id']['videoId'],
                    'title': item['snippet']['title'],
                    'description': item['snippet']['description'],
                    'thumbnail': item['snippet']['thumbnails']['medium']['url'],
                    'channelTitle': item['snippet']['channelTitle'],
                    'publishedAt': item['snippet']['publishedAt'],
                  }),
            );
            _loadingYouTubeVideos = false;
          });
        } else {
          _loadSampleYouTubeVideos();
        }
      } else {
        print('YouTube API Error: ${response.statusCode} - ${response.body}');
        _loadSampleYouTubeVideos();
      }
    } catch (e) {
      print('YouTube API Exception: $e');
      _loadSampleYouTubeVideos();
    }
  }

  void _loadSampleYouTubeVideos() {
    setState(() {
      _youtubeVideos = [
        {
          'id': 'sample1',
          'title': 'Child Development Therapy Techniques',
          'description':
              'Learn effective therapy techniques for child development',
          'thumbnail':
              'https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg',
          'channelTitle': 'Therapy Channel',
          'publishedAt': '2024-01-01T00:00:00Z',
        },
        {
          'id': 'sample2',
          'title': 'Speech Therapy for Children',
          'description': 'Professional speech therapy methods and exercises',
          'thumbnail':
              'https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg',
          'channelTitle': 'Speech Therapy Pro',
          'publishedAt': '2024-01-01T00:00:00Z',
        },
        {
          'id': 'sample3',
          'title': 'Occupational Therapy Activities',
          'description':
              'Fun and effective occupational therapy activities for kids',
          'thumbnail':
              'https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg',
          'channelTitle': 'OT for Kids',
          'publishedAt': '2024-01-01T00:00:00Z',
        },
      ];
      _loadingYouTubeVideos = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Using sample videos - YouTube API temporarily unavailable'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Widget _buildTherapyMaterials() {
    // Check if we have clinic ID loaded, otherwise show loading
    if (_clinicId.isEmpty) {
      print('⏳ Clinic ID not loaded yet, showing loading...');
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              children: [
                CircularProgressIndicator(color: Color(0xFF006A5B)),
                SizedBox(height: 16),
                Text(
                  'Loading your clinic materials...',
                  style: TextStyle(
                    color: Color(0xFF67AFA5),
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    print('🏥 Building therapy materials for clinic: $_clinicId');
    
    // Since "Physical Therapy" maps to "motor", show motor materials for CLI03
    return StreamBuilder<QuerySnapshot>(
      stream: ParentMaterialsService.getTherapyMaterials('motor', clinicId: _clinicId, parentId: _parentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(
                  color: Color(0xFF006A5B),
                ),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'Error loading therapy materials: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Icon(
                      Icons.folder_open,
                      size: 64,
                      color: Color(0xFF67AFA5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No materials available for clinic $_clinicId',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF67AFA5),
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Process the materials directly since we're querying ClinicMaterials now
        final materials = snapshot.data!.docs;
        print('🎯 Found ${materials.length} motor materials for clinic $_clinicId');
        
        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Motor Therapy Materials (${materials.length} items)',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF006A5B),
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 16),
                // Build the materials grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: materials.length,
                  itemBuilder: (context, index) {
                    final doc = materials[index];
                    final material = doc.data() as Map<String, dynamic>;
                    return _buildMaterialCard(material, doc.id);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
    
    // Original code commented out for testing
    /*
    return StreamBuilder<QuerySnapshot>(
      stream: ParentMaterialsService.getMaterialsByTherapyType(_parentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(
                  color: Color(0xFF006A5B),
                ),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'Error loading therapy materials: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.folder_open,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No therapy sessions found',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Book a therapy session to access materials',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Extract unique therapy types and clinic info from accepted bookings
        final Set<String> therapyTypes = <String>{};
        String? userClinicId;
        
        print('Processing ${snapshot.data!.docs.length} accepted bookings for parent: $_parentId');
        
        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final appointmentType = data['appointmentType'] as String?; // Changed from therapyType
          final clinicId = data['clinicId'] as String?;
          
          print('Booking data: appointmentType=$appointmentType, clinicId=$clinicId');
          
          if (appointmentType != null && appointmentType.isNotEmpty) {
            // Convert appointment type to therapy category
            String therapyCategory;
            if (appointmentType.toLowerCase().contains('speech')) {
              therapyCategory = 'speech';
            } else if (appointmentType.toLowerCase().contains('occupational')) {
              therapyCategory = 'motor';
            } else if (appointmentType.toLowerCase().contains('physical')) {
              therapyCategory = 'motor'; // Physical Therapy maps to motor skills
            } else if (appointmentType.toLowerCase().contains('cognitive')) {
              therapyCategory = 'cognitive';
            } else {
              therapyCategory = 'general';
            }
            therapyTypes.add(therapyCategory);
            print('  -> Mapped $appointmentType to $therapyCategory');
          }
          
          // Store the clinic ID (assuming user only has bookings from one clinic)
          if (clinicId != null && clinicId.isNotEmpty) {
            userClinicId = clinicId;
          }
        }
        
        print('Found therapy types: $therapyTypes');
        print('User clinic ID: $userClinicId');
        
        // If no clinic ID found, show message that user needs to book appointment
        if (userClinicId == null || userClinicId.isEmpty) {
          print('⚠️ No clinic ID found - user needs to book appointment');
          return const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Icon(Icons.info_outline, size: 64, color: Color(0xFF67AFA5)),
                    SizedBox(height: 16),
                    Text(
                      'No Materials Available',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF006A5B),
                        fontFamily: 'Poppins',
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Please book an appointment with a clinic to access therapy materials.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF67AFA5),
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (therapyTypes.isEmpty) {
          print('⚠️ No therapy types found in bookings for clinic: $userClinicId');
          return const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Icon(Icons.info_outline, size: 64, color: Color(0xFF67AFA5)),
                    SizedBox(height: 16),
                    Text(
                      'No Therapy Materials Found',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF006A5B),
                        fontFamily: 'Poppins',
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Your clinic hasn\'t uploaded materials for your therapy type yet.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF67AFA5),
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index < therapyTypes.length) {
                return _buildTherapyContainer(therapyTypes[index], userClinicId!);
              },
              childCount: 1,
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final therapyType = therapyTypes.elementAt(index);
              return _buildTherapyContainer(therapyType, userClinicId);
            },
            childCount: therapyTypes.length,
          ),
        );
      },
    );
    */
  }

  Widget _buildTherapyContainer(String therapyType, String? clinicId) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getTherapyColor(therapyType),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getTherapyIcon(therapyType),
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${therapyType.toUpperCase()} THERAPY',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF006A5B),
                      ),
                    ),
                    Text(
                      'Tap to view materials',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // Camera button
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: IconButton(
                  onPressed: _openKindoraCamera,
                  icon: const Icon(Icons.camera_alt),
                  color: const Color(0xFF006A5B),
                  iconSize: 28,
                  tooltip: 'Take Photo',
                ),
              ),
            ],
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: _buildMaterialsList(therapyType, clinicId),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialsList(String therapyType, String? clinicId) {
    // Debug logging
    print('=== MATERIALS LIST DEBUG ===');
    print('Building materials list for therapy: $therapyType, clinic: $clinicId');
    
    return StreamBuilder<QuerySnapshot>(
      stream: ParentMaterialsService.getTherapyMaterials(therapyType, clinicId: clinicId, parentId: _parentId),
      builder: (context, snapshot) {
        print('Snapshot connection state: ${snapshot.connectionState}');
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          print('Loading materials...');
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF006A5B)),
          );
        }

        if (snapshot.hasError) {
          print('Error loading materials: ${snapshot.error}');
          return Column(
            children: [
              const Icon(Icons.error, size: 48, color: Colors.red),
              const SizedBox(height: 8),
              Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          print('No materials found. Docs count: ${snapshot.data?.docs.length ?? 0}');
          return Column(
            children: [
              const Icon(Icons.folder_open, size: 48, color: Colors.grey),
              const SizedBox(height: 8),
              Text(
                'No materials available for $therapyType therapy',
                style: const TextStyle(color: Colors.grey),
              ),
              if (clinicId != null)
                Text(
                  'Clinic: $clinicId',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              const SizedBox(height: 8),
              const Text(
                'Check Firebase ClinicMaterials collection',
                style: TextStyle(color: Colors.orange, fontSize: 10),
              ),
            ],
          );
        }

        final materials = snapshot.data!.docs;
        print('Found ${materials.length} materials:');
        for (var doc in materials) {
          final data = doc.data() as Map<String, dynamic>;
          print('  - ${data['title']} (${data['category']}) from clinic ${data['clinicId']}');
        }
        
        return Column(
          children: materials.map((doc) {
            final material = doc.data() as Map<String, dynamic>;
            return _buildMaterialCard(material, doc.id);
          }).toList(),
        );
      },
    );
  }

  Widget _buildMaterialCard(Map<String, dynamic> material, String docId) {
    final fileName = material['fileName'] as String? ?? '';
    final fileSize = material['fileSize'] as String? ?? 'Unknown size';
    final uploadedAt = material['uploadedAt'] as Timestamp?;
    final isImage = material['isImage'] == true;
    final isVideo = material['isVideo'] == true;
    final isDocument = material['isDocument'] == true;
    
    // Format upload date
    String uploadDate = 'Unknown date';
    if (uploadedAt != null) {
      final date = uploadedAt.toDate();
      uploadDate = '${date.day}/${date.month}/${date.year}';
    }
    
    // Get file type indicator
    String fileType = 'File';
    Color typeColor = Colors.grey;
    if (isImage) {
      fileType = 'Image';
      typeColor = Colors.orange;
    } else if (isVideo) {
      fileType = 'Video';
      typeColor = Colors.purple;
    } else if (isDocument) {
      fileType = 'Document';
      typeColor = Colors.blue;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // File icon with type indicator
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF006A5B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getFileIcon(fileName),
                  color: const Color(0xFF006A5B),
                  size: 24,
                ),
              ),
              // File type badge
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: typeColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    fileType.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Material information
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  material['title'] ?? 'Untitled',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF006A5B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (material['description'] != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    material['description'],
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                // File details row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        fileType,
                        style: TextStyle(
                          color: typeColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      fileSize,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 10,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      uploadDate,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Action buttons
          Column(
            children: [
              // Download button
              IconButton(
                onPressed: () {
                  final downloadUrl = material['downloadUrl'] as String?;
                  if (downloadUrl != null) {
                    _downloadFile(downloadUrl, material['title'] ?? fileName);
                  }
                },
                icon: const Icon(Icons.download, size: 20),
                color: const Color(0xFF006A5B),
                tooltip: 'Download',
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
              // Open button
              IconButton(
                onPressed: () => _openMaterial(material),
                icon: const Icon(Icons.open_in_new, size: 20),
                color: const Color(0xFF006A5B),
                tooltip: 'Open',
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getTherapyColor(String therapyType) {
    switch (therapyType.toLowerCase()) {
      case 'speech':
        return const Color(0xFFFFA07A);
      case 'occupational':
        return const Color(0xFF87CEEB);
      case 'physical':
        return const Color(0xFFE8A87C);
      case 'cognitive':
        return const Color(0xFF98FB98);
      default:
        return const Color(0xFF006A5B);
    }
  }

  IconData _getTherapyIcon(String therapyType) {
    switch (therapyType.toLowerCase()) {
      case 'speech':
        return Icons.record_voice_over;
      case 'occupational':
        return Icons.accessibility_new;
      case 'physical':
        return Icons.fitness_center;
      case 'cognitive':
        return Icons.psychology;
      default:
        return Icons.healing;
    }
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      case 'mp4':
      case 'avi':
        return Icons.video_file;
      case 'mp3':
      case 'wav':
        return Icons.audio_file;
      default:
        return Icons.insert_drive_file;
    }
  }

  void _openMaterial(Map<String, dynamic> material) {
    final downloadUrl = material['downloadUrl'] as String?;
    final fileName = material['fileName'] as String?;
    final title = material['title'] as String?;
    final isImage = material['isImage'] == true;
    final isVideo = material['isVideo'] == true;
    final isDocument = material['isDocument'] == true;
    
    if (downloadUrl != null) {
      // Increment download count
      final materialId = material['materialId'] ?? material['clinicMaterialId'];
      if (materialId != null) {
        ParentMaterialsService.incrementDownloadCount(materialId);
      }
      
      // Show different options based on file type
      if (isImage) {
        _showImageViewer(downloadUrl, title ?? fileName ?? 'Image');
      } else if (isVideo) {
        _showVideoOptions(downloadUrl, title ?? fileName ?? 'Video');
      } else if (isDocument) {
        _showDocumentOptions(downloadUrl, title ?? fileName ?? 'Document');
      } else {
        // Generic file - show download options
        _showFileOptions(downloadUrl, title ?? fileName ?? 'File');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Material not available for download'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Show image in full screen with download option
  void _showImageViewer(String imageUrl, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
            maxWidth: MediaQuery.of(context).size.width * 0.95,
          ),
          child: Column(
            children: [
              // Header with title and close button
              Container(
                color: const Color(0xFF006A5B),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.download, color: Colors.white),
                      onPressed: () => _downloadFile(imageUrl, title),
                      tooltip: 'Download Image',
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Image viewer
              Expanded(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 3.0,
                  child: Center(
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            color: const Color(0xFF006A5B),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error, size: 64, color: Colors.red),
                              SizedBox(height: 16),
                              Text(
                                'Failed to load image',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Show video options
  void _showVideoOptions(String videoUrl, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Open Video: $title'),
        content: const Text('Choose how you want to view this video:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _downloadFile(videoUrl, title);
            },
            icon: const Icon(Icons.download, color: Colors.white),
            label: const Text('Download', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006A5B),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _openInBrowser(videoUrl);
            },
            icon: const Icon(Icons.play_arrow, color: Colors.white),
            label: const Text('Play', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006A5B),
            ),
          ),
        ],
      ),
    );
  }

  // Show document options
  void _showDocumentOptions(String documentUrl, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Open Document: $title'),
        content: const Text('Choose how you want to access this document:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _downloadFile(documentUrl, title);
            },
            icon: const Icon(Icons.download, color: Colors.white),
            label: const Text('Download', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006A5B),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _openInBrowser(documentUrl);
            },
            icon: const Icon(Icons.open_in_browser, color: Colors.white),
            label: const Text('View Online', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006A5B),
            ),
          ),
        ],
      ),
    );
  }

  // Show generic file options
  void _showFileOptions(String fileUrl, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Open File: $title'),
        content: const Text('Choose an action for this file:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _downloadFile(fileUrl, title);
            },
            icon: const Icon(Icons.download, color: Colors.white),
            label: const Text('Download', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006A5B),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _openInBrowser(fileUrl);
            },
            icon: const Icon(Icons.open_in_browser, color: Colors.white),
            label: const Text('Open', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006A5B),
            ),
          ),
        ],
      ),
    );
  }

  // Download file function
  Future<void> _downloadFile(String url, String fileName) async {
    try {
      print('📁 Starting download for: $fileName');
      print('🔗 URL: $url');
      
      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Downloading $fileName...'),
          backgroundColor: const Color(0xFF006A5B),
          duration: const Duration(seconds: 2),
        ),
      );

      // Download the file
      final response = await http.get(Uri.parse(url));
      print('📡 HTTP Response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        // Clean the filename
        final String fileExtension = url.split('.').last.split('?').first;
        final String cleanFileName = fileName.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
        final String fullFileName = '$cleanFileName.$fileExtension';
        
        Directory? saveDirectory;
        
        if (Platform.isAndroid) {
          // Try multiple permission strategies for Downloads folder
          try {
            bool hasPermission = false;
            
            // Try different permission types based on Android version
            var storageStatus = await Permission.storage.request();
            var manageExternalStorageStatus = await Permission.manageExternalStorage.request();
            
            print('🔐 Storage permission: $storageStatus');
            print('🔐 Manage external storage: $manageExternalStorageStatus');
            
            // Check if any permission is granted
            if (storageStatus.isGranted || manageExternalStorageStatus.isGranted) {
              hasPermission = true;
            }
            
            if (hasPermission) {
              // Use Downloads folder
              saveDirectory = Directory('/storage/emulated/0/Download');
              print('✅ Using Downloads folder: ${saveDirectory.path}');
            } else {
              // Show permission explanation and try again
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('For better access, allow storage permission. File will be saved to app folder.'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 3),
                ),
              );
              saveDirectory = await getApplicationDocumentsDirectory();
              print('📂 Using app directory: ${saveDirectory.path}');
            }
          } catch (e) {
            print('❌ Permission error: $e');
            saveDirectory = await getApplicationDocumentsDirectory();
          }
        } else {
          saveDirectory = await getApplicationDocumentsDirectory();
        }
        
        // Create directory if it doesn't exist
        if (!await saveDirectory.exists()) {
          print('📂 Creating directory: ${saveDirectory.path}');
          await saveDirectory.create(recursive: true);
        }
        
        // Save file
        final File file = File('${saveDirectory.path}/$fullFileName');
        print('📝 Writing file to: ${file.path}');
        print('📊 File size: ${response.bodyBytes.length} bytes');
        
        try {
          await file.writeAsBytes(response.bodyBytes);
          
          // Verify file was actually written
          if (await file.exists()) {
            final int fileSize = await file.length();
            print('✅ File successfully saved: ${file.path}');
            print('✅ Verified file size: $fileSize bytes');
            
            // Determine location message
            String locationMessage;
            if (file.path.contains('/storage/emulated/0/Download')) {
              locationMessage = 'Downloaded to: Downloads folder 📁\n\nOpen your file manager and look in Downloads to find: $fullFileName';
            } else {
              locationMessage = 'Downloaded to: App storage 📱\n\nFind in: File Manager > Android > data > com.example.kindora > files';
            }
            
            // Show success message with clear location info
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ $fullFileName downloaded!\n\n$locationMessage\n\nSize: ${(fileSize / 1024).round()} KB'),
                backgroundColor: const Color(0xFF006A5B),
                duration: const Duration(seconds: 8),
                action: SnackBarAction(
                  label: 'Got it',
                  textColor: Colors.white,
                  onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
                ),
              ),
            );
          } else {
            throw 'File was not created successfully';
          }
        } catch (fileError) {
          print('❌ File write error: $fileError');
          throw 'Failed to save file: $fileError';
        }
      } else {
        throw 'Failed to download file. Server responded with ${response.statusCode}';
      }
    } catch (e) {
      print('❌ Download error: $e');
      
      // Show error with option to try in browser
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download failed: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Try Browser',
            textColor: Colors.white,
            onPressed: () => _openInBrowser(url),
          ),
        ),
      );
    }
  }

  // Open file in browser
  Future<void> _openInBrowser(String url) async {
    try {
      if (await canLaunch(url)) {
        await launch(url, forceWebView: true, enableJavaScript: true);
      } else {
        throw 'Could not open file';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Show file information after download
  void _showFileInfo(String filePath, int fileSize) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Download Complete'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('File downloaded successfully!'),
              const SizedBox(height: 10),
              Text('Path: $filePath'),
              Text('Size: ${(fileSize / 1024).round()} KB'),
              const SizedBox(height: 10),
              const Text(
                'You can find this file in your file manager by navigating to:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text('Android > data > com.example.kindora > files'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Show download information
  void _showDownloadInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Download Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your files are downloaded to:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (Platform.isAndroid) ...[
              const Text('📱 Android: /storage/emulated/0/Download/'),
              const SizedBox(height: 8),
              const Text('To find your downloads:'),
              const Text('1. Open your File Manager app'),
              const Text('2. Look for "Downloads" folder'),
              const Text('3. Find your downloaded materials'),
            ] else ...[
              const Text('Your file is being downloaded to your device\'s Downloads folder.'),
              const Text('Check your browser\'s download section or your file manager to access it.'),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '💡 Tip: If you can\'t find the file, try checking your phone\'s notification panel for download completion.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final Size mq = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF006A5B),
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              color: Colors.white,
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
      ),
      drawer: const ParentNavbar(),
      body: Stack(
        children: [
          // Background images with fallback gradients
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ConstrainedBox(
              constraints: BoxConstraints.expand(height: mq.height * 0.30),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.fromARGB(255, 255, 255, 255),
                      Color.fromARGB(255, 255, 255, 255)
                    ],
                  ),
                ),
                child: Image.asset(
                  'asset/images/Ellipse 1.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(); // Gradient fallback
                  },
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ConstrainedBox(
              constraints: BoxConstraints.expand(height: mq.height * 0.3),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xFF67AFA5), Colors.white],
                  ),
                ),
                child: Image.asset(
                  'asset/images/Ellipse 2.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(); // Gradient fallback
                  },
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CustomScrollView(
              slivers: <Widget>[
                const SliverToBoxAdapter(
                  child: SizedBox(height: 30),
                ),

                // Search bar
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16.0),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search therapy materials...',
                        prefixIcon:
                            Icon(Icons.search, color: Color(0xFF006A5B)),
                        border: InputBorder.none,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.toLowerCase();
                        });
                      },
                    ),
                  ),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 16),
                ),

                // Material Categories Section
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Material Categories',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 0, 0, 0),
                          ),
                        ),
                        const SizedBox(height: 16),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.95,
                          children: _materialCategories.map((category) {
                            return _buildMaterialCategoryCard(category);
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 24),
                ),

                // Filter dropdown button
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Filter by Category:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF006A5B),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(color: const Color(0xFF006A5B)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.3),
                                spreadRadius: 1,
                                blurRadius: 3,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: DropdownButton<String>(
                            value: _selectedTherapyType,
                            icon: const Icon(Icons.arrow_drop_down,
                                color: Color(0xFF006A5B)),
                            iconSize: 24,
                            elevation: 16,
                            style: const TextStyle(color: Color(0xFF006A5B)),
                            underline: Container(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedTherapyType = newValue!;
                              });
                              _fetchYouTubeVideos(); // Refresh YouTube videos with new therapy type
                            },
                            items: _availableTherapyTypes
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 20),
                ),

                // YouTube Videos Section Header
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'YouTube Therapy Videos',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF006A5B),
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 15),
                ),
                _buildYouTubeVideos(),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 80), // Extra space at bottom
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openKindoraCamera,
        backgroundColor: const Color(0xFF006A5B),
        child: const Icon(
          Icons.camera_alt,
          color: Colors.white,
          size: 28,
        ),
        tooltip: 'Take Photo with Kindora Camera',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildYouTubeVideos() {
    if (_loadingYouTubeVideos) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: CircularProgressIndicator(
              color: Color(0xFF006A5B),
            ),
          ),
        ),
      );
    }

    if (_youtubeVideos.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              children: [
                Icon(
                  Icons.video_library,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No YouTube videos found',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Filter videos based on search query and limit to 3 videos
    final filteredVideos = _youtubeVideos
        .where((video) {
          if (_searchQuery.isEmpty) return true;
          final title = video['title'].toString().toLowerCase();
          final description = video['description'].toString().toLowerCase();
          return title.contains(_searchQuery) ||
              description.contains(_searchQuery);
        })
        .take(3)
        .toList(); // Limit to exactly 3 videos

    if (filteredVideos.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Text(
              'No YouTube videos found for the selected category',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: Container(
        height: 200,
        margin: const EdgeInsets.symmetric(horizontal: 16.0),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: filteredVideos.length,
          itemBuilder: (context, index) {
            final video = filteredVideos[index];

            return Container(
              width: 280,
              margin: const EdgeInsets.only(right: 12.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.0),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: GestureDetector(
                onTap: () {
                  _showVideoDetail(video);
                },
                child: Column(
                  children: [
                    // Video thumbnail
                    Expanded(
                      flex: 3,
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12.0),
                              topRight: Radius.circular(12.0),
                            ),
                            child: Image.network(
                              video['thumbnail'],
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color:
                                      const Color(0xFF006A5B).withOpacity(0.1),
                                  child: const Icon(
                                    Icons.play_circle_outline,
                                    size: 50,
                                    color: Color(0xFF006A5B),
                                  ),
                                );
                              },
                            ),
                          ),
                          // Play button overlay
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(12.0),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.play_arrow,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Video info
                    Expanded(
                      flex: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              video['title'] ?? 'Untitled Video',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF006A5B),
                                fontFamily: 'Poppins',
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              video['channelTitle'] ?? '',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                                fontFamily: 'Poppins',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showVideoDetail(Map<String, dynamic> videoData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          videoData['title'] ?? 'Video',
          style: const TextStyle(fontSize: 16),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.network(
                videoData['thumbnail'],
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              const SizedBox(height: 16),
              Text(
                'Channel: ${videoData['channelTitle'] ?? 'Unknown'}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (videoData['description'] != null)
                Text(
                  videoData['description'].toString().length > 200
                      ? '${videoData['description'].toString().substring(0, 200)}...'
                      : videoData['description'].toString(),
                  style: const TextStyle(fontSize: 14),
                ),
              const SizedBox(height: 8),
              Text(
                'Published: ${_formatDate(videoData['publishedAt'])}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _playVideoInApp(videoData['id'], videoData['title']);
            },
            child: const Text('Watch in App'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _openYouTubeVideo(videoData['id']);
            },
            child: const Text('Open in YouTube'),
          ),
        ],
      ),
    );
  }

  void _playVideoInApp(String videoId, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmbeddedVideoPlayer(
          videoId: videoId,
          title: title.isNotEmpty ? title : 'Therapy Video',
        ),
      ),
    );
  }

  void _openYouTubeVideo(String videoId) async {
    final youtubeUrl = 'https://www.youtube.com/watch?v=$videoId';
    final youtubeAppUrl = 'youtube://watch?v=$videoId';

    try {
      // Try to open in YouTube app first
      if (await canLaunch(youtubeAppUrl)) {
        await launch(youtubeAppUrl);
      } else if (await canLaunch(youtubeUrl)) {
        // Fallback to web browser
        await launch(youtubeUrl, forceWebView: false, enableJavaScript: true);
      } else {
        throw 'Could not launch video';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open video: $e')),
        );
      }
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown';
    }
  }

  // Camera functionality
  Future<void> _openKindoraCamera() async {
    // Show camera options dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Kindora Camera',
            style: TextStyle(
              color: Color(0xFF006A5B),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Take a photo to share with your therapy team or save therapy progress.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _launchCamera();
              },
              icon: const Icon(Icons.camera_alt, color: Colors.white),
              label: const Text('Open Camera', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006A5B),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _launchCamera() async {
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => KindoraCameraScreen(),
        ),
      );
      
      if (result == 'sent') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo sent successfully to therapy team!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      } else if (result == 'saved') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo saved to device!'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening camera: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // Build Material Category Card
  Widget _buildMaterialCategoryCard(Map<String, dynamic> category) {
    print('🔍 Building category card for: ${category['title']}');
    print('   - parentId: $_parentId');
    print('   - clinicId: $_clinicId');
    
    return StreamBuilder<QuerySnapshot>(
      stream: _parentId.isNotEmpty
          ? FirebaseFirestore.instance
              .collection('Materials')  // Changed from ClinicMaterials to Materials
              .where('category', isEqualTo: category['title'].toString().toLowerCase())
              .where('parentId', isEqualTo: _parentId)  // Filter by parentId
              .where('isActive', isEqualTo: true)
              .snapshots()
          : null,
      builder: (context, snapshot) {
        int materialCount = 0;
        if (snapshot.hasData) {
          materialCount = snapshot.data!.docs.length;
          print('📊 ${category['title']} category: $materialCount materials found');
          // Debug: show what materials were found
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            print('   - Material: ${data['title']} | Category: ${data['category']} | ParentId: ${data['parentId']}');
          }
        } else {
          print('📊 ${category['title']} category: No data yet');
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _openMaterialCategory(category['title'], category['color']),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: category['color'].withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        category['icon'],
                        size: 24,
                        color: category['color'],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      category['title'],
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      category['subtitle'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: category['color'].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$materialCount files',
                        style: TextStyle(
                          fontSize: 11,
                          color: category['color'],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Navigate to material list for specific category
  void _navigateToMaterialList(String category) {
    // Get the color for this category
    Map<String, Color> categoryColors = {
      'Motor': const Color(0xFF4CAF50),
      'Speech': const Color(0xFF2196F3),
      'Cognitive': const Color(0xFF9C27B0),
      'General': const Color(0xFFFF9800),
    };
    
    Color categoryColor = categoryColors[category] ?? const Color(0xFF006A5B);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MaterialCategoryPage(
          categoryTitle: category,
          categoryColor: categoryColor,
        ),
      ),
    );
  }

  // Open Material Category
  void _openMaterialCategory(String categoryTitle, Color categoryColor) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MaterialCategoryPage(
          categoryTitle: categoryTitle,
          categoryColor: categoryColor,
        ),
      ),
    );
  }
}

// Material Viewer for displaying PDF and other content
class MaterialViewer extends StatefulWidget {
  final Map<String, dynamic> material;
  final Color categoryColor;

  const MaterialViewer({
    super.key, 
    required this.material,
    required this.categoryColor,
  });

  @override
  State<MaterialViewer> createState() => _MaterialViewerState();
}

class _MaterialViewerState extends State<MaterialViewer> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final String materialTitle = widget.material['title'] ?? 'Material';
    final String? fileUrl = widget.material['downloadUrl'] ?? widget.material['fileUrl'];
    final String? description = widget.material['description'];
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          materialTitle,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: widget.categoryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Material Info Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: widget.categoryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.picture_as_pdf,
                            color: widget.categoryColor,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                materialTitle,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Category: ${widget.material['category']?.toString().toUpperCase() ?? 'Unknown'}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: widget.categoryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (description != null && description.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Description:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      'Uploaded: ${_formatDate(widget.material['uploadedAt'])}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: fileUrl != null ? () => _viewInApp() : null,
                    icon: const Icon(Icons.visibility),
                    label: const Text('View in App'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.categoryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: fileUrl != null ? () => _downloadMaterial() : null,
                    icon: _isLoading 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.download),
                    label: Text(_isLoading ? 'Downloading...' : 'Download'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.categoryColor.withOpacity(0.8),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.categoryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.categoryColor.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: widget.categoryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'How to view this material:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: widget.categoryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '• Tap "View in App" to view the PDF directly in the app\n'
                    '• Tap "Download" to save the file to your device\n'
                    '• Once downloaded, you can open it with any PDF reader app',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            
            if (fileUrl == null || fileUrl.isEmpty) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This material is not available for viewing. Please contact your clinic.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _viewInApp() async {
    final String? fileUrl = widget.material['downloadUrl'] ?? widget.material['fileUrl'];
    
    // Debug: Show URL being used
    print('MaterialViewer: Opening PDF with URL: $fileUrl');
    
    if (fileUrl != null && fileUrl.isNotEmpty) {
      try {
        // Show debug info to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opening PDF: ${fileUrl.length > 50 ? '${fileUrl.substring(0, 50)}...' : fileUrl}'),
            duration: Duration(seconds: 3),
          ),
        );
        
        // Navigate to in-app PDF viewer
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InAppPDFViewer(
              title: widget.material['title'] ?? 'Material',
              pdfUrl: fileUrl,
              categoryColor: widget.categoryColor,
            ),
          ),
        );
      } catch (e) {
        _showErrorDialog('Error opening file: ${e.toString()}');
      }
    } else {
      _showErrorDialog('File URL not available for this material.');
    }
  }

  Future<void> _downloadMaterial() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final String? downloadUrl = widget.material['downloadUrl'] ?? widget.material['fileUrl'];
      
      if (downloadUrl == null || downloadUrl.isEmpty) {
        _showErrorDialog('Download URL not available for this material.');
        return;
      }

      print('📁 Starting material download');
      print('🔗 URL: $downloadUrl');

      // Download the file
      final response = await http.get(Uri.parse(downloadUrl));
      print('📡 HTTP Response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        // Clean the filename
        final String fileName = widget.material['title'] ?? 'material';
        final String fileExtension = downloadUrl.split('.').last.split('?').first;
        final String cleanFileName = fileName.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
        final String fullFileName = '$cleanFileName.$fileExtension';
        
        Directory? saveDirectory;
        
        if (Platform.isAndroid) {
          // Try multiple permission strategies for Downloads folder
          try {
            bool hasPermission = false;
            
            // Try different permission types based on Android version
            var storageStatus = await Permission.storage.request();
            var manageExternalStorageStatus = await Permission.manageExternalStorage.request();
            
            print('🔐 Storage permission: $storageStatus');
            print('🔐 Manage external storage: $manageExternalStorageStatus');
            
            // Check if any permission is granted
            if (storageStatus.isGranted || manageExternalStorageStatus.isGranted) {
              hasPermission = true;
            }
            
            if (hasPermission) {
              // Use Downloads folder
              saveDirectory = Directory('/storage/emulated/0/Download');
              print('✅ Using Downloads folder: ${saveDirectory.path}');
            } else {
              // Use app directory as fallback
              saveDirectory = await getApplicationDocumentsDirectory();
              print('📂 Using app directory: ${saveDirectory.path}');
            }
          } catch (e) {
            print('❌ Permission error: $e');
            saveDirectory = await getApplicationDocumentsDirectory();
          }
        } else {
          saveDirectory = await getApplicationDocumentsDirectory();
        }
        
        // Create directory if it doesn't exist
        if (!await saveDirectory.exists()) {
          print('📂 Creating directory: ${saveDirectory.path}');
          await saveDirectory.create(recursive: true);
        }
        
        // Save file
        final File file = File('${saveDirectory.path}/$fullFileName');
        print('📝 Writing file to: ${file.path}');
        print('📊 File size: ${response.bodyBytes.length} bytes');
        
        try {
          await file.writeAsBytes(response.bodyBytes);
          
          // Verify file was actually written
          if (await file.exists()) {
            final int fileSize = await file.length();
            print('✅ File successfully saved: ${file.path}');
            print('✅ Verified file size: $fileSize bytes');
            
            // Determine location message
            String locationMessage;
            if (file.path.contains('/storage/emulated/0/Download')) {
              locationMessage = 'File saved to Downloads folder 📁\n\nOpen your file manager and look in Downloads to find your file.';
            } else {
              locationMessage = 'File saved to app storage 📱\n\nFind in: File Manager > Android > data > com.example.kindora > files';
            }
            
            // Show success dialog
            _showSuccessDialog('✅ Download Complete!\n\n$locationMessage\n\nFile: $fullFileName\nSize: ${(fileSize / 1024).round()} KB', file.path);
          } else {
            throw 'File was not created successfully';
          }
        } catch (fileError) {
          print('❌ File write error: $fileError');
          throw 'Failed to save file: $fileError';
        }
      } else {
        _showErrorDialog('Failed to download file. Please try again.');
      }
    } catch (e) {
      _showErrorDialog('Error downloading file: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog(String message, String filePath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Success'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              const SizedBox(height: 8),
              Text(
                'Saved to: $filePath',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    try {
      if (timestamp is Timestamp) {
        final date = timestamp.toDate();
        return '${date.day}/${date.month}/${date.year}';
      }
      return 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }
}

// Embedded YouTube Video Player for in-app video viewing
class EmbeddedVideoPlayer extends StatefulWidget {
  final String videoId;
  final String title;

  const EmbeddedVideoPlayer({
    super.key,
    required this.videoId,
    required this.title,
  });

  @override
  State<EmbeddedVideoPlayer> createState() => _EmbeddedVideoPlayerState();
}

class _EmbeddedVideoPlayerState extends State<EmbeddedVideoPlayer> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  void _initializePlayer() {
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      autoPlay: false,
      params: const YoutubePlayerParams(
        mute: false,
        showControls: true,
        showFullscreenButton: true,
        loop: false,
        enableCaption: true,
        captionLanguage: 'en',
      ),
    );

    _controller.setFullScreenListener((isFullScreen) {
      // Handle fullscreen changes
    });
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: const Color(0xFF006A5B),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser, color: Colors.white),
            onPressed: () => _openInYouTube(),
            tooltip: 'Open in YouTube',
          ),
        ],
      ),
      body: Column(
        children: [
          // Video Player with fixed height
          Container(
            height: 250,
            width: double.infinity,
            color: Colors.black,
            child: YoutubePlayer(
              controller: _controller,
              aspectRatio: 16 / 9,
            ),
          ),

          // Video Controls and Information Panel
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Video Title
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF006A5B),
                        fontFamily: 'Poppins',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),

                    // Action Buttons Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton(
                          icon: Icons.replay_10,
                          label: 'Replay 10s',
                          onPressed: () async {
                            final currentTime = await _controller.currentTime;
                            final newTime =
                                (currentTime - 10).clamp(0.0, double.infinity);
                            _controller.seekTo(seconds: newTime);
                          },
                        ),
                        _buildActionButton(
                          icon: Icons.play_arrow,
                          label: 'Play/Pause',
                          onPressed: () async {
                            final playerState = await _controller.playerState;
                            if (playerState == PlayerState.playing) {
                              _controller.pauseVideo();
                            } else {
                              _controller.playVideo();
                            }
                          },
                        ),
                        _buildActionButton(
                          icon: Icons.forward_10,
                          label: 'Forward 10s',
                          onPressed: () async {
                            final currentTime = await _controller.currentTime;
                            final newTime = currentTime + 10;
                            _controller.seekTo(seconds: newTime);
                          },
                        ),
                        _buildActionButton(
                          icon: Icons.fullscreen,
                          label: 'Fullscreen',
                          onPressed: () {
                            _controller.enterFullScreen();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Help Text
                    Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF006A5B).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(
                          color: const Color(0xFF006A5B).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Color(0xFF006A5B),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'This therapeutic video is playing within the Kindora app for a seamless learning experience.',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF006A5B),
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF006A5B),
            foregroundColor: Colors.white,
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(12),
            elevation: 3,
          ),
          child: Icon(icon, size: 20),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF006A5B),
            fontFamily: 'Poppins',
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _openInYouTube() async {
    final youtubeUrl = 'https://www.youtube.com/watch?v=${widget.videoId}';
    final youtubeAppUrl = 'youtube://watch?v=${widget.videoId}';

    try {
      if (await canLaunch(youtubeAppUrl)) {
        await launch(youtubeAppUrl);
      } else if (await canLaunch(youtubeUrl)) {
        await launch(youtubeUrl, forceWebView: false, enableJavaScript: true);
      } else {
        throw 'Could not launch video';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open video in YouTube: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Parent Material Folder View Page
class ParentMaterialFolderView extends StatelessWidget {
  final String category;
  final Color categoryColor;
  final String title;
  final String? clinicId;
  final String? parentId;

  const ParentMaterialFolderView({
    Key? key,
    required this.category,
    required this.categoryColor,
    required this.title,
    this.clinicId,
    this.parentId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: categoryColor,
        title: Text(
          '$title Materials',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: ParentMaterialsService.getTherapyMaterials(category, clinicId: clinicId, parentId: parentId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: categoryColor),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading materials',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please try again later',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_open_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No materials found',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No materials available in this category',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final material = doc.data() as Map<String, dynamic>;
              return _buildMaterialCard(
                  context, material, doc.id, categoryColor);
            },
          );
        },
      ),
    );
  }

  Widget _buildMaterialCard(BuildContext context, Map<String, dynamic> material,
      String docId, Color categoryColor) {
    final uploadedAt = material['uploadedAt'] as Timestamp?;
    final dateStr = uploadedAt != null
        ? '${uploadedAt.toDate().day}/${uploadedAt.toDate().month}/${uploadedAt.toDate().year}'
        : 'Unknown date';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () => _openMaterial(context, material),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // File icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getFileIcon(material['fileName'] ?? ''),
                    size: 28,
                    color: categoryColor,
                  ),
                ),
                const SizedBox(width: 16),
                // Material info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        material['title'] ?? 'Untitled',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: categoryColor,
                          fontFamily: 'Poppins',
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (material['description'] != null &&
                          material['description'].toString().isNotEmpty)
                        Text(
                          material['description'],
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            fontFamily: 'Poppins',
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            dateStr,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.download_outlined,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${material['downloadCount'] ?? 0}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Arrow icon
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getFileIcon(String fileName) {
    final extension = _getFileExtension(fileName).toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      case 'mp4':
      case 'avi':
        return Icons.video_file;
      case 'mp3':
      case 'wav':
        return Icons.audio_file;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _getFileExtension(String fileName) {
    return fileName.split('.').last;
  }

  void _openMaterial(
      BuildContext context, Map<String, dynamic> material) async {
    final downloadUrl = material['downloadUrl'] as String?;
    final materialId = material['materialId'] as String?;
    final fileName = material['fileName'] as String?;

    if (downloadUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Download URL not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Increment download count
      if (materialId != null) {
        await ParentMaterialsService.incrementDownloadCount(materialId);
      }

      // Show options for different file types
      final isImage = material['isImage'] == true;

      if (isImage) {
        // Show image in a dialog
        _showImageDialog(
            context, downloadUrl, material['title'] ?? fileName ?? 'Image');
      } else {
        // For other files, show download/open options
        _showFileOptionsDialog(context, downloadUrl, fileName ?? 'file');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening material: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showImageDialog(BuildContext context, String imageUrl, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                backgroundColor: categoryColor,
                iconTheme: const IconThemeData(color: Colors.white),
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Expanded(
                child: InteractiveViewer(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          color: categoryColor,
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            const Text('Failed to load image'),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFileOptionsDialog(
      BuildContext context, String downloadUrl, String fileName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Open $fileName'),
        content: const Text('Choose how you want to open this file:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                if (await canLaunch(downloadUrl)) {
                  await launch(downloadUrl,
                      forceWebView: false, enableJavaScript: true);
                } else {
                  throw 'Could not launch file';
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Could not open file: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: categoryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Open'),
          ),
        ],
      ),
    );
  }
}

// Content-only version (no AppBar, Drawer, or TabBar)
class MaterialsPageContent extends StatefulWidget {
  const MaterialsPageContent({super.key});

  @override
  State<MaterialsPageContent> createState() => _MaterialsPageContentState();
}

class _MaterialsPageContentState extends State<MaterialsPageContent> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedTherapyType = 'All';

  static const String _youtubeApiKey =
      'AIzaSyDQaMiBpfKXc5JlPckBYtQRRkLmrdRv0jo';
  static const String _youtubeBaseUrl =
      'https://www.googleapis.com/youtube/v3/search';
  List<Map<String, dynamic>> _youtubeVideos = [];
  bool _loadingYouTubeVideos = false;

  @override
  void initState() {
    super.initState();
    _fetchYouTubeVideos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchYouTubeVideos() async {
    setState(() {
      _loadingYouTubeVideos = true;
    });

    try {
      String searchQuery = 'child development therapy';
      if (_selectedTherapyType != 'All') {
        searchQuery = '$_selectedTherapyType child development therapy';
      }

      final response = await http.get(
        Uri.parse(
          '$_youtubeBaseUrl?part=snippet&q=${Uri.encodeComponent(searchQuery)}&type=video&maxResults=3&key=$_youtubeApiKey',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['items'] != null && data['items'].isNotEmpty) {
          setState(() {
            _youtubeVideos = List<Map<String, dynamic>>.from(
              data['items'].map((item) => {
                    'id': item['id']['videoId'],
                    'title': item['snippet']['title'],
                    'description': item['snippet']['description'],
                    'thumbnail': item['snippet']['thumbnails']['high']['url'],
                    'channelTitle': item['snippet']['channelTitle'],
                    'publishedAt': item['snippet']['publishedAt'],
                  }),
            );
            _loadingYouTubeVideos = false;
          });
        } else {
          _loadSampleYouTubeVideos();
        }
      } else {
        _loadSampleYouTubeVideos();
      }
    } catch (e) {
      print('YouTube API Exception: $e');
      _loadSampleYouTubeVideos();
    }
  }

  void _loadSampleYouTubeVideos() {
    setState(() {
      _youtubeVideos = [
        {
          'id': 'sample1',
          'title': 'Child Development Therapy Techniques',
          'description':
              'Learn effective therapy techniques for child development',
          'thumbnail':
              'https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg',
          'channelTitle': 'Therapy Channel',
          'publishedAt': '2024-01-01T00:00:00Z',
        },
        {
          'id': 'sample2',
          'title': 'Speech Therapy for Children',
          'description': 'Professional speech therapy methods and exercises',
          'thumbnail':
              'https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg',
          'channelTitle': 'Speech Therapy Pro',
          'publishedAt': '2024-01-01T00:00:00Z',
        },
        {
          'id': 'sample3',
          'title': 'Occupational Therapy Activities',
          'description':
              'Fun and effective occupational therapy activities for kids',
          'thumbnail':
              'https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg',
          'channelTitle': 'OT for Kids',
          'publishedAt': '2024-01-01T00:00:00Z',
        },
      ];
      _loadingYouTubeVideos = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size mq = MediaQuery.of(context).size;

    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: ConstrainedBox(
            constraints: BoxConstraints.expand(height: mq.height * 0.30),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.fromARGB(255, 255, 255, 255),
                    Color.fromARGB(255, 224, 241, 239)
                  ],
                ),
              ),
              child: Image.asset(
                'asset/images/Ellipse 1.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container();
                },
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: ConstrainedBox(
            constraints: BoxConstraints.expand(height: mq.height * 0.3),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xFF67AFA5), Colors.white],
                ),
              ),
              child: Image.asset(
                'asset/images/Ellipse 2.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container();
                },
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: CustomScrollView(
            slivers: <Widget>[
              const SliverToBoxAdapter(
                child: SizedBox(height: 20),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Learning Materials',
                    style: TextStyle(
                      color: Color(0xFF67AFA5),
                      fontSize: 24,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w900,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.0),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      // Search functionality handled by parent MaterialsPage
                    },
                    decoration: InputDecoration(
                      hintText: 'Search materials...',
                      border: InputBorder.none,
                      suffixIcon: IconButton(
                        icon: const Icon(
                          Icons.search,
                          color: Color(0xFF67AFA5),
                        ),
                        onPressed: () {
                          FocusScope.of(context).unfocus();
                        },
                      ),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 20),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Therapy Videos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF006A5B),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 10),
              ),
              _buildYouTubeVideos(),
              const SliverToBoxAdapter(
                child: SizedBox(height: 20),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Educational Resources',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF006A5B),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 10),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.school,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Educational resources are now organized by therapy type',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Access materials specific to your therapy sessions above',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildYouTubeVideos() {
    if (_loadingYouTubeVideos) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: CircularProgressIndicator(
              color: Color(0xFF006A5B),
            ),
          ),
        ),
      );
    }

    if (_youtubeVideos.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Text(
              'No videos available',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ),
      );
    }

    final filteredVideos = _youtubeVideos.take(3).toList();

    return SliverToBoxAdapter(
      child: Container(
        height: 200,
        margin: const EdgeInsets.symmetric(horizontal: 16.0),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: filteredVideos.length,
          itemBuilder: (context, index) {
            final video = filteredVideos[index];
            return Container(
              width: 300,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Image.network(
                        video['thumbnail'],
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: const Color(0xFF67AFA5),
                            child: const Center(
                              child: Icon(
                                Icons.play_circle_outline,
                                size: 50,
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        video['title'],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Material Category Page for viewing specific category materials
class MaterialCategoryPage extends StatefulWidget {
  final String categoryTitle;
  final Color categoryColor;

  const MaterialCategoryPage({
    super.key,
    required this.categoryTitle,
    required this.categoryColor,
  });

  @override
  State<MaterialCategoryPage> createState() => _MaterialCategoryPageState();
}

class _MaterialCategoryPageState extends State<MaterialCategoryPage> {
  String? _parentId;

  @override
  void initState() {
    super.initState();
    _loadParentId();
  }

  Future<void> _loadParentId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _parentId = prefs.getString('user_id') ?? prefs.getString('parent_id');
      print('📱 MaterialCategoryPage loaded parentId: $_parentId');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.categoryTitle} Materials',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: widget.categoryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _parentId == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Materials')
                  .where('parentId', isEqualTo: _parentId)
                  .where('category', isEqualTo: widget.categoryTitle.toLowerCase())
                  .snapshots(),
              builder: (context, snapshot) {
          print('🔍 MaterialCategoryPage Query Debug:');
          print('   - Category: ${widget.categoryTitle.toLowerCase()}');
          print('   - ParentId: $_parentId');
          print('   - Connection State: ${snapshot.connectionState}');
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            print('❌ Query Error: ${snapshot.error}');
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          print('   - Has Data: ${snapshot.hasData}');
          print('   - Doc Count: ${snapshot.hasData ? snapshot.data!.docs.length : 0}');
          
          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            print('📄 Found documents:');
            for (var doc in snapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              print('   Doc ${doc.id}: ${data.keys.toList()}');
              print('   - parentId: ${data['parentId']}');
              print('   - clinicId: ${data['clinicId']}');
              print('   - category: ${data['category']}');
              print('   - title: ${data['title']}');
            }
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_open,
                    size: 100,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No ${widget.categoryTitle} materials found',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Materials will appear here when your clinic uploads them.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final material = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.only(bottom: 16.0),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16.0),
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: widget.categoryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.picture_as_pdf,
                      color: widget.categoryColor,
                      size: 30,
                    ),
                  ),
                  title: Text(
                    material['title'] ?? 'Untitled',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        material['description'] ?? 'No description available',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Uploaded: ${_formatDate(material['uploadedAt'])}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.download,
                          color: widget.categoryColor,
                          size: 24,
                        ),
                        onPressed: () => _downloadMaterial(context, material),
                        tooltip: 'Download',
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: widget.categoryColor,
                        size: 16,
                      ),
                    ],
                  ),
                  onTap: () {
                    // Handle material tap - open material viewer
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MaterialViewer(
                          material: material,
                          categoryColor: widget.categoryColor,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    try {
      if (timestamp is Timestamp) {
        final date = timestamp.toDate();
        return '${date.day}/${date.month}/${date.year}';
      }
      return 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  // Download material method
  Future<void> _downloadMaterial(BuildContext context, Map<String, dynamic> material) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(color: widget.categoryColor),
                const SizedBox(width: 20),
                const Text('Downloading...'),
              ],
            ),
          );
        },
      );

      // Get the download URL from the material data
      final String? downloadUrl = material['downloadUrl'] ?? material['fileUrl'];
      
      if (downloadUrl == null || downloadUrl.isEmpty) {
        Navigator.of(context).pop(); // Close loading dialog
        _showErrorDialog(context, 'Download URL not available for this material.');
        return;
      }

      print('📁 Starting material download');
      print('🔗 URL: $downloadUrl');

      // Download the file
      final response = await http.get(Uri.parse(downloadUrl));
      print('📡 HTTP Response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        // Clean the filename
        final String fileName = material['title'] ?? 'material';
        final String fileExtension = downloadUrl.split('.').last.split('?').first;
        final String cleanFileName = fileName.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
        final String fullFileName = '$cleanFileName.$fileExtension';
        
        Directory? saveDirectory;
        
        if (Platform.isAndroid) {
          // Try multiple permission strategies for Downloads folder
          try {
            bool hasPermission = false;
            
            // Try different permission types based on Android version
            var storageStatus = await Permission.storage.request();
            var manageExternalStorageStatus = await Permission.manageExternalStorage.request();
            
            print('🔐 Storage permission: $storageStatus');
            print('🔐 Manage external storage: $manageExternalStorageStatus');
            
            // Check if any permission is granted
            if (storageStatus.isGranted || manageExternalStorageStatus.isGranted) {
              hasPermission = true;
            }
            
            if (hasPermission) {
              // Use Downloads folder
              saveDirectory = Directory('/storage/emulated/0/Download');
              print('✅ Using Downloads folder: ${saveDirectory.path}');
            } else {
              // Use app directory as fallback
              saveDirectory = await getApplicationDocumentsDirectory();
              print('📂 Using app directory: ${saveDirectory.path}');
            }
          } catch (e) {
            print('❌ Permission error: $e');
            saveDirectory = await getApplicationDocumentsDirectory();
          }
        } else {
          saveDirectory = await getApplicationDocumentsDirectory();
        }
        
        // Save file
        final File file = File('${saveDirectory.path}/$fullFileName');
        print('📝 Writing file to: ${file.path}');
        print('📊 File size: ${response.bodyBytes.length} bytes');
        
        try {
          await file.writeAsBytes(response.bodyBytes);
          
          // Verify file was actually written
          if (await file.exists()) {
            final int fileSize = await file.length();
            print('✅ File successfully saved: ${file.path}');
            print('✅ Verified file size: $fileSize bytes');

            // Determine location message
            String locationMessage;
            if (file.path.contains('/storage/emulated/0/Download')) {
              locationMessage = 'File saved to Downloads folder 📁\n\nOpen your file manager and look in Downloads to find your file.';
            } else {
              locationMessage = 'File saved to app storage 📱\n\nFind in: File Manager > Android > data > com.example.kindora > files';
            }

            Navigator.of(context).pop(); // Close loading dialog
            
            // Show success dialog
            _showSuccessDialog(context, '✅ Download Complete!\n\n$locationMessage\n\nFile: $fullFileName\nSize: ${(fileSize / 1024).round()} KB', file.path);
          } else {
            Navigator.of(context).pop(); // Close loading dialog
            throw 'File was not created successfully';
          }
        } catch (fileError) {
          Navigator.of(context).pop(); // Close loading dialog
          print('❌ File write error: $fileError');
          throw 'Failed to save file: $fileError';
        }
      } else {
        Navigator.of(context).pop(); // Close loading dialog
        _showErrorDialog(context, 'Failed to download file. Please try again.');
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      _showErrorDialog(context, 'Error downloading file: ${e.toString()}');
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Download Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog(BuildContext context, String message, String filePath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Download Complete'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              const SizedBox(height: 8),
              Text(
                'Saved to: $filePath',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

// In-App PDF Viewer using WebView
class InAppPDFViewer extends StatefulWidget {
  final String title;
  final String pdfUrl;
  final Color categoryColor;

  const InAppPDFViewer({
    super.key,
    required this.title,
    required this.pdfUrl,
    required this.categoryColor,
  });

  @override
  State<InAppPDFViewer> createState() => _InAppPDFViewerState();
}

class _InAppPDFViewerState extends State<InAppPDFViewer> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    print('🔗 PDF URL: ${widget.pdfUrl}');
    
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            print('📄 Page started loading: $url');
            setState(() {
              _isLoading = true;
              _hasError = false;
            });
          },
          onPageFinished: (String url) {
            print('✅ Page finished loading: $url');
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            print('❌ WebView error: ${error.description}');
            setState(() {
              _isLoading = false;
              _hasError = true;
              _errorMessage = error.description;
            });
          },
        ),
      );

    // Try multiple PDF viewing approaches
    _loadPDF();
  }

  void _loadPDF() async {
    print('🔄 Starting PDF load for: ${widget.pdfUrl}');
    
    // Validate URL
    if (!widget.pdfUrl.startsWith('http')) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Invalid PDF URL format';
      });
      return;
    }
    
    try {
      // Check if it's a Firebase Storage URL
      final bool isFirebaseUrl = widget.pdfUrl.contains('firebase') || widget.pdfUrl.contains('googleapis.com');
      
      if (isFirebaseUrl) {
        print('🔥 Detected Firebase URL, using direct approach');
        // For Firebase URLs, try direct loading first
        await _controller.loadRequest(Uri.parse(widget.pdfUrl));
        
        // Wait a bit to see if it loads
        await Future.delayed(const Duration(seconds: 5));
        
        // If still loading, try Google Docs
        if (_isLoading && !_hasError) {
          print('🔄 Direct Firebase load taking time, trying Google Docs...');
          final String googleDocsUrl = 'https://docs.google.com/viewer?url=${Uri.encodeComponent(widget.pdfUrl)}&embedded=true';
          await _controller.loadRequest(Uri.parse(googleDocsUrl));
        }
      } else {
        // For other URLs, start with Google Docs Viewer
        final String googleDocsUrl = 'https://docs.google.com/viewer?url=${Uri.encodeComponent(widget.pdfUrl)}&embedded=true';
        print('🔄 Trying Google Docs Viewer: $googleDocsUrl');
        await _controller.loadRequest(Uri.parse(googleDocsUrl));
        
        // Wait a bit to see if it loads
        await Future.delayed(const Duration(seconds: 3));
        
        // If still loading after 3 seconds, show alternative
        if (_isLoading && !_hasError) {
          print('⏰ Google Docs taking too long, trying alternative...');
          _tryAlternativePDFViewer();
        }
      }
    } catch (e) {
      print('❌ Initial PDF load failed: $e');
      _tryAlternativePDFViewer();
    }
  }

  void _tryAlternativePDFViewer() async {
    try {
      // Alternative 1: Mozilla PDF.js viewer
      final String pdfJsUrl = 'https://mozilla.github.io/pdf.js/web/viewer.html?file=${Uri.encodeComponent(widget.pdfUrl)}';
      print('🔄 Trying PDF.js Viewer: $pdfJsUrl');
      await _controller.loadRequest(Uri.parse(pdfJsUrl));
    } catch (e) {
      print('❌ PDF.js failed: $e');
      // Alternative 2: Direct PDF URL (some browsers can handle this)
      try {
        print('🔄 Trying direct PDF URL: ${widget.pdfUrl}');
        await _controller.loadRequest(Uri.parse(widget.pdfUrl));
      } catch (e2) {
        print('❌ Direct PDF failed: $e2');
        setState(() {
          _hasError = true;
          _errorMessage = 'Could not load PDF. Please try downloading or opening in browser.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: widget.categoryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _initializeWebView();
            },
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.open_in_browser, color: Colors.white),
            onPressed: () async {
              final Uri url = Uri.parse(widget.pdfUrl);
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
            tooltip: 'Open in Browser',
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_hasError)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 80,
                      color: Colors.red.shade300,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Unable to load PDF',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _errorMessage.isNotEmpty ? _errorMessage : 'There was an error loading the PDF file.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            '💡 Troubleshooting Tips:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '• Try downloading the file instead\n'
                            '• Check your internet connection\n'
                            '• The PDF might not be publicly accessible\n'
                            '• Some PDFs require special permissions',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            print('🔄 Manual retry triggered');
                            _initializeWebView();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.categoryColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final Uri url = Uri.parse(widget.pdfUrl);
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url, mode: LaunchMode.externalApplication);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Could not open URL in browser'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.open_in_browser),
                          label: const Text('Browser'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.categoryColor.withOpacity(0.8),
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            // Try to download the file as alternative
                            Navigator.of(context).pop(); // Go back
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Try using the download button to save the file to your device'),
                                backgroundColor: Color(0xFF006A5B),
                              ),
                            );
                          },
                          icon: const Icon(Icons.download),
                          label: const Text('Download'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          else
            WebViewWidget(controller: _controller),
          
          if (_isLoading)
            Container(
              color: Colors.white.withOpacity(0.8),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: widget.categoryColor,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Loading PDF...',
                      style: TextStyle(
                        fontSize: 16,
                        color: widget.categoryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
