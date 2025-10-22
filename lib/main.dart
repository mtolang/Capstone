import 'package:kindora/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:kindora/splash_page.dart';
import 'package:kindora/services/global_call_service.dart'; // Add GlobalCallService import
import 'package:kindora/services/session_manager.dart'; // Add SessionManager import
import 'package:flutter/foundation.dart';
import 'dart:async'; // Add for Timer
import 'package:kindora/app_routes_demo.dart'
    if (dart.library.io) 'package:kindora/app_routes_full.dart' as routes;
//logins imports
import 'package:kindora/screens/auth/login_page.dart';
import 'package:kindora/screens/auth/parent_login.dart';
import 'package:kindora/screens/auth/therapist_login.dart';
import 'package:kindora/screens/admin/fix_therapist_account.dart';
import 'package:kindora/screens/therapist/ther_booking_page.dart'
    as ther_booking_full;
import 'package:kindora/screens/therapist/ther_booking.dart'
    as ther_booking_main;
import 'package:kindora/screens/therapist/ther_materials_page.dart';
import 'package:kindora/screens/auth/login_as.dart';
import 'package:kindora/screens/auth/admin_login.dart';
import 'package:kindora/screens/admin/admin_dashboard.dart';
import 'package:kindora/screens/login_test_page.dart';
//registration imports
import 'package:kindora/screens/registration/clinic_reg.dart';
import 'package:kindora/screens/registration/parent_reg.dart';
import 'package:kindora/screens/registration/therapist_reg.dart';
//parent page imports
import 'package:kindora/screens/parent/new_dashboard_tabbar.dart';
import 'package:kindora/screens/parent/games_option.dart';
import 'package:kindora/screens/parent/games/talk_with_tiles.dart';
import 'package:kindora/screens/parent/games/cognitive_pattern_master.dart';
import 'package:kindora/screens/parent/parent_schedule.dart';
import 'package:kindora/screens/parent/parent_journal.dart';
//therapist page imports
import 'package:kindora/screens/therapist/ther_profile.dart';
import 'package:kindora/screens/therapist/ther_gallery.dart';
import 'package:kindora/screens/therapist/ther_review.dart';
import 'package:kindora/screens/therapist/ther_progress.dart';
import 'package:kindora/screens/therapist/ther_chat_list.dart';
import 'package:kindora/screens/therapist/ther_patient_selection.dart';
import 'package:kindora/screens/therapist/ther_schedule.dart';
import 'package:kindora/screens/therapist/ther_setup_sched.dart';
//clinic page imports
import 'package:kindora/screens/clinic/clinic_gallery.dart';
import 'package:kindora/screens/clinic/clinic_profile.dart';
import 'package:kindora/screens/clinic/clinic_booking.dart';
import 'package:kindora/screens/clinic/clinic_schedule.dart';
import 'package:kindora/screens/clinic/clinic_edit_schedule.dart';
import 'package:kindora/screens/clinic/clinic_patientlist.dart';
import 'package:kindora/screens/clinic/clinic_progress.dart';
import 'package:kindora/screens/clinic/clinic_patient_progress_report.dart';
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

  // Auto-logout timer for 1-hour inactivity
  Timer? _autoLogoutTimer;
  DateTime? _lastActivityTime;
  static const Duration _autoLogoutDuration = Duration(hours: 1);

  // Static instance to allow global access to activity updates
  static _MyAppState? _instance;

  @override
  void initState() {
    super.initState();
    _instance = this;
    WidgetsBinding.instance.addObserver(this);

    // Initialize SessionManager with navigator key
    SessionManager.initialize(navigatorKey);

    _updateLastActivity();
    _startAutoLogoutTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoLogoutTimer?.cancel();
    _instance = null;
    super.dispose();
  }

  /// Static method to update user activity from anywhere in the app
  static void updateUserActivity() {
    _instance?._updateLastActivity();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    print('App Lifecycle State: $state');

    switch (state) {
      case AppLifecycleState.resumed:
        // App is back in foreground - check if should logout due to inactivity
        _checkForAutoLogout();
        break;
      case AppLifecycleState.paused:
        // App goes to background - update last activity time but don't logout immediately
        _updateLastActivity();
        break;
      case AppLifecycleState.detached:
        // App is being terminated - clear IDs for security
        _clearStoredIdsOnAppClose();
        break;
      case AppLifecycleState.inactive:
        // App is inactive (e.g., phone call, notification) - update activity time
        _updateLastActivity();
        break;
      default:
        break;
    }
  }

  /// Update the last activity timestamp
  void _updateLastActivity() {
    _lastActivityTime = DateTime.now();
    SessionManager.updateUserActivity(); // Also update SessionManager
    print('Updated last activity time: $_lastActivityTime');
  }

  /// Start the auto-logout timer
  void _startAutoLogoutTimer() {
    _autoLogoutTimer?.cancel();
    _autoLogoutTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _checkForAutoLogout();
    });
    print(
        'Auto-logout timer started - checking every 5 minutes for 1-hour inactivity');
  }

  /// Check if user should be logged out due to inactivity
  void _checkForAutoLogout() async {
    if (_lastActivityTime == null) {
      _updateLastActivity();
      return;
    }

    final now = DateTime.now();
    final inactiveDuration = now.difference(_lastActivityTime!);

    print(
        'Checking auto-logout: inactive for ${inactiveDuration.inMinutes} minutes');

    // Check if user has been inactive for more than 1 hour
    if (inactiveDuration >= _autoLogoutDuration) {
      // Check if user is in an active call (should prevent auto-logout)
      final isInCall = await SessionManager.isUserInActiveCall();

      if (isInCall) {
        print('Auto-logout prevented: User is in active call');
        _updateLastActivity(); // Reset activity time during call
        return;
      }

      print(
          'Auto-logout triggered: User inactive for ${inactiveDuration.inHours} hours');
      await SessionManager.forceLogout(
          reason: 'Session expired due to inactivity');
    }
  }

  /// Clear stored user IDs when app is closed to prevent conflicts
  Future<void> _clearStoredIdsOnAppClose() async {
    await SessionManager.clearStoredUserIds();
  }

  @override
  Widget build(BuildContext context) {
    // Initialize GlobalCallService with navigator key
    GlobalCallService().initialize(navigatorKey);

    return GestureDetector(
      // Track user interactions to reset inactivity timer
      onTap: _updateLastActivity,
      onPanDown: (_) => _updateLastActivity(),
      onScaleStart: (_) => _updateLastActivity(),
      behavior: HitTestBehavior.translucent,
      child: MaterialApp(
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
            '/fixtherapist': (context) =>
                const FixTherapistAccountPage(), // Fix therapist accounts
            '/logintest': (context) => const LoginTestPage(), // Test route
            '/storagetest': (context) =>
                const StorageTestScreen(), // Storage debug route

            //Registration Routes
            '/clinicreg': (context) => const ClinicRegister(),
            '/parentreg': (context) => const ParentRegister(),
            '/therapistreg': (context) => const TherapistRegister(),

            //Parent Page Routes
            '/parentdashboard': (context) => const NewDashboardTabBar(
                initialSelectedIndex: 0), // New Clinics tab
            '/therdashboard': (context) => const NewDashboardTabBar(
                initialSelectedIndex: 1), // New Therapists tab
            '/materials': (context) => const NewDashboardTabBar(
                initialSelectedIndex: 2), // Materials tab
            '/gamesoption': (context) => const GamesOption(),
            '/talkwithtiles': (context) => const TalkWithTilesGame(),
            '/shapeshifters': (context) => const PatternMasterApp(),
            '/cognitivepatternmaster': (context) => const PatternMasterGame(),
            '/parentschedule': (context) => const ParentSchedulePage(),
            '/parentjournal': (context) => const ParentJournalPage(),

            //Therapist Page Routes
            '/therapistprofile': (context) => const TherapistProfile(),
            '/therapistbooking': (context) =>
                const ther_booking_full.TherapistBookingPage(),
            '/therapistbookingmain': (context) =>
                const ther_booking_main.TherapistBookingPage(),
            '/therapistmaterials': (context) => const TherapistMaterialsPage(),
            '/therapistgallery': (context) => const TherapistGallery(),
            '/therapistreview': (context) => const TherapistReview(),
            '/therapistprogress': (context) => const TherProgress(),
            '/therapistschedule': (context) => const TherapistSchedulePage(),
            '/therapistsetupschedule': (context) =>
                const TherapistSetupSchedulePage(),
            '/therapistpatients': (context) =>
                const _ComingSoonPage(title: 'Patient List'),
            '/therapiststaff': (context) =>
                const _ComingSoonPage(title: 'Clinic Staff'),

            //Chat Page Routes
            '/patientselection': (context) => const PatientSelectionPage(),
            '/therapistpatientselection': (context) =>
                const TherapistPatientSelectionPage(),
            '/therapistchatlist': (context) => const TherapistChatListPage(),
            '/therapistchat': (context) {
              final args =
                  ModalRoute.of(context)?.settings.arguments as String?;
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
            '/clinicassessment': (context) {
              final args = ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>?;
              return ClinicPatientProgressReport(
                patientName: args?['patientName'] as String? ?? '',
                progressData:
                    args?['progressData'] as Map<String, dynamic>? ?? {},
              );
            },

            // Add routes from the routes module
            ...routes.routes,
          } // Show splash screen first
          ),
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

// Placeholder page for coming soon features
class _ComingSoonPage extends StatelessWidget {
  final String title;

  const _ComingSoonPage({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF006A5B),
        elevation: 0,
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Poppins',
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          // Background ellipses
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ConstrainedBox(
              constraints: BoxConstraints.expand(
                  height: MediaQuery.of(context).size.height * 0.3),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF006A5B), Color(0xFF67AFA5)],
                  ),
                ),
                child: Image.asset(
                  'asset/images/Ellipse 1.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container();
                  },
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ConstrainedBox(
              constraints: BoxConstraints.expand(
                  height: MediaQuery.of(context).size.height * 0.3),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xFF67AFA5), Colors.white],
                  ),
                ),
                child: Image.asset(
                  'asset/images/Ellipse 2.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container();
                  },
                ),
              ),
            ),
          ),

          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.construction,
                  size: 80,
                  color: const Color(0xFF006A5B).withOpacity(0.6),
                ),
                const SizedBox(height: 24),
                Text(
                  '$title Coming Soon!',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF006A5B),
                    fontFamily: 'Poppins',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'This feature is currently under development.\nStay tuned for updates!',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontFamily: 'Poppins',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006A5B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Go Back',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
