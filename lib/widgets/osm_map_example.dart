import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OSMMapExample extends StatefulWidget {
  const OSMMapExample({Key? key}) : super(key: key);

  @override
  State<OSMMapExample> createState() => _OSMMapExampleState();
}

class _OSMMapExampleState extends State<OSMMapExample> {
  final MapController mapController = MapController();
  Location location = Location();

  LatLng? _currentLocation;
  List<Marker> _markers = [];
  List<LatLng> _routePoints = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationData locationData = await location.getLocation();
      setState(() {
        _currentLocation =
            LatLng(locationData.latitude!, locationData.longitude!);
      });
      mapController.move(_currentLocation!, 15.0);
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  // Search for places using Nominatim API
  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty || _currentLocation == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Search near current location
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/search?format=json&q=$query&limit=10&countrycodes=ph&viewbox=${_currentLocation!.longitude - 0.1},${_currentLocation!.latitude - 0.1},${_currentLocation!.longitude + 0.1},${_currentLocation!.latitude + 0.1}&bounded=1');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> results = json.decode(response.body);

        List<Marker> newMarkers = [];

        for (var result in results) {
          final double lat = double.parse(result['lat']);
          final double lon = double.parse(result['lon']);

          newMarkers.add(
            Marker(
              point: LatLng(lat, lon),
              width: 40,
              height: 40,
              child: GestureDetector(
                onTap: () => _showPlaceDetails(result),
                child: const Icon(
                  Icons.place,
                  color: Colors.red,
                  size: 40,
                ),
              ),
            ),
          );
        }

        setState(() {
          _markers = newMarkers;
          _isLoading = false;
        });

        if (results.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Found ${results.length} places')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No places found')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Search error: $e')),
      );
    }
  }

  // Show place details
  void _showPlaceDetails(Map<String, dynamic> place) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              place['display_name'] ?? 'Unknown Place',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Type: ${place['type'] ?? 'Unknown'}'),
            Text('Class: ${place['class'] ?? 'Unknown'}'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _getRoute(LatLng(double.parse(place['lat']),
                        double.parse(place['lon'])));
                  },
                  icon: const Icon(Icons.directions),
                  label: const Text('Get Route'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    mapController.move(
                      LatLng(double.parse(place['lat']),
                          double.parse(place['lon'])),
                      16.0,
                    );
                  },
                  icon: const Icon(Icons.zoom_in),
                  label: const Text('Zoom To'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Get route using OSRM (Open Source Routing Machine)
  Future<void> _getRoute(LatLng destination) async {
    if (_currentLocation == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse(
          'https://router.project-osrm.org/route/v1/driving/${_currentLocation!.longitude},${_currentLocation!.latitude};${destination.longitude},${destination.latitude}?overview=full&geometries=geojson');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry']['coordinates'];

          List<LatLng> routePoints = [];
          for (var point in geometry) {
            routePoints.add(
                LatLng(point[1], point[0])); // Note: [lon, lat] to [lat, lon]
          }

          setState(() {
            _routePoints = routePoints;
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Route found: ${(route['duration'] / 60).toStringAsFixed(1)} minutes, ${(route['distance'] / 1000).toStringAsFixed(1)} km'),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Route error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OpenStreetMap Example'),
        backgroundColor: const Color(0xFF006A5B),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter:
                  _currentLocation ?? const LatLng(14.5995, 120.9842),
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.capstone_2',
              ),
              // Route line
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      color: Colors.blue,
                      strokeWidth: 4.0,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  ..._markers,
                  // Current location marker
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

          // Search bar
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
                  hintText: 'Search places (hospitals, clinics, etc.)',
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search, color: Color(0xFF006A5B)),
                ),
                onSubmitted: _searchPlaces,
              ),
            ),
          ),

          // Loading indicator
          if (_isLoading)
            const Positioned(
              top: 80,
              right: 16,
              child: CircularProgressIndicator(
                backgroundColor: Colors.white,
              ),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "clear",
            onPressed: () {
              setState(() {
                _markers.clear();
                _routePoints.clear();
              });
            },
            backgroundColor: Colors.red,
            child: const Icon(Icons.clear, color: Colors.white),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: "location",
            onPressed: _getCurrentLocation,
            backgroundColor: const Color(0xFF006A5B),
            child: const Icon(Icons.my_location, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
