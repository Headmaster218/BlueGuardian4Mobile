import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; // Added for map functionality
import 'package:latlong2/latlong.dart'; // Added for LatLng
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart'; // Added for marker popups
import 'package:shared_preferences/shared_preferences.dart';
import 'sensor_screen.dart'; // Import the new sensor screen
import 'package:mqtt_client/mqtt_client.dart'; // Added for MQTT
import 'package:mqtt_client/mqtt_server_client.dart'; // Added for MQTT server client
import 'dart:convert'; // Added for JSON encoding and decoding

class MapScreen extends StatefulWidget {
  final String riverName;

  const MapScreen({super.key, required this.riverName});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late MqttServerClient client;
  final PopupController popupController = PopupController();
  final Map<String, dynamic> sensorData = {}; // Store real-time data for each marker
  Marker? activeMarker; // Track the currently active marker

  @override
  void initState() {
    super.initState();
    _connectToMqtt();
  }

  Future<void> _connectToMqtt() async {
    final prefs = await SharedPreferences.getInstance();
    final mqttIp = prefs.getString('mqtt_ip')!;
    final mqttPort = int.parse(prefs.getString('mqtt_port')!);

    client = MqttServerClient(mqttIp, 'flutter_client');
    client.port = mqttPort;
    client.logging(on: true);
    client.onConnected = _onConnected;
    client.onDisconnected = _onDisconnected;
    client.onSubscribed = _onSubscribed;

    // 等待连接成功后再订阅主题
    client.onConnected = () async {
      print('Connected to MQTT server');
      client.subscribe('AQ/send', MqttQos.atMostOnce);
      client.subscribe('AQ/request', MqttQos.atMostOnce);
      client.subscribe('AQ/response', MqttQos.atMostOnce);
      print('Subscribed to topics: AQ/send, AQ/request, AQ/response');
      client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
        final MqttPublishMessage message = messages[0].payload as MqttPublishMessage;
        final payload = MqttPublishPayload.bytesToStringAsString(message.payload.message);
        print('Received message: $payload');
        _onMessage(payload); // 处理接收到的消息
      });
    };

    try {
      await client.connect();
    } catch (e) {
      print('MQTT connection failed: $e');
      client.disconnect();
    }
  }

  void _onMessage(String payload) {
    try {
      final parts = jsonDecode(payload) as List<dynamic>;
      final data = {
        'timestamp': parts[0],
        'do': parts[1],
        'tds': parts[2],
        'turb': parts[3],
        'ph': parts[4],
        'temp': parts[5],
        'coli': parts[6],
      };

      setState(() {
        sensorData.addAll(data); // Update sensor data
      });

      print('Updated data $data');
    } catch (e) {
      print('Failed to parse message: $e');
    }
  }

  void _onConnected() {
    print('Connected to MQTT server');
    client.subscribe('AQ/send', MqttQos.atMostOnce);
    client.subscribe('AQ/request', MqttQos.atMostOnce);
    client.subscribe('AQ/response', MqttQos.atMostOnce);
    print('Subscribed to topics: AQ/send, AQ/request, AQ/response');
  }

  void _onDisconnected() {
    print('Disconnected from MQTT server');
  }

  void _onSubscribed(String topic) {
    print('Subscribed to topic: $topic');
  }

  @override
  void dispose() {
    client.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.riverName} Map'),
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
      body: GestureDetector(
        onTap: () {
          setState(() {
            popupController.hideAllPopups(); // Close all popups when the map is tapped
            activeMarker = null;
          });
        },
        child: FlutterMap(
          options: MapOptions(
            center: LatLng(51.5495, -0.0280), // Updated coordinates for the map center
            zoom: 14.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: ['a', 'b', 'c'],
            ),
            PopupMarkerLayerWidget(
              options: PopupMarkerLayerOptions(
                popupController: popupController,
                markers: [
                  Marker(
                    point: LatLng(51.5495, -0.0280), // Sensor 1 location
                    builder: (context) => GestureDetector(
                      onTap: () {
                        final marker = Marker(
                          point: LatLng(51.5495, -0.0280),
                          builder: (_) => const SizedBox(),
                        );
                        setState(() {
                          if (activeMarker == marker) {
                            popupController.hideAllPopups(); // Hide popup if already active
                            activeMarker = null;
                          } else {
                            popupController.hideAllPopups(); // Hide any other active popup
                            popupController.togglePopup(marker); // Show this popup
                            activeMarker = marker;
                          }
                        });
                      },
                      child: Container(
                        width: 30,
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
                  ),
                  Marker(
                    point: LatLng(51.55500, -0.0344), // Sensor 2 location
                    builder: (context) => GestureDetector(
                      onTap: () {
                        final marker = Marker(
                          point: LatLng(51.55500, -0.0344),
                          builder: (_) => const SizedBox(),
                        );
                        setState(() {
                          if (activeMarker == marker) {
                            popupController.hideAllPopups(); // Hide popup if already active
                            activeMarker = null;
                          } else {
                            popupController.hideAllPopups(); // Hide any other active popup
                            popupController.togglePopup(marker); // Show this popup
                            activeMarker = marker;
                          }
                        });
                      },
                      child: Container(
                        width: 30,
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
                  ),
                  Marker(
                    point: LatLng(51.54190, -0.02150), // Sensor 3 location
                    builder: (context) => GestureDetector(
                      onTap: () {
                        final marker = Marker(
                          point: LatLng(51.54190, -0.02150),
                          builder: (_) => const SizedBox(),
                        );
                        setState(() {
                          if (activeMarker == marker) {
                            popupController.hideAllPopups(); // Hide popup if already active
                            activeMarker = null;
                          } else {
                            popupController.hideAllPopups(); // Hide any other active popup
                            popupController.togglePopup(marker); // Show this popup
                            activeMarker = marker;
                          }
                        });
                      },
                      child: Container(
                        width: 30,
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
                  ),
                ],
                popupBuilder: (context, marker) {
                  return ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 250), // Limit the popup width
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start, // Align content to the left
                          mainAxisSize: MainAxisSize.min,
                            children: [
                            const Center( // Center-align the title
                              child: Text(
                              'Sensor Data',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('           ${sensorData['timestamp'] ?? 'N/A'}'),
                            Text('D.O.:    ${sensorData['do'] ?? 'N/A'} mg/L'),
                            Text('TDS:    ${sensorData['tds'] ?? 'N/A'} ppm'),
                            Text('Turb:    ${sensorData['turb'] ?? 'N/A'} NTU'),
                            Text('pH:       ${sensorData['ph'] ?? 'N/A'}'),
                            Text('Temp:  ${sensorData['temp'] ?? 'N/A'} °C'),
                            Text('Coli:     ${sensorData['coli'] ?? 'N/A'} CFU/100mL'),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
