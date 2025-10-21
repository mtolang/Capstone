import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kindora/helper/field_helper.dart';
import 'package:kindora/screens/clinic/clinic_patient_progress_report.dart';
import 'package:kindora/screens/clinic/clinic_patient_profile.dart';

class ClinicPatientListPage extends StatefulWidget {
  const ClinicPatientListPage({Key? key}) : super(key: key);

  @override
  State<ClinicPatientListPage> createState() => _ClinicPatientListPageState();
}

class _ClinicPatientListPageState extends State<ClinicPatientListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _clinicId;

  @override
  void initState() {
    super.initState();
    _loadClinicId();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadClinicId() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Debug: Print all stored keys
      final allKeys = prefs.getKeys();
      print('🔑 All stored SharedPreferences keys: $allKeys');

      // Try multiple possible keys in order of preference
      String? clinicId;

      // First, try the most likely keys
      clinicId = prefs.getString('clinic_id');
      if (clinicId != null) {
        print('✅ Found clinic ID with key "clinic_id": $clinicId');
      } else {
        print('❌ No clinic_id found, trying other keys...');

        // Try alternative keys
        final possibleKeys = ['user_id', 'clinicId', 'userId', 'id'];
        for (final key in possibleKeys) {
          clinicId = prefs.getString(key);
          if (clinicId != null) {
            print('✅ Found clinic ID with key "$key": $clinicId');
            break;
          } else {
            print('❌ No value found for key: $key');
          }
        }
      }

      print('🏥 Final clinic ID: $clinicId');

      if (mounted) {
        setState(() {
          _clinicId = clinicId;
        });
      }
    } catch (e) {
      print('❌ Error loading clinic ID: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Top ellipse background
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ConstrainedBox(
              constraints: BoxConstraints.expand(height: size.height * 0.30),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF006A5B), Color(0xFF67AFA5)],
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

          // Bottom ellipse background
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ConstrainedBox(
              constraints: BoxConstraints.expand(height: size.height * 0.30),
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

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back,
                                color: Colors.white),
                          ),
                          const Expanded(
                            child: Text(
                              'Patient Records',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                          // Debug button to check SharedPreferences
                          IconButton(
                            onPressed: () async {
                              final prefs =
                                  await SharedPreferences.getInstance();
                              final allKeys = prefs.getKeys();
                              final allData = <String, dynamic>{};
                              for (final key in allKeys) {
                                allData[key] = prefs.get(key);
                              }

                              if (mounted) {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title:
                                        const Text('SharedPreferences Debug'),
                                    content: SingleChildScrollView(
                                      child: Text(
                                        allData.entries
                                            .map((e) => '${e.key}: ${e.value}')
                                            .join('\n'),
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Close'),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.bug_report,
                                color: Colors.white),
                            tooltip: 'Debug SharedPreferences',
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Therapy Clinic Patient Records',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Search bar
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value.toLowerCase();
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Search for a Patient',
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                              fontFamily: 'Poppins',
                            ),
                            prefixIcon:
                                Icon(Icons.search, color: Colors.grey[400]),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Patient list
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    child: _clinicId == null
                        ? const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF006A5B)),
                            ),
                          )
                        : StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('AcceptedBooking')
                                .where('clinicId', isEqualTo: _clinicId)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return Center(
                                  child: Text(
                                    'Error loading patients: ${snapshot.error}',
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                );
                              }

                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFF006A5B)),
                                  ),
                                );
                              }

                              if (!snapshot.hasData ||
                                  snapshot.data!.docs.isEmpty) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.people_outline,
                                        size: 64,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No patients found',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Accepted bookings will appear here',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[500],
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              // Debug: Print total documents found
                              print(
                                  '📊 DEBUG: Found ${snapshot.data!.docs.length} AcceptedBooking documents');

                              // Process all patients without grouping (show each booking separately)
                              var patientsList = <Map<String, dynamic>>[];

                              for (var doc in snapshot.data!.docs) {
                                final data = doc.data() as Map<String, dynamic>;
                                print('📝 Document ${doc.id}: $data');

                                // Extract patient name from different possible fields
                                final childName = data['patientName'] ??
                                    data['childName'] ??
                                    data['patientInfo']?['childName'] ??
                                    'Unknown Patient';

                                final parentName = data['parentName'] ??
                                    data['patientInfo']?['parentName'] ??
                                    'Unknown Parent';

                                patientsList.add({
                                  ...data,
                                  'documentId': doc.id,
                                  'childName':
                                      childName, // Standardize field name
                                  'parentName':
                                      parentName, // Standardize field name
                                });

                                print(
                                    '✅ Added patient: $childName (Parent: $parentName)');
                              }
                              patientsList.sort((a, b) {
                                final aDate = a['appointmentDate'] != null
                                    ? (a['appointmentDate'] as Timestamp)
                                        .toDate()
                                    : DateTime(2000);
                                final bDate = b['appointmentDate'] != null
                                    ? (b['appointmentDate'] as Timestamp)
                                        .toDate()
                                    : DateTime(2000);
                                return bDate.compareTo(
                                    aDate); // Descending order (most recent first)
                              });

                              print(
                                  '📋 Final patient list count: ${patientsList.length}');

                              // Filter based on search query
                              final filteredPatients =
                                  patientsList.where((patient) {
                                if (_searchQuery.isEmpty) return true;

                                final childName =
                                    (patient['childName'] ?? '').toLowerCase();
                                final parentName =
                                    (patient['parentName'] ?? '').toLowerCase();
                                final appointmentType =
                                    (patient['appointmentType'] ?? '')
                                        .toLowerCase();

                                return childName.contains(_searchQuery) ||
                                    parentName.contains(_searchQuery) ||
                                    appointmentType.contains(_searchQuery);
                              }).toList();

                              return ListView.builder(
                                padding: const EdgeInsets.only(bottom: 100),
                                itemCount: filteredPatients.length,
                                itemBuilder: (context, index) {
                                  final patient = filteredPatients[index];
                                  return _buildPatientCard(patient);
                                },
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientCard(Map<String, dynamic> patient) {
    // Use the standardized field names we set in the processing above
    final childName = patient['childName'] ?? 'Unknown Patient';
    final parentName = patient['parentName'] ?? 'Unknown Parent';
    final appointmentType = patient['appointmentType'] ?? 'Therapy';

    // Try different possible field names for age and gender
    final childAge = patient['patientInfo']?['childAge']?.toString() ??
        patient['patientInfo']?['age']?.toString() ??
        patient['age']?.toString() ??
        'N/A';
    final childGender = patient['patientInfo']?['childGender'] ??
        patient['patientInfo']?['gender'] ??
        patient['gender'] ??
        'Not specified';

    final lastAppointment = patient['appointmentDate'] != null
        ? (patient['appointmentDate'] as Timestamp).toDate()
        : DateTime.now();

    print('🎨 Rendering card for: $childName (Parent: $parentName)');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _navigateToPatientProfile(patient),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Patient avatar
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF006A5B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Icon(
                    childGender.toLowerCase() == 'female'
                        ? Icons.face_3
                        : Icons.face,
                    size: 30,
                    color: const Color(0xFF006A5B),
                  ),
                ),
                const SizedBox(width: 16),

                // Patient info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        childName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF006A5B),
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Parent: $parentName',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Age: $childAge | $appointmentType',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Last visit: ${_formatDate(lastAppointment)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Status indicator
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(patient['status'] ?? 'confirmed')
                        .withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(patient['status'] ?? 'confirmed'),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: _getStatusColor(patient['status'] ?? 'confirmed'),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPatientDetailsPopup(Map<String, dynamic> patient) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Material(
          color: Colors.black.withOpacity(0.5), // Blur background effect
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Close button (Top Right Corner)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.grey),
                    ),
                  ),

                  // Main content
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: const Color(0xFF006A5B).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(40),
                              ),
                              child: Icon(
                                (patient['patientInfo']?['childGender'] ?? '')
                                            .toLowerCase() ==
                                        'female'
                                    ? Icons.face_3
                                    : Icons.face,
                                size: 40,
                                color: const Color(0xFF006A5B),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    patient['childName'] ?? 'Unknown Patient',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF006A5B),
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${patient['patientInfo']?['childAge'] ?? 'N/A'} years old | ${patient['patientInfo']?['childGender'] ?? 'Not specified'}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Patient Details
                        _buildDetailRow(
                          'Parent Name',
                          patient['parentName'] ?? 'Not provided',
                          Icons.person,
                        ),
                        _buildDetailRow(
                          'Contact Phone',
                          patient['patientInfo']?['parentPhone'] ??
                              'Not provided',
                          Icons.phone,
                        ),
                        _buildDetailRow(
                          'Email',
                          patient['patientInfo']?['parentEmail'] ??
                              'Not provided',
                          Icons.email,
                        ),
                        _buildDetailRow(
                          'Appointment Type',
                          patient['appointmentType'] ?? 'Therapy',
                          Icons.medical_services,
                        ),
                        _buildDetailRow(
                          'Last Appointment',
                          patient['appointmentDate'] != null
                              ? '${_formatDate((patient['appointmentDate'] as Timestamp).toDate())} at ${patient['appointmentTime'] ?? 'N/A'}'
                              : 'No appointments yet',
                          Icons.schedule,
                        ),
                        _buildDetailRow(
                          'Status',
                          _getStatusText(patient['status'] ?? 'confirmed'),
                          Icons.info,
                        ),
                        if (patient['assignmentInfo']?['specialInstructions'] !=
                                null &&
                            patient['assignmentInfo']['specialInstructions']
                                .toString()
                                .isNotEmpty)
                          _buildDetailRow(
                            'Special Instructions',
                            patient['assignmentInfo']['specialInstructions'],
                            Icons.note,
                          ),

                        const SizedBox(height: 24),

                        // Progress Tracking Section
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF006A5B).withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF006A5B).withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.trending_up,
                                    color: const Color(0xFF006A5B),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Progress Tracking',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF006A5B),
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Track patient progress and add therapy notes',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _navigateToProgressReport(patient);
                                  },
                                  icon: const Icon(Icons.assessment, size: 18),
                                  label: const Text('Create OT Assessment'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF006A5B),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _showBookingHistory(patient);
                                },
                                icon: const Icon(Icons.history, size: 18),
                                label: const Text('History'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[100],
                                  foregroundColor: Colors.grey[700],
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: const Color(0xFF006A5B),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return 'Active';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'rescheduled':
        return 'Rescheduled';
      default:
        return 'Active';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      case 'rescheduled':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  void _navigateToPatientProfile(Map<String, dynamic> patient) {
    // Extract the required parameters from the patient data
    final patientId = patient['patientInfo']?['parentId'] ?? 
                     patient['parentID'] ?? 
                     patient['id'] ?? 
                     patient['documentId'] ?? 
                     'unknown';
    
    final patientName = patient['childName'] ?? 'Unknown Patient';
    
    // For now, use empty string for image URL since we don't have profile images
    final patientImageUrl = patient['patientInfo']?['profileImageUrl'] ?? 
                           patient['profileImage'] ?? 
                           '';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClinicPatientProfile(
          patientId: patientId,
          patientName: patientName,
          patientImageUrl: patientImageUrl,
        ),
      ),
    );
  }

  void _navigateToProgressReport(Map<String, dynamic> patient) {
    // Navigate to new OT Assessment form
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClinicPatientProgressReport(
          patientName: patient['childName'],
          progressData: {
            'patientId':
                patient['id'] ?? patient['patientInfo']?['parentId'] ?? '',
            'clinicId': _clinicId,
            'childName': patient['childName'],
            'parentName': patient['parentName'],
            'age': patient['age']?.toString() ??
                patient['patientInfo']?['childAge']?.toString() ??
                '',
            'gender': patient['patientInfo']?['childGender'] ??
                patient['gender'] ??
                '',
            'contactNumber': patient['patientInfo']?['parentContact'] ?? '',
          },
        ),
      ),
    );
  }

  void _showBookingHistory(Map<String, dynamic> patient) {
    // TODO: Show booking history
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Showing booking history for ${patient['childName']}'),
        backgroundColor: const Color(0xFF006A5B),
      ),
    );
  }

  void _showAddProgressForm(Map<String, dynamic> patient) {
    // Form controllers
    final TextEditingController _diagnosisController = TextEditingController();
    final TextEditingController _sessionDurationController =
        TextEditingController();
    final TextEditingController _sessionNumberController =
        TextEditingController();
    final TextEditingController _totalSessionsController =
        TextEditingController();
    final TextEditingController _missedSessionsController =
        TextEditingController();
    final TextEditingController _attendanceRemarksController =
        TextEditingController();
    final TextEditingController _shortTermGoalsController =
        TextEditingController();
    final TextEditingController _longTermGoalsController =
        TextEditingController();
    final TextEditingController _goalProgressNotesController =
        TextEditingController();
    final TextEditingController _behaviorController = TextEditingController();
    final TextEditingController _therapyResponseController =
        TextEditingController();
    final TextEditingController _familyInvolvementController =
        TextEditingController();
    final TextEditingController _toolsUsedController = TextEditingController();
    final TextEditingController _nextSessionPlanController =
        TextEditingController();
    final TextEditingController _homeExerciseController =
        TextEditingController();
    final TextEditingController _referralNotesController =
        TextEditingController();

    // Developmental domains controllers
    final Map<String, Map<String, TextEditingController>> domainControllers = {
      'gross_motor': {
        'baseline': TextEditingController(),
        'progress': TextEditingController(),
        'remarks': TextEditingController(),
      },
      'fine_motor': {
        'baseline': TextEditingController(),
        'progress': TextEditingController(),
        'remarks': TextEditingController(),
      },
      'speech_language': {
        'baseline': TextEditingController(),
        'progress': TextEditingController(),
        'remarks': TextEditingController(),
      },
      'cognitive': {
        'baseline': TextEditingController(),
        'progress': TextEditingController(),
        'remarks': TextEditingController(),
      },
      'social_emotional': {
        'baseline': TextEditingController(),
        'progress': TextEditingController(),
        'remarks': TextEditingController(),
      },
      'self_help': {
        'baseline': TextEditingController(),
        'progress': TextEditingController(),
        'remarks': TextEditingController(),
      },
    };

    // Dropdown values
    String _selectedGender = patient['patientInfo']?['childGender'] ?? 'Male';
    String _selectedSpecialization = 'Speech Therapy';
    String _selectedFrequency = '1x/week';
    bool _referralNeeded = false;
    DateTime _selectedSessionDate = DateTime.now();
    DateTime _selectedReportDate = DateTime.now();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              insetPadding: const EdgeInsets.all(16),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.95,
                height: MediaQuery.of(context).size.height * 0.95,
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Color(0xFF006A5B),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.assessment,
                            color: Colors.white,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Progress Report - ${patient['childName']}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              _disposeAllControllers(domainControllers, [
                                _diagnosisController,
                                _sessionDurationController,
                                _sessionNumberController,
                                _totalSessionsController,
                                _missedSessionsController,
                                _attendanceRemarksController,
                                _shortTermGoalsController,
                                _longTermGoalsController,
                                _goalProgressNotesController,
                                _behaviorController,
                                _therapyResponseController,
                                _familyInvolvementController,
                                _toolsUsedController,
                                _nextSessionPlanController,
                                _homeExerciseController,
                                _referralNotesController
                              ]);
                              Navigator.of(context).pop();
                            },
                            icon: const Icon(Icons.close, color: Colors.white),
                          ),
                        ],
                      ),
                    ),

                    // Form content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Patient Information Section
                            _buildSectionHeader(
                                'Patient Information', Icons.person),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    'Child Name',
                                    patient['childName'] ?? '',
                                    enabled: false,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildTextField(
                                    'Age',
                                    patient['patientInfo']?['childAge']
                                            ?.toString() ??
                                        '',
                                    enabled: false,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDropdownField(
                                    'Gender',
                                    _selectedGender,
                                    ['Male', 'Female', 'Other'],
                                    (value) => setState(
                                        () => _selectedGender = value!),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildTextFieldWithController(
                                    'Diagnosis',
                                    _diagnosisController,
                                    hint:
                                        'e.g., Global Developmental Delay, ASD, Speech Delay',
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // 2. Therapist Information Section
                            _buildSectionHeader('Therapist Information',
                                Icons.medical_services),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    'Therapist Name',
                                    patient['assignmentInfo']?['assignedBy'] ??
                                        'Current Therapist',
                                    enabled: false,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildDropdownField(
                                    'Specialization',
                                    _selectedSpecialization,
                                    [
                                      'Speech Therapy',
                                      'Occupational Therapy',
                                      'Physical Therapy',
                                      'Behavioral Therapy',
                                      'Cognitive Therapy'
                                    ],
                                    (value) => setState(
                                        () => _selectedSpecialization = value!),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDateField(
                                    'Session Date',
                                    _selectedSessionDate,
                                    (date) => setState(
                                        () => _selectedSessionDate = date),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildTextFieldWithController(
                                    'Session Duration (minutes)',
                                    _sessionDurationController,
                                    hint: '60',
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildTextFieldWithController(
                                    'Session Number',
                                    _sessionNumberController,
                                    hint: '1',
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // 3. Attendance & Session Summary
                            _buildSectionHeader('Attendance & Session Summary',
                                Icons.calendar_today),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextFieldWithController(
                                    'Total Sessions',
                                    _totalSessionsController,
                                    hint: '0',
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildTextFieldWithController(
                                    'Missed Sessions',
                                    _missedSessionsController,
                                    hint: '0',
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildTextFieldWithController(
                              'Attendance Remarks',
                              _attendanceRemarksController,
                              hint: 'Comments about attendance consistency...',
                              maxLines: 2,
                            ),

                            const SizedBox(height: 24),

                            // 4. Therapy Goals
                            _buildSectionHeader(
                                'Therapy Goals', Icons.track_changes),
                            const SizedBox(height: 16),
                            _buildTextFieldWithController(
                              'Short-term Goals (1-3 months)',
                              _shortTermGoalsController,
                              hint:
                                  'Measurable goals for the next 1-3 months...',
                              maxLines: 3,
                            ),
                            const SizedBox(height: 16),
                            _buildTextFieldWithController(
                              'Long-term Goals (6+ months)',
                              _longTermGoalsController,
                              hint: 'Broader goals for 6+ months...',
                              maxLines: 3,
                            ),
                            const SizedBox(height: 16),
                            _buildTextFieldWithController(
                              'Goal Progress Notes',
                              _goalProgressNotesController,
                              hint:
                                  'Progress toward goals (remarks or % progress)...',
                              maxLines: 3,
                            ),

                            const SizedBox(height: 24),

                            // 5. Developmental Domains Progress
                            _buildSectionHeader(
                                'Developmental Domains Progress',
                                Icons.trending_up),
                            const SizedBox(height: 16),
                            ...domainControllers.entries.map((domain) {
                              return _buildDomainSection(
                                  domain.key, domain.value);
                            }).toList(),

                            const SizedBox(height: 24),

                            // 6. Therapist Observations
                            _buildSectionHeader(
                                'Therapist Observations', Icons.visibility),
                            const SizedBox(height: 16),
                            _buildTextFieldWithController(
                              'Behavior During Session',
                              _behaviorController,
                              hint: 'e.g., attentive, cooperative, restless...',
                              maxLines: 2,
                            ),
                            const SizedBox(height: 16),
                            _buildTextFieldWithController(
                              'Therapy Response',
                              _therapyResponseController,
                              hint: 'e.g., responds well to visual aids...',
                              maxLines: 2,
                            ),
                            const SizedBox(height: 16),
                            _buildTextFieldWithController(
                              'Family Involvement',
                              _familyInvolvementController,
                              hint: 'Parent support, home practice...',
                              maxLines: 2,
                            ),
                            const SizedBox(height: 16),
                            _buildTextFieldWithController(
                              'Tools Used',
                              _toolsUsedController,
                              hint:
                                  'Materials or techniques used in session...',
                              maxLines: 2,
                            ),

                            const SizedBox(height: 24),

                            // 7. Recommendations
                            _buildSectionHeader(
                                'Recommendations', Icons.recommend),
                            const SizedBox(height: 16),
                            _buildTextFieldWithController(
                              'Plan for Next Session',
                              _nextSessionPlanController,
                              hint: 'What to focus on next...',
                              maxLines: 3,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDropdownField(
                                    'Frequency Recommendation',
                                    _selectedFrequency,
                                    [
                                      '1x/week',
                                      '2x/week',
                                      '3x/week',
                                      'Daily',
                                      'Bi-weekly'
                                    ],
                                    (value) => setState(
                                        () => _selectedFrequency = value!),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildDateField(
                                    'Report Date',
                                    _selectedReportDate,
                                    (date) => setState(
                                        () => _selectedReportDate = date),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildTextFieldWithController(
                              'Home Exercise',
                              _homeExerciseController,
                              hint: 'Suggested activities for parents...',
                              maxLines: 3,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Checkbox(
                                  value: _referralNeeded,
                                  onChanged: (value) =>
                                      setState(() => _referralNeeded = value!),
                                  activeColor: const Color(0xFF006A5B),
                                ),
                                const Text(
                                  'Referral Needed',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                            if (_referralNeeded) ...[
                              const SizedBox(height: 16),
                              _buildTextFieldWithController(
                                'Referral Notes',
                                _referralNotesController,
                                hint:
                                    'Additional specialist referrals needed...',
                                maxLines: 2,
                              ),
                            ],

                            const SizedBox(height: 40),

                            // Save Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () async {
                                  try {
                                    // Show loading indicator
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (BuildContext context) {
                                        return const Center(
                                          child: CircularProgressIndicator(
                                            color: Color(0xFF006A5B),
                                          ),
                                        );
                                      },
                                    );

                                    await _saveComprehensiveProgress(
                                      patient,
                                      {
                                        'gender': _selectedGender,
                                        'diagnosis':
                                            _diagnosisController.text.trim(),
                                        'specialization':
                                            _selectedSpecialization,
                                        'sessionDate': _selectedSessionDate,
                                        'sessionDuration':
                                            _sessionDurationController.text
                                                .trim(),
                                        'sessionNumber':
                                            _sessionNumberController.text
                                                .trim(),
                                        'totalSessions':
                                            _totalSessionsController.text
                                                .trim(),
                                        'missedSessions':
                                            _missedSessionsController.text
                                                .trim(),
                                        'attendanceRemarks':
                                            _attendanceRemarksController.text
                                                .trim(),
                                        'shortTermGoals':
                                            _shortTermGoalsController.text
                                                .trim(),
                                        'longTermGoals':
                                            _longTermGoalsController.text
                                                .trim(),
                                        'goalProgressNotes':
                                            _goalProgressNotesController.text
                                                .trim(),
                                        'behaviorDuringSession':
                                            _behaviorController.text.trim(),
                                        'therapyResponse':
                                            _therapyResponseController.text
                                                .trim(),
                                        'familyInvolvement':
                                            _familyInvolvementController.text
                                                .trim(),
                                        'toolsUsed':
                                            _toolsUsedController.text.trim(),
                                        'nextSessionPlan':
                                            _nextSessionPlanController.text
                                                .trim(),
                                        'frequencyRecommendation':
                                            _selectedFrequency,
                                        'homeExercise':
                                            _homeExerciseController.text.trim(),
                                        'referralNeeded': _referralNeeded,
                                        'referralNotes':
                                            _referralNotesController.text
                                                .trim(),
                                        'reportDate': _selectedReportDate,
                                      },
                                      domainControllers,
                                    );

                                    // Dispose controllers
                                    _disposeAllControllers(domainControllers, [
                                      _diagnosisController,
                                      _sessionDurationController,
                                      _sessionNumberController,
                                      _totalSessionsController,
                                      _missedSessionsController,
                                      _attendanceRemarksController,
                                      _shortTermGoalsController,
                                      _longTermGoalsController,
                                      _goalProgressNotesController,
                                      _behaviorController,
                                      _therapyResponseController,
                                      _familyInvolvementController,
                                      _toolsUsedController,
                                      _nextSessionPlanController,
                                      _homeExerciseController,
                                      _referralNotesController
                                    ]);

                                    // Close loading dialog first
                                    if (mounted) Navigator.of(context).pop();
                                    // Then close the progress form
                                    if (mounted) Navigator.of(context).pop();
                                  } catch (e) {
                                    // Close loading dialog
                                    if (mounted) Navigator.of(context).pop();

                                    // Show error
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Error saving progress: $e',
                                            style: const TextStyle(
                                                fontFamily: 'Poppins'),
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF006A5B),
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Save Progress Report',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _saveProgressToDatabase(
    Map<String, dynamic> patient,
    String category,
    String progressType,
    String progressDescription,
    String therapyNotes,
  ) async {
    try {
      // Get current clinic/therapist ID
      final prefs = await SharedPreferences.getInstance();

      // Use the same clinic ID lookup logic
      String? clinicId = prefs.getString('clinic_id');
      if (clinicId == null) {
        final possibleKeys = ['user_id', 'clinicId', 'userId', 'id'];
        for (final key in possibleKeys) {
          clinicId = prefs.getString(key);
          if (clinicId != null) {
            print(
                '✅ Found clinic ID for simple progress save with key "$key": $clinicId');
            break;
          }
        }
      }

      final therapistName = prefs.getString('clinic_name') ??
          prefs.getString('user_name') ??
          'Unknown Therapist';

      if (clinicId == null) {
        throw Exception('Clinic ID not found in SharedPreferences');
      }

      // Create progress document
      final progressData = {
        // Patient Information
        'patientId': patient['patientInfo']?['parentId'] ?? '',
        'childName': patient['childName'] ?? '',
        'parentName': patient['parentName'] ?? '',

        // Clinic/Therapist Information
        'clinicId': clinicId,
        'therapistName': therapistName,

        // Progress Details
        'category': category,
        'progressType': progressType,
        'progressDescription': progressDescription,
        'therapyNotes': therapyNotes,

        // Timestamps
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'reportDate': Timestamp.fromDate(DateTime.now()),

        // Additional metadata
        'status': 'active',
        'version': 1,
      };

      // Save to ClinicProgress collection
      await FirebaseFirestore.instance
          .collection('ClinicProgress')
          .add(progressData);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Progress added successfully for ${patient['childName']}',
              style: const TextStyle(fontFamily: 'Poppins'),
            ),
            backgroundColor: const Color(0xFF006A5B),
          ),
        );
      }
    } catch (e) {
      print('Error saving progress: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error saving progress: $e',
              style: const TextStyle(fontFamily: 'Poppins'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _scheduleNewAppointment(Map<String, dynamic> patient) {
    // TODO: Navigate to schedule new appointment
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Scheduling new appointment for ${patient['childName']}'),
        backgroundColor: const Color(0xFF006A5B),
      ),
    );
  }

  // Helper methods for building form components
  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFF006A5B),
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF006A5B),
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, String value, {bool enabled = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF006A5B),
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: value,
          enabled: enabled,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF006A5B)),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            fillColor: enabled ? Colors.white : Colors.grey[100],
            filled: true,
          ),
        ),
      ],
    );
  }

  Widget _buildTextFieldWithController(
    String label,
    TextEditingController controller, {
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF006A5B),
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontFamily: 'Poppins'),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF006A5B)),
            ),
            fillColor: Colors.white,
            filled: true,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(
    String label,
    String value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF006A5B),
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: Container(),
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item,
                  style: const TextStyle(fontFamily: 'Poppins'),
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(
    String label,
    DateTime selectedDate,
    Function(DateTime) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF006A5B),
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (date != null) {
              onChanged(date);
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.grey[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                  style: const TextStyle(fontFamily: 'Poppins'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDomainSection(
      String domainKey, Map<String, TextEditingController> controllers) {
    final domainNames = {
      'gross_motor': 'Gross Motor Skills',
      'fine_motor': 'Fine Motor Skills',
      'speech_language': 'Speech & Language',
      'cognitive': 'Cognitive Skills',
      'social_emotional': 'Social & Emotional',
      'self_help': 'Self-Help / Adaptive',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[50],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            domainNames[domainKey] ?? domainKey,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF006A5B),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 16),
          _buildTextFieldWithController(
            'Baseline',
            controllers['baseline']!,
            hint: 'Initial state/condition...',
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          _buildTextFieldWithController(
            'Current Progress',
            controllers['progress']!,
            hint: 'Current state/progress...',
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          _buildTextFieldWithController(
            'Remarks',
            controllers['remarks']!,
            hint: 'Additional observations...',
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  void _disposeAllControllers(
    Map<String, Map<String, TextEditingController>> domainControllers,
    List<TextEditingController> otherControllers,
  ) {
    // Dispose domain controllers
    for (final domain in domainControllers.values) {
      for (final controller in domain.values) {
        controller.dispose();
      }
    }

    // Dispose other controllers
    for (final controller in otherControllers) {
      controller.dispose();
    }
  }

  Future<void> _saveComprehensiveProgress(
    Map<String, dynamic> patient,
    Map<String, dynamic> progressData,
    Map<String, Map<String, TextEditingController>> domainControllers,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Use the same clinic ID lookup logic
      String? clinicId = prefs.getString('clinic_id');
      if (clinicId == null) {
        final possibleKeys = ['user_id', 'clinicId', 'userId', 'id'];
        for (final key in possibleKeys) {
          clinicId = prefs.getString(key);
          if (clinicId != null) {
            print(
                '✅ Found clinic ID for progress save with key "$key": $clinicId');
            break;
          }
        }
      }

      if (clinicId == null) {
        throw Exception('Clinic ID not found in SharedPreferences');
      }

      // Build comprehensive progress data
      final comprehensiveProgressData = {
        'patientId': patient['id'],
        'childName': patient['childName'],
        'parentName': patient['parentName'],
        'clinicId': clinicId,
        'therapistId': await SharedPreferences.getInstance()
            .then((prefs) => prefs.getString('userId')),
        'date': DateTime.now().toIso8601String(),

        // Patient Information
        'patientInfo': {
          'age': patient['age']?.toString() ?? '',
          'gender': progressData['gender'] ?? '',
          'diagnosis': progressData['diagnosis'] ?? '',
        },

        // Therapist Information
        'therapistInfo': {
          'name': await SharedPreferences.getInstance()
              .then((prefs) => prefs.getString('userName') ?? ''),
          'specialization': progressData['specialization'] ?? '',
          'sessionNumber': progressData['sessionNumber'] ?? '',
          'sessionDuration': progressData['sessionDuration'] ?? '',
        },

        // Attendance & Session Summary
        'attendance': {
          'totalSessions': progressData['totalSessions'] ?? '',
          'missedSessions': progressData['missedSessions'] ?? '',
          'attendanceRemarks': progressData['attendanceRemarks'] ?? '',
        },

        // Therapy Goals
        'goals': {
          'shortTerm': progressData['shortTermGoals'] ?? '',
          'longTerm': progressData['longTermGoals'] ?? '',
          'progressNotes': progressData['goalProgressNotes'] ?? '',
        },

        // Developmental Domains
        'developmentalDomains': {},

        // Therapist Observations
        'observations': {
          'behavior': progressData['behaviorDuringSession'] ?? '',
          'response': progressData['therapyResponse'] ?? '',
          'familyInvolvement': progressData['familyInvolvement'] ?? '',
          'toolsUsed': progressData['toolsUsed'] ?? '',
        },

        // Recommendations
        'recommendations': {
          'nextSessionPlan': progressData['nextSessionPlan'] ?? '',
          'frequency': progressData['frequencyRecommendation'] ?? '',
          'homeExercises': progressData['homeExercise'] ?? '',
          'referrals': progressData['referralNeeded'] == true
              ? progressData['referralNotes'] ?? ''
              : 'None',
        },

        // Additional metadata
        'sessionDate':
            (progressData['sessionDate'] as DateTime?)?.toIso8601String() ?? '',
        'reportDate':
            (progressData['reportDate'] as DateTime?)?.toIso8601String() ?? '',
      };

      // Add developmental domains data
      for (final domainKey in domainControllers.keys) {
        comprehensiveProgressData['developmentalDomains'][domainKey] = {
          'baseline': domainControllers[domainKey]!['baseline']?.text ?? '',
          'progress': domainControllers[domainKey]!['progress']?.text ?? '',
          'remarks': domainControllers[domainKey]!['remarks']?.text ?? '',
        };
      }

      // Save to Firebase
      await FirebaseFirestore.instance
          .collection('ClinicProgress')
          .add(comprehensiveProgressData);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Comprehensive progress report saved successfully!',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
            backgroundColor: Color(0xFF006A5B),
          ),
        );
      }
    } catch (e) {
      // Show error message (but don't close dialog here, let the caller handle it)
      print('Error in _saveComprehensiveProgress: $e');
      rethrow; // Re-throw the error so the caller can handle it
    }
  }
}
