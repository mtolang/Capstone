import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:delayed_display/delayed_display.dart';
import 'package:capstone_2/screens/auth/login_as.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late Size mq;
  bool _logoVisible = false;
  bool _textVisible = false;

  @override
  void initState() {
    super.initState();
    // Delay for 3 seconds before animating the logo
    Timer(const Duration(seconds: 3), () {
      setState(() {
        _logoVisible = true;
      });
    });
    // Delay for 4 seconds before animating the text
    Timer(const Duration(seconds: 4), () {
      setState(() {
        _textVisible = true;
      });
    });
    Timer(const Duration(seconds: 10), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginAs()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Welcome to Kindora',
          style: TextStyle(color: Colors.white),
          // textAlign: TextAlign.center,
        ),
        backgroundColor: const Color(0xFF006A5B),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Logo Animation
          // This section displays the TherapEase logo image with animation.
          Align(
            alignment:
                Alignment.topCenter, // Change this for different positions
            child: Padding(
              padding: const EdgeInsets.only(
                  top: 100), // Adjust top padding as needed
              child: DelayedDisplay(
                delay: const Duration(seconds: 4),
                child: AnimatedOpacity(
                  opacity: _logoVisible ? 1.0 : 0.0,
                  duration: const Duration(seconds: 2),
                  child: SizedBox(
                    width: 200, // Set your desired width
                    height: 200, // Set your desired height
                    child: Image.asset('asset/logo1.png'), // <-- Logo image
                  ),
                ),
              ),
            ),
          ),

          // MADE IN DAVAO WITH ❣️ Animation
          Positioned(
            bottom: mq.height * (_textVisible ? 0.09 : 0.5),
            width: mq.width,
            child: DelayedDisplay(
              delay: const Duration(seconds: 6),
              child: AnimatedOpacity(
                opacity: _textVisible ? 1.0 : 0.0,
                duration: const Duration(seconds: 2),
                child: const Text(
                  'MADE IN DAVAO WITH ❣️',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    color: Color.fromARGB(255, 17, 158, 132),
                    letterSpacing: 0.9,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
