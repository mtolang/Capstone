import 'package:flutter/material.dart';
// Minimal imports to avoid initializing Firebase-heavy features on web
import 'package:capstone_2/screens/therapist/therapist_progress_tracking.dart';
import 'package:capstone_2/screens/parent/games/trace_and_pop_pro.dart';

final Map<String, WidgetBuilder> routes = {
  '/therapistprogress2': (context) => const TherapistProgressTrackingPage(),
  '/traceandpoppro': (context) => const TraceAndPopProGame(),
};
