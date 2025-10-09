import 'package:kindora/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:kindora/splash_page.dart';
import 'package:kindora/services/global_call_service.dart'; // Add GlobalCallService import
import 'package:shared_preferences/shared_preferences.dart'; // Add for lifecycle ID cleanup
import 'package:flutter/foundation.dart';
import 'package:kindora/app_routes_demo.dart'
    if (dart.library.io) 'package:kindora/app_routes_full.dart' as routes;
//logins imports
import 'package:kindora/screens/auth/login_page.dart';
import 'package:kindora/screens/auth/parent_login.dart';
import 'package:kindora/screens/auth/therapist_login.dart';
import 'package:kindora/screens/auth/login_as.dart';
import 'package:kindora/screens/auth/admin_login.dart';
import 'package:kindora/screens/admin/admin_dashboard.dart';
import 'package:kindora/screens/login_test_page.dart';
//registration imports
import 'package:kindora/screens/registration/clinic_reg.dart';
import 'package:kindora/screens/registration/parent_reg.dart';
import 'package:kindora/screens/registration/therapist_reg.dart';
//parent page imports
import 'package:kindora/screens/parent/dashboard.dart';
import 'package:kindora/screens/parent/ther_dash.dart';
import 'package:kindora/screens/parent/materials.dart';
import 'package:kindora/screens/parent/games_option.dart';
import 'package:kindora/screens/parent/games/talk_with_tiles.dart';
import 'package:kindora/screens/parent/games/shape_shifters.dart';
import 'package:kindora/screens/parent/parent_schedule.dart';
//therapist page imports
import 'package:kindora/screens/therapist/ther_profile.dart';
import 'package:kindora/screens/therapist/ther_gallery.dart';
import 'package:kindora/screens/therapist/ther_review.dart';
import 'package:kindora/screens/therapist/ther_progress.dart';
//clinic page imports
import 'package:kindora/screens/clinic/clinic_gallery.dart';
import 'package:kindora/screens/clinic/clinic_profile.dart';
import 'package:kindora/screens/clinic/clinic_booking.dart';
import 'package:kindora/screens/clinic/clinic_schedule.dart';
import 'package:kindora/screens/clinic/clinic_edit_schedule.dart';
import 'package:kindora/screens/clinic/clinic_patientlist.dart';
import 'package:kindora/screens/clinic/clinic_progress.dart';
//chat page imports
import 'package:kindora/chat/patient_selection.dart';
import 'package:kindora/chat/therapist_chat.dart';
import 'package:kindora/chat/patienside_select.dart';
import 'package:kindora/chat/patient_chat.dart';
//debug imports
import 'package:kindora/debug/storage_test.dart';

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

class MyApp extends StatefulWidget {
  final bool firebaseReady;
  const MyApp({super.key, this.firebaseReady = true});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  // Global navigator key for GlobalCallService
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Clear stored IDs when app is terminated or becomes inactive
    if (state == AppLifecycleState.detached ||
        state == AppLifecycleState.paused) {
      _clearStoredIdsOnAppClose();
    }
  }

  /// Clear stored user IDs when app is closed to prevent conflicts
  Future<void> _clearStoredIdsOnAppClose() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Clear all potential user IDs but keep login status for next session
      await prefs.remove('user_id');
      await prefs.remove('clinic_id');
      await prefs.remove('current_user_id');
      await prefs.remove('userId');
      await prefs.remove('parent_id');
      await prefs.remove('static_clinic_id');
      await prefs.remove('static_parent_id');
      await prefs.remove('fallback_id');

      print(
          'App Lifecycle: Cleared stored IDs to prevent conflicts on next app start');
    } catch (e) {
      print('App Lifecycle: Error clearing stored IDs: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Initialize GlobalCallService with navigator key
    GlobalCallService().initialize(navigatorKey);

    return MaterialApp(
        navigatorKey: navigatorKey, // Add the navigator key
        title: 'Flutter Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: widget.firebaseReady ? const SplashScreen() : const _DemoHome(),
        routes: {
          //Logins Routes
          '/login': (context) => const LoginPage(),
          '/parentlogin': (context) => const ParentLogin(), // <-- Add this
          '/therlogin': (context) => const TherapistLogin(), // <-- Add this
          '/loginas': (context) => const LoginAs(),
          '/adminlogin': (context) =>
              const AdminLogin(), // <-- Admin login route
          '/admindashboard': (context) =>
              const AdminDashboard(), // <-- Admin dashboard route
          '/logintest': (context) => const LoginTestPage(), // Test route
          '/storagetest': (context) => const StorageTestScreen(), // Storage debug route

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
          '/parentschedule': (context) => const ParentSchedulePage(),

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
          '/clinicbooking': (context) => const ClinicBookingPage(),
          '/clinicschedule': (context) => const ClinicSchedulePage(),
          '/cliniceditschedule': (context) => const ClinicEditSchedulePage(),
          '/clinicpatientlist': (context) => const ClinicPatientListPage(),
          '/clinicprogress': (context) => const ClinicProgress(),

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
              onPressed: () =>
                  Navigator.of(context).pushNamed('/therapistprogress2'),
              icon: const Icon(Icons.insights_outlined),
              label: const Text('Open Therapist Progress Demo'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () =>
                  Navigator.of(context).pushNamed('/traceandpoppro'),
              icon: const Icon(Icons.gesture),
              label: const Text('Open Trace & Pop Pro (Motor Skills)'),
            ),
          ],
        ),
      ),
    );
  }
}
