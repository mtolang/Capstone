import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AddSessionForm extends StatefulWidget {
  final Map<String, dynamic> clientData;
  final String clinicId;

  const AddSessionForm({
    Key? key,
    required this.clientData,
    required this.clinicId,
  }) : super(key: key);

  @override
  State<AddSessionForm> createState() => _AddSessionFormState();
}

class _AddSessionFormState extends State<AddSessionForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  // Session Information
  DateTime _sessionDate = DateTime.now();
  TimeOfDay _sessionTime = TimeOfDay.now();
  final TextEditingController _sessionNotesController = TextEditingController();
  String _assessmentType = 'Occupational Therapy';
  int _sessionDuration = 60; // minutes

  // Fine Motor Skills (0-5 scale)
  double _handwriting = 3.0;
  double _grip = 3.0;
  double _dexterity = 3.0;
  double _coordination = 3.0;
  double _bilateralCoordination = 3.0;

  // Gross Motor Skills (0-5 scale)
  double _balance = 3.0;
  double _strength = 3.0;
  double _endurance = 3.0;
  double _motorPlanning = 3.0;
  double _bodyAwareness = 3.0;

  // Sensory Processing (0-5 scale)
  double _tactile = 3.0;
  double _vestibular = 3.0;
  double _proprioceptive = 3.0;
  double _auditory = 3.0;
  double _visual = 3.0;

  // Cognitive Skills (0-5 scale)
  double _attention = 3.0;
  double _memory = 3.0;
  double _problemSolving = 3.0;
  double _executiveFunction = 3.0;
  double _sequencing = 3.0;

  // Activities & Progress
  final TextEditingController _activitiesCompletedController = TextEditingController();
  final TextEditingController _progressNotesController = TextEditingController();
  final TextEditingController _challengesController = TextEditingController();
  final TextEditingController _homeExercisesController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Add New Session',
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
            // Client Info Card
            _buildClientInfoCard(),
            const SizedBox(height: 20),

            // Session Details
            _buildSectionCard(
              'Session Details',
              Icons.event_note,
              [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Session Date',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: _selectDate,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 20, color: Color(0xFF006A5B)),
                                  const SizedBox(width: 12),
                                  Text(
                                    DateFormat('MMMM dd, yyyy').format(_sessionDate),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Session Time',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: _selectTime,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time, size: 20, color: Color(0xFF006A5B)),
                                  const SizedBox(width: 12),
                                  Text(
                                    _sessionTime.format(context),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDropdown(
                  'Assessment Type',
                  _assessmentType,
                  [
                    'Occupational Therapy',
                    'Physical Therapy',
                    'Speech Therapy',
                    'Behavioral Therapy',
                    'Cognitive Therapy',
                  ],
                  (value) => setState(() => _assessmentType = value!),
                ),
                const SizedBox(height: 16),
                _buildDropdown(
                  'Session Duration (minutes)',
                  _sessionDuration.toString(),
                  ['30', '45', '60', '90', '120'],
                  (value) => setState(() => _sessionDuration = int.parse(value!)),
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _sessionNotesController,
                  label: 'Session Overview/Notes',
                  hint: 'Brief description of today\'s session focus and activities...',
                  maxLines: 3,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Fine Motor Skills
            _buildSkillSection(
              'Fine Motor Skills',
              Icons.touch_app,
              Colors.blue,
              [
                _buildSkillSlider('Handwriting', _handwriting, (val) => setState(() => _handwriting = val)),
                _buildSkillSlider('Grip Strength', _grip, (val) => setState(() => _grip = val)),
                _buildSkillSlider('Hand Dexterity', _dexterity, (val) => setState(() => _dexterity = val)),
                _buildSkillSlider('Hand-Eye Coordination', _coordination, (val) => setState(() => _coordination = val)),
                _buildSkillSlider('Bilateral Coordination', _bilateralCoordination, (val) => setState(() => _bilateralCoordination = val)),
              ],
            ),
            const SizedBox(height: 20),

            // Gross Motor Skills
            _buildSkillSection(
              'Gross Motor Skills',
              Icons.directions_run,
              Colors.green,
              [
                _buildSkillSlider('Balance', _balance, (val) => setState(() => _balance = val)),
                _buildSkillSlider('Strength', _strength, (val) => setState(() => _strength = val)),
                _buildSkillSlider('Endurance', _endurance, (val) => setState(() => _endurance = val)),
                _buildSkillSlider('Motor Planning', _motorPlanning, (val) => setState(() => _motorPlanning = val)),
                _buildSkillSlider('Body Awareness', _bodyAwareness, (val) => setState(() => _bodyAwareness = val)),
              ],
            ),
            const SizedBox(height: 20),

            // Sensory Processing
            _buildSkillSection(
              'Sensory Processing',
              Icons.sensors,
              Colors.orange,
              [
                _buildSkillSlider('Tactile Response', _tactile, (val) => setState(() => _tactile = val)),
                _buildSkillSlider('Vestibular Processing', _vestibular, (val) => setState(() => _vestibular = val)),
                _buildSkillSlider('Proprioceptive Awareness', _proprioceptive, (val) => setState(() => _proprioceptive = val)),
                _buildSkillSlider('Auditory Processing', _auditory, (val) => setState(() => _auditory = val)),
                _buildSkillSlider('Visual Processing', _visual, (val) => setState(() => _visual = val)),
              ],
            ),
            const SizedBox(height: 20),

            // Cognitive Skills
            _buildSkillSection(
              'Cognitive Skills',
              Icons.psychology,
              Colors.purple,
              [
                _buildSkillSlider('Attention & Focus', _attention, (val) => setState(() => _attention = val)),
                _buildSkillSlider('Memory', _memory, (val) => setState(() => _memory = val)),
                _buildSkillSlider('Problem Solving', _problemSolving, (val) => setState(() => _problemSolving = val)),
                _buildSkillSlider('Executive Function', _executiveFunction, (val) => setState(() => _executiveFunction = val)),
                _buildSkillSlider('Sequencing', _sequencing, (val) => setState(() => _sequencing = val)),
              ],
            ),
            const SizedBox(height: 20),

            // Progress & Notes
            _buildSectionCard(
              'Session Progress & Notes',
              Icons.note,
              [
                _buildTextField(
                  controller: _activitiesCompletedController,
                  label: 'Activities Completed',
                  hint: 'List the specific activities performed during this session...',
                  maxLines: 3,
                  required: true,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _progressNotesController,
                  label: 'Progress Observations',
                  hint: 'Note any improvements, achievements, or significant observations...',
                  maxLines: 4,
                  required: true,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _challengesController,
                  label: 'Challenges Encountered',
                  hint: 'Describe any difficulties or areas that need more work...',
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _homeExercisesController,
                  label: 'Home Exercises Assigned',
                  hint: 'List exercises or activities for the family to practice at home...',
                  maxLines: 3,
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Submit Button
            SizedBox(
              height: 55,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _submitSession,
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
                        'Save Session',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Poppins',
                        ),
                      ),
              ),
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
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              const Color(0xFF006A5B),
              const Color(0xFF006A5B).withOpacity(0.8),
            ],
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Client',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  Text(
                    childName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Parent: $parentName • Age: $age',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
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

  Widget _buildSkillSection(String title, IconData icon, Color color, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
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
              const SizedBox(height: 8),
              Text(
                'Rate each skill (0 = Unable, 5 = Excellent)',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontFamily: 'Poppins',
                ),
              ),
              const Divider(height: 24),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkillSlider(String label, double value, Function(double) onChanged) {
    String getLevelText(double val) {
      if (val == 0) return 'Unable';
      if (val == 1) return 'Poor';
      if (val == 2) return 'Below Average';
      if (val == 3) return 'Average';
      if (val == 4) return 'Good';
      return 'Excellent';
    }

    Color getSliderColor(double val) {
      if (val <= 1) return Colors.red;
      if (val <= 2) return Colors.orange;
      if (val <= 3) return Colors.amber;
      if (val <= 4) return Colors.lightGreen;
      return Colors.green;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
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
                  fontFamily: 'Poppins',
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: getSliderColor(value).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${value.toInt()} - ${getLevelText(value)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: getSliderColor(value),
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: getSliderColor(value),
              inactiveTrackColor: Colors.grey[300],
              thumbColor: getSliderColor(value),
              overlayColor: getSliderColor(value).withOpacity(0.2),
            ),
            child: Slider(
              value: value,
              min: 0,
              max: 5,
              divisions: 5,
              onChanged: onChanged,
            ),
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
        ),
      ],
    );
  }

  Widget _buildDropdown(
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

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _sessionDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF006A5B),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _sessionDate) {
      setState(() {
        _sessionDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _sessionTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF006A5B),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _sessionTime) {
      setState(() {
        _sessionTime = picked;
      });
    }
  }

  Future<void> _submitSession() async {
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
      // Combine date and time
      final sessionDateTime = DateTime(
        _sessionDate.year,
        _sessionDate.month,
        _sessionDate.day,
        _sessionTime.hour,
        _sessionTime.minute,
      );

      // Prepare session data
      final sessionData = {
        // Client Information
        'patientId': widget.clientData['clientId'],
        'childName': widget.clientData['childName'],
        'parentName': widget.clientData['parentName'],
        'age': widget.clientData['age'],
        'clinicId': widget.clinicId,

        // Session Information
        'createdAt': Timestamp.fromDate(sessionDateTime),
        'sessionDate': Timestamp.fromDate(sessionDateTime),
        'assessmentType': _assessmentType,
        'sessionDuration': _sessionDuration,
        'sessionNotes': _sessionNotesController.text.trim(),

        // Fine Motor Skills
        'fineMotorSkills': {
          'handwriting': _handwriting.toInt(),
          'grip': _grip.toInt(),
          'dexterity': _dexterity.toInt(),
          'coordination': _coordination.toInt(),
          'bilateralCoordination': _bilateralCoordination.toInt(),
        },

        // Gross Motor Skills
        'grossMotorSkills': {
          'balance': _balance.toInt(),
          'strength': _strength.toInt(),
          'endurance': _endurance.toInt(),
          'motorPlanning': _motorPlanning.toInt(),
          'bodyAwareness': _bodyAwareness.toInt(),
        },

        // Sensory Processing
        'sensoryProcessing': {
          'tactile': _tactile.toInt(),
          'vestibular': _vestibular.toInt(),
          'proprioceptive': _proprioceptive.toInt(),
          'auditory': _auditory.toInt(),
          'visual': _visual.toInt(),
        },

        // Cognitive Skills
        'cognitiveSkills': {
          'attention': _attention.toInt(),
          'memory': _memory.toInt(),
          'problemSolving': _problemSolving.toInt(),
          'executiveFunction': _executiveFunction.toInt(),
          'sequencing': _sequencing.toInt(),
        },

        // Progress Notes
        'activitiesCompleted': _activitiesCompletedController.text.trim(),
        'progressNotes': _progressNotesController.text.trim(),
        'challenges': _challengesController.text.trim(),
        'homeExercises': _homeExercisesController.text.trim(),

        // Metadata
        'recordedAt': Timestamp.now(),
        'recordedBy': 'therapist', // TODO: Get from auth
      };

      // Save to Firebase
      await FirebaseFirestore.instance
          .collection('OTAssessments')
          .add(sessionData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving session: $e'),
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

  @override
  void dispose() {
    _sessionNotesController.dispose();
    _activitiesCompletedController.dispose();
    _progressNotesController.dispose();
    _challengesController.dispose();
    _homeExercisesController.dispose();
    super.dispose();
  }
}
