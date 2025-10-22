import 'package:flutter/material.dart';
import 'package:kindora/screens/therapist/ther_tab.dart';
import 'package:kindora/screens/therapist/ther_navbar.dart';
import 'package:kindora/helper/therapist_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
// import 'package:kindora/calendar.dart';

class TherapistProfile extends StatefulWidget {
  const TherapistProfile({Key? key}) : super(key: key);

  @override
  State<TherapistProfile> createState() => _TherapistProfileState();
}

class _TherapistProfileState extends State<TherapistProfile> {
  String _therapistName = 'Loading...';
  String _aboutText = 'Offers variety of therapy services for your child!';
  String _email = '';
  String _address = '';
  String _username = '';
  String _contactNumber = '';
  String? _profileImagePath;
  bool _isLoading = true;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadTherapistData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _aboutController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _addressController.dispose();
    _usernameController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _loadTherapistData() async {
    try {
      final therapistInfo = await TherapistAuthService.getStoredTherapistInfo();
      final therapistId = therapistInfo['therapist_id'];
      
      if (therapistId != null) {
        // Get fresh data from Firebase
        final doc = await FirebaseFirestore.instance
            .collection('TherapistAcc')
            .doc(therapistId)
            .get();
        
        if (!doc.exists) {
          // Try TherAcc collection as fallback
          final therDoc = await FirebaseFirestore.instance
              .collection('TherAcc')
              .doc(therapistId)
              .get();
          
          if (therDoc.exists) {
            final data = therDoc.data() as Map<String, dynamic>;
            _updateUI(data);
          }
        } else {
          final data = doc.data() as Map<String, dynamic>;
          _updateUI(data);
        }
      } else {
        // Fallback to stored data
        setState(() {
          _therapistName = therapistInfo['therapist_name'] ?? 'Therapist';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading therapist data: $e');
      setState(() {
        _therapistName = 'Therapist Profile';
        _isLoading = false;
      });
    }
  }

  void _updateUI(Map<String, dynamic> data) {
    setState(() {
      // Try different field name variations
      _therapistName = data['User_Name'] ?? 
                     data['Full_Name'] ?? 
                     data['user_name'] ?? 
                     data['full_name'] ?? 
                     data['Name'] ?? 
                     'Therapist';
      
      // Load about text if available
      _aboutText = data['About'] ?? 
                   data['about'] ?? 
                   'Offers variety of therapy services for your child!';
      
      // Load additional fields
      _email = data['Email'] ?? data['email'] ?? '';
      _address = data['Address'] ?? data['address'] ?? '';
      _username = data['User_Name'] ?? data['user_name'] ?? '';
      _contactNumber = data['Contact_Number'] ?? data['contact_number'] ?? '';
      
      _isLoading = false;
    });
    
    // Update controllers with current values
    _nameController.text = _therapistName;
    _aboutController.text = _aboutText;
    _emailController.text = _email;
    _addressController.text = _address;
    _usernameController.text = _username;
    _contactController.text = _contactNumber;
    // Note: We don't populate password for security reasons
    _passwordController.text = '';
  }

  // Show edit profile dialog
  void _showEditProfileDialog() {
    // Reset controllers with current values
    _nameController.text = _therapistName;
    _aboutController.text = _aboutText;
    _emailController.text = _email;
    _addressController.text = _address;
    _usernameController.text = _username;
    _contactController.text = _contactNumber;
    _passwordController.text = ''; // Always empty for security

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Edit Profile',
                style: TextStyle(
                  color: Color(0xFF006A5B),
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Profile picture section
                      GestureDetector(
                        onTap: () => _pickProfileImage(setDialogState),
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundImage: _profileImagePath != null
                                  ? FileImage(File(_profileImagePath!))
                                  : const AssetImage('asset/images/ther.jpg') as ImageProvider,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF006A5B),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Full Name field
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          labelStyle: TextStyle(color: Color(0xFF006A5B)),
                          prefixIcon: Icon(Icons.person, color: Color(0xFF006A5B)),
                          border: OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF006A5B)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Username field
                      TextField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          labelStyle: TextStyle(color: Color(0xFF006A5B)),
                          prefixIcon: Icon(Icons.account_circle, color: Color(0xFF006A5B)),
                          border: OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF006A5B)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Email field
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          labelStyle: TextStyle(color: Color(0xFF006A5B)),
                          prefixIcon: Icon(Icons.email, color: Color(0xFF006A5B)),
                          border: OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF006A5B)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Contact Number field
                      TextField(
                        controller: _contactController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Contact Number',
                          labelStyle: TextStyle(color: Color(0xFF006A5B)),
                          prefixIcon: Icon(Icons.phone, color: Color(0xFF006A5B)),
                          border: OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF006A5B)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Address field
                      TextField(
                        controller: _addressController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Address',
                          labelStyle: TextStyle(color: Color(0xFF006A5B)),
                          prefixIcon: Icon(Icons.location_on, color: Color(0xFF006A5B)),
                          border: OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF006A5B)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Password field
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'New Password (optional)',
                          labelStyle: TextStyle(color: Color(0xFF006A5B)),
                          prefixIcon: Icon(Icons.lock, color: Color(0xFF006A5B)),
                          border: OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF006A5B)),
                          ),
                          helperText: 'Leave empty to keep current password',
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // About field
                      TextField(
                        controller: _aboutController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'About',
                          labelStyle: TextStyle(color: Color(0xFF006A5B)),
                          prefixIcon: Icon(Icons.info, color: Color(0xFF006A5B)),
                          border: OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF006A5B)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _saveProfile(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006A5B),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Pick profile image
  Future<void> _pickProfileImage(StateSetter setDialogState) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 70,
      );
      
      if (image != null) {
        setDialogState(() {
          _profileImagePath = image.path;
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to pick image. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Save profile changes
  Future<void> _saveProfile() async {
    try {
      // Validate required fields
      if (_nameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Full name is required'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      if (_emailController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email is required'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Validate email format
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(_emailController.text.trim())) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid email address'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final therapistInfo = await TherapistAuthService.getStoredTherapistInfo();
      final therapistId = therapistInfo['therapist_id'];
      
      if (therapistId == null) {
        throw Exception('No therapist ID found');
      }

      // Prepare update data
      Map<String, dynamic> updateData = {
        'Full_Name': _nameController.text.trim(),
        'User_Name': _usernameController.text.trim().isEmpty 
            ? _nameController.text.trim() 
            : _usernameController.text.trim(),
        'Email': _emailController.text.trim(),
        'Contact_Number': _contactController.text.trim(),
        'Address': _addressController.text.trim(),
        'About': _aboutController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Only update password if a new one is provided
      if (_passwordController.text.trim().isNotEmpty) {
        updateData['Password'] = _passwordController.text.trim();
      }

      // Try TherapistAcc collection first, then TherAcc as fallback
      bool updateSuccessful = false;
      
      try {
        await FirebaseFirestore.instance
            .collection('TherapistAcc')
            .doc(therapistId)
            .update(updateData);
        updateSuccessful = true;
      } catch (e) {
        print('TherapistAcc update failed: $e');
        try {
          // If fails, try TherAcc collection
          await FirebaseFirestore.instance
              .collection('TherAcc')
              .doc(therapistId)
              .update(updateData);
          updateSuccessful = true;
        } catch (e2) {
          print('TherAcc update also failed: $e2');
          throw Exception('Failed to update profile in database');
        }
      }

      if (updateSuccessful) {
        // Update local state
        setState(() {
          _therapistName = _nameController.text.trim();
          _aboutText = _aboutController.text.trim();
          _email = _emailController.text.trim();
          _address = _addressController.text.trim();
          _username = _usernameController.text.trim().isEmpty 
              ? _nameController.text.trim() 
              : _usernameController.text.trim();
          _contactNumber = _contactController.text.trim();
        });

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Color(0xFF006A5B),
            ),
          );
        }
      }
    } catch (e) {
      print('Error updating profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size mq = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF006A5B),
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              color: Colors.white,
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
      ),

      // drawer or sidebar of hamburger menu
      drawer: const TherapistNavbar(currentPage: 'profile'),

      // body
      body: Builder(
        builder: (context) => Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ConstrainedBox(
                constraints: BoxConstraints.expand(height: mq.height * 0.30),
                child: Image.asset(
                  'asset/images/Ellipse 1.png', // top background
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // bottom background
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: ConstrainedBox(
                constraints: BoxConstraints.expand(height: mq.height * 0.3),
                child: Image.asset(
                  'asset/images/Ellipse 2.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // List view
            // - Custom Tab bar
            // - Therapist name
            // - About us
            // - Services offered
            // - Prices

            Positioned(
              child: ListView(
                children: <Widget>[
                  const SizedBox(height: 30),

                  // - Custom Tab bar -
                  const Center(
                    child:
                        TherDashTab(initialTabIndex: 0), // Profile tab active
                  ),

                  // Padding added before the CustomTabBar to avoid overlap
                  const SizedBox(height: 60),

                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Profile picture
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color.fromARGB(255, 10, 94, 45),
                            width: 1.0,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          radius: 70,
                          backgroundImage: _profileImagePath != null
                              ? FileImage(File(_profileImagePath!))
                              : const AssetImage('asset/images/ther.jpg') as ImageProvider,
                          child: _profileImagePath == null
                              ? null
                              : ClipOval(
                                  child: Image.file(
                                    File(_profileImagePath!),
                                    width: 140,
                                    height: 140,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.person,
                                        size: 80,
                                        color: Colors.grey,
                                      );
                                    },
                                  ),
                                ),
                        ),
                      ),

                      // Spacing between profile picture and clinic name
                      const SizedBox(height: 5),

                      // Therapist Name
                      _isLoading
                          ? const CircularProgressIndicator(
                              color: Color(0xFF67AFA5),
                            )
                          : Text(
                              _therapistName,
                              style: const TextStyle(
                                color: Color(0xFF67AFA5),
                                fontSize: 20,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w900,
                              ),
                            ),

                      // Spacing between clinic name and 'About Us'
                      const SizedBox(height: 10),

                      // About Us
                      const Text(
                        'ABOUT',
                        style: TextStyle(
                          color: Color(0xFF999999),
                          fontSize: 16,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w900,
                        ),
                      ),

                      // Spacing between 'About Us' and its content
                      const SizedBox(height: 5),

                      // About Us content
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          _aboutText,
                          style: const TextStyle(
                            height: 1.3,
                            fontSize: 15.0,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),

                  // Spacing between About Us content and Contact Info
                  const SizedBox(height: 20),

                  // Contact Information Section
                  if (!_isLoading && (_email.isNotEmpty || _contactNumber.isNotEmpty || _address.isNotEmpty))
                    Column(
                      children: [
                        const Text(
                          'CONTACT INFORMATION',
                          style: TextStyle(
                            color: Color(0xFF999999),
                            fontSize: 16,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              if (_email.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.email, 
                                          color: Color(0xFF006A5B), size: 18),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _email,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (_contactNumber.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.phone, 
                                          color: Color(0xFF006A5B), size: 18),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _contactNumber,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (_address.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.location_on, 
                                          color: Color(0xFF006A5B), size: 18),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _address,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),

                  // Spacing between Contact Info and "Services offered"
                  const SizedBox(height: 20),

                  // Services Offered
                  const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'SERVICES OFFERED',
                        style: TextStyle(
                          color: Color(0xFF999999),
                          fontSize: 16,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),

                  // Spacing between "Services Offered" and its content
                  const SizedBox(height: 5),

                  const SizedBox(
                    // I've removed the height constraint so the SizedBox will take as much space as its child needs.
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          // Center the items in the row
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment
                                  .start, // Adjusted the spacing for the column
                              children: [
                                Text('• Occupational Therapy',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12.0)),
                                SizedBox(
                                    height: 5), // For spacing between items
                                Text('• Physical Therapy',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12.0)),
                                SizedBox(
                                    height: 5), // For spacing between items
                                Text('• Cognitive Therapy',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12.0)),
                                SizedBox(
                                    height: 5), // For spacing between items
                                Text('• Speech Therapy',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12.0)),
                              ],
                            ),
                            SizedBox(
                                width:
                                    20), // Optional: Added this for spacing between two columns
                            Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment
                                  .start, // Adjusted the spacing for the column
                              children: [
                                Text('• Developmental Delays',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12.0)),
                                SizedBox(
                                    height: 5), // For spacing between items
                                Text('• ADHD',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12.0)),
                                SizedBox(
                                    height: 5), // For spacing between items
                                Text('• Learning Disability',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12.0)),
                                SizedBox(
                                    height: 5), // For spacing between items
                                Text('• Oral Motor Issues',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12.0)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Spacing between services offered content and "Prices"
                  const SizedBox(height: 20),

                  // Prices
                  const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'PRICES',
                        style: TextStyle(
                          color: Color(0xFF999999),
                          fontSize: 16,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),

                  // Spacing between "Prices" and its content
                  const SizedBox(height: 15),

                  // Prices content
                  Column(
                    children: [
                      Center(
                        child: Container(
                          width: 297,
                          height: 51,
                          decoration: ShapeDecoration(
                            color: const Color(0xFF006A5B),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            shadows: const [
                              BoxShadow(
                                color: Color(0x3F000000),
                                blurRadius: 4,
                                offset: Offset(0, 4),
                                spreadRadius: 0,
                              )
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              "₱750/Session (1hr)",
                              style: TextStyle(
                                color: Colors.white, // Text color
                                fontSize: 16, // Adjust the font size as needed
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Add other widgets to the Column if needed
                    ],
                  )
                ],
              ),
            ),

            // Edit Profile Button (FAB)
            Positioned(
              bottom: 35,
              right: 30,
              child: FloatingActionButton(
                onPressed: _showEditProfileDialog,
                backgroundColor: const Color(0xFF006A5B),
                child: const Icon(
                  Icons.edit,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
