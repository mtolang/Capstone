import 'package:capstone_2/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:capstone_2/splash_page.dart';
import 'package:flutter/foundation.dart';
import 'package:capstone_2/app_routes_demo.dart'
  if (dart.library.io) 'package:capstone_2/app_routes_full.dart' as routes;

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
        routes: routes.routes // Show splash screen first
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
