import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class Maps extends StatefulWidget {
  const Maps({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<Maps> createState() => _MapsState();
}

class _MapsState extends State<Maps> {
  late final MapController mapController;
  Location location = Location();

  // Default location (Philippines - you can change this)
  final LatLng _center = const LatLng(14.5995, 120.9842); // Manila, Philippines

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
        Marker(
          point: const LatLng(14.6091, 121.0223), // Quezon City
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
          point: const LatLng(14.5547, 121.0244), // Makati
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
          point: const LatLng(14.5764, 121.0851), // Pasig
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
          point: const LatLng(14.6507, 121.0497), // San Juan
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
      case 'clinic1':
        return 'The Tiny House Therapy Center';
      case 'clinic2':
        return 'Child Development Center';
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
      case 'clinic1':
        return 'Speech & Occupational Therapy\n₱750/session';
      case 'clinic2':
        return 'Physical & Cognitive Therapy\n₱800/session';
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
                      width: 30,
                      height: 30,
                      child: const Icon(
                        Icons.my_location,
                        color: Colors.blue,
                        size: 30,
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
                  hintText: 'Search for therapists or clinics...',
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
            } catch (e) {
              print('Error moving to location: $e');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Error moving to your location')),
              );
            }
          } else {
            _getCurrentLocation();
          }
        },
        backgroundColor: const Color(0xFF006A5B),
        child: const Icon(Icons.my_location, color: Colors.white),
      ),
    );
  }
}
