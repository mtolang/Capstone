import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../helper/clinic_auth.dart';
import '../splash_page.dart';
import '../screens/auth/login_as.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: ClinicAuthService.authStateChanges,
      builder: (context, snapshot) {
        // Show loading while waiting for auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        // If user is logged in, show the app
        if (snapshot.hasData && snapshot.data != null) {
          // You can navigate to the appropriate dashboard based on user type
          // For now, navigate to clinic profile as per the original login page
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/clinicprofile');
          });
          return const SplashScreen(); // Show splash while navigating
        }

        // If user is not logged in, show login selection
        return const LoginAs();
      },
    );
  }
}
