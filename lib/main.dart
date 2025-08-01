import 'package:flutter/material.dart';
import 'package:capstone_2/splash_page.dart';
//logins imports
import 'package:capstone_2/screens/auth/login_page.dart';
import 'package:capstone_2/screens/auth/parent_login.dart';
import 'package:capstone_2/screens/auth/therapist_login.dart';
//registration imports
import 'package:capstone_2/screens/registration/clinic_reg.dart';
//parent page imports
import 'package:capstone_2/screens/parent/dashboard.dart';
import 'package:capstone_2/screens/parent/ther_dash.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const SplashScreen(),
        routes: {
          //Logins Routes
          '/login': (context) => const LoginPage(),
          '/parentlogin': (context) => const ParentLogin(), // <-- Add this
          '/therlogin': (context) => const TherapistLogin(), // <-- Add this

          //Registration Routes
          '/clinicreg': (context) => const ClinicRegister(),

          //Parent Page Routes
          '/parentdashboard': (context) => const Dashboard(),
          'therdashboard': (context) => const TherapistsDashboard(),
        } // Show splash screen first
        );
  }
}
