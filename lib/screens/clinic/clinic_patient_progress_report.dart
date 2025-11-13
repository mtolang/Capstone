import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ClinicPatientProgressReport extends StatefulWidget {
  final String? patientName;
  final Map<String, dynamic> progressData;

  const ClinicPatientProgressReport({
    Key? key,
    required this.patientName,
    required this.progressData,
  }) : super(key: key);

  @override
  State<ClinicPatientProgressReport> createState() =>
      _ClinicPatientProgressReportState();
}

class _ClinicPatientProgressReportState
    extends State<ClinicPatientProgressReport> {
  final _formKey = GlobalKey<FormState>();

  // Form Controllers
  final _childNameController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _carerNameController = TextEditingController();
  final _relationshipController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _primaryConcernsController = TextEditingController();
  final _sensoryNotesController = TextEditingController();
  final _cognitiveNotesController = TextEditingController();
  final _grossMotorNotesController = TextEditingController();
  final _fineMotorNotesController = TextEditingController();

  String _selectedGender = 'Select...';
  final List<String> _genderOptions = ['Select...', 'Male', 'Female', 'Other'];

  // Fine Motor Skills Ratings (1-5)
  Map<String, int> _fineMotorRatings = {
    'pincerGrasp': 0,
    'handEyeCoordination': 0,
    'inHandManipulation': 0,
    'bilateralCoordination': 0,
  };

  // Gross Motor Skills Ratings (1-5)
  Map<String, int> _grossMotorRatings = {
    'balance': 0,
    'runningJumping': 0,
    'throwingCatching': 0,
    'motorPlanning': 0,
  };

  // Sensory Processing Ratings (1-5)
  Map<String, int> _sensoryRatings = {
    'tactileResponse': 0,
    'auditoryFiltering': 0,
    'vestibularSeeking': 0,
    'proprioceptiveAwareness': 0,
  };

  // Cognitive Skills Ratings (1-5)
  Map<String, int> _cognitiveRatings = {
    'problemSolving': 0,
    'attentionSpan': 0,
    'followingDirections': 0,
    'sequencingTasks': 0,
  };

  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  @override
  void dispose() {
    _childNameController.dispose();
    _dateOfBirthController.dispose();
    _carerNameController.dispose();
    _relationshipController.dispose();
    _contactNumberController.dispose();
    _primaryConcernsController.dispose();
    _sensoryNotesController.dispose();
    _cognitiveNotesController.dispose();
    _grossMotorNotesController.dispose();
    _fineMotorNotesController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingData() async {
    try {
      // First, try to load from progressData
      _childNameController.text = widget.progressData['childName'] ??
          widget.progressData['patientName'] ??
          '';
      _carerNameController.text = widget.progressData['parentName'] ?? '';
      _relationshipController.text =
          widget.progressData['relationship'] ?? 'Parent';
      _contactNumberController.text =
          widget.progressData['contactNumber'] ?? '';

      // Handle gender - ensure it's a valid option
      final gender = widget.progressData['gender'];
      if (gender != null && _genderOptions.contains(gender)) {
        _selectedGender = gender;
      } else {
        _selectedGender = 'Select...';
      }

      _primaryConcernsController.text =
          widget.progressData['primaryConcerns'] ?? '';

      // Date of birth
      if (widget.progressData['dateOfBirth'] != null) {
        _dateOfBirthController.text = widget.progressData['dateOfBirth'];
      }

      // If we don't have enough data, fetch from AcceptedBooking
      if (_childNameController.text.isEmpty &&
          widget.progressData['patientId'] != null) {
        await _fetchPatientDataFromBooking();
      }

      setState(() {
        _isLoadingData = false;
      });
    } catch (e) {
      print('Error loading existing data: $e');
      setState(() {
        _isLoadingData = false;
      });
    }
  }

  Future<void> _fetchPatientDataFromBooking() async {
    try {
      final patientId = widget.progressData['patientId']?.toString();
      if (patientId == null) return;

      // Query AcceptedBooking collection for this patient
      final bookingQuery = await FirebaseFirestore.instance
          .collection('AcceptedBooking')
          .where('patientId', isEqualTo: patientId)
          .limit(1)
          .get();

      if (bookingQuery.docs.isNotEmpty) {
        final bookingData = bookingQuery.docs.first.data();

        // Auto-fill from AcceptedBooking
        _childNameController.text = bookingData['childName'] ??
            bookingData['patientName'] ??
            _childNameController.text;
        _carerNameController.text =
            bookingData['parentName'] ?? _carerNameController.text;
        _contactNumberController.text = bookingData['parentContact'] ??
            bookingData['contactNumber'] ??
            _contactNumberController.text;

        // Try to extract date of birth if available
        if (bookingData['dateOfBirth'] != null) {
          _dateOfBirthController.text = bookingData['dateOfBirth'];
        } else if (bookingData['patientInfo']?['dateOfBirth'] != null) {
          _dateOfBirthController.text =
              bookingData['patientInfo']['dateOfBirth'];
        }

        // Gender - validate against available options
        final bookingGender = bookingData['gender'];
        if (bookingGender != null && _genderOptions.contains(bookingGender)) {
          _selectedGender = bookingGender;
        } else if (bookingGender != null) {
          // Try to match case-insensitively
          final matchingOption = _genderOptions.firstWhere(
            (option) =>
                option.toLowerCase() == bookingGender.toString().toLowerCase(),
            orElse: () => 'Select...',
          );
          _selectedGender = matchingOption;
        }
      }
    } catch (e) {
      print('Error fetching patient data from booking: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF006A5B),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: const Text(
          'Occupational Therapy Assessment',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        actions: [
          IconButton(
            onPressed: _saveAssessment,
            icon: const Icon(Icons.save, color: Colors.white),
            tooltip: 'Save Assessment',
          ),
        ],
      ),
      body: _isLoadingData
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF006A5B),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    const Text(
                      'Occupational Therapy Assessment',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Personal Information Section
                    _buildSectionCard(
                      title: 'Personal Information',
                      children: [
                        Row(
                          children: [
                            // Child's Full Name
                            Expanded(
                              child: _buildTextField(
                                label: 'Child\'s Full Name',
                                controller: _childNameController,
                                hintText: 'Alex Johnson',
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Date of Birth
                            Expanded(
                              child: _buildDateField(
                                label: 'Date of Birth',
                                controller: _dateOfBirthController,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            // Gender
                            Expanded(
                              child: _buildDropdownField(
                                label: 'Gender',
                                value: _selectedGender,
                                items: _genderOptions,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedGender = value!;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Carer/Parent's Full Name
                            Expanded(
                              child: _buildTextField(
                                label: 'Carer/Parent\'s Full Name',
                                controller: _carerNameController,
                                hintText: 'Sarah Johnson',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            // Contact Number
                            Expanded(
                              child: _buildTextField(
                                label: 'Contact Number',
                                controller: _contactNumberController,
                                hintText: 'e.g., 555-1234',
                                keyboardType: TextInputType.phone,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Relationship to Child
                            Expanded(
                              child: _buildTextField(
                                label: 'Relationship to Child',
                                controller: _relationshipController,
                                hintText: 'Parent',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Primary Concerns / Reason for Assessment
                        _buildTextAreaField(
                          label: 'Primary Concerns / Reason for Assessment',
                          controller: _primaryConcernsController,
                          hintText:
                              'Describe the main challenges or goals for the child...',
                          maxLines: 4,
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // Fine Motor Skills Section
                    _buildSectionCard(
                      title: 'Fine Motor Skills',
                      children: [
                        _buildRatingRow(
                          'Pincer Grasp',
                          'pincerGrasp',
                          _fineMotorRatings,
                        ),
                        _buildRatingRow(
                          'Hand-eye Coordination',
                          'handEyeCoordination',
                          _fineMotorRatings,
                        ),
                        _buildRatingRow(
                          'In-hand Manipulation',
                          'inHandManipulation',
                          _fineMotorRatings,
                        ),
                        _buildRatingRow(
                          'Bilateral Coordination',
                          'bilateralCoordination',
                          _fineMotorRatings,
                        ),
                        const SizedBox(height: 8),
                        _buildTextAreaField(
                          label: 'Therapist\'s Notes for Fine Motor Skills',
                          controller: _fineMotorNotesController,
                          hintText: 'Enter qualitative observations here...',
                          maxLines: 3,
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // Gross Motor Skills Section
                    _buildSectionCard(
                      title: 'Gross Motor Skills',
                      children: [
                        _buildRatingRow(
                          'Balance',
                          'balance',
                          _grossMotorRatings,
                        ),
                        _buildRatingRow(
                          'Running and Jumping',
                          'runningJumping',
                          _grossMotorRatings,
                        ),
                        _buildRatingRow(
                          'Throwing and Catching',
                          'throwingCatching',
                          _grossMotorRatings,
                        ),
                        _buildRatingRow(
                          'Motor Planning',
                          'motorPlanning',
                          _grossMotorRatings,
                        ),
                        const SizedBox(height: 8),
                        _buildTextAreaField(
                          label: 'Therapist\'s Notes for Gross Motor Skills',
                          controller: _grossMotorNotesController,
                          hintText: 'Enter qualitative observations here...',
                          maxLines: 3,
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // Sensory Processing Section
                    _buildSectionCard(
                      title: 'Sensory Processing',
                      children: [
                        _buildRatingRow(
                          'Tactile Response',
                          'tactileResponse',
                          _sensoryRatings,
                        ),
                        _buildRatingRow(
                          'Auditory Filtering',
                          'auditoryFiltering',
                          _sensoryRatings,
                        ),
                        _buildRatingRow(
                          'Vestibular Seeking/Avoiding',
                          'vestibularSeeking',
                          _sensoryRatings,
                        ),
                        _buildRatingRow(
                          'Proprioceptive Awareness',
                          'proprioceptiveAwareness',
                          _sensoryRatings,
                        ),
                        const SizedBox(height: 8),
                        _buildTextAreaField(
                          label: 'Therapist\'s Notes for Sensory Processing',
                          controller: _sensoryNotesController,
                          hintText: 'Enter qualitative observations here...',
                          maxLines: 3,
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // Cognitive Skills Section
                    _buildSectionCard(
                      title: 'Cognitive Skills',
                      children: [
                        _buildRatingRow(
                          'Problem Solving',
                          'problemSolving',
                          _cognitiveRatings,
                        ),
                        _buildRatingRow(
                          'Attention Span',
                          'attentionSpan',
                          _cognitiveRatings,
                        ),
                        _buildRatingRow(
                          'Following Directions',
                          'followingDirections',
                          _cognitiveRatings,
                        ),
                        _buildRatingRow(
                          'Sequencing Tasks',
                          'sequencingTasks',
                          _cognitiveRatings,
                        ),
                        const SizedBox(height: 8),
                        _buildTextAreaField(
                          label: 'Therapist\'s Notes for Cognitive Skills',
                          controller: _cognitiveNotesController,
                          hintText: 'Enter qualitative observations here...',
                          maxLines: 3,
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // Save Button
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _saveAssessment,
                        icon: const Icon(Icons.save),
                        label: const Text(
                          'Save Assessment',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF006A5B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 48,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
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
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2563EB),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hintText,
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
            color: Color(0xFF374151),
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontFamily: 'Poppins',
            ),
            filled: true,
            fillColor: Colors.grey[50],
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
              borderSide: const BorderSide(color: Color(0xFF006A5B), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          style: const TextStyle(
            fontSize: 14,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: true,
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
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
            if (date != null) {
              controller.text = '${date.month}/${date.day}/${date.year}';
            }
          },
          decoration: InputDecoration(
            hintText: '10/15/2018',
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontFamily: 'Poppins',
            ),
            suffixIcon: const Icon(Icons.calendar_today, size: 20),
            filled: true,
            fillColor: Colors.grey[50],
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
              borderSide: const BorderSide(color: Color(0xFF006A5B), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          style: const TextStyle(
            fontSize: 14,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(
                item,
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'Poppins',
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[50],
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
              borderSide: const BorderSide(color: Color(0xFF006A5B), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          style: const TextStyle(
            fontSize: 14,
            fontFamily: 'Poppins',
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildTextAreaField({
    required String label,
    required TextEditingController controller,
    String? hintText,
    int maxLines = 3,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontFamily: 'Poppins',
            ),
            filled: true,
            fillColor: Colors.grey[50],
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
              borderSide: const BorderSide(color: Color(0xFF006A5B), width: 2),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          style: const TextStyle(
            fontSize: 14,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  Widget _buildRatingRow(
    String label,
    String key,
    Map<String, int> ratingsMap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: List.generate(5, (index) {
              final rating = index + 1;
              final isSelected = ratingsMap[key] == rating;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      ratingsMap[key] = rating;
                    });
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF006A5B)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF006A5B)
                            : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$rating',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.grey[700],
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAssessment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      // Check if this is the first assessment for this patient
      final existingAssessments = await FirebaseFirestore.instance
          .collection('OTAssessments')
          .where('patientId', isEqualTo: widget.progressData['patientId'])
          .where('clinicId', isEqualTo: widget.progressData['clinicId'])
          .get();

      final isInitialAssessment = existingAssessments.docs.isEmpty;

      final assessmentData = {
        'childName': _childNameController.text,
        'dateOfBirth': _dateOfBirthController.text,
        'gender': _selectedGender,
        'parentName': _carerNameController.text,
        'relationship': _relationshipController.text,
        'contactNumber': _contactNumberController.text,
        'primaryConcerns': _primaryConcernsController.text,
        'fineMotorSkills': {
          'pincerGrasp': _fineMotorRatings['pincerGrasp'],
          'handEyeCoordination': _fineMotorRatings['handEyeCoordination'],
          'inHandManipulation': _fineMotorRatings['inHandManipulation'],
          'bilateralCoordination': _fineMotorRatings['bilateralCoordination'],
          'notes': _fineMotorNotesController.text,
        },
        'grossMotorSkills': {
          'balance': _grossMotorRatings['balance'],
          'runningJumping': _grossMotorRatings['runningJumping'],
          'throwingCatching': _grossMotorRatings['throwingCatching'],
          'motorPlanning': _grossMotorRatings['motorPlanning'],
          'notes': _grossMotorNotesController.text,
        },
        'sensoryProcessing': {
          'tactileResponse': _sensoryRatings['tactileResponse'],
          'auditoryFiltering': _sensoryRatings['auditoryFiltering'],
          'vestibularSeeking': _sensoryRatings['vestibularSeeking'],
          'proprioceptiveAwareness': _sensoryRatings['proprioceptiveAwareness'],
          'notes': _sensoryNotesController.text,
        },
        'cognitiveSkills': {
          'problemSolving': _cognitiveRatings['problemSolving'],
          'attentionSpan': _cognitiveRatings['attentionSpan'],
          'followingDirections': _cognitiveRatings['followingDirections'],
          'sequencingTasks': _cognitiveRatings['sequencingTasks'],
          'notes': _cognitiveNotesController.text,
        },
        'assessmentType': 'Occupational Therapy',
        'isInitialAssessment': isInitialAssessment,
        'isFinalEvaluation': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'patientId': widget.progressData['patientId'],
        'clinicId': widget.progressData['clinicId'],
      };

      // Save to Firebase
      await FirebaseFirestore.instance
          .collection('OTAssessments')
          .add(assessmentData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Assessment saved successfully!',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
            backgroundColor: Color(0xFF006A5B),
            duration: Duration(seconds: 2),
          ),
        );

        // Navigate back after successful save
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error saving assessment: $e',
              style: const TextStyle(fontFamily: 'Poppins'),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
