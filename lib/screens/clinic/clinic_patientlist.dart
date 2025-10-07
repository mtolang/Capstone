import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      final clinicId = prefs.getString('clinic_id') ?? prefs.getString('user_id');
      if (mounted) {
        setState(() {
          _clinicId = clinicId;
        });
      }
    } catch (e) {
      print('Error loading clinic ID: $e');
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
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                          ),
                          const Text(
                            'Patient Records',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
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
                            prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
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
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF006A5B)),
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

                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF006A5B)),
                                  ),
                                );
                              }

                              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
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

                              // Group patients by unique child names to avoid duplicates
                              Map<String, Map<String, dynamic>> uniquePatients = {};
                              for (var doc in snapshot.data!.docs) {
                                final data = doc.data() as Map<String, dynamic>;
                                final childName = data['childName'] ?? 'Unknown Patient';
                                final patientKey = '${childName}_${data['patientInfo']?['parentId'] ?? ''}';
                                
                                if (!uniquePatients.containsKey(patientKey)) {
                                  uniquePatients[patientKey] = {
                                    ...data,
                                    'documentId': doc.id,
                                  };
                                }
                              }

                              // Convert to list and sort by date (most recent first)
                              var patientsList = uniquePatients.values.toList();
                              patientsList.sort((a, b) {
                                final aDate = a['appointmentDate'] != null 
                                    ? (a['appointmentDate'] as Timestamp).toDate()
                                    : DateTime(2000);
                                final bDate = b['appointmentDate'] != null 
                                    ? (b['appointmentDate'] as Timestamp).toDate()
                                    : DateTime(2000);
                                return bDate.compareTo(aDate); // Descending order (most recent first)
                              });

                              // Filter based on search query
                              final filteredPatients = patientsList.where((patient) {
                                if (_searchQuery.isEmpty) return true;
                                
                                final childName = (patient['childName'] ?? '').toLowerCase();
                                final parentName = (patient['parentName'] ?? '').toLowerCase();
                                final appointmentType = (patient['appointmentType'] ?? '').toLowerCase();
                                
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
    final childName = patient['childName'] ?? 'Unknown Patient';
    final parentName = patient['parentName'] ?? 'Unknown Parent';
    final appointmentType = patient['appointmentType'] ?? 'Therapy';
    final childAge = patient['patientInfo']?['childAge']?.toString() ?? 'N/A';
    final childGender = patient['patientInfo']?['childGender'] ?? 'Not specified';
    final lastAppointment = patient['appointmentDate'] != null
        ? (patient['appointmentDate'] as Timestamp).toDate()
        : DateTime.now();

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
          onTap: () => _showPatientDetailsPopup(patient),
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(patient['status'] ?? 'confirmed').withOpacity(0.2),
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
                  // Progress Report Button (Top Right)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF006A5B),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            Navigator.pop(context);
                            _navigateToProgressReport(patient);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.analytics, color: Colors.white, size: 16),
                                SizedBox(width: 4),
                                Text(
                                  'Progress',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

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
                                (patient['patientInfo']?['childGender'] ?? '').toLowerCase() == 'female'
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
                          patient['patientInfo']?['parentPhone'] ?? 'Not provided',
                          Icons.phone,
                        ),
                        _buildDetailRow(
                          'Email',
                          patient['patientInfo']?['parentEmail'] ?? 'Not provided',
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
                        if (patient['assignmentInfo']?['specialInstructions'] != null &&
                            patient['assignmentInfo']['specialInstructions'].toString().isNotEmpty)
                          _buildDetailRow(
                            'Special Instructions',
                            patient['assignmentInfo']['specialInstructions'],
                            Icons.note,
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
                                onPressed: () {
                                  Navigator.pop(context);
                                  _scheduleNewAppointment(patient);
                                },
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Schedule'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF006A5B),
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

  void _navigateToProgressReport(Map<String, dynamic> patient) {
    // TODO: Navigate to progress report page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening progress report for ${patient['childName']}'),
        backgroundColor: const Color(0xFF006A5B),
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

  void _scheduleNewAppointment(Map<String, dynamic> patient) {
    // TODO: Navigate to schedule new appointment
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Scheduling new appointment for ${patient['childName']}'),
        backgroundColor: const Color(0xFF006A5B),
      ),
    );
  }
}
