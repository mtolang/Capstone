import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kindora/services/booking_request_service.dart';

class ParentBookingProcessPage extends StatefulWidget {
  final String? clinicId;
  final String? therapistId;
  final DateTime selectedDate;
  final String selectedTimeSlot;
  final String selectedTime;
  final String bookingProcessType; // Add booking process type

  const ParentBookingProcessPage({
    Key? key,
    required this.selectedDate,
    required this.selectedTimeSlot,
    required this.selectedTime,
    this.clinicId,
    this.therapistId,
    this.bookingProcessType = 'single', // Default to single session
  }) : super(key: key);

  @override
  State<ParentBookingProcessPage> createState() =>
      _ParentBookingProcessPageState();
}

class _ParentBookingProcessPageState extends State<ParentBookingProcessPage> {
  final _formKey = GlobalKey<FormState>();
  final _parentNameController = TextEditingController();
  final _parentPhoneController = TextEditingController();
  final _parentEmailController = TextEditingController();
  final _childNameController = TextEditingController();
  final _childAgeController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedAppointmentType = 'Speech Therapy';
  String _selectedGender = 'Male';
  bool _isLoading = false;
  String? _parentId;

  final List<String> _appointmentTypes = [
    'Speech Therapy',
    'Occupational Therapy',
    'Physical Therapy',
    'Behavioral Therapy',
    'Consultation',
    'Follow-up Session',
  ];

