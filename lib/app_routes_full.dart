import 'package:flutter/material.dart';

// Logins
import 'package:kindora/screens/auth/login_page.dart';
import 'package:kindora/screens/auth/parent_login.dart';
import 'package:kindora/screens/auth/therapist_login.dart';
import 'package:kindora/screens/auth/login_as.dart';
import 'package:kindora/screens/login_test_page.dart';

// Registration
import 'package:kindora/screens/registration/clinic_reg.dart';
import 'package:kindora/screens/registration/parent_reg.dart';
import 'package:kindora/screens/registration/therapist_reg.dart';

// Parent pages
import 'package:kindora/screens/parent/dashboard.dart';
import 'package:kindora/screens/parent/ther_dash.dart';
import 'package:kindora/screens/parent/materials.dart';
import 'package:kindora/screens/parent/games_option.dart';
import 'package:kindora/screens/parent/games/talk_with_tiles.dart';
import 'package:kindora/screens/parent/games/shape_shifters.dart';
import 'package:kindora/screens/parent/games/trace_and_pop_pro.dart';

// Therapist pages
import 'package:kindora/screens/therapist/ther_profile.dart';
import 'package:kindora/screens/therapist/ther_gallery.dart';
import 'package:kindora/screens/therapist/ther_review.dart';
import 'package:kindora/screens/therapist/ther_progress.dart';
import 'package:kindora/screens/therapist/therapist_progress_tracking.dart';

// Clinic pages
import 'package:kindora/screens/clinic/clinic_gallery.dart';
import 'package:kindora/screens/clinic/clinic_profile.dart';

// Chat
import 'package:kindora/chat/patient_selection.dart';
import 'package:kindora/chat/therapist_chat.dart';
import 'package:kindora/chat/patienside_select.dart';
import 'package:kindora/chat/patient_chat.dart';

final Map<String, WidgetBuilder> routes = {
  // Logins
  '/login': (context) => const LoginPage(),
  '/parentlogin': (context) => const ParentLogin(),
  '/therlogin': (context) => const TherapistLogin(),
  '/loginas': (context) => const LoginAs(),
  '/logintest': (context) => const LoginTestPage(),

  // Registration
  '/clinicreg': (context) => const ClinicRegister(),
  '/parentreg': (context) => const ParentRegister(),
  '/therapistreg': (context) => const TherapistRegister(),

  // Parent pages
  '/parentdashboard': (context) => const Dashboard(),
  '/therdashboard': (context) => const TherapistsDashboard(),
  '/materials': (context) => const MaterialsPage(),
  '/gamesoption': (context) => const GamesOption(),
  '/talkwithtiles': (context) => const TalkWithTilesGame(),
  '/shapeshifters': (context) => const ShapeShiftersGame(),
  '/traceandpoppro': (context) => const TraceAndPopProGame(),

  // Therapist pages
  '/therapistprofile': (context) => const TherapistProfile(),
  '/therapistgallery': (context) => const TherapistGallery(),
  '/therapistreview': (context) => const TherapistReview(),
  '/therapistprogress': (context) => const TherProgress(),
  '/therapistprogress2': (context) => const TherapistProgressTrackingPage(),

  // Chat
  '/patientselection': (context) => const PatientSelectionPage(),
  '/therapistchat': (context) {
    final args = ModalRoute.of(context)?.settings.arguments as String?;
    return TherapistChatPage(patientId: args);
  },
  '/patientchat': (context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    return PatientChatPage(
      therapistId: args?['therapistId'] as String?,
      therapistName: args?['therapistName'] as String?,
      isPatientSide: args?['isPatientSide'] as bool? ?? true,
    );
  },
  '/patientsideselect': (context) => const PatientSideSelectPage(),

  // Clinic pages
  '/clinicgallery': (context) => const ClinicGallery(),
  '/clinicprofile': (context) => const ClinicProfile(),
};
