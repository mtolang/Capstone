import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'give_materials_screen.dart';

class ClinicPatientProfile extends StatefulWidget {
  final String patientId;
  final String patientName;
  final String patientImageUrl;
  final Map<String, dynamic>?
      patientData; // Add patient data from AcceptedBooking

  const ClinicPatientProfile({
    Key? key,
    required this.patientId,
    required this.patientName,
    required this.patientImageUrl,
    this.patientData,
  }) : super(key: key);

  @override
  _ClinicPatientProfileState createState() => _ClinicPatientProfileState();
}

class _ClinicPatientProfileState extends State<ClinicPatientProfile>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _parentId;
  String? _parentEmail;
  String? _clinicId;
  bool _isMenuOpen = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _extractParentInfo();
    _extractClinicId();
  }

  Future<void> _extractClinicId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _clinicId = prefs.getString('clinic_id');
      print('🏥 Extracted Clinic ID: $_clinicId');
      setState(() {});
    } catch (e) {
      print('❌ Error extracting clinic ID: $e');
    }
  }

  void _extractParentInfo() {
    // Extract parent information from the patient data passed from patient list
    if (widget.patientData != null) {
      // Check multiple possible locations for parent ID based on the Firebase structure
      _parentId = widget.patientData!['originalRequestData']?['parentInfo']
              ?['parentId'] ??
          widget.patientData!['parentId'] ??
          widget.patientData!['parentID'] ??
          widget.patientData!['patientInfo']?['parentId'] ??
          widget.patientData!['id']; // fallback to document ID

      // Extract parent email from the correct location
      _parentEmail = widget.patientData!['originalRequestData']?['parentInfo']
              ?['parentEmail'] ??
          widget.patientData!['parentEmail'];

      print('🔍 DEBUG: Full patient data structure: ${widget.patientData}');
      print('🔍 Extracted Parent ID: $_parentId');
      print('🔍 Extracted Parent Email: $_parentEmail');

      // Debug: Print the originalRequestData structure
      if (widget.patientData!['originalRequestData'] != null) {
        print(
            '🔍 originalRequestData: ${widget.patientData!['originalRequestData']}');
        if (widget.patientData!['originalRequestData']['parentInfo'] != null) {
          print(
              '🔍 parentInfo: ${widget.patientData!['originalRequestData']['parentInfo']}');
        }
      }
      
      // If still no parent ID found, try to search by child name in TherapyPhotos
      if (_parentId == null || _parentId!.isEmpty) {
        print('🔍 No parent ID found in patient data, will search by child name: ${widget.patientName}');
        // Try to get parent ID from the Info tab's successful query
        _findParentIdFromPatientData();
      }
    } else {
      print('🔍 No patient data available, will search by child name: ${widget.patientName}');
    }
  }

  // Helper method to find parent ID from patient data structure
  void _findParentIdFromPatientData() {
    if (widget.patientData != null) {
      // Additional checks for parent ID in various locations
      final data = widget.patientData!;
      
      // Check if the document ID itself is the parent ID (like AcceptedBooking structure)
      if (widget.patientId != 'unknown' && widget.patientId.startsWith('ParAcc')) {
        _parentId = widget.patientId;
        print('🔍 Using widget.patientId as parent ID: $_parentId');
        return;
      }
      
      // Check in different nested structures
      _parentId = data['parentInfo']?['parentId'] ??
          data['requestData']?['parentInfo']?['parentId'] ??
          data['bookingData']?['parentId'] ??
          data['parent']?['id'];
          
      print('🔍 Alternative parent ID search result: $_parentId');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showTerminateContractDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.red),
              SizedBox(width: 8),
              Text('Terminate Contract'),
            ],
          ),
          content: Text(
            'Are you sure you want to terminate the contract with ${widget.patientName}?\n\n'
            'This action will:\n'
            '• Remove all scheduled appointments\n'
            '• End the therapeutic relationship\n'
            '• Cannot be undone\n\n'
            'Please confirm if you want to proceed.',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _terminateContract();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Terminate Contract'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _terminateContract() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text('Terminating contract...'),
              ],
            ),
          );
        },
      );

      // Get the accepted booking document to delete
      final QuerySnapshot bookingSnapshot = await FirebaseFirestore.instance
          .collection('AcceptedBooking')
          .where('parentEmail', isEqualTo: _parentEmail)
          .where('clinicId', isEqualTo: _clinicId)
          .get();

      // Delete the accepted booking
      for (QueryDocumentSnapshot doc in bookingSnapshot.docs) {
        await doc.reference.delete();
        print('Deleted AcceptedBooking: ${doc.id}');
      }

      // Also delete any related schedules for this patient
      final QuerySnapshot scheduleSnapshot = await FirebaseFirestore.instance
          .collection('Schedule')
          .where('parentEmail', isEqualTo: _parentEmail)
          .where('clinicId', isEqualTo: _clinicId)
          .get();

      for (QueryDocumentSnapshot doc in scheduleSnapshot.docs) {
        await doc.reference.delete();
        print('Deleted Schedule: ${doc.id}');
      }

      // Close loading dialog
      Navigator.of(context).pop();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contract terminated successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back to previous screen
      Navigator.of(context).pop();

    } catch (e) {
      print('Error terminating contract: $e');
      
      // Close loading dialog if still open
      Navigator.of(context).pop();
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error terminating contract: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: GestureDetector(
        onTap: () {
          // Close menu when tapping anywhere on the screen
          if (_isMenuOpen) {
            setState(() {
              _isMenuOpen = false;
            });
          }
        },
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 30), // Increased spacing
              _buildProfileSection(),
              const SizedBox(
                  height: 20), // Added spacing between profile and tabs
              _buildTabBar(),
              const SizedBox(height: 30), // Increased spacing after tabbar
              SizedBox(
                height: MediaQuery.of(context).size.height *
                    0.6, // More space for content
                child: _buildTabBarView(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionMenu(),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 180,
      decoration: const BoxDecoration(
        color: const Color(0xFF006D63),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Stack(
        children: [
          // Top ellipse - removed gradient, only ellipse image
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          // Bottom ellipse - removed gradient, only ellipse image
          Positioned(
            bottom: -30,
            left: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          // App bar content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back,
                        color: Colors.white, size: 24),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Patient Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onSelected: (String value) {
                      if (value == 'terminate') {
                        _showTerminateContractDialog();
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem<String>(
                        value: 'terminate',
                        child: Row(
                          children: [
                            Icon(Icons.cancel, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Terminate Contract',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipOval(
              child: widget.patientImageUrl.isNotEmpty
                  ? Image.network(
                      widget.patientImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.grey),
                    )
                  : const Icon(Icons.person, size: 40, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 20), // Improved spacing
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.patientName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 12),
                // Dynamic status badge based on patient data
                FutureBuilder<Map<String, dynamic>>(
                  future: widget.patientData != null
                      ? _calculateDynamicStatus(widget.patientData!)
                      : null,
                  builder: (context, snapshot) {
                    String statusText = 'Active';
                    Color statusColor = const Color(0xFF48BB78);

                    if (snapshot.hasData) {
                      statusText = snapshot.data!['statusText'] as String;
                      statusColor = snapshot.data!['statusColor'] as Color;
                    }

                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: const Color(0xFF006D63),
          borderRadius: BorderRadius.circular(26),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: EdgeInsets.zero,
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF006D63),
        labelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        dividerColor: Colors.transparent,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        splashFactory: NoSplash.splashFactory,
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.info_outline, size: 16),
                SizedBox(width: 4),
                Text('Info'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.library_books, size: 16),
                SizedBox(width: 4),
                Text('Records'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.calendar_today, size: 16),
                SizedBox(width: 4),
                Text('Schedule'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBarView() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildInfoTab(),
          _buildRecordsTab(), // Changed from Progress to Records
          _buildScheduleTab(), // Changed from Sessions to Schedule
        ],
      ),
    );
  }

  Widget _buildInfoTab() {
    // Use parent ID if available, otherwise fallback to patient ID
    final String searchId = _parentId ?? widget.patientId;
    print('🔍 Searching ParentsAcc with ID: $searchId');

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('ParentsAcc')
          .doc(searchId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF006D63),
            ),
          );
        }

        if (snapshot.hasError) {
          print('🔥 Error in Info tab: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_outline,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No carers information available',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Error: ${snapshot.error}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red.shade400,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          print(
              '🔍 No document found for Parent ID: $searchId in ParentsAcc collection');
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_off_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No carers information found',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoCard('Carers Information', [
                _buildInfoRow('Full Name', data['Full_Name'] ?? 'N/A'),
                _buildInfoRow('Email', data['Email'] ?? 'N/A'),
                _buildInfoRow('Phone', data['Contact_Number'] ?? 'N/A'),
                _buildInfoRow('Address', data['Address'] ?? 'N/A'),
                _buildInfoRow('User Name', data['User_Name'] ?? 'N/A'),
              ]),
              const SizedBox(height: 16),
              _buildInfoCard('Child Information', [
                _buildInfoRow('Child Name', widget.patientName),
                _buildInfoRow('Age',
                    widget.patientData?['childAge']?.toString() ?? 'N/A'),
                _buildInfoRow(
                    'Gender', widget.patientData?['childGender'] ?? 'N/A'),
                _buildInfoRow('Therapy Type',
                    widget.patientData?['appointmentType'] ?? 'N/A'),
              ]),
              const SizedBox(height: 16),
              _buildInfoCard('Account Details', [
                _buildInfoRow(
                    'Registration Date', _formatDate(data['createdAt'])),
                _buildInfoRow('Last Login', _formatDate(data['lastLoginAt'])),
                _buildInfoRow('Accepted Date', _formatDate(data['acceptedAt'])),
                _buildInfoRow('Accepted By', data['acceptedBy'] ?? 'N/A'),
              ]),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecordsTab() {
    // Use parent ID from patient list and clinic ID from local storage for filtering TherapyPhotos
    final String searchParentId = _parentId ?? widget.patientId;
    final String searchClinicId = _clinicId ?? '';
    
    // DEBUGGING: Let's check the exact values and add a fallback for Kurimeow
    print('🔍 === DEBUGGING TherapyPhotos Query ===');
    print('🔍 searchParentId: "$searchParentId"');
    print('🔍 searchClinicId: "$searchClinicId"');
    print('🔍 widget.patientName: "${widget.patientName}"');
    print('🔍 widget.patientId: "${widget.patientId}"');
    print('🔍 _parentId: "$_parentId"');
    print('🔍 _clinicId: "$_clinicId"');
    
    // TEMPORARY: If this is Kurimeow, use ParAcc04 directly
    String finalParentId = searchParentId;
    String finalClinicId = searchClinicId;
    
    if (widget.patientName == 'Kurimeow') {
      finalParentId = 'ParAcc04';
      finalClinicId = 'CLI01';
      print('🔧 OVERRIDE: Using hardcoded values for Kurimeow - ParAcc04, CLI01');
    }
    
    print('🔍 Final query values: parentId="$finalParentId", clinicId="$finalClinicId"');
    
    // TEST: Let's also try a simple query to see if we can access TherapyPhotos at all
    FirebaseFirestore.instance
        .collection('TherapyPhotos')
        .limit(5)
        .get()
        .then((snapshot) {
          print('🔍 === TEST QUERY RESULTS ===');
          print('🔍 Total TherapyPhotos in collection: ${snapshot.docs.length}');
          for (var doc in snapshot.docs) {
            final data = doc.data();
            print('🔍 Document ${doc.id}:');
            print('    uploadedById: "${data['uploadedById']}"');
            print('    clinicId: "${data['clinicId']}"');
            print('    childName: "${data['childName']}"');
          }
        }).catchError((error) {
          print('🔥 TEST QUERY ERROR: $error');
        });

    // Query TherapyPhotos using uploadedById (matches parent ID) to filter by specific parent
    // Simplified query without orderBy to avoid index requirement
    print('🔍 === EXECUTING QUERY ===');
    print('🔍 Query: TherapyPhotos where uploadedById = "$finalParentId"');
    
    return StreamBuilder<QuerySnapshot>(
      stream: finalParentId.isNotEmpty && finalParentId != 'null'
          ? FirebaseFirestore.instance
              .collection('TherapyPhotos')
              .where('uploadedById', isEqualTo: finalParentId)
              .snapshots()
          : FirebaseFirestore.instance
              .collection('TherapyPhotos')
              .where('childName', isEqualTo: widget.patientName)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF006D63),
            ),
          );
        }

        if (snapshot.hasError) {
          print('🔥 === FIRESTORE ERROR ===');
          print('🔥 Error type: ${snapshot.error.runtimeType}');
          print('🔥 Error message: ${snapshot.error}');
          if (snapshot.stackTrace != null) {
            print('🔥 Stack trace: ${snapshot.stackTrace}');
          }
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.photo_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'Error loading therapy photos',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '${snapshot.error}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final allRecords = snapshot.data?.docs ?? [];
        print('🔍 === QUERY RESULTS ===');
        print('🔍 Queried for parentId: "$finalParentId"');
        print('🔍 Total TherapyPhotos found: ${allRecords.length}');
        
        // Debug: Print all available documents for debugging
        for (int i = 0; i < allRecords.length && i < 10; i++) {
          final data = allRecords[i].data() as Map<String, dynamic>;
          print('🔍 TherapyPhoto $i:');
          print('    uploadedById: "${data['uploadedById']}"');
          print('    parentId: "${data['parentId']}"');
          print('    clinicId: "${data['clinicId']}"'); 
          print('    childName: "${data['childName']}"');
          print('    category: "${data['category']}"');
          print('    isActive: ${data['isActive']}');
          print('    photoUrl: "${data['photoUrl']}"');
        }

        // Filter records by isActive and sort by uploadedAt
        var records = allRecords.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final docIsActive = data['isActive'] as bool?;
          
          // Check if photo is active
          bool isActive = docIsActive == true;
          
          print('🔍 Checking doc: isActive=$docIsActive, result=$isActive');
          
          return isActive;
        }).toList();
        
        // Sort by uploadedAt (client-side)
        records.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTime = aData['uploadedAt'] as Timestamp?;
          final bTime = bData['uploadedAt'] as Timestamp?;
          
          if (aTime == null || bTime == null) return 0;
          return bTime.compareTo(aTime); // descending order
        });

        print('🔍 === FINAL RESULTS ===');
        print('🔍 Active records count: ${records.length}');

        if (records.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.photo_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No therapy photos',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'No therapy photos have been uploaded yet',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        print('🔍 Filtered records count: ${records.length}');

        if (records.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.photo_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No therapy photos',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'No therapy photos have been uploaded yet',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Records statistics
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _buildRecordStat('Total Photos', records.length.toString()),
                  _buildRecordStat(
                      'This Month', _getThisMonthCount(records.map((e) => e).toList()).toString()),
                  _buildRecordStat(
                      'Recent', _getRecentCount(records.map((e) => e).toList()).toString()),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Photos list
            Expanded(
              child: ListView.builder(
                itemCount: records.length,
                itemBuilder: (context, index) {
                  final record = records[index].data() as Map<String, dynamic>;
                  return _buildTherapyPhotoCard(record);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildScheduleTab() {
    // Use parent email for the query - AcceptedBooking documents contain parentEmail field
    final String searchEmail = _parentEmail ?? '';
    print('🔍 Searching AcceptedBooking with parentEmail: $searchEmail');
    print('🔍 Patient Name for reference: ${widget.patientName}');

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('AcceptedBooking')
          .where('parentEmail', isEqualTo: searchEmail)
          .where('patientName', isEqualTo: widget.patientName)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF006D63),
            ),
          );
        }

        if (snapshot.hasError) {
          print('🔥 Error in Schedule tab: ${snapshot.error}');
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_month_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No schedule available',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'No scheduled appointments found',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          print(
              '🔍 No AcceptedBooking documents found for parentEmail: $searchEmail and patientName: ${widget.patientName}');
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_month_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No scheduled appointments',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'No appointments have been scheduled yet',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final schedules = snapshot.data!.docs;
        print(
            '🔍 Found ${schedules.length} AcceptedBooking documents for this patient');

        return Column(
          children: [
            // Schedule statistics with OTAssessment count for Total
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('OTAssessments')
                  .where('childName', isEqualTo: widget.patientName)
                  .where('clinicId', isEqualTo: 'CLI01')
                  .snapshots(),
              builder: (context, assessmentSnapshot) {
                final assessmentCount = assessmentSnapshot.hasData
                    ? assessmentSnapshot.data!.docs.length
                    : 0;

                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      _buildRecordStat(
                          'Assessments', assessmentCount.toString()),
                      FutureBuilder<int>(
                        future: _getUpcomingCountDynamic(schedules),
                        builder: (context, snapshot) {
                          return _buildRecordStat(
                              'Upcoming',
                              snapshot.hasData
                                  ? snapshot.data.toString()
                                  : '...');
                        },
                      ),
                      FutureBuilder<int>(
                        future: _getTotalSessionsCount(schedules),
                        builder: (context, snapshot) {
                          return _buildRecordStat(
                              'Total',
                              snapshot.hasData
                                  ? snapshot.data.toString()
                                  : '...');
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            // Schedule list - simplified to show only time and day
            Expanded(
              child: ListView.builder(
                itemCount: schedules.length,
                itemBuilder: (context, index) {
                  final schedule =
                      schedules[index].data() as Map<String, dynamic>;
                  return _buildSimpleScheduleCard(schedule);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF718096),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF2D3748),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordStat(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF006D63),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF718096),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJournalCard(Map<String, dynamic> record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                record['title'] ?? 'Journal Entry',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3748),
                ),
              ),
              Text(
                _formatDate(record['createdAt'] ?? record['timestamp']),
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF718096),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            record['description'] ??
                record['content'] ??
                'No content available',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF4A5568),
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          if (record['mood'] != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF006D63).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Mood: ${record['mood']}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF006D63),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTherapyPhotoCard(Map<String, dynamic> record) {
    final photoUrl = record['photoUrl'] as String?;
    final materialTitle = record['associatedMaterialTitle'] as String? ?? 'Progress Photo';
    final materialCategory = record['associatedMaterialCategory'] as String? ?? record['category'] as String? ?? 'therapy_progress';
    final uploadedAt = record['uploadedAt'];
    final notes = record['notes'] as String? ?? '';
    final fileName = record['fileName'] as String? ?? '';
    final fileSize = record['fileSize'] as int? ?? 0;
    final viewed = record['viewed'] as bool? ?? false;

    // Category color mapping for progress photos
    Color getCategoryColor(String category) {
      switch (category.toLowerCase()) {
        case 'progress_photo':
        case 'therapy_progress':
          return const Color(0xFF87CEEB);
        case 'speech':
          return const Color(0xFFFFA07A);
        case 'motor':
        case 'physical':
          return const Color(0xFF98FB98);
        case 'occupational':
          return const Color(0xFFE8A87C);
        case 'cognitive':
          return const Color(0xFFDDD6FE);
        default:
          return const Color(0xFF87CEEB);
      }
    }

    // Category icon mapping
    IconData getCategoryIcon(String category) {
      switch (category.toLowerCase()) {
        case 'progress_photo':
        case 'therapy_progress':
          return Icons.trending_up;
        case 'speech':
          return Icons.record_voice_over;
        case 'motor':
        case 'physical':
          return Icons.fitness_center;
        case 'occupational':
          return Icons.accessibility_new;
        case 'cognitive':
          return Icons.psychology;
        default:
          return Icons.photo;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with material info and status
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Category icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: getCategoryColor(materialCategory),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    getCategoryIcon(materialCategory),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                // Material info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        materialTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      Text(
                        materialCategory.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          color: getCategoryColor(materialCategory),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Upload date and viewed status
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatDate(uploadedAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF718096),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: viewed ? Colors.green[100] : Colors.orange[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        viewed ? 'Viewed' : 'New',
                        style: TextStyle(
                          fontSize: 10,
                          color: viewed ? Colors.green[700] : Colors.orange[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Photo preview
          if (photoUrl != null)
            GestureDetector(
              onTap: () => _showFullScreenPhoto(photoUrl, materialTitle, record),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    children: [
                      Image.network(
                        photoUrl,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 200,
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF006D63),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200,
                            color: Colors.grey[200],
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Colors.grey,
                                    size: 40,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Failed to load image',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      // Tap to expand overlay
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            Icons.fullscreen,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          
          // Notes and file info
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (notes.isNotEmpty) ...[
                  const Text(
                    'Notes:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4A5568),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notes,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF4A5568),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                // File details
                Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Color(0xFF718096),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '$fileName • ${_formatFileSize(fileSize)} • Child: ${record['childName'] ?? widget.patientName}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF718096),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFullScreenPhoto(String photoUrl, String title, Map<String, dynamic> photoData) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            // Photo viewer
            Center(
              child: InteractiveViewer(
                maxScale: 5.0,
                minScale: 0.1,
                child: Image.network(
                  photoUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.white,
                            size: 64,
                          ),
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
            
            // Header with close button and info
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 16,
                  right: 16,
                  bottom: 16,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black54,
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _formatDate(photoData['uploadedAt']),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Bottom info panel
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: MediaQuery.of(context).padding.bottom + 16,
                  top: 16,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black54,
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (photoData['notes'] != null && photoData['notes'].toString().isNotEmpty)
                      Text(
                        photoData['notes'].toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      'Category: ${photoData['associatedMaterialCategory']?.toString().toUpperCase() ?? 'GENERAL'}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }

  Widget _buildSimpleScheduleCard(Map<String, dynamic> booking) {
    // Extract day from appointment date
    String dayOfWeek = 'N/A';
    if (booking['appointmentDate'] != null) {
      try {
        DateTime date;
        if (booking['appointmentDate'] is Timestamp) {
          date = (booking['appointmentDate'] as Timestamp).toDate();
        } else if (booking['appointmentDate'] is String) {
          date = DateTime.parse(booking['appointmentDate']);
        } else {
          date = DateTime.now();
        }

        // Get day name
        List<String> weekdays = [
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday',
          'Sunday'
        ];
        dayOfWeek = weekdays[date.weekday - 1];
      } catch (e) {
        print('Error parsing date: $e');
        dayOfWeek = 'N/A';
      }
    }

    // Extract contract day if available
    String contractDay = booking['originalRequestData']?['contractInfo']
            ?['dayOfWeek'] ??
        dayOfWeek;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Day indicator
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF006D63).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  contractDay
                      .substring(0, 3)
                      .toUpperCase(), // Show first 3 letters
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF006D63),
                  ),
                ),
                const SizedBox(height: 2),
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: const Color(0xFF006D63),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Time and basic info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking['appointmentTime'] ?? 'Time not specified',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  booking['appointmentType'] ?? 'Therapy Session',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF718096),
                  ),
                ),
              ],
            ),
          ),
          // Dynamic Status indicator with FutureBuilder
          FutureBuilder<Map<String, dynamic>>(
            future: _calculateDynamicStatus(booking),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                print('❌ Profile Status calculation error: ${snapshot.error}');
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF006D63),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Active',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }

              final statusData = snapshot.data!;
              final statusColor = statusData['statusColor'] as Color;
              final statusText = statusData['statusText'] as String;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusText,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Dynamic status calculation based on contract schedule and OT assessments
  Future<Map<String, dynamic>> _calculateDynamicStatus(
      Map<String, dynamic> booking) async {
    try {
      final now = DateTime.now();

      // Extract contract information
      final contractInfo = booking['contractInfo'] as Map<String, dynamic>? ??
          booking['originalRequestData']?['contractInfo']
              as Map<String, dynamic>?;
      final appointmentTime = booking['appointmentTime'] as String?;
      final dayOfWeek = contractInfo?['dayOfWeek'] as String?;
      final childName =
          booking['childName'] ?? booking['patientName'] ?? widget.patientName;

      print('🔍 Profile: Calculating status for: $childName');
      print('   Contract day: $dayOfWeek');
      print('   Appointment time: $appointmentTime');

      // Check if there's an OT Assessment completed for this patient
      bool hasCompletedAssessment = false;
      try {
        // Try matching by childName and clinicId (most reliable)
        final nameQuery = await FirebaseFirestore.instance
            .collection('OTAssessments')
            .where('childName', isEqualTo: childName)
            .where('clinicId',
                isEqualTo: 'CLI01') // You might want to get this dynamically
            .get();

        if (nameQuery.docs.isNotEmpty) {
          hasCompletedAssessment = true;
          print('   Profile: Found OT Assessment by childName: $childName');
        } else {
          // Fallback: try by patientId
          final idQuery = await FirebaseFirestore.instance
              .collection('OTAssessments')
              .where('patientId', isEqualTo: _parentId ?? widget.patientId)
              .where('clinicId', isEqualTo: 'CLI01')
              .get();

          hasCompletedAssessment = idQuery.docs.isNotEmpty;
          print(
              '   Profile: Found OT Assessment by patientId: $hasCompletedAssessment');
        }

        print('   Profile: Final Assessment Status: $hasCompletedAssessment');
      } catch (e) {
        print('   Profile: Error checking OT Assessment: $e');
      }

      // If no contract info, use fallback logic
      if (contractInfo == null ||
          dayOfWeek == null ||
          appointmentTime == null) {
        return {
          'status': hasCompletedAssessment ? 'completed' : 'active',
          'statusText': hasCompletedAssessment ? 'Completed' : 'Active',
          'statusColor':
              hasCompletedAssessment ? Colors.blue : const Color(0xFF006D63),
        };
      }

      // Parse appointment time to get start time
      final timeMatch =
          RegExp(r'(\d{1,2}):(\d{2})').firstMatch(appointmentTime);
      if (timeMatch == null) {
        return {
          'status': hasCompletedAssessment ? 'completed' : 'active',
          'statusText': hasCompletedAssessment ? 'Completed' : 'Active',
          'statusColor':
              hasCompletedAssessment ? Colors.blue : const Color(0xFF006D63),
        };
      }

      final appointmentHour = int.parse(timeMatch.group(1)!);
      final appointmentMinute = int.parse(timeMatch.group(2)!);

      // Get current week's appointment date based on contract schedule
      final currentWeekStart = now
          .subtract(Duration(days: now.weekday - 1)); // Monday of current week
      final appointmentDayNumber = _getDayNumber(dayOfWeek);
      final thisWeekAppointment =
          currentWeekStart.add(Duration(days: appointmentDayNumber - 1));
      final appointmentDateTime = DateTime(
        thisWeekAppointment.year,
        thisWeekAppointment.month,
        thisWeekAppointment.day,
        appointmentHour,
        appointmentMinute,
      );

      print(
          '   Profile: This week appointment: ${appointmentDateTime.toString()}');
      print('   Profile: Current time: ${now.toString()}');
      print('   Profile: Current weekday: ${now.weekday} (1=Monday, 7=Sunday)');
      print('   Profile: Appointment weekday: $appointmentDayNumber');

      // Weekly Schedule Logic (same as patient list)
      final currentDayOfWeek = now.weekday; // 1=Monday, 7=Sunday

      if (currentDayOfWeek < appointmentDayNumber) {
        // Appointment day is still upcoming this week
        return {
          'status': 'upcoming',
          'statusText': 'Upcoming',
          'statusColor': Colors.orange,
        };
      } else if (currentDayOfWeek == appointmentDayNumber) {
        // Today is the appointment day
        final sessionEndTime =
            appointmentDateTime.add(const Duration(hours: 1));

        if (now.isBefore(appointmentDateTime)) {
          // Appointment hasn't started yet today
          return {
            'status': 'today',
            'statusText': 'Today',
            'statusColor': Colors.orange[600]!,
          };
        } else if (now.isBefore(sessionEndTime)) {
          // Currently in session
          return {
            'status': 'in_session',
            'statusText': 'In Session',
            'statusColor': Colors.green[600]!,
          };
        } else {
          // Session ended today
          if (hasCompletedAssessment) {
            return {
              'status': 'completed',
              'statusText': 'Completed',
              'statusColor': Colors.blue,
            };
          } else {
            return {
              'status': 'pending_assessment',
              'statusText': 'Needs Assessment',
              'statusColor': Colors.red[400]!,
            };
          }
        }
      } else {
        // Appointment day has already passed this week
        if (hasCompletedAssessment) {
          return {
            'status': 'completed',
            'statusText': 'Completed',
            'statusColor': Colors.blue,
          };
        } else {
          // Past appointment day but no assessment - still show as active
          return {
            'status': 'active',
            'statusText': 'Active',
            'statusColor': const Color(0xFF006D63),
          };
        }
      }
    } catch (e) {
      print('❌ Profile: Error calculating dynamic status: $e');
      return {
        'status': 'active',
        'statusText': 'Active',
        'statusColor': const Color(0xFF006D63),
      };
    }
  }

  int _getDayNumber(String dayOfWeek) {
    switch (dayOfWeek.toLowerCase()) {
      case 'monday':
        return 1;
      case 'tuesday':
        return 2;
      case 'wednesday':
        return 3;
      case 'thursday':
        return 4;
      case 'friday':
        return 5;
      case 'saturday':
        return 6;
      case 'sunday':
        return 7;
      default:
        return 1;
    }
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                booking['appointmentType'] ?? 'Therapy Session',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3748),
                ),
              ),
              Row(
                children: [
                  if (booking['bookingType'] == 'contract' ||
                      booking['originalRequestData']?['contractInfo'] !=
                          null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF006D63).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Contract',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF006D63),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(booking['status']),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      booking['status'] ?? 'Scheduled',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                _formatDate(booking['appointmentDate']),
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF4A5568),
                ),
              ),
            ],
          ),
          if (booking['appointmentTime'] != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  booking['appointmentTime'],
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF4A5568),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.person, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Patient: ${booking['patientName'] ?? widget.patientName}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF4A5568),
                  ),
                ),
              ),
            ],
          ),
          if (booking['additionalNotes'] != null &&
              booking['additionalNotes'].toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              booking['additionalNotes'],
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF718096),
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFloatingActionMenu() {
    if (_isMenuOpen) {
      // When menu is open, show menu options vertically
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Give Materials button
          _buildMenuButton(
            icon: Icons.folder_shared,
            label: 'Assign Materials',
            onTap: () {
              print('📁 Assign Materials tapped');
              setState(() {
                _isMenuOpen = false;
              });
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GiveMaterialsScreen(
                    patientId: widget.patientId,
                    patientName: widget.patientName,
                    parentId: _parentId,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          // Assess Client button
          _buildMenuButton(
            icon: Icons.assessment,
            label: 'Assess Client',
            onTap: () {
              print('📊 Direct assessment navigation');
              setState(() {
                _isMenuOpen = false;
              });
              _navigateToAssessment();
            },
          ),
          const SizedBox(height: 16),
          // Close button
          FloatingActionButton(
            onPressed: () {
              print('❌ Closing menu');
              setState(() {
                _isMenuOpen = false;
              });
            },
            backgroundColor: const Color(0xFF006D63),
            child: const Icon(
              Icons.close,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      );
    } else {
      // When menu is closed, show the toggle button
      return FloatingActionButton(
        onPressed: () {
          print('🔘 Opening assessment menu');
          setState(() {
            _isMenuOpen = true;
          });
        },
        backgroundColor: const Color(0xFF006D63),
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 28,
        ),
      );
    }
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          print('🔘 Menu button tapped: $label');
          onTap();
        },
        borderRadius: BorderRadius.circular(25),
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Label
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Icon button
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF006D63),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToAssessment() {
    print('🚀 _navigateToAssessment called');
    print('🚀 Widget data - Patient ID: ${widget.patientId}');
    print('🚀 Widget data - Patient Name: ${widget.patientName}');
    print('🚀 Widget data - Patient Data: ${widget.patientData}');

    // Prepare data for the assessment form
    final progressData = {
      'patientId': widget.patientId,
      'patientName': widget.patientName,
      'childName': widget.patientName,
      'parentName':
          _parentEmail?.split('@').first ?? '', // Extract name part from email
      'parentEmail': _parentEmail,
      'parentId': _parentId,
      'clinicId':
          'CLI01', // You might want to get this from a global state or service
      'childAge': widget.patientData?['childAge'],
      'childGender': widget.patientData?['childGender'],
      'appointmentType': widget.patientData?['appointmentType'],
    };

    print('🚀 Prepared progress data: $progressData');

    try {
      // Use named route navigation like other pages in the app
      print('🚀 Attempting navigation to /clinicassessment');
      Navigator.pushNamed(
        context,
        '/clinicassessment',
        arguments: {
          'patientName': widget.patientName,
          'progressData': progressData,
        },
      ).then((_) {
        print('🚀 Navigation completed successfully');
      }).catchError((error) {
        print('🔥 Navigation error: $error');
        // Show error message to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Navigation error: $error'),
            backgroundColor: Colors.red,
          ),
        );
      });
    } catch (e) {
      print('🔥 Exception during navigation: $e');
      // Show error message to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to open assessment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showManageClientOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Title
            const Text(
              'Manage Client',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 24),

            // Options
            _buildManageOption(
              icon: Icons.edit_note,
              title: 'Edit Profile',
              subtitle: 'Update patient information',
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to edit profile
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Edit Profile - Coming Soon')),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildManageOption(
              icon: Icons.schedule,
              title: 'Schedule Appointment',
              subtitle: 'Book new therapy session',
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to schedule appointment
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Schedule Appointment - Coming Soon')),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildManageOption(
              icon: Icons.history,
              title: 'View History',
              subtitle: 'See appointment history',
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to appointment history
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('View History - Coming Soon')),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildManageOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF006D63).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF006D63),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF718096),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFF718096),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return const Color(0xFF48BB78);
      case 'cancelled':
        return const Color(0xFFE53E3E);
      case 'pending':
        return const Color(0xFFED8936);
      default:
        return const Color(0xFF006D63);
    }
  }

  Future<int> _getUpcomingCountDynamic(
      List<QueryDocumentSnapshot> schedules) async {
    int count = 0;
    for (final schedule in schedules) {
      final data = schedule.data() as Map<String, dynamic>;
      final statusResult = await _calculateDynamicStatus(data);
      final status = statusResult['status'] as String;

      if (status == 'upcoming' || status == 'today') {
        count++;
      }
    }
    return count;
  }

  Future<int> _getCompletedCountDynamic(
      List<QueryDocumentSnapshot> schedules) async {
    int count = 0;
    for (final schedule in schedules) {
      final data = schedule.data() as Map<String, dynamic>;
      final statusResult = await _calculateDynamicStatus(data);
      final status = statusResult['status'] as String;

      if (status == 'completed') {
        count++;
      }
    }
    return count;
  }

  int _getUpcomingCount(List<QueryDocumentSnapshot> schedules) {
    final now = DateTime.now();

    return schedules.where((schedule) {
      final data = schedule.data() as Map<String, dynamic>;
      final appointmentDate = data['appointmentDate'];
      if (appointmentDate == null) return false;

      DateTime scheduleDate;
      if (appointmentDate is Timestamp) {
        scheduleDate = appointmentDate.toDate();
      } else if (appointmentDate is String) {
        scheduleDate = DateTime.tryParse(appointmentDate) ?? DateTime.now();
      } else {
        return false;
      }

      return scheduleDate.isAfter(now) &&
          (data['status']?.toString().toLowerCase() != 'completed');
    }).length;
  }

  int _getCompletedCount(List<QueryDocumentSnapshot> schedules) {
    return schedules.where((schedule) {
      final data = schedule.data() as Map<String, dynamic>;
      return data['status']?.toString().toLowerCase() == 'completed';
    }).length;
  }

  int _getThisMonthCount(List<QueryDocumentSnapshot> records) {
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month);

    return records.where((record) {
      final data = record.data() as Map<String, dynamic>;
      final timestamp = data['uploadedAt'] ?? data['createdAt'] ?? data['timestamp'];
      if (timestamp == null) return false;

      DateTime recordDate;
      if (timestamp is Timestamp) {
        recordDate = timestamp.toDate();
      } else if (timestamp is String) {
        recordDate = DateTime.tryParse(timestamp) ?? DateTime.now();
      } else {
        return false;
      }

      return recordDate.isAfter(thisMonth);
    }).length;
  }

  int _getRecentCount(List<QueryDocumentSnapshot> records) {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));

    return records.where((record) {
      final data = record.data() as Map<String, dynamic>;
      final timestamp = data['uploadedAt'] ?? data['createdAt'] ?? data['timestamp'];
      if (timestamp == null) return false;

      DateTime recordDate;
      if (timestamp is Timestamp) {
        recordDate = timestamp.toDate();
      } else if (timestamp is String) {
        recordDate = DateTime.tryParse(timestamp) ?? DateTime.now();
      } else {
        return false;
      }

      return recordDate.isAfter(weekAgo);
    }).length;
  }

  Future<int> _getTotalSessionsCount(
      List<QueryDocumentSnapshot> schedules) async {
    if (schedules.isEmpty) return 0;

    // Get the first schedule to extract acceptance date and day of week
    final firstSchedule = schedules.first.data() as Map<String, dynamic>;
    final acceptedAt = firstSchedule['acceptedAt'];

    if (acceptedAt == null) return 0;

    DateTime acceptanceDate;
    if (acceptedAt is Timestamp) {
      acceptanceDate = acceptedAt.toDate();
    } else if (acceptedAt is String) {
      acceptanceDate = DateTime.tryParse(acceptedAt) ?? DateTime.now();
    } else {
      return 0;
    }

    // Get the day of week from contract info
    final contractInfo =
        firstSchedule['contractInfo'] as Map<String, dynamic>? ??
            firstSchedule['originalRequestData']?['contractInfo']
                as Map<String, dynamic>?;

    if (contractInfo == null) return 0;

    final dayOfWeek = contractInfo['dayOfWeek'] as String?;
    if (dayOfWeek == null) return 0;

    // Get the target weekday number (1=Monday, 7=Sunday)
    int targetWeekday = _getDayNumber(dayOfWeek);
    if (targetWeekday == -1) return 0;

    // Find the first occurrence of the target weekday on or after acceptance date
    DateTime startDate = acceptanceDate;
    while (startDate.weekday != targetWeekday) {
      startDate = startDate.add(const Duration(days: 1));
    }

    // Count weeks from start date to today
    final now = DateTime.now();
    if (startDate.isAfter(now)) return 0;

    int totalWeeks = 0;
    DateTime currentWeek = startDate;

    while (currentWeek.isBefore(now) ||
        (currentWeek.year == now.year &&
            currentWeek.month == now.month &&
            currentWeek.day == now.day)) {
      totalWeeks++;
      currentWeek = currentWeek.add(const Duration(days: 7));
    }

    return totalWeeks;
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';

    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is String) {
      date = DateTime.tryParse(timestamp) ?? DateTime.now();
    } else {
      return 'N/A';
    }

    return '${date.day}/${date.month}/${date.year}';
  }
}