  final List<String> _genderOptions = ['Male', 'Female'];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _parentId = prefs.getString('user_id') ?? prefs.getString('parent_id');
      _parentNameController.text = prefs.getString('user_name') ?? '';
      _parentPhoneController.text = prefs.getString('user_phone') ?? '';
      _parentEmailController.text = prefs.getString('user_email') ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Top wave background
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 120,
              decoration: const BoxDecoration(
                color: Color(0xFF006A5B),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
            ),
          ),

          // Main content
          Column(
            children: [
              // Custom AppBar
              Container(
                padding: const EdgeInsets.only(
                    top: 40, left: 16, right: 16, bottom: 20),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Booking Process',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Poppins',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 40), // For balance
                  ],
                ),
              ),

              // Form content - now includes all summary info
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),

                        // Booking summary card - now inside scrollable form
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Appointment Summary',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF006A5B),
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today,
                                      color: Color(0xFF67AFA5), size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    DateFormat('EEEE, MMMM dd, yyyy')
                                        .format(widget.selectedDate),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.access_time,
                                      color: Color(0xFF67AFA5), size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    widget.selectedTime,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Booking Type Information - now inside scrollable form
                        Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: widget.bookingProcessType == 'contract'
                                ? const Color(0xFF006A5B).withOpacity(0.1)
                                : Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: widget.bookingProcessType == 'contract'
                                  ? const Color(0xFF006A5B)
                                  : Colors.blue,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    widget.bookingProcessType == 'contract'
                                        ? Icons.repeat
                                        : Icons.event_note,
                                    color: widget.bookingProcessType == 'contract'
                                        ? const Color(0xFF006A5B)
                                        : Colors.blue,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    widget.bookingProcessType == 'contract'
                                        ? 'Contract Booking'
                                        : 'Single Session Booking',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: widget.bookingProcessType == 'contract'
                                          ? const Color(0xFF006A5B)
                                          : Colors.blue,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.bookingProcessType == 'contract'
                                    ? 'This appointment will be reserved for you every ${DateFormat('EEEE').format(widget.selectedDate)} at ${widget.selectedTime} until you choose to end it.'
                                    : 'This is a one-time appointment booking.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: widget.bookingProcessType == 'contract'
                                      ? const Color(0xFF006A5B).withOpacity(0.8)
                                      : Colors.blue.withOpacity(0.8),
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Parent Information Section
                        _buildSectionHeader('Parent Information'),
                        const SizedBox(height: 16),

                        _buildTextFormField(
                          controller: _parentNameController,
                          label: 'Full Name',
                          icon: Icons.person,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your full name';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        _buildTextFormField(
                          controller: _parentPhoneController,
                          label: 'Contact Number',
                          icon: Icons.phone,
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your contact number';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        _buildTextFormField(
                          controller: _parentEmailController,
                          label: 'Email Address',
                          icon: Icons.email,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email address';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                .hasMatch(value)) {
                              return 'Please enter a valid email address';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 30),

                        // Child Information Section
                        _buildSectionHeader('Child Information'),
                        const SizedBox(height: 16),

                        _buildTextFormField(
                          controller: _childNameController,
                          label: 'Child\'s Full Name',
                          icon: Icons.child_care,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your child\'s name';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: _buildTextFormField(
                                controller: _childAgeController,
                                label: 'Age',
                                icon: Icons.cake,
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter age';
                                  }
                                  final age = int.tryParse(value);
                                  if (age == null || age < 1 || age > 18) {
                                    return 'Please enter a valid age (1-18)';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
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
                                icon: Icons.person_outline,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 30),

                        // Appointment Details Section
                        _buildSectionHeader('Appointment Details'),
                        const SizedBox(height: 16),

                        _buildDropdownField(
                          label: 'Appointment Type',
                          value: _selectedAppointmentType,
                          items: _appointmentTypes,
                          onChanged: (value) {
                            setState(() {
                              _selectedAppointmentType = value!;
                            });
                          },
                          icon: Icons.medical_services,
                        ),

                        const SizedBox(height: 16),

                        _buildTextFormField(
                          controller: _notesController,
                          label: 'Additional Notes (Optional)',
                          icon: Icons.note,
                          maxLines: 4,
                          hint:
                              'Please describe any specific concerns, symptoms, or information about your child that would be helpful for the therapist...',
                        ),

                        const SizedBox(height: 30),

                        // Confirmation message
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF67AFA5).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF67AFA5).withOpacity(0.3),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Color(0xFF006A5B),
                                size: 20,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Once your booking request is accepted by the Therapy Clinic, you will get a confirmation.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF006A5B),
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Confirm button - now inside scroll view
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _confirmSchedule,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF006A5B),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              elevation: 5,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Confirm Schedule',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 30), // Bottom padding for keyboard
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF006A5B),
        fontFamily: 'Poppins',
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? hint,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(fontFamily: 'Poppins'),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF67AFA5)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF67AFA5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF006A5B), width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF67AFA5)),
        ),
        labelStyle: const TextStyle(
          color: Color(0xFF67AFA5),
          fontFamily: 'Poppins',
        ),
        hintStyle: const TextStyle(
          color: Colors.grey,
          fontSize: 14,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
    required IconData icon,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      style: const TextStyle(
        color: Colors.black87,
        fontFamily: 'Poppins',
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF67AFA5)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF67AFA5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF006A5B), width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF67AFA5)),
        ),
        labelStyle: const TextStyle(
          color: Color(0xFF67AFA5),
          fontFamily: 'Poppins',
        ),
      ),
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
    );
  }

  String _getDayName(DateTime date) {
    final days = [
      'sunday',
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday'
    ];
    return days[date.weekday % 7];
  }

  String _buildBookingNotes() {
    final buffer = StringBuffer();

    // Add parent information
    buffer.writeln('=== PARENT INFORMATION ===');
    buffer.writeln('Parent Name: ${_parentNameController.text.trim()}');
    buffer.writeln('Contact Number: ${_parentPhoneController.text.trim()}');
    buffer.writeln('Email: ${_parentEmailController.text.trim()}');

    // Add child information
    buffer.writeln('\n=== CHILD INFORMATION ===');
    buffer.writeln('Child Name: ${_childNameController.text.trim()}');
    buffer.writeln('Age: ${_childAgeController.text.trim()} years old');
    buffer.writeln('Gender: $_selectedGender');

    // Add appointment details
    buffer.writeln('\n=== APPOINTMENT DETAILS ===');
    buffer.writeln('Type: $_selectedAppointmentType');
    buffer.writeln(
        'Date: ${DateFormat('EEEE, MMMM dd, yyyy').format(widget.selectedDate)}');
    buffer.writeln('Time: ${widget.selectedTime}');

    // Add additional notes if provided
    if (_notesController.text.trim().isNotEmpty) {
      buffer.writeln('\n=== ADDITIONAL NOTES ===');
      buffer.writeln(_notesController.text.trim());
    }

    return buffer.toString();
  }

  Future<void> _confirmSchedule() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_parentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to identify parent user. Please login again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String requestId;

      if (widget.bookingProcessType == 'contract') {
        // Use contract booking service for recurring appointments
        final dayOfWeek = DateFormat('EEEE').format(widget.selectedDate);

        requestId = await BookingRequestService.saveContractBookingRequest(
          // Parent Information
          parentName: _parentNameController.text.trim(),
          parentPhone: _parentPhoneController.text.trim(),
          parentEmail: _parentEmailController.text.trim(),
          parentId: _parentId!,

          // Child Information
          childName: _childNameController.text.trim(),
          childAge: int.tryParse(_childAgeController.text) ?? 0,
          childGender: _selectedGender,

          // Contract Appointment Information
          startDate: widget.selectedDate,
          appointmentTime: widget.selectedTime,
          timeSlotId: widget.selectedTimeSlot,
          appointmentType: _selectedAppointmentType,
          dayOfWeek: dayOfWeek,

          // Contract settings
          contractDurationWeeks: 52, // Default to 1 year
          contractType: 'weekly_recurring',

          // Additional Information
          additionalNotes: _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,

          // Clinic/Therapist Information
          clinicId: widget.clinicId,
          therapistId: widget.therapistId,
        );
      } else {
        // Use regular booking service for single sessions
        requestId = await BookingRequestService.saveBookingRequest(
          // Parent Information
          parentName: _parentNameController.text.trim(),
          parentPhone: _parentPhoneController.text.trim(),
          parentEmail: _parentEmailController.text.trim(),
          parentId: _parentId!,

          // Child Information
          childName: _childNameController.text.trim(),
          childAge: int.tryParse(_childAgeController.text) ?? 0,
          childGender: _selectedGender,

          // Appointment Information
          appointmentDate: widget.selectedDate,
          appointmentTime: widget.selectedTime,
          timeSlotId: widget.selectedTimeSlot,
          appointmentType: _selectedAppointmentType,

          // Additional Information
          additionalNotes: _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,

          // Clinic/Therapist Information
          clinicId: widget.clinicId,
          therapistId: widget.therapistId,
        );
      }

      if (mounted) {
        // Show success dialog
        _showSuccessDialog(requestId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessDialog(String requestId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 60,
              ),
              const SizedBox(height: 16),
              Text(
                widget.bookingProcessType == 'contract'
                    ? 'Contract Booking Request Sent!'
                    : 'Booking Request Sent!',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF006A5B),
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.bookingProcessType == 'contract'
                    ? 'Your contract appointment request has been sent to the therapy clinic. Once approved, this time slot will be reserved for you every ${DateFormat('EEEE').format(widget.selectedDate)} at ${widget.selectedTime}.'
                    : 'Your appointment request has been sent to the therapy clinic. You will receive a confirmation once it\'s approved.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF67AFA5).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF67AFA5).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Request ID:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF006A5B),
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      requestId,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF006A5B),
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.of(context).pop(); // Go back to booking page
                    Navigator.of(context).pop(); // Go back to main page
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006A5B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _parentNameController.dispose();
    _parentPhoneController.dispose();
    _parentEmailController.dispose();
    _childNameController.dispose();
    _childAgeController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
