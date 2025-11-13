import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'final_evaluation_form.dart';
import 'add_session_form.dart';
import 'final_evaluation_list.dart';
import 'session_detail_view.dart';
import 'final_evaluation_viewer.dart';

class ClientProgressDetailPage extends StatefulWidget {
  final Map<String, dynamic> clientData;
  final String clinicId;

  const ClientProgressDetailPage({
    Key? key,
    required this.clientData,
    required this.clinicId,
  }) : super(key: key);

  @override
  State<ClientProgressDetailPage> createState() =>
      _ClientProgressDetailPageState();
}

class _ClientProgressDetailPageState extends State<ClientProgressDetailPage> {
  List<Map<String, dynamic>> assessments = [];
  Map<String, dynamic>? initialAssessment;
  List<Map<String, dynamic>> finalEvaluations = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAssessments();
    _loadInitialAssessment();
    _loadFinalEvaluations();
  }

  Future<void> _navigateToAddSession() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddSessionForm(
          clientData: widget.clientData,
          clinicId: widget.clinicId,
        ),
      ),
    );

    // Refresh data if session was added
    if (result == true) {
      setState(() {
        isLoading = true;
      });
      await _loadAssessments();
      await _loadInitialAssessment();
      await _loadFinalEvaluations();
    }
  }

  Future<void> _navigateToViewEvaluations() async {
    final clientId = widget.clientData['clientId']?.toString() ?? '';
    final childName = widget.clientData['childName']?.toString() ?? 
                      widget.clientData['patientName']?.toString() ?? 
                      'Unknown';
    
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FinalEvaluationList(
          patientId: clientId,
          childName: childName,
        ),
      ),
    );
  }

  Future<void> _navigateToFinalEvaluation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FinalEvaluationForm(
          clientData: widget.clientData,
          clinicId: widget.clinicId,
          sessionHistory: assessments,
        ),
      ),
    );

    // Refresh data if evaluation was submitted
    if (result == true) {
      setState(() {
        isLoading = true;
      });
      await _loadAssessments();
      await _loadInitialAssessment();
      await _loadFinalEvaluations();
    }
  }

  void _showViewPrintOptions() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.folder_open, color: Color(0xFF006A5B)),
              SizedBox(width: 10),
              Text(
                'Assessment Reports',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // FIRST ASSESSMENT SECTION
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
                  child: Text(
                    'FIRST ASSESSMENT',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                if (initialAssessment != null) ...[
                  ListTile(
                    leading: const Icon(Icons.visibility, color: Color(0xFF00897B)),
                    title: const Text(
                      'View Assessment',
                      style: TextStyle(fontFamily: 'Poppins'),
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      _viewInitialAssessment();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.print, color: Color(0xFF00897B)),
                    title: const Text(
                      'Print / Download',
                      style: TextStyle(fontFamily: 'Poppins'),
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      _printInitialAssessment();
                    },
                  ),
                ] else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'No initial assessment available',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                
                const Divider(height: 24),
                
                // FINAL EVALUATION SECTION
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
                  child: Text(
                    'FINAL EVALUATION',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                if (finalEvaluations.isNotEmpty) ...[
                  ListTile(
                    leading: const Icon(Icons.visibility, color: Color(0xFFFF6F00)),
                    title: const Text(
                      'View Evaluations',
                      style: TextStyle(fontFamily: 'Poppins'),
                    ),
                    subtitle: Text(
                      '${finalEvaluations.length} evaluation(s)',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      _navigateToViewEvaluations();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.print, color: Color(0xFFFF6F00)),
                    title: const Text(
                      'Print / Download',
                      style: TextStyle(fontFamily: 'Poppins'),
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      _printFinalEvaluations();
                    },
                  ),
                ],
                // Create Final Evaluation option
                if (assessments.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.add_circle, color: Color(0xFF006A5B)),
                    title: const Text(
                      'Create New Evaluation',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      _navigateToFinalEvaluation();
                    },
                  ),
                if (finalEvaluations.isEmpty && assessments.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'No evaluations available. Complete sessions first.',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Close',
                style: TextStyle(
                  color: Color(0xFF006A5B),
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _viewInitialAssessment() {
    if (initialAssessment != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SessionDetailView(
            sessionData: initialAssessment!,
            sessionNumber: 0,
          ),
        ),
      );
    }
  }

  void _printInitialAssessment() {
    // TODO: Implement print/download initial assessment
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.info_outline, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Print/Download feature coming soon!',
                style: TextStyle(fontFamily: 'Poppins'),
              ),
            ),
          ],
        ),
        backgroundColor: Color(0xFF00897B),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _printFinalEvaluations() {
    // TODO: Implement print/download final evaluations
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.info_outline, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Print/Download feature coming soon!',
                style: TextStyle(fontFamily: 'Poppins'),
              ),
            ),
          ],
        ),
        backgroundColor: Color(0xFFFF6F00),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _loadAssessments() async {
    try {
      print('🔍 Loading assessments for client: ${widget.clientData}');

      final clientId = widget.clientData['clientId']?.toString();
      final patientName = widget.clientData['childName']?.toString() ??
          widget.clientData['patientName']?.toString();
      final bookingId = widget.clientData['bookingId']?.toString();

      print(
          '🔍 Searching with - clientId: $clientId, patientName: $patientName, bookingId: $bookingId');
      print('🔍 Clinic ID: ${widget.clinicId}');

      List<QueryDocumentSnapshot> foundDocs = [];

      // Strategy 1: Query by clientId (patientId)
      if (clientId != null && clientId.isNotEmpty) {
        try {
          final snapshot = await FirebaseFirestore.instance
              .collection('OTAssessments')
              .where('patientId', isEqualTo: clientId)
              .where('clinicId', isEqualTo: widget.clinicId)
              .get();

          print(
              '🔍 Strategy 1 (patientId = $clientId): ${snapshot.docs.length} documents');
          foundDocs.addAll(snapshot.docs);
        } catch (e) {
          print('❌ Strategy 1 failed: $e');
        }
      }

      // Strategy 2: Query by childName if no results from strategy 1
      if (foundDocs.isEmpty && patientName != null && patientName.isNotEmpty) {
        try {
          final snapshot = await FirebaseFirestore.instance
              .collection('OTAssessments')
              .where('childName', isEqualTo: patientName)
              .where('clinicId', isEqualTo: widget.clinicId)
              .get();

          print(
              '🔍 Strategy 2 (childName = $patientName): ${snapshot.docs.length} documents');
          foundDocs.addAll(snapshot.docs);
        } catch (e) {
          print('❌ Strategy 2 failed: $e');
        }
      }

      // Strategy 3: Query all for clinic and filter manually
      if (foundDocs.isEmpty) {
        try {
          print(
              '🔍 Strategy 3: Querying all clinic assessments for manual filtering');
          final snapshot = await FirebaseFirestore.instance
              .collection('OTAssessments')
              .where('clinicId', isEqualTo: widget.clinicId)
              .get();

          print(
              '🔍 Strategy 3: Got ${snapshot.docs.length} total clinic assessments');

          // Print all available assessments for debugging
          for (var doc in snapshot.docs) {
            final data = doc.data();
            print(
                '🔍 Available assessment: patientId=${data['patientId']}, childName=${data['childName']}, parentName=${data['parentName']}');
          }

          // Filter manually with various matching strategies
          final filteredDocs = snapshot.docs.where((doc) {
            final data = doc.data();
            final docPatientId = data['patientId']?.toString().toLowerCase();
            final docChildName = data['childName']?.toString().toLowerCase();

            final searchClientId = clientId?.toLowerCase();
            final searchPatientName = patientName?.toLowerCase();

            // Try various matching approaches
            bool matches = false;

            // Exact matches
            if (docPatientId == searchClientId) {
              print('🔍 Match found: patientId exact match');
              matches = true;
            } else if (docChildName == searchPatientName) {
              print('🔍 Match found: childName exact match');
              matches = true;
            }
            // Partial matches
            else if (searchClientId != null &&
                docPatientId != null &&
                (docPatientId.contains(searchClientId) ||
                    searchClientId.contains(docPatientId))) {
              print('🔍 Match found: patientId partial match');
              matches = true;
            } else if (searchPatientName != null &&
                docChildName != null &&
                (docChildName.contains(searchPatientName) ||
                    searchPatientName.contains(docChildName))) {
              print('🔍 Match found: childName partial match');
              matches = true;
            }

            if (matches) {
              print('🔍 Matched document: ${doc.id} with data: $data');
            }

            return matches;
          }).toList();

          print(
              '🔍 Strategy 3: Manual filtering found ${filteredDocs.length} matching documents');
          foundDocs.addAll(filteredDocs);
        } catch (e) {
          print('❌ Strategy 3 failed: $e');
        }
      }

      // Sort by creation date (newest first)
      foundDocs.sort((a, b) {
        try {
          final aData = a.data() as Map<String, dynamic>?;
          final bData = b.data() as Map<String, dynamic>?;
          final aTime =
              (aData?['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
          final bTime =
              (bData?['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
          return bTime.compareTo(aTime);
        } catch (e) {
          return 0;
        }
      });

      setState(() {
        assessments = foundDocs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return <String, dynamic>{'id': doc.id, ...data};
        }).toList();
        isLoading = false;
      });

      print('🔍 Final result: ${assessments.length} assessments loaded');
      if (assessments.isNotEmpty) {
        print('🔍 First assessment sample: ${assessments.first}');
      }
    } catch (e) {
      print('❌ Error loading assessments: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadInitialAssessment() async {
    try {
      final clientId = widget.clientData['clientId']?.toString();

      if (clientId == null || clientId.isEmpty) return;

      // Query for the initial assessment
      final snapshot = await FirebaseFirestore.instance
          .collection('OTAssessments')
          .where('patientId', isEqualTo: clientId)
          .where('clinicId', isEqualTo: widget.clinicId)
          .where('isInitialAssessment', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          final doc = snapshot.docs.first;
          initialAssessment = {
            'id': doc.id,
            ...doc.data(),
          };
        });
        print('✅ Initial assessment loaded: ${initialAssessment?['id']}');
      } else {
        print('ℹ️ No initial assessment found');
      }
    } catch (e) {
      print('❌ Error loading initial assessment: $e');
    }
  }

  Future<void> _loadFinalEvaluations() async {
    try {
      final clientId = widget.clientData['clientId']?.toString();
      if (clientId == null || clientId.isEmpty) return;

      // Query for final evaluations
      final snapshot = await FirebaseFirestore.instance
          .collection('FinalEvaluations')
          .where('patientId', isEqualTo: clientId)
          .where('clinicId', isEqualTo: widget.clinicId)
          .orderBy('createdAt', descending: true)
          .get();

      setState(() {
        finalEvaluations = snapshot.docs.map((doc) {
          return <String, dynamic>{
            'id': doc.id,
            ...doc.data(),
          };
        }).toList();
      });

      print('✅ Loaded ${finalEvaluations.length} final evaluations');
    } catch (e) {
      print('❌ Error loading final evaluations: $e');
    }
  }

  Future<void> _testDirectQuery() async {
    print('🧪 Running test direct query for all clinic assessments...');
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('OTAssessments')
          .where('clinicId', isEqualTo: widget.clinicId)
          .get();

      print(
          '🧪 Test query found ${snapshot.docs.length} total assessments for clinic ${widget.clinicId}');

      for (var doc in snapshot.docs) {
        final data = doc.data();
        print('🧪 Assessment ID: ${doc.id}');
        print('🧪   - patientId: ${data['patientId']}');
        print('🧪   - childName: ${data['childName']}');
        print('🧪   - parentName: ${data['parentName']}');
        print('🧪   - clinicId: ${data['clinicId']}');
        print('🧪   - createdAt: ${data['createdAt']}');
        print('🧪   ---');
      }
    } catch (e) {
      print('🧪 Test query error: $e');
    }
  }

  Map<String, double> _calculateAverageScores() {
    if (assessments.isEmpty) {
      return {
        'fineMotor': 0,
        'grossMotor': 0,
        'sensory': 0,
        'cognitive': 0,
      };
    }

    double fineMotorSum = 0;
    double grossMotorSum = 0;
    double sensorySum = 0;
    double cognitiveSum = 0;
    int count = assessments.length;

    for (var assessment in assessments) {
      // Fine Motor
      final fineMotor = assessment['fineMotorSkills'];
      if (fineMotor != null) {
        fineMotorSum += ((fineMotor['pincerGrasp'] ?? 0) +
                (fineMotor['handEyeCoordination'] ?? 0) +
                (fineMotor['inHandManipulation'] ?? 0) +
                (fineMotor['bilateralCoordination'] ?? 0)) /
            4;
      }

      // Gross Motor
      final grossMotor = assessment['grossMotorSkills'];
      if (grossMotor != null) {
        grossMotorSum += ((grossMotor['balance'] ?? 0) +
                (grossMotor['runningJumping'] ?? 0) +
                (grossMotor['throwingCatching'] ?? 0) +
                (grossMotor['motorPlanning'] ?? 0)) /
            4;
      }

      // Sensory
      final sensory = assessment['sensoryProcessing'];
      if (sensory != null) {
        sensorySum += ((sensory['tactileResponse'] ?? 0) +
                (sensory['auditoryFiltering'] ?? 0) +
                (sensory['vestibularSeeking'] ?? 0) +
                (sensory['proprioceptiveAwareness'] ?? 0)) /
            4;
      }

      // Cognitive
      final cognitive = assessment['cognitiveSkills'];
      if (cognitive != null) {
        cognitiveSum += ((cognitive['problemSolving'] ?? 0) +
                (cognitive['attentionSpan'] ?? 0) +
                (cognitive['followingDirections'] ?? 0) +
                (cognitive['sequencingTasks'] ?? 0)) /
            4;
      }
    }

    return {
      'fineMotor': count > 0 ? fineMotorSum / count : 0,
      'grossMotor': count > 0 ? grossMotorSum / count : 0,
      'sensory': count > 0 ? sensorySum / count : 0,
      'cognitive': count > 0 ? cognitiveSum / count : 0,
    };
  }

  List<FlSpot> _getProgressTrendData(String skillType) {
    if (assessments.isEmpty) return [];

    List<FlSpot> spots = [];

    // Reverse to show oldest to newest
    final reversedAssessments = assessments.reversed.toList();

    for (int i = 0; i < reversedAssessments.length && i < 10; i++) {
      final assessment = reversedAssessments[i];
      double score = 0;

      switch (skillType) {
        case 'fineMotor':
          final fineMotor = assessment['fineMotorSkills'];
          if (fineMotor != null) {
            score = ((fineMotor['pincerGrasp'] ?? 0) +
                    (fineMotor['handEyeCoordination'] ?? 0) +
                    (fineMotor['inHandManipulation'] ?? 0) +
                    (fineMotor['bilateralCoordination'] ?? 0)) /
                4;
          }
          break;
        case 'grossMotor':
          final grossMotor = assessment['grossMotorSkills'];
          if (grossMotor != null) {
            score = ((grossMotor['balance'] ?? 0) +
                    (grossMotor['runningJumping'] ?? 0) +
                    (grossMotor['throwingCatching'] ?? 0) +
                    (grossMotor['motorPlanning'] ?? 0)) /
                4;
          }
          break;
        case 'sensory':
          final sensory = assessment['sensoryProcessing'];
          if (sensory != null) {
            score = ((sensory['tactileResponse'] ?? 0) +
                    (sensory['auditoryFiltering'] ?? 0) +
                    (sensory['vestibularSeeking'] ?? 0) +
                    (sensory['proprioceptiveAwareness'] ?? 0)) /
                4;
          }
          break;
        case 'cognitive':
          final cognitive = assessment['cognitiveSkills'];
          if (cognitive != null) {
            score = ((cognitive['problemSolving'] ?? 0) +
                    (cognitive['attentionSpan'] ?? 0) +
                    (cognitive['followingDirections'] ?? 0) +
                    (cognitive['sequencingTasks'] ?? 0)) /
                4;
          }
          break;
      }

      spots.add(FlSpot(i.toDouble(), score));
    }

    return spots;
  }

  @override
  Widget build(BuildContext context) {
    final averageScores = _calculateAverageScores();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF006A5B),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: Text(
          '${widget.clientData['childName']} - Progress',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        actions: [
          // View/Print Options Button
          IconButton(
            onPressed: _showViewPrintOptions,
            icon: const Icon(Icons.folder_open, color: Colors.white),
            tooltip: 'View & Print Options',
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Add Session Button
          FloatingActionButton.extended(
            onPressed: _navigateToAddSession,
            backgroundColor: const Color(0xFF006A5B),
            heroTag: 'addSession',
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Add Session',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Final Evaluation Button (only show if there are sessions)
          if (assessments.isNotEmpty)
            FloatingActionButton.extended(
              onPressed: _navigateToFinalEvaluation,
              backgroundColor: const Color(0xFFFF9800),
              heroTag: 'finalEvaluation',
              icon: const Icon(Icons.assignment_turned_in, color: Colors.white),
              label: const Text(
                'Final Evaluation',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF006A5B),
              ),
            )
          : assessments.isEmpty
              ? _buildEmptyState()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Client Info Card
                      _buildClientInfoCard(),
                      const SizedBox(height: 20),

                      // Overall Progress Card
                      _buildOverallProgressCard(averageScores),
                      const SizedBox(height: 20),

                      // Progress Trend Chart
                      _buildProgressTrendChart(),
                      const SizedBox(height: 20),

                      // Skills Breakdown
                      _buildSkillsBreakdown(averageScores),
                      const SizedBox(height: 20),

                      // Initial Assessment Section
                      if (initialAssessment != null)
                        _buildInitialAssessmentSection(),
                      if (initialAssessment != null)
                        const SizedBox(height: 20),

                      // Final Evaluations Section
                      if (finalEvaluations.isNotEmpty)
                        _buildFinalEvaluationsSection(),
                      if (finalEvaluations.isNotEmpty)
                        const SizedBox(height: 20),

                      // Assessment History
                      _buildAssessmentHistory(),
                      const SizedBox(height: 20),

                      // Detailed Assessment Table
                      _buildDetailedAssessmentTable(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF006A5B).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.note_add_outlined,
              size: 80,
              color: const Color(0xFF006A5B),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Sessions Yet',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Start tracking therapy progress by adding\nthe first session for this client.',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[600],
              fontFamily: 'Poppins',
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Add First Session Button
          ElevatedButton.icon(
            onPressed: _navigateToAddSession,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006A5B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            icon: const Icon(Icons.add, size: 24),
            label: const Text(
              'Add First Session',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Or Retry Loading
          TextButton(
            onPressed: () {
              setState(() {
                isLoading = true;
              });
              _loadAssessments();
            },
            child: Text(
              'Or Retry Loading',
              style: TextStyle(
                color: Colors.grey[600],
                fontFamily: 'Poppins',
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Test query button
          ElevatedButton(
            onPressed: () => _testDirectQuery(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'Test Direct Query',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
          ),

          const SizedBox(height: 30),

          // Debug information card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Debug Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF006A5B),
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 12),
                _buildDebugInfo('Client ID',
                    widget.clientData['clientId']?.toString() ?? 'null'),
                _buildDebugInfo('Child Name',
                    widget.clientData['childName']?.toString() ?? 'null'),
                _buildDebugInfo('Patient Name',
                    widget.clientData['patientName']?.toString() ?? 'null'),
                _buildDebugInfo('Clinic ID', widget.clinicId),
                _buildDebugInfo('Booking ID',
                    widget.clientData['bookingId']?.toString() ?? 'null'),
                const SizedBox(height: 12),
                const Text(
                  'Client Data:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.clientData.toString(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontFamily: 'monospace',
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

  Widget _buildDebugInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF006A5B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(
              Icons.person,
              color: Color(0xFF006A5B),
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.clientData['childName'] ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Age: ${widget.clientData['age']} • ${widget.clientData['diagnosis']}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Parent: ${widget.clientData['parentName']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF006A5B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${assessments.length} Sessions',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallProgressCard(Map<String, double> averageScores) {
    final overallAverage = (averageScores['fineMotor']! +
            averageScores['grossMotor']! +
            averageScores['sensory']! +
            averageScores['cognitive']!) /
        4;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF006A5B), Color(0xFF67AFA5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF006A5B).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Overall Progress Score',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${(overallAverage * 20).toStringAsFixed(1)}%',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Based on ${assessments.length} session${assessments.length != 1 ? 's' : ''}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressTrendChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          const Text(
            'Progress Trend Over Time',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[200]!,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 1,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            color: Colors.grey[600],
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
                        return Text(
                          '${value.toInt() + 1}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                            fontFamily: 'Poppins',
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey[200]!),
                ),
                minX: 0,
                maxX: (assessments.length - 1).toDouble().clamp(1, 9),
                minY: 0,
                maxY: 5,
                lineBarsData: [
                  // Fine Motor
                  LineChartBarData(
                    spots: _getProgressTrendData('fineMotor'),
                    isCurved: true,
                    color: const Color(0xFF006A5B),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(show: false),
                  ),
                  // Gross Motor
                  LineChartBarData(
                    spots: _getProgressTrendData('grossMotor'),
                    isCurved: true,
                    color: const Color(0xFF67AFA5),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(show: false),
                  ),
                  // Sensory
                  LineChartBarData(
                    spots: _getProgressTrendData('sensory'),
                    isCurved: true,
                    color: Colors.orange,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(show: false),
                  ),
                  // Cognitive
                  LineChartBarData(
                    spots: _getProgressTrendData('cognitive'),
                    isCurved: true,
                    color: Colors.purple,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Legend
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildLegendItem('Fine Motor', const Color(0xFF006A5B)),
              _buildLegendItem('Gross Motor', const Color(0xFF67AFA5)),
              _buildLegendItem('Sensory', Colors.orange),
              _buildLegendItem('Cognitive', Colors.purple),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  Widget _buildSkillsBreakdown(Map<String, double> averageScores) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          const Text(
            'Skills Breakdown',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 20),
          _buildSkillBar(
            'Fine Motor Skills',
            averageScores['fineMotor']!,
            const Color(0xFF006A5B),
          ),
          const SizedBox(height: 16),
          _buildSkillBar(
            'Gross Motor Skills',
            averageScores['grossMotor']!,
            const Color(0xFF67AFA5),
          ),
          const SizedBox(height: 16),
          _buildSkillBar(
            'Sensory Processing',
            averageScores['sensory']!,
            Colors.orange,
          ),
          const SizedBox(height: 16),
          _buildSkillBar(
            'Cognitive Skills',
            averageScores['cognitive']!,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildSkillBar(String label, double score, Color color) {
    final percentage = (score / 5 * 100);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
                fontFamily: 'Poppins',
              ),
            ),
            Text(
              '${score.toStringAsFixed(1)}/5',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 10,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            FractionallySizedBox(
              widthFactor: score / 5,
              child: Container(
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${percentage.toStringAsFixed(0)}%',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  Widget _buildInitialAssessmentSection() {
    if (initialAssessment == null) return const SizedBox.shrink();

    String dateStr = 'Unknown date';
    try {
      final timestamp = initialAssessment!['createdAt'] as Timestamp?;
      if (timestamp != null) {
        final date = timestamp.toDate();
        dateStr = '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      // Use default
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF006A5B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.assignment,
                  color: Color(0xFF006A5B),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Initial Assessment',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Text(
                      'Date: $dateStr',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SessionDetailView(
                    sessionData: initialAssessment!,
                    sessionNumber: 0,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF006A5B).withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF006A5B).withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'View Initial Assessment Details',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF006A5B),
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: Color(0xFF006A5B),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalEvaluationsSection() {
    if (finalEvaluations.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.assignment_turned_in,
                  color: Color(0xFFFF9800),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Final Evaluations',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          ...finalEvaluations.asMap().entries.map((entry) {
            final index = entry.key;
            final evaluation = entry.value;
            
            String dateStr = 'Unknown date';
            try {
              final timestamp = evaluation['createdAt'] as Timestamp?;
              if (timestamp != null) {
                final date = timestamp.toDate();
                dateStr = '${date.day}/${date.month}/${date.year}';
              }
            } catch (e) {
              // Use default
            }

            return Padding(
              padding: EdgeInsets.only(bottom: index < finalEvaluations.length - 1 ? 12 : 0),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FinalEvaluationViewer(
                        evaluationId: evaluation['id'],
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9800).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFF9800).withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Final Evaluation ${finalEvaluations.length - index}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFFF9800),
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dateStr,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: Color(0xFFFF9800),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildAssessmentHistory() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          const Text(
            'Session History',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 16),
          ...assessments.asMap().entries.map((entry) {
            final index = entry.key;
            final assessment = entry.value;
            return _buildAssessmentHistoryItem(assessment, index);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildAssessmentHistoryItem(
      Map<String, dynamic> assessment, int index) {
    String dateStr = 'Unknown date';
    try {
      final timestamp = assessment['createdAt'] as Timestamp?;
      if (timestamp != null) {
        final date = timestamp.toDate();
        dateStr = '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      // Use default
    }

    return InkWell(
      onTap: () {
        // Navigate to session detail view
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SessionDetailView(
              sessionData: assessment,
              sessionNumber: assessments.length - index,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF006A5B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  '${assessments.length - index}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF006A5B),
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Session ${assessments.length - index}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C3E50),
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedAssessmentTable() {
    if (assessments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'No session data available',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            children: [
              const Icon(
                Icons.table_chart,
                color: Color(0xFF006A5B),
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Detailed Session Data',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF006A5B).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                const Expanded(
                  flex: 2,
                  child: Text(
                    'Session Date',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF006A5B),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                const Expanded(
                  child: Text(
                    'Fine Motor',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF006A5B),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                const Expanded(
                  child: Text(
                    'Gross Motor',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF006A5B),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                const Expanded(
                  child: Text(
                    'Sensory',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF006A5B),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                const Expanded(
                  child: Text(
                    'Cognitive',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF006A5B),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Table Rows
          ...assessments.asMap().entries.map((entry) {
            final index = entry.key;
            final assessment = entry.value;
            return _buildTableRow(assessment, index);
          }).toList(),

          const SizedBox(height: 20),

          // Expandable detailed view for each assessment
          ...assessments.asMap().entries.map((entry) {
            final index = entry.key;
            final assessment = entry.value;
            return _buildExpandableAssessmentCard(assessment, index);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTableRow(Map<String, dynamic> assessment, int index) {
    String dateStr = 'Unknown';
    try {
      final timestamp = assessment['createdAt'] as Timestamp?;
      if (timestamp != null) {
        final date = timestamp.toDate();
        dateStr = '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      // Use default
    }

    // Calculate average scores for each category
    double fineMotorAvg =
        _calculateCategoryAverage(assessment['fineMotorSkills']);
    double grossMotorAvg =
        _calculateCategoryAverage(assessment['grossMotorSkills']);
    double sensoryAvg =
        _calculateCategoryAverage(assessment['sensoryProcessing']);
    double cognitiveAvg =
        _calculateCategoryAverage(assessment['cognitiveSkills']);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: index % 2 == 0 ? Colors.grey[50] : Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              dateStr,
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'Poppins',
                color: Color(0xFF2C3E50),
              ),
            ),
          ),
          Expanded(
            child: _buildScoreCell(fineMotorAvg),
          ),
          Expanded(
            child: _buildScoreCell(grossMotorAvg),
          ),
          Expanded(
            child: _buildScoreCell(sensoryAvg),
          ),
          Expanded(
            child: _buildScoreCell(cognitiveAvg),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCell(double score) {
    Color scoreColor = _getScoreColor(score);

    return Container(
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: scoreColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: scoreColor.withOpacity(0.3)),
        ),
        child: Text(
          score.toStringAsFixed(1),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: scoreColor,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 4.0) return Colors.green;
    if (score >= 3.0) return Colors.orange;
    if (score >= 2.0) return Colors.deepOrange;
    return Colors.red;
  }

  double _calculateCategoryAverage(dynamic categoryData) {
    if (categoryData == null) return 0.0;

    final Map<String, dynamic> category = categoryData as Map<String, dynamic>;
    List<double> scores = [];

    category.forEach((key, value) {
      if (key != 'notes' && value is num) {
        scores.add(value.toDouble());
      }
    });

    if (scores.isEmpty) return 0.0;
    return scores.reduce((a, b) => a + b) / scores.length;
  }

  Widget _buildExpandableAssessmentCard(
      Map<String, dynamic> assessment, int index) {
    String dateStr = 'Unknown';
    try {
      final timestamp = assessment['createdAt'] as Timestamp?;
      if (timestamp != null) {
        final date = timestamp.toDate();
        dateStr = '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      // Use default
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        backgroundColor: Colors.grey[50],
        collapsedBackgroundColor: Colors.white,
        title: Text(
          'Session ${assessments.length - index} - $dateStr',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C3E50),
            fontFamily: 'Poppins',
          ),
        ),
        subtitle: Text(
          'Type: ${assessment['assessmentType'] ?? 'Occupational Therapy'}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontFamily: 'Poppins',
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fine Motor Skills
                _buildSkillSection(
                  'Fine Motor Skills',
                  assessment['fineMotorSkills'],
                  [
                    'Pincer Grasp',
                    'Hand-Eye Coordination',
                    'In-Hand Manipulation',
                    'Bilateral Coordination'
                  ],
                  [
                    'pincerGrasp',
                    'handEyeCoordination',
                    'inHandManipulation',
                    'bilateralCoordination'
                  ],
                  const Color(0xFF006A5B),
                ),
                const SizedBox(height: 16),

                // Gross Motor Skills
                _buildSkillSection(
                  'Gross Motor Skills',
                  assessment['grossMotorSkills'],
                  [
                    'Balance',
                    'Running/Jumping',
                    'Throwing/Catching',
                    'Motor Planning'
                  ],
                  [
                    'balance',
                    'runningJumping',
                    'throwingCatching',
                    'motorPlanning'
                  ],
                  const Color(0xFF67AFA5),
                ),
                const SizedBox(height: 16),

                // Sensory Processing
                _buildSkillSection(
                  'Sensory Processing',
                  assessment['sensoryProcessing'],
                  [
                    'Tactile Response',
                    'Auditory Filtering',
                    'Vestibular Seeking',
                    'Proprioceptive Awareness'
                  ],
                  [
                    'tactileResponse',
                    'auditoryFiltering',
                    'vestibularSeeking',
                    'proprioceptiveAwareness'
                  ],
                  Colors.orange,
                ),
                const SizedBox(height: 16),

                // Cognitive Skills
                _buildSkillSection(
                  'Cognitive Skills',
                  assessment['cognitiveSkills'],
                  [
                    'Problem Solving',
                    'Attention Span',
                    'Following Directions',
                    'Sequencing Tasks'
                  ],
                  [
                    'problemSolving',
                    'attentionSpan',
                    'followingDirections',
                    'sequencingTasks'
                  ],
                  Colors.purple,
                ),

                // Additional Information
                if (assessment['primaryConcerns'] != null &&
                    assessment['primaryConcerns'].toString().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Primary Concerns',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          assessment['primaryConcerns'].toString(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillSection(
    String title,
    dynamic skillData,
    List<String> skillNames,
    List<String> skillKeys,
    Color color,
  ) {
    if (skillData == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '$title: No data available',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontFamily: 'Poppins',
          ),
        ),
      );
    }

    final Map<String, dynamic> skills = skillData as Map<String, dynamic>;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          ...skillNames.asMap().entries.map((entry) {
            final index = entry.key;
            final skillName = entry.value;
            final skillKey = skillKeys[index];
            final score = skills[skillKey] ?? 0;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    skillName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getScoreColor(score.toDouble()),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      score.toString(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),

          // Notes if available
          if (skills['notes'] != null &&
              skills['notes'].toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Notes: ${skills['notes']}',
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: Colors.grey[600],
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ],
      ),
    );
  }
}
