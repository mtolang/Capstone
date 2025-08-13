# OpenStreetMap Implementation Guide

## Overview
Your Flutter app now uses OpenStreetMap (OSM) instead of Google Maps, providing a free, open-source mapping solution with powerful APIs.

## Key Components Implemented

### 1. **Map Display**
- **flutter_map**: Main mapping package for Flutter
- **OpenStreetMap tiles**: Free map tiles from OSM servers
- **No API key required**: Unlike Google Maps, OSM is completely free

### 2. **Location Services**
- **Current location**: GPS positioning using the `location` package
- **Location permissions**: Automatic permission handling
- **Real-time updates**: Live location tracking

### 3. **Search Functionality**
- **Nominatim API**: OpenStreetMap's free geocoding service
- **Place search**: Find hospitals, clinics, therapists, etc.
- **Bounded search**: Search within specific geographic areas
- **Country-specific**: Limited to Philippines (`countrycodes=ph`)

### 4. **Routing & Directions**
- **OSRM API**: Open Source Routing Machine for route calculation
- **Turn-by-turn directions**: Detailed routing information
- **Distance & duration**: Automatic calculation of travel time
- **Route visualization**: Blue polyline showing the path

## API Services Used

### 1. **Nominatim (Geocoding)**
```
https://nominatim.openstreetmap.org/search
```
- **Purpose**: Convert addresses to coordinates
- **Features**: Search for places, reverse geocoding
- **Rate limit**: 1 request per second
- **Free**: No API key required

### 2. **OSRM (Routing)**
```
https://router.project-osrm.org/route/v1/driving
```
- **Purpose**: Calculate routes between points
- **Features**: Driving, walking, cycling routes
- **Response**: GeoJSON route geometry
- **Free**: Public instance available

### 3. **Overpass API (Advanced Queries)**
```
https://overpass-api.de/api/interpreter
```
- **Purpose**: Query OSM database for specific features
- **Features**: Find hospitals, clinics, amenities
- **Example**: Find all hospitals within 5km radius

## Implementation Features

### Current `map.dart` Features:
✅ **Basic map display** with OSM tiles
✅ **Current location** with GPS positioning
✅ **Custom markers** for therapists and clinics
✅ **Search functionality** using Nominatim
✅ **Marker interaction** with bottom sheets
✅ **Location-based search** within geographic bounds

### Advanced `osm_map_example.dart` Features:
✅ **Advanced search** with multiple results
✅ **Route calculation** using OSRM
✅ **Route visualization** with polylines
✅ **Place details** with type and class information
✅ **Clear markers** and routes functionality
✅ **Distance and duration** display

## Code Examples

### Basic Map Setup
```dart
FlutterMap(
  mapController: mapController,
  options: MapOptions(
    initialCenter: LatLng(14.5995, 120.9842), // Manila
    initialZoom: 12.0,
  ),
  children: [
    TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.example.capstone_2',
    ),
    MarkerLayer(markers: _markers),
  ],
)
```

### Search Implementation
```dart
Future<void> _searchLocation(String query) async {
  final url = Uri.parse(
    'https://nominatim.openstreetmap.org/search?format=json&q=$query&limit=1&countrycodes=ph'
  );
  
  final response = await http.get(url);
  if (response.statusCode == 200) {
    final results = json.decode(response.body);
    // Process results...
  }
}
```

### Route Calculation
```dart
Future<void> _getRoute(LatLng destination) async {
  final url = Uri.parse(
    'https://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${destination.longitude},${destination.latitude}?overview=full&geometries=geojson'
  );
  
  final response = await http.get(url);
  // Process route geometry...
}
```

## Advantages of OpenStreetMap

### 1. **Cost-Effective**
- **Free to use**: No API keys or billing
- **No usage limits**: Unlimited map views
- **Open source**: Community-driven development

### 2. **Privacy-Friendly**
- **No tracking**: Users aren't tracked by Google
- **Data sovereignty**: Control over map data
- **GDPR compliant**: Better privacy compliance

### 3. **Customizable**
- **Map styles**: Multiple tile providers available
- **Custom tiles**: Host your own tile server
- **Offline support**: Cache tiles for offline use

### 4. **Rich Data**
- **Detailed POI data**: Comprehensive place information
- **Community updated**: Real-time updates from contributors
- **Global coverage**: Worldwide map data

## Performance Optimizations

### 1. **Tile Caching**
```dart
TileLayer(
  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  userAgentPackageName: 'com.example.capstone_2',
  maxZoom: 19,
  // Add caching options
)
```

### 2. **Marker Clustering**
For many markers, implement clustering to improve performance:
```dart
// Use flutter_map_marker_cluster package
MarkerClusterLayerWidget(
  options: MarkerClusterLayerOptions(
    markers: _markers,
  ),
)
```

### 3. **Rate Limiting**
Implement proper rate limiting for API calls:
```dart
// Add delays between requests
await Future.delayed(Duration(milliseconds: 1000));
```

## Alternative Tile Providers

You can use different map styles:

### 1. **CartoDB**
```dart
urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png'
```

### 2. **Stamen**
```dart
urlTemplate: 'https://stamen-tiles.a.ssl.fastly.net/terrain/{z}/{x}/{y}.png'
```

### 3. **Satellite**
```dart
urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
```

## Next Steps

### 1. **Find Nearby Therapists**
Use Overpass API to find real therapist locations:
```dart
// Query for healthcare facilities
String query = '[out:json][timeout:25];(node["amenity"="clinic"]["healthcare"="therapy"](around:5000,${lat},${lon}););out;';
```

### 2. **Offline Support**
Implement tile caching for offline use:
```dart
// Use flutter_map_tile_caching package
```

### 3. **Custom Icons**
Add custom marker icons for different therapist types:
```dart
Marker(
  point: location,
  child: Image.asset('assets/icons/therapist_icon.png'),
)
```

## Usage in Your App

The map is accessible from:
1. **Parent Dashboard**: Navigate to "Find Therapists"
2. **Therapist Dashboard**: View clinic locations
3. **Direct navigation**: Use `Maps(title: "Find Therapists")`

Your OpenStreetMap implementation is now fully functional and provides a robust, free alternative to Google Maps!
