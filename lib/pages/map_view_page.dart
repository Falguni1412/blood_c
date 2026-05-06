import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

class MapViewPage extends StatefulWidget {
  const MapViewPage({super.key});

  @override
  State<MapViewPage> createState() => _MapViewPageState();
}

class _MapViewPageState extends State<MapViewPage> {
  final MapController _controller = MapController();

  // Default location (e.g., Mumbai) if permission denied or loading
  static const LatLng _center = LatLng(19.0760, 72.8777);
  LatLng _currentPosition = _center;
  bool _isLoading = true;
  final List<Marker> _markers = [];

  @override
  void initState() {
    super.initState();
    _initializeMapData();
  }

  Future<void> _initializeMapData() async {
    await _getUserLocation();
    _addBloodBankMarkers();
    await _fetchDonors();
  }

  Future<void> _fetchDonors() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'Donor')
          .get();

      final random = Random();
      
      setState(() {
        for (var doc in snapshot.docs) {
          final data = doc.data();
          final details = data['details'] ?? {};
          final name = data['fullName'] ?? 'Unknown Donor';
          final bloodGroup = details['bloodGroup'] ?? '?';
          
          final latOffset = (random.nextDouble() - 0.5) * 0.08;
          final lngOffset = (random.nextDouble() - 0.5) * 0.08;
          final donorLat = _currentPosition.latitude + latOffset;
          final donorLng = _currentPosition.longitude + lngOffset;

          _markers.add(
            Marker(
              point: LatLng(donorLat, donorLng),
              width: 80,
              height: 80,
              child: GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$name ($bloodGroup)'),
                      backgroundColor: const Color(0xFFAB0202),
                    ),
                  );
                },
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person_pin_circle, color: Color(0xFFAB0202), size: 40),
                  ],
                ),
              ),
            ),
          );
        }
      });
    } catch (e) {
      debugPrint('Error fetching donors: $e');
    }
  }

  Future<void> _getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled
      setState(() => _isLoading = false);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _isLoading = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });

      Future.delayed(const Duration(milliseconds: 100), () {
        _controller.move(_currentPosition, 14.0);
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _addBloodBankMarkers() {
    // Simulated data for nearby blood banks generated around current user location
    final random = Random();
    List<String> bankNames = [
      'City Life Blood Bank',
      'Red Cross Center',
      'St. Jude Hospital',
      'Hope Blood Center',
      'Unity Blood Bank'
    ];

    setState(() {
      for (int i = 0; i < bankNames.length; i++) {
        final latOffset = (random.nextDouble() - 0.5) * 0.08;
        final lngOffset = (random.nextDouble() - 0.5) * 0.08;
        
        _markers.add(
          Marker(
            point: LatLng(_currentPosition.latitude + latOffset, _currentPosition.longitude + lngOffset),
            width: 80,
            height: 80,
            child: GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${bankNames[i]} - Open Now'),
                    backgroundColor: Colors.blue.shade800,
                  ),
                );
              },
              child: const Icon(Icons.local_hospital, color: Colors.blue, size: 35),
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _controller,
            options: const MapOptions(
              initialCenter: _center,
              initialZoom: 12.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.blood.app',
              ),
              MarkerLayer(
                markers: [
                  ..._markers,
                  Marker(
                    point: _currentPosition,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.my_location, color: Colors.blue, size: 30),
                  ),
                ],
              ),
            ],
          ),

          // Custom Back Button
          Positioned(
            top: 50,
            left: 20,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(Icons.arrow_back, color: Colors.black),
              ),
            ),
          ),

          // Search Card Overlay
          Positioned(
            top: 50,
            left: 80,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Color(0xFFAB0202)),
                  const SizedBox(width: 10),
                  Text(
                    'Search blood banks...',
                    style: GoogleFonts.poppins(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Info Card
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFAB0202).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.location_on,
                          color: Color(0xFFAB0202),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nearby Blood Banks',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${_markers.length} centers found near you',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: _getUserLocation,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2D2D2D),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.my_location,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFFAB0202)),
              ),
            ),
        ],
      ),
    );
  }
}
