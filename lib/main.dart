import 'package:capstone_2/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:capstone_2/splash_page.dart';
import 'package:capstone_2/services/global_call_service.dart'; // Add GlobalCallService import
import 'package:shared_preferences/shared_preferences.dart'; // Add for lifecycle ID cleanup
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
import 'package:capstone_2/screens/parent/parent_schedule.dart';
//therapist page imports
import 'package:capstone_2/screens/therapist/ther_profile.dart';
import 'package:capstone_2/screens/therapist/ther_gallery.dart';
import 'package:capstone_2/screens/therapist/ther_review.dart';
//clinic page imports
import 'package:capstone_2/screens/clinic/clinic_gallery.dart';
import 'package:capstone_2/screens/clinic/clinic_profile.dart';
import 'package:capstone_2/screens/clinic/clinic_booking.dart';
import 'package:capstone_2/screens/clinic/clinic_schedule.dart';
import 'package:capstone_2/screens/clinic/clinic_edit_schedule.dart';
import 'package:capstone_2/screens/clinic/clinic_patientlist.dart';
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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

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
          '/parentschedule': (context) => const ParentSchedulePage(),

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
          '/clinicbooking': (context) => const ClinicBookingPage(),
          '/clinicschedule': (context) => const ClinicSchedulePage(),
          '/cliniceditschedule': (context) => const ClinicEditSchedulePage(),
          '/clinicpatientlist': (context) => const ClinicPatientListPage(),
        } // Show splash screen first
        );
  }
}
