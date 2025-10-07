import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:capstone_2/controller/register_controller.dart';

class ParentRegister extends StatefulWidget {
  const ParentRegister({super.key});

  @override
  State<ParentRegister> createState() => _ParentRegisterState();
}

class _ParentRegisterState extends State<ParentRegister> {
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController userNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController contactNumberController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  RegisterParentUser controller = RegisterParentUser();
  XFile? _attachFile; // Changed from bool to XFile?

  // Add image picker functionality
  Future<XFile?> pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    return image;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text(
          'Register as Parent',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF006A5B),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            // Background waves
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ConstrainedBox(
                constraints: BoxConstraints.expand(height: size.height * 0.20),
                child: Image.asset(
                  'asset/images/WAVE.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: ConstrainedBox(
                constraints: BoxConstraints.expand(height: size.height * 0.20),
                child: Image.asset(
                  'asset/images/WAVE (1).png',
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // Form content
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTextField(fullNameController, 'Full Name'),
                    const SizedBox(height: 14.0),
                    _buildTextField(userNameController, 'User Name'),
                    const SizedBox(height: 14.0),
                    _buildTextField(emailController, 'Email'),
                    const SizedBox(height: 14.0),
                    _buildTextField(contactNumberController, 'Contact Number'),
                    const SizedBox(height: 14.0),
                    _buildTextField(addressController, 'Address'),
                    const SizedBox(height: 14.0),
                    _buildTextField(passwordController, 'Password',
                        isPassword: true),
                    const SizedBox(height: 14.0),
                    _buildTextField(
                        confirmPasswordController, 'Confirm Password',
                        isPassword: true),

                    // ID Upload Section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Upload any Valid Government ID:",
                          style: TextStyle(
                            height: 2,
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        _attachFile == null
                            ? ElevatedButton.icon(
                                icon: const Icon(Icons.attach_file),
                                label: const Text('Attach File'),
                                onPressed: () async {
                                  _attachFile = await pickImageFromGallery();
                                  setState(() {});
                                },
                              )
                            : Chip(
                                label: Text(_attachFile?.name ?? 'Attached'),
                                deleteIcon: const Icon(Icons.delete),
                                onDeleted: () {
                                  setState(() {
                                    _attachFile = null;
                                  });
                                },
                              ),

                        // Register Button
                        const SizedBox(height: 20),
                        Center(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF006A5B),
                              padding: const EdgeInsets.symmetric(
                                vertical: 20.0,
                                horizontal: 115.0,
                              ),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            onPressed: () {
                              controller.registerParentUser(
                                context,
                                fullNameController.text,
                                userNameController.text,
                                emailController.text,
                                contactNumberController.text,
                                addressController.text,
                                passwordController.text,
                                confirmPasswordController.text,
                                governmentIdFile: _attachFile,
                              );
                            },
                            child: const Text('Register'),
                          ),
                        ),

                        // Social Login Options
                        const SizedBox(height: 10),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Or",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildSocialButton('asset/icons/social.png'),
                            const SizedBox(width: 20),
                            _buildSocialButton('asset/icons/facebook (1).png'),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool isPassword = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: Colors.white),
        color: Colors.white,
        boxShadow: const [
          BoxShadow(
            color: Color(0x3F000000),
            blurRadius: 4,
            offset: Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildSocialButton(String iconPath) {
    return GestureDetector(
      onTap: () {},
      child: Image.asset(
        iconPath,
        width: 35,
        height: 35,
      ),
    );
  }
}
