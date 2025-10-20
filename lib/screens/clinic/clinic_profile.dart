import 'package:flutter/material.dart';
import 'package:kindora/screens/clinic/custom_tabbar.dart';
import 'package:kindora/screens/clinic/clinic_navbar.dart';
import '../../helper/clinic_auth.dart';

class ClinicProfile extends StatefulWidget {
  const ClinicProfile({super.key});

  @override
  State<ClinicProfile> createState() => _ClinicProfileState();
}

class _ClinicProfileState extends State<ClinicProfile> {
  String _clinicName = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadClinicData();
  }

  Future<void> _loadClinicData() async {
    try {
      final clinicData = await ClinicAuthService.getCurrentClinicData();
      if (clinicData != null && mounted) {
        setState(() {
          // Try different field name variations for clinic name
          _clinicName = clinicData['Clinic_Name'] ??
              clinicData['clinic_name'] ??
              clinicData['clinicName'] ??
              clinicData['name'] ??
              'Unknown Clinic';
        });
      }
    } catch (e) {
      print('Error loading clinic data: $e');
      if (mounted) {
        setState(() {
          _clinicName = 'Clinic Profile';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size mq = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _clinicName,
          style: const TextStyle(color: Colors.white),
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

      // drawer or sidebar of hamburger menu
      drawer: const ClinicNavBar(),

      // body
      body: Builder(
        builder: (context) => Stack(
          children: [
            // Background images with fallback gradients
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ConstrainedBox(
                constraints: BoxConstraints.expand(height: mq.height * 0.30),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF006A5B), Color(0xFF67AFA5)],
                    ),
                  ),
                  // Fallback for missing image
                  child: Image.asset(
                    'asset/images/Ellipse 1.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(); // Return empty container if image fails
                    },
                  ),
                ),
              ),
            ),
            // bottom background
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: ConstrainedBox(
                constraints: BoxConstraints.expand(height: mq.height * 0.3),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Color(0xFF67AFA5), Colors.white],
                    ),
                  ),
                  // Fallback for missing image
                  child: Image.asset(
                    'asset/images/Ellipse 2.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(); // Return empty container if image fails
                    },
                  ),
                ),
              ),
            ),

            // Main Content
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: <Widget>[
                    const SizedBox(height: 30),

                    // - Custom Tab bar -
                    const Center(
                      child: CustomTabBar(),
                    ),

                    // Padding added before the CustomTabBar to avoid overlap
                    const SizedBox(height: 60),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Profile picture with fallback
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color.fromARGB(255, 10, 94, 45),
                              width: 1.0,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: CircleAvatar(
                            radius: 70,
                            backgroundColor: Colors.grey[300],
                            child: Image.asset(
                              'asset/images/profile.jpg',
                              width: 140,
                              height: 140,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.business,
                                  size: 80,
                                  color: Colors.grey,
                                );
                              },
                            ),
                          ),
                        ),

                        // Spacing between profile picture and clinic name
                        const SizedBox(height: 5),

                        // Clinic Name
                        Text(
                          _clinicName,
                          style: const TextStyle(
                            color: Color(0xFF67AFA5),
                            fontSize: 20,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w900,
                          ),
                        ),

                        // Spacing between clinic name and 'About Us'
                        const SizedBox(height: 10),

                        // About Us
                        const Text(
                          'ABOUT US',
                          style: TextStyle(
                            color: Color(0xFF999999),
                            fontSize: 16,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w900,
                          ),
                        ),

                        // Spacing between 'About Us' and its content
                        const SizedBox(height: 5),

                        // About Us content
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            'A center with all your needed services, The Tiny House Therapy and Learning Center',
                            style: TextStyle(
                              height: 1.3,
                              fontSize: 15.0,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),

                    // Spacing between About Us content and "Services offered"
                    const SizedBox(height: 15),

                    // Services Offered
                    const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'SERVICES OFFERED',
                          style: TextStyle(
                            color: Color(0xFF999999),
                            fontSize: 16,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),

                    // Spacing between "Services Offered" and its content
                    const SizedBox(height: 5),
                    const SizedBox(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('• Occupational Therapy',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13.0)),
                                  SizedBox(height: 5),
                                  Text('• Physical Therapy',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13.0)),
                                  SizedBox(height: 5),
                                  Text('• Cognitive Therapy',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13.0)),
                                  SizedBox(height: 5),
                                  Text('• Speech Therapy',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13.0)),
                                ],
                              ),
                              SizedBox(width: 20),
                              Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('• Developmental Delays',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13.0)),
                                  SizedBox(height: 5),
                                  Text('• ADHD',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13.0)),
                                  SizedBox(height: 5),
                                  Text('• Learning Disability',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13.0)),
                                  SizedBox(height: 5),
                                  Text('• Oral Motor Issues',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13.0)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Spacing between services offered content and "Prices"
                    const SizedBox(height: 20),

                    // Prices
                    const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'PRICES',
                          style: TextStyle(
                            color: Color(0xFF999999),
                            fontSize: 16,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),

                    // Spacing between "Prices" and its content
                    const SizedBox(height: 15),

                    // Prices content
                    Column(
                      children: [
                        Center(
                          child: Container(
                            width: 297,
                            height: 51,
                            decoration: ShapeDecoration(
                              color: const Color(0xFF006A5B),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              shadows: const [
                                BoxShadow(
                                  color: Color(0x3F000000),
                                  blurRadius: 4,
                                  offset: Offset(0, 4),
                                  spreadRadius: 0,
                                )
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                "₱750/Session (1hr)",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Additional spacing at bottom
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),

            // Floating Action Button (FAB) - Calendar/Booking
            Positioned(
              bottom: 35,
              right: 30,
              child: FloatingActionButton(
                onPressed: () {
                  print('Calendar/Booking FAB tapped');
                  _showBookingOptions(context);
                },
                backgroundColor: const Color(0xFF006A5B),
                child: const Icon(
                  Icons.calendar_month,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Show booking options
  void _showBookingOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Booking Options',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading:
                  const Icon(Icons.event_available, color: Color(0xFF006A5B)),
              title: const Text('View Calendar'),
              subtitle: const Text('See all appointments'),
              onTap: () {
                Navigator.pop(context);
                print('View Calendar selected');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Calendar view functionality')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.schedule, color: Color(0xFF006A5B)),
              title: const Text('Manage Bookings'),
              subtitle: const Text('Edit or cancel appointments'),
              onTap: () {
                Navigator.pop(context);
                print('Manage Bookings selected');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Manage bookings functionality')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.add, color: Color(0xFF006A5B)),
              title: const Text('New Booking'),
              subtitle: const Text('Create a new appointment'),
              onTap: () {
                Navigator.pop(context);
                print('New Booking selected');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('New booking functionality')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
