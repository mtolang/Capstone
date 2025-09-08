import 'package:capstone_2/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:capstone_2/splash_page.dart';
//logins imports
import 'package:capstone_2/screens/auth/login_page.dart';
import 'package:capstone_2/screens/auth/parent_login.dart';
import 'package:capstone_2/screens/auth/therapist_login.dart';
import 'package:capstone_2/screens/auth/login_as.dart';
import 'package:capstone_2/screens/login_test_page.dart';
//registration imports
import 'package:capstone_2/screens/registration/clinic_reg.dart';
import 'package:capstone_2/screens/registration/parent_reg.dart';
import 'package:capstone_2/screens/registration/therapist_reg.dart';
//parent page imports
import 'package:capstone_2/screens/parent/dashboard.dart';
import 'package:capstone_2/screens/parent/ther_dash.dart';
import 'package:capstone_2/screens/parent/materials.dart';
import 'package:capstone_2/screens/parent/games_option.dart';
import 'package:capstone_2/screens/parent/games/talk_with_tiles.dart';
import 'package:capstone_2/screens/parent/games/shape_shifters.dart';
//therapist page imports
import 'package:capstone_2/screens/therapist/ther_profile.dart';
import 'package:capstone_2/screens/therapist/ther_gallery.dart';
import 'package:capstone_2/screens/therapist/ther_review.dart';
//clinic page imports
import 'package:capstone_2/screens/clinic/clinic_gallery.dart';
import 'package:capstone_2/screens/clinic/clinic_profile.dart';
//chat page imports
import 'package:capstone_2/chat/patient_selection.dart';
import 'package:capstone_2/chat/therapist_chat.dart';
import 'package:capstone_2/chat/patienside_select.dart';
import 'package:capstone_2/chat/patient_chat.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
          '/loginas': (context) => const LoginAs(),
          '/logintest': (context) => const LoginTestPage(), // Test route

          //Registration Routes
          '/clinicreg': (context) => const ClinicRegister(),
          '/parentreg': (context) => const ParentRegister(),
          '/therapistreg': (context) => const TherapistRegister(),

          //Parent Page Routes
          '/parentdashboard': (context) => const Dashboard(),
          '/therdashboard': (context) => const TherapistsDashboard(),
          '/materials': (context) => const MaterialsPage(),
          '/gamesoption': (context) => const GamesOption(),
          '/talkwithtiles': (context) => const TalkWithTilesGame(),
          '/shapeshifters': (context) => const ShapeShiftersGame(),

          //Therapist Page Routes
          '/therapistprofile': (context) => const TherapistProfile(),
          '/therapistgallery': (context) => const TherapistGallery(),
          '/therapistreview': (context) => const TherapistReview(),

          //Chat Page Routes
          '/patientselection': (context) => const PatientSelectionPage(),
          '/therapistchat': (context) {
            final args = ModalRoute.of(context)?.settings.arguments as String?;
            return TherapistChatPage(patientId: args);
          },
          '/patientchat': (context) {
            final args = ModalRoute.of(context)?.settings.arguments
                as Map<String, dynamic>?;
            return PatientChatPage(
              therapistId: args?['therapistId'] as String?,
              therapistName: args?['therapistName'] as String?,
              isPatientSide: args?['isPatientSide'] as bool? ?? true,
            );
          },
          '/patientsideselect': (context) => const PatientSideSelectPage(),

          //Clinic Page Routes
          '/clinicgallery': (context) => const ClinicGallery(),
          '/clinicprofile': (context) => const ClinicProfile(),
        } // Show splash screen first
        );
  }
}
