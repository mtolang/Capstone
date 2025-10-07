import 'package:capstone_2/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:capstone_2/splash_page.dart';
import 'package:flutter/foundation.dart';
import 'package:capstone_2/app_routes_demo.dart'
  if (dart.library.io) 'package:capstone_2/app_routes_full.dart' as routes;
//logins imports
import 'package:capstone_2/screens/auth/login_page.dart';
import 'package:capstone_2/screens/auth/parent_login.dart';
import 'package:capstone_2/screens/auth/therapist_login.dart';
import 'package:capstone_2/screens/auth/login_as.dart';
import 'package:capstone_2/screens/auth/admin_login.dart';
import 'package:capstone_2/screens/admin/admin_dashboard.dart';
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
import 'package:capstone_2/screens/therapist/ther_progress.dart';
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
  bool firebaseReady = true;
  if (kIsWeb) {
    // Web config is missing; allow app to start without Firebase for UI/dev.
    firebaseReady = false;
  } else {
    try {
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);
    } catch (_) {
      firebaseReady = false;
    }
  }
  runApp(MyApp(firebaseReady: firebaseReady));
}

class MyApp extends StatelessWidget {
  final bool firebaseReady;
  const MyApp({super.key, this.firebaseReady = true});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: firebaseReady ? const SplashScreen() : const _DemoHome(),
        routes: {
          //Logins Routes
          '/login': (context) => const LoginPage(),
          '/parentlogin': (context) => const ParentLogin(), // <-- Add this
          '/therlogin': (context) => const TherapistLogin(), // <-- Add this
          '/loginas': (context) => const LoginAs(),
          '/adminlogin': (context) => const AdminLogin(), // <-- Admin login route
          '/admindashboard': (context) => const AdminDashboard(), // <-- Admin dashboard route
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
          '/therapistprogress': (context) => const TherProgress(),

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
          
          // Add routes from the routes module
          ...routes.routes,
        } // Show splash screen first
        );
  }
}

class _DemoHome extends StatelessWidget {
  const _DemoHome();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kindora (Web Demo)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3CD),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFEEBA)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.warning_amber, color: Color(0xFF856404)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Firebase is not configured for Web in this dev run. Use the button below to open the Therapist Progress demo page.',
                      style: TextStyle(color: Color(0xFF856404)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pushNamed('/therapistprogress2'),
              icon: const Icon(Icons.insights_outlined),
              label: const Text('Open Therapist Progress Demo'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pushNamed('/traceandpoppro'),
              icon: const Icon(Icons.gesture),
              label: const Text('Open Trace & Pop Pro (Motor Skills)'),
            ),
          ],
        ),
      ),
    );
  }
}
