import 'package:flutter/material.dart';
import '../../helper/auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Show error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Show success snackbar
  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Handle login
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await AuthService.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (mounted) {
        _showSuccessMessage('Login successful!');
        Navigator.pushReplacementNamed(context, '/clinicprofile');
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Handle forgot password
  Future<void> _handleForgotPassword() async {
    if (_emailController.text.isEmpty) {
      _showErrorDialog('Please enter your email address first.');
      return;
    }

    try {
      await AuthService.resetPassword(email: _emailController.text);
      _showSuccessMessage('Password reset email sent! Check your inbox.');
    } catch (e) {
      _showErrorDialog(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text(
          'Clinic Login',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF006A5B),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ConstrainedBox(
                constraints: BoxConstraints.expand(height: size.height * 0.2),
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
                constraints: BoxConstraints.expand(height: size.height * 0.30),
                child: Image.asset(
                  'asset/images/WAVE (1).png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(45.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Image.asset(
                      'asset/logo1.png',
                      height: 100,
                    ),
                    const SizedBox(height: 16.0),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.0),
                        border: Border.all(
                          color: Color.fromARGB(255, 255, 255, 255),
                        ),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x3F000000),
                            blurRadius: 4,
                            offset: Offset(0, 4),
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email or username',
                          border: InputBorder.none,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!AuthService.isValidEmail(value)) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.0),
                        border: Border.all(
                          color: Color.fromARGB(255, 245, 250, 255),
                        ),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x3F000000),
                            blurRadius: 4,
                            offset: Offset(0, 4),
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: InputBorder.none,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (!AuthService.isValidPassword(value)) {
                            return 'Password must be at least 6 characters long';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 30.0),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF006A5B),
                        padding: EdgeInsets.symmetric(vertical: 20.0),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _isLoading ? null : _handleLogin,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Login'),
                    ),
                    TextButton(
                      onPressed: _handleForgotPassword,
                      child: const Text('Forgot Password?'),
                    ),
                    const SizedBox(height: 16.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account?"),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/clinicreg');
                          },
                          child: const Text('Register'),
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
}
