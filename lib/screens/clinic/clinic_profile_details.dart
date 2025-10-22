import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ClinicProfileDetailsPage extends StatefulWidget {
  const ClinicProfileDetailsPage({Key? key}) : super(key: key);

  @override
  State<ClinicProfileDetailsPage> createState() => _ClinicProfileDetailsPageState();
}

class _ClinicProfileDetailsPageState extends State<ClinicProfileDetailsPage> {
  // Controllers for text fields
  final TextEditingController _clinicNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  bool isLoading = true;
  bool isEditing = false;
  bool _obscurePassword = true;
  String? currentClinicId;
  Map<String, dynamic>? clinicData;

  @override
  void initState() {
    super.initState();
    _loadClinicData();
  }

  @override
  void dispose() {
    _clinicNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _contactController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // Load clinic data from SharedPreferences and Firebase
  Future<void> _loadClinicData() async {
    try {
      setState(() {
        isLoading = true;
      });

      final prefs = await SharedPreferences.getInstance();
      // Try clinic_id first (clinic auth key), then fallback to user_id
      currentClinicId = prefs.getString('clinic_id') ?? prefs.getString('user_id');

      if (currentClinicId == null) {
        setState(() {
          isLoading = false;
        });
        _showErrorDialog('Clinic not found. Please login again.');
        return;
      }

      // Load clinic data from Firebase
      final doc = await FirebaseFirestore.instance
          .collection('ClinicAcc')
          .doc(currentClinicId)
          .get();

      if (doc.exists) {
        clinicData = doc.data();
        
        // Populate controllers with clinic data
        _clinicNameController.text = clinicData?['Clinic_Name'] ?? '';
        _usernameController.text = clinicData?['User_Name'] ?? '';
        _emailController.text = clinicData?['Email'] ?? '';
        _passwordController.text = clinicData?['Password'] ?? '';
        _contactController.text = clinicData?['Contact_Number'] ?? '';
        _addressController.text = clinicData?['Address'] ?? '';

        setState(() {
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        _showErrorDialog('Clinic profile not found.');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error loading clinic data: $e');
      _showErrorDialog('Error loading profile: $e');
    }
  }

  // Update clinic data in Firebase
  Future<void> _updateClinicData() async {
    try {
      if (currentClinicId == null) {
        _showErrorDialog('Clinic not found. Please login again.');
        return;
      }

      setState(() {
        isLoading = true;
      });

      // Prepare updated data
      final updatedData = {
        'Clinic_Name': _clinicNameController.text.trim(),
        'User_Name': _usernameController.text.trim(),
        'Email': _emailController.text.trim(),
        'Password': _passwordController.text.trim(),
        'Contact_Number': _contactController.text.trim(),
        'Address': _addressController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Update in Firebase
      await FirebaseFirestore.instance
          .collection('ClinicAcc')
          .doc(currentClinicId)
          .update(updatedData);

      // Update local clinicData
      clinicData = {...clinicData!, ...updatedData};

      setState(() {
        isLoading = false;
        isEditing = false;
      });

      _showSuccessDialog('Profile updated successfully!');
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error updating clinic data: $e');
      _showErrorDialog('Error updating profile: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Error',
            style: TextStyle(
              color: Colors.red,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(
              fontFamily: 'Poppins',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'OK',
                style: TextStyle(
                  color: Color(0xFF006A5B),
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Success',
            style: TextStyle(
              color: Color(0xFF006A5B),
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(
              fontFamily: 'Poppins',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'OK',
                style: TextStyle(
                  color: Color(0xFF006A5B),
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _toggleEditMode() {
    setState(() {
      if (isEditing) {
        // Cancel editing - restore original values
        _clinicNameController.text = clinicData?['Clinic_Name'] ?? '';
        _usernameController.text = clinicData?['User_Name'] ?? '';
        _emailController.text = clinicData?['Email'] ?? '';
        _passwordController.text = clinicData?['Password'] ?? '';
        _contactController.text = clinicData?['Contact_Number'] ?? '';
        _addressController.text = clinicData?['Address'] ?? '';
        isEditing = false;
      } else {
        isEditing = true;
      }
    });
  }

  void _saveChanges() {
    // Validate fields
    if (_clinicNameController.text.trim().isEmpty ||
        _usernameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty ||
        _contactController.text.trim().isEmpty ||
        _addressController.text.trim().isEmpty) {
      _showErrorDialog('Please fill in all fields.');
      return;
    }

    // Validate email format
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailController.text.trim())) {
      _showErrorDialog('Please enter a valid email address.');
      return;
    }

    // Validate contact number (basic validation)
    if (!RegExp(r'^[0-9+\-\s\(\)]+$').hasMatch(_contactController.text.trim())) {
      _showErrorDialog('Please enter a valid contact number.');
      return;
    }

    _updateClinicData();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xFF006A5B),
          title: const Text(
            'Clinic Profile',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF006A5B),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background gradients
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: size.height * 0.35,
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
            ),
          ),

          // Main content
          Column(
            children: [
              // Custom AppBar
              Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 10,
                  left: 16,
                  right: 16,
                  bottom: 10,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Clinic Profile',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48), // Space to balance the back button
                  ],
                ),
              ),

              // Profile Avatar Section
              Container(
                margin: const EdgeInsets.symmetric(vertical: 20),
                child: Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        backgroundColor: const Color(0xFF006A5B),
                        child: Text(
                          _getInitials(_clinicNameController.text),
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),
                    if (isEditing)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFF006A5B),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Profile Form
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildProfileField(
                          'Clinic Name',
                          _clinicNameController,
                          Icons.business,
                        ),
                        const SizedBox(height: 20),
                        _buildProfileField(
                          'Username',
                          _usernameController,
                          Icons.account_circle,
                        ),
                        const SizedBox(height: 20),
                        _buildProfileField(
                          'Email',
                          _emailController,
                          Icons.email,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 20),
                        _buildPasswordField(),
                        const SizedBox(height: 20),
                        _buildProfileField(
                          'Contact Number',
                          _contactController,
                          Icons.phone,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 20),
                        _buildProfileField(
                          'Address',
                          _addressController,
                          Icons.location_on,
                          maxLines: 3,
                        ),
                        
                        if (isEditing) ...[
                          const SizedBox(height: 40),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _toggleEditMode,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey[300],
                                    foregroundColor: Colors.black87,
                                    padding: const EdgeInsets.symmetric(vertical: 15),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _saveChanges,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF006A5B),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 15),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Save Changes',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 100), // Space for floating button
            ],
          ),

          // Floating Action Buttons
          if (isEditing) ...[
            // Cancel Button (bottom left)
            Positioned(
              bottom: 30,
              left: 20,
              child: FloatingActionButton(
                heroTag: "clinic_cancel_fab",
                onPressed: _toggleEditMode,
                backgroundColor: Colors.grey[600],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
            // Save Button (bottom right)
            Positioned(
              bottom: 30,
              right: 20,
              child: FloatingActionButton(
                heroTag: "clinic_save_fab",
                onPressed: _saveChanges,
                backgroundColor: const Color(0xFF006A5B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.save,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ] else ...[
            // Edit Button (when not editing)
            Positioned(
              bottom: 30,
              right: 20,
              child: FloatingActionButton(
                heroTag: "clinic_edit_fab",
                onPressed: _toggleEditMode,
                backgroundColor: const Color(0xFF006A5B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.edit,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileField(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF006A5B),
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: isEditing,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(
              icon,
              color: isEditing ? const Color(0xFF006A5B) : Colors.grey,
            ),
            filled: true,
            fillColor: isEditing ? Colors.white : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isEditing ? const Color(0xFF006A5B) : Colors.grey[300]!,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isEditing ? const Color(0xFF006A5B) : Colors.grey[300]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF006A5B),
                width: 2,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey[300]!,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Password',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF006A5B),
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          enabled: isEditing,
          obscureText: _obscurePassword,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(
              Icons.lock,
              color: isEditing ? const Color(0xFF006A5B) : Colors.grey,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                color: isEditing ? const Color(0xFF006A5B) : Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            filled: true,
            fillColor: isEditing ? Colors.white : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isEditing ? const Color(0xFF006A5B) : Colors.grey[300]!,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isEditing ? const Color(0xFF006A5B) : Colors.grey[300]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF006A5B),
                width: 2,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey[300]!,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'C';
    
    List<String> names = name.trim().split(' ');
    String initials = '';
    
    for (int i = 0; i < names.length && i < 2; i++) {
      if (names[i].isNotEmpty) {
        initials += names[i][0].toUpperCase();
      }
    }
    
    return initials.isEmpty ? 'C' : initials;
  }
}