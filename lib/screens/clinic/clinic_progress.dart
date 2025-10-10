import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'clinic_patient_progress_report.dart';

class ClinicProgress extends StatefulWidget {
  const ClinicProgress({Key? key}) : super(key: key);

  @override
  State<ClinicProgress> createState() => _ClinicProgressState();
}

class _ClinicProgressState extends State<ClinicProgress> {
  String? clinicId;
  List<Map<String, dynamic>> patientsWithProgress = [];
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
    await _loadPatientsAndProgress();
  }

  Future<void> _getClinicId() async {
    final prefs = await SharedPreferences.getInstance();
    // Use the same lookup logic as clinic_patientlist.dart
    String? clinicId = prefs.getString('clinic_id');
    if (clinicId == null) {
      final possibleKeys = ['user_id', 'clinicId', 'userId', 'id'];
      for (final key in possibleKeys) {
        clinicId = prefs.getString(key);
        if (clinicId != null) {
          print('✅ Found clinic ID with key "$key": $clinicId');
          break;
        }
      }
    }

    setState(() {
      this.clinicId = clinicId;
    });
  }

  Future<void> _loadPatientsAndProgress() async {
    if (clinicId == null) return;

    try {
      setState(() {
        isLoading = true;
      });

      print('🚀 Starting optimized data loading...');
      final startTime = DateTime.now();

      // Load both collections in parallel for better performance
      final futures = await Future.wait([
        FirebaseFirestore.instance
            .collection('AcceptedBooking')
            .where('clinicId', isEqualTo: clinicId)
            .get(),
        FirebaseFirestore.instance
            .collection('ClinicProgress')
            .where('clinicId', isEqualTo: clinicId)
            .orderBy('date', descending: true)
            .limit(50) // Limit to recent reports for better performance
            .get(),
      ]);

      final patientsSnapshot = futures[0];
      final progressSnapshot = futures[1];

      print(
          '📊 Loaded ${patientsSnapshot.docs.length} bookings and ${progressSnapshot.docs.length} reports');

      // Process analytics data
      _processAnalyticsData(progressSnapshot.docs);

      // Create a map of progress reports by patient ID for O(1) lookup
      final Map<String, List<Map<String, dynamic>>> progressByPatient = {};
      final List<Map<String, dynamic>> allProgressReports = [];

      for (var doc in progressSnapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        allProgressReports.add(data);

        final patientId = data['patientId']?.toString() ?? '';
        if (patientId.isNotEmpty) {
          progressByPatient.putIfAbsent(patientId, () => []).add(data);
        }
      }

      // Process patients data efficiently
      final List<Map<String, dynamic>> patientsList = [];

      for (var doc in patientsSnapshot.docs) {
        final patientData = doc.data();
        final bookingId = doc.id;
        final patientId = patientData['patientId']?.toString() ?? bookingId;

        // Extract child name from different possible fields
        final childName = patientData['patientName'] ??
            patientData['childName'] ??
            patientData['patientInfo']?['childName'] ??
            'Unknown';

        final patientReports = progressByPatient[patientId] ?? [];

        patientsList.add({
          'bookingId': bookingId,
          'patientId': patientId,
          'childName': childName,
          'parentName': patientData['parentName'] ??
              patientData['patientInfo']?['parentName'] ??
              'Unknown',
          'age': patientData['patientInfo']?['age']?.toString() ?? 'N/A',
          'diagnosis': patientData['patientInfo']?['diagnosis'] ?? 'N/A',
          'appointmentType': patientData['appointmentType'] ?? 'N/A',
          'status': patientData['status'] ?? 'confirmed',
          'appointmentDate': patientData['appointmentDate'] ?? 'N/A',
          'appointmentTime': patientData['appointmentTime'] ?? 'N/A',
          'progressReports': patientReports,
          'totalReports': patientReports.length,
          'lastReportDate':
              patientReports.isNotEmpty ? patientReports.first['date'] : null,
        });
      }

      final loadTime = DateTime.now().difference(startTime).inMilliseconds;
      print('⚡ Data loaded in ${loadTime}ms');

      setState(() {
        patientsWithProgress = patientsList;
        progressReports = allProgressReports;
        isLoading = false;
      });

      print(
          '✅ Final: ${patientsList.length} patients, ${allProgressReports.length} reports');
    } catch (e) {
      print('❌ Error loading data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _processAnalyticsData(List<QueryDocumentSnapshot> progressDocs) {
    monthlyReports.clear();
    progressTypeStats.clear();
    weeklyProgressScores.clear();

    final now = DateTime.now();

    for (var doc in progressDocs) {
      final data = doc.data() as Map<String, dynamic>;

      // Process monthly reports
      try {
        final reportDate = data['date'] != null
            ? DateTime.parse(data['date'])
            : DateTime.now();
        final monthKey =
            '${reportDate.year}-${reportDate.month.toString().padLeft(2, '0')}';
        monthlyReports[monthKey] = (monthlyReports[monthKey] ?? 0) + 1;
      } catch (e) {
        print('Error parsing date: $e');
      }

      // Process progress types
      final progressType =
          data['progressType'] ?? data['category'] ?? 'General';
      progressTypeStats[progressType] =
          (progressTypeStats[progressType] ?? 0) + 1;

      // Generate mock progress scores for demonstration
      // In real app, you'd extract actual scores from progress data
      final score = (data['progressScore'] as num?)?.toDouble() ??
          (50 + (DateTime.now().millisecond % 50)).toDouble();
      if (weeklyProgressScores.length < 7) {
        weeklyProgressScores.add(score);
      }
    }

    // Fill weekly scores if needed
    while (weeklyProgressScores.length < 7) {
      weeklyProgressScores.add(50.0 + (weeklyProgressScores.length * 5));
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
                        'Comprehensive tracking of patient progress',
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

                // Stats cards
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          title: 'Total Patients',
                          value: patientsWithProgress.length.toString(),
                          icon: Icons.people,
                          color: Colors.white,
                          textColor: const Color(0xFF006A5B),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildStatCard(
                          title: 'Total Reports',
                          value: progressReports.length.toString(),
                          icon: Icons.assignment,
                          color: Colors.white,
                          textColor: const Color(0xFF006A5B),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Charts section (only show if not loading and has data)
                if (!isLoading && progressReports.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      children: [
                        // Weekly Progress Chart
                        Expanded(
                          child: Container(
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.white,
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
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Weekly Progress',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF006A5B),
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Expanded(
                                    child: _buildProgressChart(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        // Progress Types Chart
                        Expanded(
                          child: Container(
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.white,
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
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Progress Types',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF006A5B),
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Expanded(
                                    child: _buildProgressTypesChart(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                // Content area with rounded container
                Expanded(
                  child: Container(
                    width: double.infinity,
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
                    child: isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF006A5B),
                            ),
                          )
                        : patientsWithProgress.isEmpty
                            ? _buildEmptyState()
                            : _buildPatientsList(),
                  ),
                ),
              ],
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

  Widget _buildPatientsList() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(30),
        topRight: Radius.circular(30),
      ),
      child: Column(
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
                    'Patient Information',
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
                    'Reports',
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
          // Patient list
          Expanded(
            child: ListView.builder(
              itemCount: patientsWithProgress.length,
              itemBuilder: (context, index) {
                return _buildPatientRow(patientsWithProgress[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientRow(Map<String, dynamic> patient) {
    final hasReports = patient['totalReports'] > 0;
    final lastReportDate = patient['lastReportDate'];
    String formattedDate = 'No reports';

    if (lastReportDate != null) {
      try {
        final date = DateTime.parse(lastReportDate);
        formattedDate = '${date.day}/${date.month}/${date.year}';
      } catch (e) {
        formattedDate = 'Invalid date';
      }
    }

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
                  patient['childName'] ?? 'Unknown',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                    fontFamily: 'Poppins',
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Parent: ${patient['parentName'] ?? 'N/A'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF7F8C8D),
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  'Age: ${patient['age']} • ${patient['diagnosis']}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF7F8C8D),
                    fontFamily: 'Poppins',
                  ),
                ),
                if (patient['appointmentDate'] != null &&
                    patient['appointmentDate'] != 'N/A')
                  Text(
                    'Booking: ${patient['appointmentDate']} ${patient['appointmentTime'] ?? ''}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF95A5A6),
                      fontFamily: 'Poppins',
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color:
                        hasReports ? const Color(0xFF006A5B) : Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${patient['totalReports']} reports',
                    style: TextStyle(
                      color: hasReports ? Colors.white : Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formattedDate,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF95A5A6),
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: ElevatedButton(
                onPressed: hasReports
                    ? () {
                        // Navigate to latest progress report
                        final latestReport = patient['progressReports'][0];
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ClinicPatientProgressReport(
                              patientName: patient['childName'],
                              progressData: latestReport,
                            ),
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      hasReports ? const Color(0xFF006A5B) : Colors.grey[300],
                  foregroundColor: hasReports ? Colors.white : Colors.grey[600],
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  minimumSize: const Size(60, 32),
                ),
                child: Text(
                  hasReports ? 'View' : 'None',
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
          ),
        ],
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
}
