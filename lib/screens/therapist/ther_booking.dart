import 'package:flutter/material.dart';
import 'ther_booking_tabbar.dart';

class TherapistBookingPage extends StatelessWidget {
  const TherapistBookingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: TherapistBookingTabBar(),
    );
  }
}
