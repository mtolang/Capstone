import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class FinalEvaluationViewer extends StatelessWidget {
  final String evaluationId;

  const FinalEvaluationViewer({
    Key? key,
    required this.evaluationId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Final Evaluation Report',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        backgroundColor: const Color(0xFF006A5B),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {
              // TODO: Implement print/export functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Print/Export feature coming soon'),
                ),
              );
            },
            tooltip: 'Print Report',
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('FinalEvaluations')
            .doc(evaluationId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF006A5B)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text('Evaluation not found'),
            );
          }

          final evaluation = snapshot.data!.data() as Map<String, dynamic>;
          return _buildEvaluationContent(context, evaluation);
        },
      ),
    );
  }

  Widget _buildEvaluationContent(BuildContext context, Map<String, dynamic> evaluation) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Client Info
          _buildHeaderCard(evaluation),
          const SizedBox(height: 20),
          
          // Overall Assessment
          _buildSection(
            'Overall Assessment',
            Icons.assessment,
            [
              _buildReadOnlyField('Overall Progress Summary', evaluation['overallSummary']),
              const SizedBox(height: 16),
              _buildReadOnlyField('Therapy Goals Achieved', evaluation['therapyGoalsAchieved']),
              const SizedBox(height: 16),
              _buildChipField('Progress Rating', evaluation['overallProgressRating']),
              const SizedBox(height: 16),
              _buildReadOnlyField('Progress Description', evaluation['progressDescription']),
            ],
          ),
          const SizedBox(height: 20),
          
          // Skills Development
          _buildSection(
            'Skills Development Analysis',
            Icons.star,
            [
              _buildSkillDisplay('Fine Motor Skills', evaluation['fineMotorEvaluation'], Colors.blue),
              const SizedBox(height: 16),
              _buildSkillDisplay('Gross Motor Skills', evaluation['grossMotorEvaluation'], Colors.green),
              const SizedBox(height: 16),
              _buildSkillDisplay('Cognitive Skills', evaluation['cognitiveEvaluation'], Colors.purple),
              const SizedBox(height: 16),
              _buildSkillDisplay('Sensory Processing', evaluation['sensoryEvaluation'], Colors.orange),
              const SizedBox(height: 16),
              _buildSkillDisplay('Social & Emotional', evaluation['socialEmotionalEvaluation'], Colors.pink),
            ],
          ),
          const SizedBox(height: 20),
          
          // Recommendations
          _buildSection(
            'Recommendations & Future Planning',
            Icons.medical_services,
            [
              _buildReadOnlyField('Continue Therapy', evaluation['continueTherapyRecommendation']),
              const SizedBox(height: 16),
              _buildReadOnlyField('Home Exercise Program', evaluation['homeExerciseProgram']),
              const SizedBox(height: 16),
              if (evaluation['schoolRecommendations'] != null && evaluation['schoolRecommendations'].toString().isNotEmpty)
                ...[
                  _buildReadOnlyField('School Recommendations', evaluation['schoolRecommendations']),
                  const SizedBox(height: 16),
                ],
              _buildReadOnlyField('Follow-up Schedule', evaluation['followUpSchedule']),
              const SizedBox(height: 16),
              if (evaluation['additionalServicesRecommended'] != null && evaluation['additionalServicesRecommended'].toString().isNotEmpty)
                ...[
                  _buildReadOnlyField('Additional Services', evaluation['additionalServicesRecommended']),
                  const SizedBox(height: 16),
                ],
              _buildReadOnlyField('Parent Guidelines', evaluation['parentGuidelines']),
            ],
          ),
          const SizedBox(height: 20),
          
          // Discharge Planning (if applicable)
          if (evaluation['isDischargeRecommended'] == true)
            ...[
              _buildSection(
                'Discharge Planning',
                Icons.exit_to_app,
                [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.info, color: Colors.amber, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Discharge Recommended',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildReadOnlyField('Discharge Rationale', evaluation['dischargeReason']),
                  const SizedBox(height: 16),
                  _buildReadOnlyField('Maintenance Plan', evaluation['maintenancePlan']),
                ],
              ),
              const SizedBox(height: 20),
            ],
          
          // Professional Notes
          _buildSection(
            'Professional Assessment',
            Icons.person,
            [
              _buildReadOnlyField('Therapist Notes', evaluation['therapistNotes']),
              const SizedBox(height: 16),
              _buildInfoRow('Therapist', evaluation['therapistName']),
              _buildInfoRow('License', evaluation['therapistLicense']),
              _buildInfoRow(
                'Evaluation Date',
                evaluation['evaluationDate'] != null
                    ? DateFormat('MMMM dd, yyyy').format((evaluation['evaluationDate'] as Timestamp).toDate())
                    : 'N/A',
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(Map<String, dynamic> evaluation) {
    final childName = evaluation['childName'] ?? 'Unknown';
    final parentName = evaluation['parentName'] ?? 'Unknown';
    final age = evaluation['age'] ?? 'N/A';
    final totalSessions = evaluation['totalSessionsCompleted'] ?? 0;
    
    String therapyPeriod = 'N/A';
    if (evaluation['therapyPeriodStart'] != null && evaluation['therapyPeriodEnd'] != null) {
      final start = DateFormat('MMM dd, yyyy').format((evaluation['therapyPeriodStart'] as Timestamp).toDate());
      final end = DateFormat('MMM dd, yyyy').format((evaluation['therapyPeriodEnd'] as Timestamp).toDate());
      therapyPeriod = '$start - $end';
    }
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              const Color(0xFF006A5B),
              const Color(0xFF006A5B).withOpacity(0.8),
            ],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.assignment_turned_in,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'FINAL EVALUATION REPORT',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        childName,
                        style: const TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white30, height: 32),
            Row(
              children: [
                Expanded(
                  child: _buildHeaderInfo('Parent/Guardian', parentName),
                ),
                Expanded(
                  child: _buildHeaderInfo('Age', age.toString()),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildHeaderInfo('Total Sessions', totalSessions.toString()),
                ),
                Expanded(
                  child: _buildHeaderInfo('Therapy Period', therapyPeriod),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white70,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF006A5B), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF006A5B),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSkillDisplay(String skillName, dynamic skillData, Color color) {
    if (skillData == null) {
      return Container();
    }
    
    final data = skillData as Map<String, dynamic>;
    final currentLevel = data['currentLevel'] ?? 3;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getSkillIcon(skillName),
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  skillName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              _buildLevelBadge(currentLevel, color),
            ],
          ),
          const SizedBox(height: 16),
          
          // Level Indicator
          Row(
            children: List.generate(5, (index) {
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: index < 4 ? 4 : 0),
                  height: 8,
                  decoration: BoxDecoration(
                    color: currentLevel > index ? color : Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          
          if (data['improvementNotes'] != null && data['improvementNotes'].toString().isNotEmpty)
            ...[
              _buildSubField('Improvement Observed', data['improvementNotes']),
              const SizedBox(height: 12),
            ],
          if (data['strengthsIdentified'] != null && data['strengthsIdentified'].toString().isNotEmpty)
            ...[
              _buildSubField('Strengths', data['strengthsIdentified']),
              const SizedBox(height: 12),
            ],
          if (data['areasForDevelopment'] != null && data['areasForDevelopment'].toString().isNotEmpty)
            ...[
              _buildSubField('Areas for Development', data['areasForDevelopment']),
              const SizedBox(height: 12),
            ],
          if (data['recommendedActivities'] != null && data['recommendedActivities'].toString().isNotEmpty)
            _buildSubField('Recommended Activities', data['recommendedActivities']),
        ],
      ),
    );
  }

  IconData _getSkillIcon(String skillName) {
    if (skillName.contains('Fine Motor')) return Icons.touch_app;
    if (skillName.contains('Gross Motor')) return Icons.directions_run;
    if (skillName.contains('Cognitive')) return Icons.psychology;
    if (skillName.contains('Sensory')) return Icons.sensors;
    if (skillName.contains('Social')) return Icons.people;
    return Icons.star;
  }

  Widget _buildLevelBadge(int level, Color color) {
    String levelText = 'Level $level';
    String description = '';
    
    switch (level) {
      case 1:
        description = 'Needs Maximum Support';
        break;
      case 2:
        description = 'Needs Moderate Support';
        break;
      case 3:
        description = 'Needs Minimal Support';
        break;
      case 4:
        description = 'Mostly Independent';
        break;
      case 5:
        description = 'Fully Independent';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            levelText,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              fontFamily: 'Poppins',
            ),
          ),
          Text(
            description,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 8,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String? value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Text(
            value ?? 'N/A',
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubField(String label, String? value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value ?? 'N/A',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[700],
            height: 1.4,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  Widget _buildChipField(String label, String? value) {
    Color chipColor = const Color(0xFF006A5B);
    if (value == 'Significant Progress') chipColor = Colors.green;
    if (value == 'Moderate Progress') chipColor = Colors.blue;
    if (value == 'Minimal Progress') chipColor = Colors.orange;
    if (value == 'No Progress' || value == 'Regression') chipColor = Colors.red;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 8),
        Chip(
          label: Text(
            value ?? 'N/A',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          backgroundColor: chipColor,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontFamily: 'Poppins',
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
