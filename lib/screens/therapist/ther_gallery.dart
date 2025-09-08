import 'package:flutter/material.dart';
import 'package:capstone_2/screens/therapist/ther_tab.dart';

class TherapistGallery extends StatelessWidget {
  const TherapistGallery({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Size mq = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Therapist Gallery',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF006A5B),
      ),
      body: Stack(
        children: [
          // Bottom Background Image
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ConstrainedBox(
              constraints: BoxConstraints.expand(height: mq.height * 0.3),
              child: Image.asset(
                'asset/images/Ellipse 2.png', // bottom background
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Background Image
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ConstrainedBox(
              constraints: BoxConstraints.expand(height: mq.height * 0.30),
              child: Image.asset(
                'asset/images/Ellipse 1.png', // top background
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Custom Tab bar (Centered on the top background)
          const Positioned(
            top: 50, // Adjust the position as needed
            left: 0,
            right: 0,
            child: Center(
              child: TherDashTab(initialTabIndex: 1), // Gallery tab active
            ),
          ),
          // Content Below CustomTabBar
          Positioned(
            top: mq.height * 0.30,
            left: 0,
            right: 0,
            bottom: mq.height * 0.3, // Adjust the bottom position
            child: const SingleChildScrollView(
              child: Column(
                children: [
                  // Add your content here
                ],
              ),
            ),
          ),
          // Gallery UI and Upload Button
          Positioned(
            bottom: 20, // Adjust the position as needed
            right: 20, // Adjust the position as needed
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Handle image upload here
                    // You can open a file picker or camera to select/upload an image
                  },
                  child: const Icon(Icons.upload),
                ),
                const SizedBox(height: 10), // Adjust the spacing
                // Add your gallery UI here
                // For example, you can use a GridView.builder to display images
              ],
            ),
          ),
        ],
      ),
    );
  }
}
