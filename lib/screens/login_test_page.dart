import 'package:flutter/material.dart';
import '../helper/clinic_auth.dart';

class LoginTestPage extends StatefulWidget {
  const LoginTestPage({super.key});

  @override
  State<LoginTestPage> createState() => _LoginTestPageState();
}

class _LoginTestPageState extends State<LoginTestPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _storedClinicId;
  Map<String, dynamic>? _clinicData;

  @override
  void initState() {
    super.initState();
    _checkStoredLogin();
  }

  Future<void> _checkStoredLogin() async {
    final isLoggedIn = await ClinicAuthService.isLoggedIn;
    if (isLoggedIn) {
      final clinicId = await ClinicAuthService.getStoredClinicId();
      final clinicData = await ClinicAuthService.getCurrentClinicData();
      setState(() {
        _storedClinicId = clinicId;
        _clinicData = clinicData;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _testLogin() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ClinicAuthService.signInClinic(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (result != null) {
        setState(() {
          _storedClinicId = result['clinicId'];
          _clinicData = result['clinicData'];
        });
        _showMessage('Login successful! Clinic ID: ${result['clinicId']}');
      }
    } catch (e) {
      _showMessage('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testLogout() async {
    try {
      await ClinicAuthService.signOut();
      setState(() {
        _storedClinicId = null;
        _clinicData = null;
      });
      _showMessage('Logged out successfully! Local storage cleared.');
    } catch (e) {
      _showMessage('Logout error: $e');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login Test'),
        backgroundColor: const Color(0xFF006A5B),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Test credentials info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Test with your Firebase data:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('Email: 210000001675@uic.edu.ph'),
                  Text('Password: 11032001'),
                  Text('Expected Document ID: CLI01'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Login form
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // Login button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _testLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006A5B),
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Test Login'),
              ),
            ),
            const SizedBox(height: 20),

            // Show stored data
            if (_storedClinicId != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stored in Local Storage:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Clinic ID: $_storedClinicId'),
                    if (_clinicData != null) ...[
                      Text('Clinic Name: ${_clinicData!['Clinic_Name']}'),
                      Text('User Name: ${_clinicData!['User_name']}'),
                      Text('Email: ${_clinicData!['email']}'),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _testLogout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Test Logout'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
