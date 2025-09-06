import 'package:flutter/material.dart';

class SimpleMap extends StatelessWidget {
  const SimpleMap({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 10.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Stack(
        children: [
          // Background
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue[100]!,
                  Colors.blue[50]!,
                ],
              ),
            ),
          ),

          // Fake map markers
          const Positioned(
            top: 40,
            left: 50,
            child: _MapMarker(title: 'Tiny House Clinic'),
          ),
          const Positioned(
            top: 80,
            right: 60,
            child: _MapMarker(title: 'Dev Center'),
          ),
          const Positioned(
            bottom: 60,
            left: 80,
            child: _MapMarker(title: 'Dr. Santos'),
          ),

          // Center location icon
          const Center(
            child: Icon(
              Icons.location_on,
              size: 40,
              color: Colors.red,
            ),
          ),

          // Overlay text
          Positioned(
            bottom: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Text(
                'Interactive Map Coming Soon',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapMarker extends StatelessWidget {
  final String title;

  const _MapMarker({required this.title});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tapped on $title')),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 2,
                ),
              ],
            ),
            child: Text(
              title,
              style: const TextStyle(fontSize: 10),
            ),
          ),
          const Icon(
            Icons.location_on,
            color: Color(0xFF006A5B),
            size: 24,
          ),
        ],
      ),
    );
  }
}
