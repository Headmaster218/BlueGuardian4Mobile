import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; // Added for map functionality
import 'package:latlong2/latlong.dart'; // Added for LatLng
import 'sensor_screen.dart'; // Import the new sensor screen

class MapScreen extends StatelessWidget {
  final String riverName;

  const MapScreen({super.key, required this.riverName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$riverName Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sensors),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SensorScreen()),
              );
            },
          ),
        ],
      ),
      body: FlutterMap(
        options: MapOptions(
          center: LatLng(51.55, -0.025), // Updated coordinates for the map center
          zoom: 13.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: ['a', 'b', 'c'],
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(51.5495, -0.0280), // Sensor location
                builder: (context) => Container(
                  width: 30, // Increased size for better visibility
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.5), // Red shadow
                        blurRadius: 10,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red, // Inner red core
                        border: Border.all(
                          color: Colors.red[900]!, // Dark red outer ring
                          width: 4,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
