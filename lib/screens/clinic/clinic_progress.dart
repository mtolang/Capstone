import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'client_progress_detail.dart';

class ClinicProgress extends StatefulWidget {
  const ClinicProgress({Key? key}) : super(key: key);

  @override
  State<ClinicProgress> createState() => _ClinicProgressState();
}

class _ClinicProgressState extends State<ClinicProgress> {
  String? clinicId;
  List<Map<String, dynamic>> clientsWithProgress = [];
  List<Map<String, dynamic>> progressReports = [];
  bool isLoading = true;

  // Analytics data
  Map<String, int> monthlyReports = {};
  Map<String, int> progressTypeStats = {};
  List<double> weeklyProgressScores = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _getClinicId();
    await _loadClientsAndProgress();
  }

  Future<void> _getClinicId() async {
    final prefs = await SharedPreferences.getInstance();

    // Debug: Print all stored keys
    print('🔍 All SharedPreferences keys: ${prefs.getKeys()}');

    // Use the same lookup logic as clinic_patientlist.dart
    String? clinicId = prefs.getString('clinic_id');
    print('🔍 clinic_id key result: $clinicId');

    if (clinicId == null) {
      final possibleKeys = ['user_id', 'clinicId', 'userId', 'id'];
      for (final key in possibleKeys) {
        clinicId = prefs.getString(key);
        print('🔍 Trying key "$key": $clinicId');
        if (clinicId != null) {
          print('✅ Found clinic ID with key "$key": $clinicId');
          break;
        }
      }
    } else {
      print('✅ Found clinic ID with primary key "clinic_id": $clinicId');
    }

    if (clinicId == null) {
      print('❌ No clinic ID found in any key!');
    }

    setState(() {
      this.clinicId = clinicId;
    });
  }

  Future<void> _loadClientsAndProgress() async {
    if (clinicId == null) {
      print('❌ Clinic ID is null, cannot load data');
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      print('🚀 Starting data loading with clinic ID: $clinicId');
      final startTime = DateTime.now();

      // Load AcceptedBooking and OTAssessments collections
      print('🔍 Loading AcceptedBooking and OTAssessments...');

      final futures = await Future.wait([
        FirebaseFirestore.instance
            .collection('AcceptedBooking')
            .where('clinicId', isEqualTo: clinicId)
            .get(),
        FirebaseFirestore.instance
            .collection('OTAssessments')
            .where('clinicId', isEqualTo: clinicId)
            .get(),
      ]);

      final patientsSnapshot = futures[0];
      final assessmentsSnapshot = futures[1];

      print(
          '📊 AcceptedBooking query returned: ${patientsSnapshot.docs.length} documents');
      print(
          '📊 OTAssessments query returned: ${assessmentsSnapshot.docs.length} documents');

      // Debug: Print first few documents to see structure
      if (patientsSnapshot.docs.isNotEmpty) {
        print(
            '🔬 First AcceptedBooking doc: ${patientsSnapshot.docs.first.data()}');
      }
      if (assessmentsSnapshot.docs.isNotEmpty) {
        print(
            '🔬 First OTAssessment doc: ${assessmentsSnapshot.docs.first.data()}');
      }

      // Create a map of OT assessments by patient ID for O(1) lookup
      final Map<String, List<Map<String, dynamic>>> assessmentsByPatient = {};
      final List<Map<String, dynamic>> allAssessments = [];

      print(
          '📊 Processing: ${patientsSnapshot.docs.length} bookings, ${assessmentsSnapshot.docs.length} assessments');

      // Process analytics data with assessment documents
      _processAnalyticsData(assessmentsSnapshot.docs);

      // Process OT assessments
      for (var doc in assessmentsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        allAssessments.add(data);

        final patientId = data['patientId']?.toString() ?? '';
        if (patientId.isNotEmpty) {
          assessmentsByPatient.putIfAbsent(patientId, () => []).add(data);
        }
      }

      // Process clients data efficiently
      final List<Map<String, dynamic>> clientsList = [];

      for (var doc in patientsSnapshot.docs) {
        final clientData = doc.data() as Map<String, dynamic>;
        final bookingId = doc.id;
        final clientId = clientData['patientId']?.toString() ?? bookingId;

        // Extract child name from different possible fields
        final childName = clientData['patientName'] ??
            clientData['childName'] ??
            clientData['patientInfo']?['childName'] ??
            'Unknown';

        final clientAssessments = assessmentsByPatient[clientId] ?? [];

        clientsList.add({
          'bookingId': bookingId,
          'clientId': clientId,
          'childName': childName,
          'parentName': clientData['parentName'] ??
              clientData['patientInfo']?['parentName'] ??
              'Unknown',
          'age': clientData['patientInfo']?['age']?.toString() ?? 'N/A',
          'diagnosis': clientData['patientInfo']?['diagnosis'] ?? 'N/A',
          'appointmentType': clientData['appointmentType'] ?? 'N/A',
          'status': clientData['status'] ?? 'confirmed',
          'appointmentDate': clientData['appointmentDate'] ?? 'N/A',
          'appointmentTime': clientData['appointmentTime'] ?? 'N/A',
          'progressReports': clientAssessments,
          'totalReports': clientAssessments.length,
          'lastReportDate': clientAssessments.isNotEmpty
              ? clientAssessments.first['createdAt']
              : null,
        });
      }

      final loadTime = DateTime.now().difference(startTime).inMilliseconds;
      print('⚡ Data loaded in ${loadTime}ms');

      setState(() {
        clientsWithProgress = clientsList;
        progressReports = allAssessments;
        isLoading = false;
      });

      print(
          '✅ Final: ${clientsList.length} clients, ${allAssessments.length} assessments');
    } catch (e) {
      print('❌ Error loading data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _processAnalyticsData(List<QueryDocumentSnapshot> assessmentDocs) {
    monthlyReports.clear();
    progressTypeStats.clear();
    weeklyProgressScores.clear();

    // Map to store daily scores for weekly average calculation
    Map<int, List<double>> dailyScores = {
      0: [],
      1: [],
      2: [],
      3: [],
      4: [],
      5: [],
      6: []
    }; // 0=Mon, 6=Sun

    for (var doc in assessmentDocs) {
      final data = doc.data() as Map<String, dynamic>;

      // Process monthly reports using createdAt timestamp
      try {
        DateTime reportDate;
        if (data['createdAt'] != null) {
          reportDate = (data['createdAt'] as Timestamp).toDate();
        } else {
          reportDate = DateTime.now();
        }
        final monthKey =
            '${reportDate.year}-${reportDate.month.toString().padLeft(2, '0')}';
        monthlyReports[monthKey] = (monthlyReports[monthKey] ?? 0) + 1;

        // Add to daily scores for weekly chart
        final dayOfWeek = (reportDate.weekday - 1) % 7; // Convert to 0-6 range
        final overallScore = _calculateOverallScore(data);
        dailyScores[dayOfWeek]?.add(overallScore);
      } catch (e) {
        print('Error parsing date: $e');
      }

      // Process assessment categories as progress types
      final assessmentType = data['assessmentType'] ?? 'Occupational Therapy';
      progressTypeStats[assessmentType] =
          (progressTypeStats[assessmentType] ?? 0) + 1;

      // Also count by skill categories
      if (data['fineMotorSkills'] != null) {
        progressTypeStats['Fine Motor'] =
            (progressTypeStats['Fine Motor'] ?? 0) + 1;
      }
      if (data['grossMotorSkills'] != null) {
        progressTypeStats['Gross Motor'] =
            (progressTypeStats['Gross Motor'] ?? 0) + 1;
      }
      if (data['sensoryProcessing'] != null) {
        progressTypeStats['Sensory Processing'] =
            (progressTypeStats['Sensory Processing'] ?? 0) + 1;
      }
      if (data['cognitiveSkills'] != null) {
        progressTypeStats['Cognitive'] =
            (progressTypeStats['Cognitive'] ?? 0) + 1;
      }
    }

    // Calculate weekly average scores for each day
    for (int day = 0; day < 7; day++) {
      if (dailyScores[day]!.isNotEmpty) {
        final average = dailyScores[day]!.reduce((a, b) => a + b) /
            dailyScores[day]!.length;
        weeklyProgressScores.add(average);
      } else {
        // If no data for this day, use interpolated value or 0
        weeklyProgressScores.add(0.0);
      }
    }

    // If no data at all, create a baseline
    if (weeklyProgressScores.every((score) => score == 0.0) &&
        assessmentDocs.isNotEmpty) {
      // Calculate overall average from all assessments
      double totalScore = 0;
      for (var doc in assessmentDocs) {
        final data = doc.data() as Map<String, dynamic>;
        totalScore += _calculateOverallScore(data);
      }
      final avgScore = totalScore / assessmentDocs.length;
      weeklyProgressScores =
          List.generate(7, (index) => avgScore + (index - 3) * 2);
    }
  }

  // Calculate overall progress score from OT Assessment data
  double _calculateOverallScore(Map<String, dynamic> assessmentData) {
    double totalScore = 0;
    int categoryCount = 0;

    // Fine Motor Skills average
    if (assessmentData['fineMotorSkills'] != null) {
      final fineMotor = assessmentData['fineMotorSkills'] as Map;
      final scores = [
        fineMotor['pincerGrasp'] ?? 0,
        fineMotor['handEyeCoordination'] ?? 0,
        fineMotor['inHandManipulation'] ?? 0,
        fineMotor['bilateralCoordination'] ?? 0,
      ];
      final avg =
          scores.reduce((a, b) => a + b) / scores.length * 20; // Scale to 100
      totalScore += avg;
      categoryCount++;
    }

    // Gross Motor Skills average
    if (assessmentData['grossMotorSkills'] != null) {
      final grossMotor = assessmentData['grossMotorSkills'] as Map;
      final scores = [
        grossMotor['balance'] ?? 0,
        grossMotor['runningJumping'] ?? 0,
        grossMotor['throwingCatching'] ?? 0,
        grossMotor['motorPlanning'] ?? 0,
      ];
      final avg =
          scores.reduce((a, b) => a + b) / scores.length * 20; // Scale to 100
      totalScore += avg;
      categoryCount++;
    }

    // Sensory Processing average
    if (assessmentData['sensoryProcessing'] != null) {
      final sensory = assessmentData['sensoryProcessing'] as Map;
      final scores = [
        sensory['tactileResponse'] ?? 0,
        sensory['auditoryFiltering'] ?? 0,
        sensory['vestibularSeeking'] ?? 0,
        sensory['proprioceptiveAwareness'] ?? 0,
      ];
      final avg =
          scores.reduce((a, b) => a + b) / scores.length * 20; // Scale to 100
      totalScore += avg;
      categoryCount++;
    }

    // Cognitive Skills average
    if (assessmentData['cognitiveSkills'] != null) {
      final cognitive = assessmentData['cognitiveSkills'] as Map;
      final scores = [
        cognitive['problemSolving'] ?? 0,
        cognitive['attentionSpan'] ?? 0,
        cognitive['followingDirections'] ?? 0,
        cognitive['sequencingTasks'] ?? 0,
      ];
      final avg =
          scores.reduce((a, b) => a + b) / scores.length * 20; // Scale to 100
      totalScore += avg;
      categoryCount++;
    }

    return categoryCount > 0 ? totalScore / categoryCount : 50.0;
  }

  int _calculateUpcomingSessions() {
    if (clientsWithProgress.isEmpty) return 0;

    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    final nextWeek = now.add(const Duration(days: 7));

    // Count appointments in the next 7 days
    int upcomingCount = 0;
    for (var client in clientsWithProgress) {
      try {
        final appointmentDateStr = client['appointmentDate'];
        if (appointmentDateStr != null && appointmentDateStr != 'N/A') {
          final appointmentDate = DateTime.parse(appointmentDateStr);
          if (appointmentDate.isAfter(tomorrow) &&
              appointmentDate.isBefore(nextWeek)) {
            upcomingCount++;
          }
        }
      } catch (e) {
        // Skip invalid dates
      }
    }
    return upcomingCount;
  }

  String _calculateWeeklyChange() {
    if (progressReports.isEmpty) return '0.0%';

    try {
      final now = DateTime.now();
      final thisWeekStart = now.subtract(Duration(days: now.weekday - 1));
      final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));

      double thisWeekAvgScore = 0;
      double lastWeekAvgScore = 0;
      int thisWeekCount = 0;
      int lastWeekCount = 0;

      for (var report in progressReports) {
        try {
          DateTime reportDate;
          if (report['createdAt'] != null) {
            reportDate = (report['createdAt'] as Timestamp).toDate();
          } else {
            continue;
          }

          final score = _calculateOverallScore(report);

          if (reportDate.isAfter(thisWeekStart)) {
            thisWeekAvgScore += score;
            thisWeekCount++;
          } else if (reportDate.isAfter(lastWeekStart) &&
              reportDate.isBefore(thisWeekStart)) {
            lastWeekAvgScore += score;
            lastWeekCount++;
          }
        } catch (e) {
          // Skip invalid data
        }
      }

      if (thisWeekCount == 0 && lastWeekCount == 0) {
        return '0.0%';
      }

      if (lastWeekCount == 0) {
        return thisWeekCount > 0 ? '+100%' : '0.0%';
      }

      thisWeekAvgScore = thisWeekAvgScore / thisWeekCount;
      lastWeekAvgScore = lastWeekAvgScore / lastWeekCount;

      final change =
          ((thisWeekAvgScore - lastWeekAvgScore) / lastWeekAvgScore * 100);
      return '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}%';
    } catch (e) {
      return '0.0%';
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Top ellipse background
          Positioned(
            top: -100,
            left: -50,
            right: -50,
            child: Container(
              height: mq.height * 0.6,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF006A5B),
                    Color(0xFF67AFA5),
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

          // Bottom ellipse background
          Positioned(
            bottom: -100,
            left: -50,
            right: -50,
            child: Container(
              height: mq.height * 0.5,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Color(0xFF67AFA5),
                    Colors.white,
                  ],
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

          // Main content
          SafeArea(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF006A5B),
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        // Header section
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () => Navigator.pop(context),
                                    icon: const Icon(Icons.arrow_back,
                                        color: Colors.white, size: 28),
                                  ),
                                  const Expanded(
                                    child: Text(
                                      'Progress Reports',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontFamily: 'Poppins',
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  const SizedBox(width: 48),
                                ],
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Comprehensive tracking of client progress',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                  fontFamily: 'Poppins',
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),

                        // Stats cards - 4 card layout
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Column(
                            children: [
                              // First row - Active Clients and Reports Recorded
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatCard(
                                      title: 'Active Clients',
                                      value: clientsWithProgress
                                          .where(
                                              (p) => p['status'] == 'confirmed')
                                          .length
                                          .toString(),
                                      icon: Icons.people,
                                      color: Colors.white,
                                      textColor: const Color(0xFF006A5B),
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: _buildStatCard(
                                      title: 'Reports Recorded',
                                      value: progressReports.length.toString(),
                                      icon: Icons.assignment,
                                      color: Colors.white,
                                      textColor: const Color(0xFF006A5B),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),
                              // Second row - Upcoming Sessions and Avg Weekly Change
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatCard(
                                      title: 'Upcoming Sessions',
                                      value: _calculateUpcomingSessions()
                                          .toString(),
                                      icon: Icons.schedule,
                                      color: Colors.white,
                                      textColor: const Color(0xFF006A5B),
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: _buildStatCard(
                                      title: 'Avg Weekly Change',
                                      value: _calculateWeeklyChange(),
                                      icon: Icons.trending_up,
                                      color: Colors.white,
                                      textColor: const Color(0xFF006A5B),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Progress Tracking Section
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  spreadRadius: 2,
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Progress Tracking Overview',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF006A5B),
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Progress Categories Grid
                                  Row(
                                    children: [
                                      // Motor Progress
                                      Expanded(
                                        child: _buildProgressCategory(
                                          title: 'Motor',
                                          progress: 0.11,
                                          daysOverview: '+11% over last 7 days',
                                          status: 'On Track',
                                          statusColor: const Color(0xFF006A5B),
                                          progressColor:
                                              const Color(0xFF006A5B),
                                        ),
                                      ),
                                      const SizedBox(width: 15),
                                      // Speech Progress
                                      Expanded(
                                        child: _buildProgressCategory(
                                          title: 'Speech',
                                          progress: 0.18,
                                          daysOverview: '+18% over last 7 days',
                                          status: 'On Track',
                                          statusColor: const Color(0xFF006A5B),
                                          progressColor:
                                              const Color(0xFF67AFA5),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 15),
                                  Row(
                                    children: [
                                      // Cognitive Progress
                                      Expanded(
                                        child: _buildProgressCategory(
                                          title: 'Cognitive',
                                          progress: 0.11,
                                          daysOverview: '+11% over last 7 days',
                                          status: 'Needs Attention',
                                          statusColor: Colors.orange,
                                          progressColor: Colors.orange,
                                        ),
                                      ),
                                      const SizedBox(width: 15),
                                      // Socio-emotional Progress
                                      Expanded(
                                        child: _buildProgressCategory(
                                          title: 'Socio-emotional',
                                          progress: 0.27,
                                          daysOverview: '+27% over last 7 days',
                                          status: 'On Track',
                                          statusColor: const Color(0xFF006A5B),
                                          progressColor:
                                              const Color(0xFF006A5B),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 20),

                                  // Upcoming Sessions Section
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF006A5B)
                                          .withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFF006A5B)
                                            .withOpacity(0.2),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'Upcoming Sessions',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF006A5B),
                                                fontFamily: 'Poppins',
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF006A5B),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: const Icon(
                                                Icons.calendar_month,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        ..._buildUpcomingSessionsList(),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Content area with rounded container
                        Container(
                          width: double.infinity,
                          constraints: BoxConstraints(
                            minHeight: MediaQuery.of(context).size.height * 0.3,
                          ),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(30),
                              topRight: Radius.circular(30),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 10,
                                offset: Offset(0, -5),
                              ),
                            ],
                          ),
                          child: clientsWithProgress.isEmpty
                              ? _buildEmptyState()
                              : _buildClientsList(),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: textColor,
            size: 30,
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textColor,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: textColor.withOpacity(0.7),
              fontFamily: 'Poppins',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No Progress Reports Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Progress reports will appear here once they are created from the patient list.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
              fontFamily: 'Poppins',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildClientsList() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(30),
        topRight: Radius.circular(30),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF006A5B).withOpacity(0.1),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Client Information',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF006A5B),
                      fontFamily: 'Poppins',
                      fontSize: 16,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Assessments',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF006A5B),
                      fontFamily: 'Poppins',
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Action',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF006A5B),
                      fontFamily: 'Poppins',
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          // Client list
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: clientsWithProgress.length,
            itemBuilder: (context, index) {
              return _buildClientRow(clientsWithProgress[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildClientRow(Map<String, dynamic> client) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client['childName'] ?? 'Unknown',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                    fontFamily: 'Poppins',
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Parent: ${client['parentName'] ?? 'N/A'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF7F8C8D),
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  'Age: ${client['age']} • ${client['diagnosis']}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF7F8C8D),
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: FutureBuilder<int>(
              future: _getOTAssessmentsCount(client['clientId']),
              builder: (context, snapshot) {
                final assessmentCount = snapshot.data ?? 0;
                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: assessmentCount > 0
                            ? const Color(0xFF006A5B)
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$assessmentCount assessments',
                        style: TextStyle(
                          color: assessmentCount > 0
                              ? Colors.white
                              : Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Expanded(
            child: Center(
              child: FutureBuilder<int>(
                future: _getOTAssessmentsCount(client['clientId']),
                builder: (context, snapshot) {
                  final hasAssessments = (snapshot.data ?? 0) > 0;
                  return ElevatedButton(
                    onPressed: hasAssessments
                        ? () => _viewClientProgress(client)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hasAssessments
                          ? const Color(0xFF006A5B)
                          : Colors.grey[300],
                      foregroundColor:
                          hasAssessments ? Colors.white : Colors.grey[600],
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      minimumSize: const Size(60, 32),
                    ),
                    child: Text(
                      hasAssessments ? 'View' : 'None',
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<int> _getOTAssessmentsCount(String? clientId) async {
    if (clientId == null) return 0;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('OTAssessments')
          .where('patientId', isEqualTo: clientId)
          .where('clinicId', isEqualTo: clinicId)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      print('Error getting OT assessments count: $e');
      return 0;
    }
  }

  void _viewClientProgress(Map<String, dynamic> client) async {
    // Navigate to individual client progress page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClientProgressDetailPage(
          clientData: client,
          clinicId: clinicId!,
        ),
      ),
    );
  }

  Widget _buildProgressTypesChart() {
    if (progressTypeStats.isEmpty) {
      return const Center(
        child: Text(
          'No data',
          style: TextStyle(
            color: Colors.grey,
            fontFamily: 'Poppins',
          ),
        ),
      );
    }

    final colors = [
      const Color(0xFF006A5B),
      const Color(0xFF67AFA5),
      const Color(0xFF95C9C3),
      const Color(0xFFB8D4D1),
      const Color(0xFFDBE9E7),
    ];

    final sections =
        progressTypeStats.entries.toList().asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final percentage = (data.value / progressReports.length * 100);

      return PieChartSectionData(
        color: colors[index % colors.length],
        value: data.value.toDouble(),
        title: '${percentage.toStringAsFixed(0)}%',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontFamily: 'Poppins',
        ),
      );
    }).toList();

    return Column(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sections: sections,
              borderData: FlBorderData(show: false),
              sectionsSpace: 2,
              centerSpaceRadius: 20,
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Legend
        Wrap(
          spacing: 8,
          children:
              progressTypeStats.entries.toList().asMap().entries.map((entry) {
            final index = entry.key;
            final data = entry.value;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: colors[index % colors.length],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  data.key,
                  style: const TextStyle(
                    fontSize: 10,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildProgressChart() {
    if (weeklyProgressScores.isEmpty) {
      return const Center(
        child: Text(
          'No data available',
          style: TextStyle(
            color: Colors.grey,
            fontFamily: 'Poppins',
          ),
        ),
      );
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 20,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey[300]!,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: 25,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  '${value.toInt()}%',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontFamily: 'Poppins',
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (double value, TitleMeta meta) {
                const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                if (value.toInt() >= 0 && value.toInt() < days.length) {
                  return Text(
                    days[value.toInt()],
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontFamily: 'Poppins',
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey[300]!),
        ),
        minX: 0,
        maxX: 6,
        minY: 0,
        maxY: 100,
        lineBarsData: [
          LineChartBarData(
            spots: weeklyProgressScores.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value);
            }).toList(),
            isCurved: true,
            gradient: const LinearGradient(
              colors: [Color(0xFF006A5B), Color(0xFF67AFA5)],
            ),
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 6,
                  color: const Color(0xFF006A5B),
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF006A5B).withOpacity(0.3),
                  const Color(0xFF67AFA5).withOpacity(0.1),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCategory({
    required String title,
    required double progress,
    required String daysOverview,
    required String status,
    required Color statusColor,
    required Color progressColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 12),

          // Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: progressColor,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  Text(
                    daysOverview,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(3),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      color: progressColor,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: statusColor.withOpacity(0.3),
              ),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: statusColor,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildUpcomingSessionsList() {
    // Filter upcoming appointments from the next 7 days
    final now = DateTime.now();
    final nextWeek = now.add(const Duration(days: 7));

    final upcomingSessions = clientsWithProgress
        .where((client) {
          try {
            final appointmentDateStr = client['appointmentDate'];
            if (appointmentDateStr != null && appointmentDateStr != 'N/A') {
              final appointmentDate = DateTime.parse(appointmentDateStr);
              return appointmentDate.isAfter(now) &&
                  appointmentDate.isBefore(nextWeek);
            }
          } catch (e) {
            // Skip invalid dates
          }
          return false;
        })
        .take(3)
        .toList(); // Show only first 3

    if (upcomingSessions.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'No upcoming sessions in the next 7 days',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ];
    }

    return upcomingSessions.map((session) {
      final sessionType =
          _getSessionTypeFromDiagnosis(session['diagnosis'] ?? 'Therapy');
      final sessionColor = _getSessionColor(sessionType);

      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: sessionColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${session['childName']} • ${session['appointmentTime']}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2C3E50),
                      fontFamily: 'Poppins',
                    ),
                  ),
                  Text(
                    sessionType,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            Text(
              _formatDate(session['appointmentDate']),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  String _getSessionTypeFromDiagnosis(String diagnosis) {
    final diagnosisLower = diagnosis.toLowerCase();
    if (diagnosisLower.contains('speech') ||
        diagnosisLower.contains('language')) {
      return 'Speech Therapy';
    } else if (diagnosisLower.contains('motor') ||
        diagnosisLower.contains('physical')) {
      return 'Motor Therapy';
    } else if (diagnosisLower.contains('cognitive') ||
        diagnosisLower.contains('learning')) {
      return 'Cognitive Therapy';
    } else if (diagnosisLower.contains('social') ||
        diagnosisLower.contains('emotional')) {
      return 'Socio-emotional';
    }
    return 'Teletherapy';
  }

  Color _getSessionColor(String sessionType) {
    switch (sessionType) {
      case 'Speech Therapy':
        return const Color(0xFF67AFA5);
      case 'Motor Therapy':
        return const Color(0xFF006A5B);
      case 'Cognitive Therapy':
        return Colors.orange;
      case 'Socio-emotional':
        return const Color(0xFF006A5B);
      default:
        return const Color(0xFF67AFA5);
    }
  }

  String _formatDate(dynamic date) {
    try {
      if (date is String) {
        final parsedDate = DateTime.parse(date);
        final now = DateTime.now();
        final difference = parsedDate.difference(now).inDays;

        if (difference == 0) {
          return 'Today';
        } else if (difference == 1) {
          return 'Tomorrow';
        } else {
          return '${parsedDate.day}/${parsedDate.month}';
        }
      }
    } catch (e) {
      // Handle parsing errors
    }
    return 'N/A';
  }
}
