import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

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
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAssessments();
  }

  Future<void> _loadAssessments() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('OTAssessments')
          .where('patientId', isEqualTo: widget.clientData['clientId'])
          .where('clinicId', isEqualTo: widget.clinicId)
          .orderBy('createdAt', descending: true)
          .get();

      setState(() {
        assessments =
            snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
        isLoading = false;
      });
    } catch (e) {
      print('Error loading assessments: $e');
      setState(() {
        isLoading = false;
      });
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

                      // Assessment History
                      _buildAssessmentHistory(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assessment_outlined,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No Assessments Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Assessments for this client will appear here.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
              '${assessments.length} Assessments',
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
            'Based on ${assessments.length} assessment${assessments.length != 1 ? 's' : ''}',
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
            'Assessment History',
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

    return Container(
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
                  'Assessment ${assessments.length - index}',
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
    );
  }
}
