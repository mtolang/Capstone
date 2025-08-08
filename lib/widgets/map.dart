import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'dart:async';

class Maps extends StatefulWidget {
  const Maps({Key? key, required this.title}) : super(key: key);

  final String title;

  @override // Fixed the typo from @overrides
  State<Maps> createState() => _MapsState();
}

class _MapsState extends State<Maps> {
  GoogleMapController? mapController;
  Location location = Location();

  // Default location (Philippines - you can change this)
  final LatLng _center = const LatLng(14.5995, 120.9842); // Manila, Philippines

  // Current user location
  LatLng? _currentLocation;

  // Markers for therapists/clinics
  Set<Marker> _markers = {};

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _addSampleMarkers();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
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

      // Move camera to user location
      if (mapController != null && _currentLocation != null) {
        mapController!.animateCamera(
          CameraUpdate.newLatLng(_currentLocation!),
        );
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
      _markers = {
        const Marker(
          markerId: MarkerId('clinic1'),
          position: LatLng(14.6091, 121.0223), // Quezon City
          infoWindow: InfoWindow(
            title: 'The Tiny House Therapy Center',
            snippet: 'Speech & Occupational Therapy',
          ),
        ),
        const Marker(
          markerId: MarkerId('clinic2'),
          position: LatLng(14.5547, 121.0244), // Makati
          infoWindow: InfoWindow(
            title: 'Child Development Center',
            snippet: 'Physical & Cognitive Therapy',
          ),
        ),
        const Marker(
          markerId: MarkerId('therapist1'),
          position: LatLng(14.5764, 121.0851), // Pasig
          infoWindow: InfoWindow(
            title: 'Dr. Maria Santos',
            snippet: 'Speech Therapist',
          ),
        ),
        const Marker(
          markerId: MarkerId('therapist2'),
          position: LatLng(14.6507, 121.0497), // San Juan
          infoWindow: InfoWindow(
            title: 'Dr. Juan Cruz',
            snippet: 'Occupational Therapist',
          ),
        ),
      };
    });
  }

  // Handle marker tap
  void _onMarkerTapped(MarkerId markerId) {
    print('Marker tapped: ${markerId.value}');

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
              _getMarkerTitle(markerId.value),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _getMarkerSubtitle(markerId.value),
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
                          content: Text(
                              'Calling ${_getMarkerTitle(markerId.value)}')),
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
                              'Getting directions to ${_getMarkerTitle(markerId.value)}')),
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
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color(0xFF006A5B),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _currentLocation ?? _center,
              zoom: 12.0,
            ),
            markers: _markers,
            onTap: (LatLng location) {
              print('Map tapped at: $location');
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            onMarkerTapped: _onMarkerTapped,
            mapType: MapType.normal,
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
                  print('Search for: $value');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Searching for: $value')),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getCurrentLocation,
        backgroundColor: const Color(0xFF006A5B),
        child: const Icon(Icons.my_location, color: Colors.white),
      ),
    );
  }
}
