import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; // Added for map functionality
import 'package:latlong2/latlong.dart'; // Added for LatLng

class MapScreen extends StatelessWidget {
  final String riverName;

  const MapScreen({super.key, required this.riverName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$riverName Map'),
      ),
      body: FlutterMap(
        options: MapOptions(
          center: LatLng(51.5074, -0.1278), // Coordinates for London
          zoom: 13.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: ['a', 'b', 'c'],
          ),
        ],
      ),
    );
  }
}
