import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'final_evaluation_viewer.dart';

class FinalEvaluationForm extends StatefulWidget {
  final Map<String, dynamic> clientData;
  final String clinicId;
  final List<Map<String, dynamic>> sessionHistory;

  const FinalEvaluationForm({
    Key? key,
    required this.clientData,
    required this.clinicId,
    required this.sessionHistory,
  }) : super(key: key);

  @override
  State<FinalEvaluationForm> createState() => _FinalEvaluationFormState();
}

class _FinalEvaluationFormState extends State<FinalEvaluationForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  String? _savedEvaluationId; // Store the evaluation ID after saving
  bool _isEvaluationSaved = false; // Track if evaluation is saved

  // Overall Assessment
  final TextEditingController _overallSummaryController = TextEditingController();
  final TextEditingController _therapyGoalsAchievedController = TextEditingController();
  
  // Progress Analysis
  String _overallProgressRating = 'Significant Progress';
  final TextEditingController _progressDescriptionController = TextEditingController();
  
  // Skills Development Assessment
  Map<String, dynamic> _fineMotorEvaluation = {
    'currentLevel': 3,
    'improvementNotes': '',
    'strengthsIdentified': '',
    'areasForDevelopment': '',
    'recommendedActivities': '',
  };
  
  Map<String, dynamic> _grossMotorEvaluation = {
    'currentLevel': 3,
    'improvementNotes': '',
    'strengthsIdentified': '',
    'areasForDevelopment': '',
    'recommendedActivities': '',
  };
  
  Map<String, dynamic> _cognitiveEvaluation = {
    'currentLevel': 3,
    'improvementNotes': '',
    'strengthsIdentified': '',
    'areasForDevelopment': '',
    'recommendedActivities': '',
  };
  
  Map<String, dynamic> _sensoryEvaluation = {
    'currentLevel': 3,
    'improvementNotes': '',
    'strengthsIdentified': '',
    'areasForDevelopment': '',
    'recommendedActivities': '',
  };
  
  Map<String, dynamic> _socialEmotionalEvaluation = {
    'currentLevel': 3,
    'improvementNotes': '',
    'strengthsIdentified': '',
    'areasForDevelopment': '',
    'recommendedActivities': '',
  };
  
  // Recommendations & Future Planning
  final TextEditingController _continueTherapyController = TextEditingController();
  final TextEditingController _homeExercisesController = TextEditingController();
  final TextEditingController _schoolRecommendationsController = TextEditingController();
  final TextEditingController _followUpScheduleController = TextEditingController();
  final TextEditingController _additionalServicesController = TextEditingController();
  final TextEditingController _parentGuidelinesController = TextEditingController();
  
  // Discharge Planning
  bool _isDischargeRecommended = false;
  final TextEditingController _dischargeReasonController = TextEditingController();
  final TextEditingController _maintenancePlanController = TextEditingController();
  
  // Professional Assessment
  final TextEditingController _therapistNotesController = TextEditingController();
  String _therapistName = '';
  String _therapistLicense = '';

  @override
  void initState() {
    super.initState();
    _loadTherapistInfo();
    _prePopulateFromSessions();
  }

  Future<void> _loadTherapistInfo() async {
    // Load therapist information from clinic data or user session
    setState(() {
      _therapistName = 'Dr. [Therapist Name]'; // TODO: Get from auth
      _therapistLicense = 'License #: [Number]'; // TODO: Get from profile
    });
  }

  void _prePopulateFromSessions() {
    if (widget.sessionHistory.isEmpty) return;
    
    // Calculate average progress from sessions
    double totalFineMotor = 0, totalGrossMotor = 0, totalCognitive = 0;
    int count = 0;
    
    for (var session in widget.sessionHistory) {
      if (session['fineMotorSkills'] != null) {
        final fineMotor = session['fineMotorSkills'] as Map;
        totalFineMotor += _calculateCategoryAverage(fineMotor);
        count++;
      }
      if (session['grossMotorSkills'] != null) {
        final grossMotor = session['grossMotorSkills'] as Map;
        totalGrossMotor += _calculateCategoryAverage(grossMotor);
      }
      if (session['cognitiveSkills'] != null) {
        final cognitive = session['cognitiveSkills'] as Map;
        totalCognitive += _calculateCategoryAverage(cognitive);
      }
    }
    
    if (count > 0) {
      setState(() {
        _fineMotorEvaluation['currentLevel'] = (totalFineMotor / count / 20).round();
        _grossMotorEvaluation['currentLevel'] = (totalGrossMotor / count / 20).round();
        _cognitiveEvaluation['currentLevel'] = (totalCognitive / count / 20).round();
      });
    }
  }

  double _calculateCategoryAverage(Map<dynamic, dynamic> category) {
    if (category.isEmpty) return 0;
    int total = 0;
    int count = 0;
    category.forEach((key, value) {
      if (value is int) {
        total += value;
        count++;
      }
    });
    return count > 0 ? (total / count) * 20 : 0;
  }

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
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Client Information Card
            _buildClientInfoCard(),
            const SizedBox(height: 20),
            
            // Session Summary Card
            _buildSessionSummaryCard(),
            const SizedBox(height: 20),
            
            // Overall Assessment Section
            _buildSectionCard(
              'Overall Assessment',
              Icons.assessment,
              [
                _buildTextField(
                  controller: _overallSummaryController,
                  label: 'Overall Progress Summary',
                  hint: 'Provide a comprehensive summary of the child\'s overall progress throughout therapy...',
                  maxLines: 4,
                  required: true,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _therapyGoalsAchievedController,
                  label: 'Therapy Goals Achieved',
                  hint: 'List the specific goals that were achieved during therapy...',
                  maxLines: 3,
                  required: true,
                ),
                const SizedBox(height: 16),
                _buildDropdown(
                  label: 'Overall Progress Rating',
                  value: _overallProgressRating,
                  items: [
                    'Significant Progress',
                    'Moderate Progress',
                    'Minimal Progress',
                    'No Progress',
                    'Regression'
                  ],
                  onChanged: (value) {
                    setState(() {
                      _overallProgressRating = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _progressDescriptionController,
                  label: 'Progress Description Details',
                  hint: 'Describe the specific improvements and changes observed...',
                  maxLines: 4,
                  required: true,
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Skills Development Assessment
            _buildSectionCard(
              'Skills Development Analysis',
              Icons.star,
              [
                _buildSkillEvaluationSection(
                  'Fine Motor Skills',
                  _fineMotorEvaluation,
                  Icons.touch_app,
                  Colors.blue,
                ),
                const SizedBox(height: 20),
                _buildSkillEvaluationSection(
                  'Gross Motor Skills',
                  _grossMotorEvaluation,
                  Icons.directions_run,
                  Colors.green,
                ),
                const SizedBox(height: 20),
                _buildSkillEvaluationSection(
                  'Cognitive Skills',
                  _cognitiveEvaluation,
                  Icons.psychology,
                  Colors.purple,
                ),
                const SizedBox(height: 20),
                _buildSkillEvaluationSection(
                  'Sensory Processing',
                  _sensoryEvaluation,
                  Icons.sensors,
                  Colors.orange,
                ),
                const SizedBox(height: 20),
                _buildSkillEvaluationSection(
                  'Social & Emotional Development',
                  _socialEmotionalEvaluation,
                  Icons.people,
                  Colors.pink,
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Recommendations & Future Planning
            _buildSectionCard(
              'Recommendations & Future Planning',
              Icons.medical_services,
              [
                _buildTextField(
                  controller: _continueTherapyController,
                  label: 'Continuation of Therapy Recommendations',
                  hint: 'Specify if therapy should continue, frequency, duration, and focus areas...',
                  maxLines: 3,
                  required: true,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _homeExercisesController,
                  label: 'Home Exercise Program',
                  hint: 'Detailed home exercises and activities for parents to implement...',
                  maxLines: 4,
                  required: true,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _schoolRecommendationsController,
                  label: 'School/Educational Recommendations',
                  hint: 'Accommodations, modifications, or strategies for school setting...',
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _followUpScheduleController,
                  label: 'Follow-up Schedule',
                  hint: 'Recommended schedule for re-evaluation or follow-up appointments...',
                  maxLines: 2,
                  required: true,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _additionalServicesController,
                  label: 'Additional Services Recommended',
                  hint: 'Other services or specialists recommended (speech therapy, physical therapy, etc.)...',
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _parentGuidelinesController,
                  label: 'Parent Guidelines & Support',
                  hint: 'Specific guidelines for parents to support child\'s continued development...',
                  maxLines: 4,
                  required: true,
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Discharge Planning (if applicable)
            _buildSectionCard(
              'Discharge Planning',
              Icons.exit_to_app,
              [
                SwitchListTile(
                  title: const Text(
                    'Recommend Discharge from Therapy',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  subtitle: const Text('Check if child has met goals and is ready for discharge'),
                  value: _isDischargeRecommended,
                  activeColor: const Color(0xFF006A5B),
                  onChanged: (value) {
                    setState(() {
                      _isDischargeRecommended = value;
                    });
                  },
                ),
                if (_isDischargeRecommended) ...[
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _dischargeReasonController,
                    label: 'Discharge Rationale',
                    hint: 'Explain why discharge is recommended and what goals have been achieved...',
                    maxLines: 3,
                    required: true,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _maintenancePlanController,
                    label: 'Maintenance Plan Post-Discharge',
                    hint: 'Plan for maintaining skills after discharge from therapy...',
                    maxLines: 3,
                    required: true,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),
            
            // Professional Notes
            _buildSectionCard(
              'Professional Assessment & Notes',
              Icons.person,
              [
                _buildTextField(
                  controller: _therapistNotesController,
                  label: 'Therapist\'s Professional Notes',
                  hint: 'Additional professional observations, concerns, or notes...',
                  maxLines: 4,
                  required: true,
                ),
                const SizedBox(height: 16),
                _buildReadOnlyField('Evaluating Therapist', _therapistName),
                const SizedBox(height: 8),
                _buildReadOnlyField('Professional License', _therapistLicense),
                const SizedBox(height: 8),
                _buildReadOnlyField(
                  'Evaluation Date',
                  DateFormat('MMMM dd, yyyy').format(DateTime.now()),
                ),
              ],
            ),
            const SizedBox(height: 30),
            
            // Action Buttons Section
            if (!_isEvaluationSaved)
              // Save Button (shows before evaluation is saved)
              SizedBox(
                height: 55,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _submitEvaluation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006A5B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Save Final Evaluation',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Poppins',
                          ),
                        ),
                ),
              )
            else
              // View and Export Buttons (shows after evaluation is saved)
              Column(
                children: [
                  // Success message
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green, width: 2),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green[700], size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Final evaluation saved successfully!',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // View Evaluation Button
                  SizedBox(
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: _viewEvaluation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF006A5B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      icon: const Icon(Icons.visibility, color: Colors.white, size: 24),
                      label: const Text(
                        'View Final Evaluation',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Export as PDF Button
                  SizedBox(
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: _exportEvaluationAsPDF,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF9800),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      icon: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 24),
                      label: const Text(
                        'Export as PDF',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildClientInfoCard() {
    final childName = widget.clientData['childName'] ?? 'Unknown';
    final parentName = widget.clientData['parentName'] ?? 'Unknown';
    final age = widget.clientData['age'] ?? 'N/A';
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF006A5B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
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
                      const Text(
                        'Client Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF006A5B),
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        childName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow('Parent/Guardian', parentName),
            _buildInfoRow('Age', age.toString()),
            _buildInfoRow('Client ID', widget.clientData['clientId'] ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionSummaryCard() {
    final totalSessions = widget.sessionHistory.length;
    final dateRange = totalSessions > 0
        ? '${DateFormat('MMM dd, yyyy').format((widget.sessionHistory.last['createdAt'] as Timestamp).toDate())} - ${DateFormat('MMM dd, yyyy').format((widget.sessionHistory.first['createdAt'] as Timestamp).toDate())}'
        : 'No sessions recorded';
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.calendar_today,
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Therapy Session Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF006A5B),
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow('Total Sessions Completed', totalSessions.toString()),
            _buildInfoRow('Therapy Period', dateRange),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
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
                Icon(icon, color: const Color(0xFF006A5B), size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
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

  Widget _buildSkillEvaluationSection(
    String skillName,
    Map<String, dynamic> evaluation,
    IconData icon,
    Color color,
  ) {
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
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  skillName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Current Level Rating
          const Text(
            'Current Functional Level',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (index) {
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      evaluation['currentLevel'] = index + 1;
                    });
                  },
                  child: Container(
                    margin: EdgeInsets.only(right: index < 4 ? 4 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: evaluation['currentLevel'] > index
                          ? color
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: evaluation['currentLevel'] > index
                              ? Colors.white
                              : Colors.grey[600],
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Needs Support',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                  fontFamily: 'Poppins',
                ),
              ),
              Text(
                'Independent',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Improvement Notes
          _buildTextField(
            controller: TextEditingController(text: evaluation['improvementNotes']),
            label: 'Improvement Observed',
            hint: 'Describe specific improvements in $skillName...',
            maxLines: 2,
            onChanged: (value) => evaluation['improvementNotes'] = value,
          ),
          const SizedBox(height: 12),
          
          // Strengths Identified
          _buildTextField(
            controller: TextEditingController(text: evaluation['strengthsIdentified']),
            label: 'Strengths Identified',
            hint: 'List the child\'s strengths in this area...',
            maxLines: 2,
            onChanged: (value) => evaluation['strengthsIdentified'] = value,
          ),
          const SizedBox(height: 12),
          
          // Areas for Development
          _buildTextField(
            controller: TextEditingController(text: evaluation['areasForDevelopment']),
            label: 'Areas Needing Further Development',
            hint: 'Identify areas that still need work...',
            maxLines: 2,
            onChanged: (value) => evaluation['areasForDevelopment'] = value,
            required: true,
          ),
          const SizedBox(height: 12),
          
          // Recommended Activities
          _buildTextField(
            controller: TextEditingController(text: evaluation['recommendedActivities']),
            label: 'Recommended Activities/Exercises',
            hint: 'Specific activities to continue development...',
            maxLines: 2,
            onChanged: (value) => evaluation['recommendedActivities'] = value,
            required: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    bool required = false,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              fontFamily: 'Poppins',
            ),
            children: required
                ? [
                    const TextSpan(
                      text: ' *',
                      style: TextStyle(color: Colors.red),
                    ),
                  ]
                : [],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: 13,
              fontFamily: 'Poppins',
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF006A5B), width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(16),
          ),
          validator: required
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'This field is required';
                  }
                  return null;
                }
              : null,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
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
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF006A5B), width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(16),
          ),
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
      ],
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
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
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontFamily: 'Poppins',
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitEvaluation() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Prepare evaluation data
      final evaluationData = {
        // Client Information
        'clientId': widget.clientData['clientId'],
        'childName': widget.clientData['childName'],
        'parentName': widget.clientData['parentName'],
        'age': widget.clientData['age'],
        'clinicId': widget.clinicId,
        
        // Evaluation Type
        'evaluationType': 'Final Assessment',
        'isFinalEvaluation': true,
        
        // Session Summary
        'totalSessionsCompleted': widget.sessionHistory.length,
        'therapyPeriodStart': widget.sessionHistory.isNotEmpty
            ? widget.sessionHistory.last['createdAt']
            : Timestamp.now(),
        'therapyPeriodEnd': Timestamp.now(),
        
        // Overall Assessment
        'overallSummary': _overallSummaryController.text.trim(),
        'therapyGoalsAchieved': _therapyGoalsAchievedController.text.trim(),
        'overallProgressRating': _overallProgressRating,
        'progressDescription': _progressDescriptionController.text.trim(),
        
        // Skills Development
        'fineMotorEvaluation': _fineMotorEvaluation,
        'grossMotorEvaluation': _grossMotorEvaluation,
        'cognitiveEvaluation': _cognitiveEvaluation,
        'sensoryEvaluation': _sensoryEvaluation,
        'socialEmotionalEvaluation': _socialEmotionalEvaluation,
        
        // Recommendations
        'continueTherapyRecommendation': _continueTherapyController.text.trim(),
        'homeExerciseProgram': _homeExercisesController.text.trim(),
        'schoolRecommendations': _schoolRecommendationsController.text.trim(),
        'followUpSchedule': _followUpScheduleController.text.trim(),
        'additionalServicesRecommended': _additionalServicesController.text.trim(),
        'parentGuidelines': _parentGuidelinesController.text.trim(),
        
        // Discharge Planning
        'isDischargeRecommended': _isDischargeRecommended,
        'dischargeReason': _dischargeReasonController.text.trim(),
        'maintenancePlan': _maintenancePlanController.text.trim(),
        
        // Professional Information
        'therapistNotes': _therapistNotesController.text.trim(),
        'therapistName': _therapistName,
        'therapistLicense': _therapistLicense,
        'evaluationDate': Timestamp.now(),
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      };

      // Save to Firestore
      final docRef = await FirebaseFirestore.instance
          .collection('FinalEvaluations')
          .add(evaluationData);

      if (mounted) {
        setState(() {
          _savedEvaluationId = docRef.id;
          _isEvaluationSaved = true;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Final evaluation saved successfully! You can now view or export it.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        
        // Scroll to bottom to show the new buttons
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Scrollable.ensureVisible(
              context,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting evaluation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _viewEvaluation() {
    if (_savedEvaluationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No evaluation found. Please save the evaluation first.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FinalEvaluationViewer(
          evaluationId: _savedEvaluationId!,
        ),
      ),
    );
  }

  Future<void> _exportEvaluationAsPDF() async {
    if (_savedEvaluationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No evaluation found. Please save the evaluation first.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF006A5B)),
        ),
      );

      // Fetch the evaluation data from Firestore
      final doc = await FirebaseFirestore.instance
          .collection('FinalEvaluations')
          .doc(_savedEvaluationId)
          .get();

      if (!doc.exists) {
        if (mounted) Navigator.pop(context); // Close loading dialog
        throw Exception('Evaluation not found');
      }

      final evaluation = doc.data()!;

      // Create PDF document
      final pdf = pw.Document();

      // Add pages to PDF
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => [
            // Header
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'FINAL EVALUATION REPORT',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.teal800,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Divider(thickness: 2, color: PdfColors.teal800),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Client Information
            _buildPdfSection('Client Information', [
              _buildPdfInfoRow('Child Name', evaluation['childName'] ?? 'N/A'),
              _buildPdfInfoRow('Parent Name', evaluation['parentName'] ?? 'N/A'),
              _buildPdfInfoRow('Age', evaluation['age']?.toString() ?? 'N/A'),
              _buildPdfInfoRow('Total Sessions Completed', evaluation['totalSessionsCompleted']?.toString() ?? '0'),
              _buildPdfInfoRow('Evaluation Date', evaluation['evaluationDate'] != null
                  ? DateFormat('MMMM dd, yyyy').format((evaluation['evaluationDate'] as Timestamp).toDate())
                  : 'N/A'),
            ]),
            pw.SizedBox(height: 20),

            // Overall Assessment
            _buildPdfSection('Overall Assessment', [
              _buildPdfTextField('Overall Progress Summary', evaluation['overallSummary'] ?? ''),
              _buildPdfTextField('Therapy Goals Achieved', evaluation['therapyGoalsAchieved'] ?? ''),
              _buildPdfInfoRow('Progress Rating', evaluation['overallProgressRating'] ?? ''),
              _buildPdfTextField('Progress Description', evaluation['progressDescription'] ?? ''),
            ]),
            pw.SizedBox(height: 20),

            // Skills Development
            _buildPdfSection('Skills Development Analysis', [
              _buildPdfSkillSection('Fine Motor Skills', evaluation['fineMotorEvaluation']),
              pw.SizedBox(height: 12),
              _buildPdfSkillSection('Gross Motor Skills', evaluation['grossMotorEvaluation']),
              pw.SizedBox(height: 12),
              _buildPdfSkillSection('Cognitive Skills', evaluation['cognitiveEvaluation']),
              pw.SizedBox(height: 12),
              _buildPdfSkillSection('Sensory Processing', evaluation['sensoryEvaluation']),
              pw.SizedBox(height: 12),
              _buildPdfSkillSection('Social & Emotional Development', evaluation['socialEmotionalEvaluation']),
            ]),
            pw.SizedBox(height: 20),

            // Recommendations
            _buildPdfSection('Recommendations & Future Planning', [
              _buildPdfTextField('Continue Therapy', evaluation['continueTherapyRecommendation'] ?? ''),
              _buildPdfTextField('Home Exercise Program', evaluation['homeExerciseProgram'] ?? ''),
              if (evaluation['schoolRecommendations'] != null && evaluation['schoolRecommendations'].toString().isNotEmpty)
                _buildPdfTextField('School Recommendations', evaluation['schoolRecommendations']),
              _buildPdfTextField('Follow-up Schedule', evaluation['followUpSchedule'] ?? ''),
              if (evaluation['additionalServicesRecommended'] != null && evaluation['additionalServicesRecommended'].toString().isNotEmpty)
                _buildPdfTextField('Additional Services', evaluation['additionalServicesRecommended']),
              _buildPdfTextField('Parent Guidelines', evaluation['parentGuidelines'] ?? ''),
            ]),
            pw.SizedBox(height: 20),

            // Discharge Planning (if applicable)
            if (evaluation['isDischargeRecommended'] == true)
              _buildPdfSection('Discharge Planning', [
                _buildPdfTextField('Discharge Reason', evaluation['dischargeReason'] ?? ''),
                _buildPdfTextField('Maintenance Plan', evaluation['maintenancePlan'] ?? ''),
              ]),
            if (evaluation['isDischargeRecommended'] == true)
              pw.SizedBox(height: 20),

            // Professional Information
            _buildPdfSection('Professional Assessment', [
              _buildPdfTextField('Therapist Notes', evaluation['therapistNotes'] ?? ''),
              _buildPdfInfoRow('Therapist Name', evaluation['therapistName'] ?? ''),
              _buildPdfInfoRow('License Number', evaluation['therapistLicense'] ?? ''),
            ]),

            // Footer
            pw.SizedBox(height: 40),
            pw.Divider(),
            pw.Text(
              'Generated on ${DateFormat('MMMM dd, yyyy - hh:mm a').format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
          ],
        ),
      );

      if (mounted) Navigator.pop(context); // Close loading dialog

      // Show PDF preview and allow user to save/print
      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
        name: 'Final_Evaluation_${evaluation['childName']}_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.pdf',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF generated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Close loading dialog if still open
        if (Navigator.canPop(context)) Navigator.pop(context);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Helper methods for PDF generation
  pw.Widget _buildPdfSection(String title, List<pw.Widget> children) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.teal800,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildPdfInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 150,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfTextField(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value.isNotEmpty ? value : 'Not provided',
            style: const pw.TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfSkillSection(String skillName, dynamic skillData) {
    if (skillData == null) {
      return pw.Text('$skillName: No data available');
    }

    final currentLevel = skillData['currentLevel'] ?? 0;
    final improvementNotes = skillData['improvementNotes'] ?? '';
    final strengths = skillData['strengthsIdentified'] ?? '';
    final areas = skillData['areasForDevelopment'] ?? '';
    final recommended = skillData['recommendedActivities'] ?? '';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          skillName,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13, color: PdfColors.blue800),
        ),
        pw.SizedBox(height: 4),
        _buildPdfInfoRow('Current Level', '$currentLevel/5'),
        if (improvementNotes.isNotEmpty) _buildPdfInfoRow('Improvement Notes', improvementNotes),
        if (strengths.isNotEmpty) _buildPdfInfoRow('Strengths', strengths),
        if (areas.isNotEmpty) _buildPdfInfoRow('Areas for Development', areas),
        if (recommended.isNotEmpty) _buildPdfInfoRow('Recommended Activities', recommended),
      ],
    );
  }

  @override
  void dispose() {
    _overallSummaryController.dispose();
    _therapyGoalsAchievedController.dispose();
    _progressDescriptionController.dispose();
    _continueTherapyController.dispose();
    _homeExercisesController.dispose();
    _schoolRecommendationsController.dispose();
    _followUpScheduleController.dispose();
    _additionalServicesController.dispose();
    _parentGuidelinesController.dispose();
    _dischargeReasonController.dispose();
    _maintenancePlanController.dispose();
    _therapistNotesController.dispose();
    super.dispose();
  }
}
