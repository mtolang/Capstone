import 'package:flutter/material.dart';
import 'package:kindora/screens/therapist/ther_navbar.dart';
import 'package:kindora/screens/therapist/ther_booking_tabbar.dart';

class TherapistBookingPage extends StatelessWidget {
  const TherapistBookingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Size mq = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Booking',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF006A5B),
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              color: Colors.white,
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
      ),

      // Use the reusable navbar
      drawer: const TherapistNavbar(currentPage: 'booking'),

      body: Stack(
        children: [
          // Top background
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ConstrainedBox(
              constraints: BoxConstraints.expand(height: mq.height * 0.30),
              child: Image.asset(
                'asset/images/Ellipse 1.png',
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Bottom background
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ConstrainedBox(
              constraints: BoxConstraints.expand(height: mq.height * 0.3),
              child: Image.asset(
                'asset/images/Ellipse 2.png',
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Main content
          Positioned.fill(
            child: Column(
              children: [
                const SizedBox(height: 30),

                // Booking tabbar
                const Expanded(
                  child: TherapistBookingTabBar(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
