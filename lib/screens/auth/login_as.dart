import 'package:flutter/material.dart';

class LoginAs extends StatefulWidget {
  const LoginAs({super.key});

  @override
  State<LoginAs> createState() => _LoginAsState();
}

class _LoginAsState extends State<LoginAs> {
  int _logoTapCount = 0;
  DateTime? _lastTapTime;

  void _onLogoTap() {
    final now = DateTime.now();
    
    // Reset tap count if more than 2 seconds have passed since last tap
    if (_lastTapTime == null || now.difference(_lastTapTime!).inSeconds > 2) {
      _logoTapCount = 1;
    } else {
      _logoTapCount++;
    }
    
    _lastTapTime = now;
    
    // Check if user tapped 3 times
    if (_logoTapCount >= 3) {
      _logoTapCount = 0; // Reset counter
      _navigateToAdminLogin();
    }
    
    // Optional: Show a subtle hint after 2 taps
    if (_logoTapCount == 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('One more tap...'),
          duration: Duration(milliseconds: 800),
          backgroundColor: Color(0xFF006A5B),
        ),
      );
    }
  }
  
  void _navigateToAdminLogin() {
    // Show brief admin access message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Admin access granted'),
        duration: Duration(milliseconds: 1000),
        backgroundColor: Color(0xFF006A5B),
      ),
    );
    
    // Navigate to admin login after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      Navigator.pushNamed(context, '/adminlogin');
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Login As',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF006A5B),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Top background image
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
          // Bottom background image (fixed at bottom)
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
          // Main content - simplified and properly centered
          Center(
            child: Padding(
              padding: const EdgeInsets.all(45.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min, // This prevents stretching
                children: [
                  // Logo (now clickable with 3-tap easter egg and bigger)
                  GestureDetector(
                    onTap: _onLogoTap,
                    child: Container(
                      // Add subtle visual feedback when tapping
                      padding: const EdgeInsets.all(10),
                      child: Image.asset(
                        'asset/logo1.png',
                        height: 140, // Increased from 100 to 140
                      ),
                    ),
                  ),
                  const SizedBox(height: 30.0),
                // Buttons (with navigation)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006A5B),
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, '/parentlogin');
                  },
                  child: const Text('Login as Carer'),
                ),
                const SizedBox(height: 30.0),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006A5B),
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, '/therlogin');
                  },
                  child: const Text('Login as Therapist'),
                ),
                const SizedBox(height: 30.0),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006A5B),
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, '/login');
                  },
                  child: const Text('Clinic Login'),
                ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
