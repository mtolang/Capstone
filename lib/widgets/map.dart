import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class Maps extends StatefulWidget {
  const Maps({super.key, required this.title});

  final String title;

  @override
  State<Maps> createState() => _MapsState();
}

class _MapsState extends State<Maps> {
  late final MapController mapController;
  Location location = Location();

  // Default location - University of the Immaculate Conception - Main (Davao City)
  final LatLng _center = const LatLng(7.069901911299253, 125.60031857042385);

  // Current user location
  LatLng? _currentLocation;

  // Markers for therapists/clinics
  List<Marker> _markers = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    mapController = MapController();
    _getCurrentLocation();
    _addSampleMarkers();
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }

  // Get user's current location
  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          setState(() {
            _errorMessage = 'Location service is disabled';
            _isLoading = false;
          });
          return;
        }
      }

      PermissionStatus permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          setState(() {
            _errorMessage = 'Location permission denied';
            _isLoading = false;
          });
          return;
        }
      }

      LocationData locationData = await location.getLocation();
      setState(() {
        _currentLocation =
            LatLng(locationData.latitude!, locationData.longitude!);
        _isLoading = false;
      });

      // Move map to user location safely
      if (_currentLocation != null && mounted) {
        try {
          mapController.move(_currentLocation!, 15.0);
        } catch (e) {
          print('Error moving map: $e');
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error getting location: $e';
        _isLoading = false;
      });
    }
  }

  // Add sample markers for therapists/clinics
  void _addSampleMarkers() {
    setState(() {
      _markers = [
        // University of the Immaculate Conception - Main Campus marker
        Marker(
          point: const LatLng(7.069901911299253, 125.60031857042385),
          width: 50,
          height: 50,
          child: GestureDetector(
            onTap: () => _onMarkerTapped('uic_main'),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.school,
                color: Color(0xFF006A5B),
                size: 30,
              ),
            ),
          ),
        ),
        Marker(
          point: const LatLng(
              7.0731, 125.6123), // Davao Medical School Foundation area
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () => _onMarkerTapped('clinic1'),
            child: const Icon(
              Icons.local_hospital,
              color: Color(0xFF006A5B),
              size: 40,
            ),
          ),
        ),
        Marker(
          point: const LatLng(7.0644, 125.6081), // Near Abreeza Mall area
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () => _onMarkerTapped('clinic2'),
            child: const Icon(
              Icons.local_hospital,
              color: Color(0xFF006A5B),
              size: 40,
            ),
          ),
        ),
        Marker(
          point: const LatLng(7.0808, 125.5964), // Buhangin area
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () => _onMarkerTapped('therapist1'),
            child: const Icon(
              Icons.person_pin,
              color: Color(0xFF67AFA5),
              size: 40,
            ),
          ),
        ),
        Marker(
          point: const LatLng(7.0559, 125.5889), // Matina area
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () => _onMarkerTapped('therapist2'),
            child: const Icon(
              Icons.person_pin,
              color: Color(0xFF67AFA5),
              size: 40,
            ),
          ),
        ),
      ];
    });
  }

  // Handle marker tap
  void _onMarkerTapped(String markerId) {
    print('Marker tapped: $markerId');

    // Show bottom sheet with details
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
            Text(
              _getMarkerTitle(markerId),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _getMarkerSubtitle(markerId),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text('Calling ${_getMarkerTitle(markerId)}')),
                    );
                  },
                  icon: const Icon(Icons.phone),
                  label: const Text('Call'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006A5B),
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Getting directions to ${_getMarkerTitle(markerId)}')),
                    );
                  },
                  icon: const Icon(Icons.directions),
                  label: const Text('Directions'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF67AFA5),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getMarkerTitle(String markerId) {
    switch (markerId) {
      case 'uic_main':
        return 'University of the Immaculate Conception';
      case 'clinic1':
        return 'Davao Medical Center';
      case 'clinic2':
        return 'The Tiny House Therapy Center';
      case 'therapist1':
        return 'Dr. Maria Santos';
      case 'therapist2':
        return 'Dr. Juan Cruz';
      default:
        return 'Unknown Location';
    }
  }

  String _getMarkerSubtitle(String markerId) {
    switch (markerId) {
      case 'uic_main':
        return 'Main Campus - Davao City\nEducational Institution';
      case 'clinic1':
        return 'General Medicine & Therapy\n₱600/consultation';
      case 'clinic2':
        return 'Speech & Occupational Therapy\n₱750/session';
      case 'therapist1':
        return 'Speech Therapist\n5+ years experience';
      case 'therapist2':
        return 'Occupational Therapist\n3+ years experience';
      default:
        return 'No details available';
    }
  }

  // Search function using Nominatim API (OpenStreetMap's geocoding service)
  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) return;

    try {
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/search?format=json&q=$query&limit=1&countrycodes=ph');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> results = json.decode(response.body);

        if (results.isNotEmpty) {
          final result = results[0];
          final double lat = double.parse(result['lat']);
          final double lon = double.parse(result['lon']);

          mapController.move(LatLng(lat, lon), 15.0);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Found: ${result['display_name']}')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location not found')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Search error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Color(0xFF006A5B),
              ),
              SizedBox(height: 16),
              Text('Loading map...'),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _getCurrentLocation();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: _currentLocation ?? _center,
              initialZoom: 12.0,
              onTap: (TapPosition tapPosition, LatLng point) {
                print('Map tapped at: $point');
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.capstone_2',
                maxZoom: 19,
              ),
              MarkerLayer(
                markers: [
                  ..._markers,
                  // Add current location marker if available
                  if (_currentLocation != null)
                    Marker(
                      point: _currentLocation!,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person_pin_circle,
                          color: Colors.white,
                          size: 25,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Search bar overlay
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search for therapists or clinics in Davao...',
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search, color: Color(0xFF006A5B)),
                ),
                onSubmitted: (value) {
                  _searchLocation(value);
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_currentLocation != null) {
            try {
              mapController.move(_currentLocation!, 15.0);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Moved to your current location')),
              );
            } catch (e) {
              print('Error moving to location: $e');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Error moving to your location')),
              );
            }
          } else {
            // If no GPS location, go to UIC location
            mapController.move(_center, 15.0);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content:
                      Text('Showing University of the Immaculate Conception')),
            );
          }
        },
        backgroundColor: const Color(0xFF006A5B),
        child: Icon(
          _currentLocation != null ? Icons.my_location : Icons.location_on,
          color: Colors.white,
        ),
      ),
    );
  }
}
