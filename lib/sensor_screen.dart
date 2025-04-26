import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Added for date formatting
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:convert'; // Added for JSON encoding and decoding

List<dynamic> sensorsData = [];

class SensorScreen extends StatefulWidget {
  const SensorScreen({super.key});

  @override
  State<SensorScreen> createState() => _SensorScreenState();
}

class _SensorScreenState extends State<SensorScreen> {
  final TextEditingController _dateController = TextEditingController();
  late MqttServerClient client;
  String _pageTitle = 'Sensor 1 History Data'; // Add a variable to track the page title

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now()); // Default to today's date
    _connectToMqtt();
  }

  Future<void> _connectToMqtt() async {
    client = MqttServerClient('127.0.0.1', 'flutter_client');
    client.logging(on: true);
    client.onConnected = _onConnected;
    client.onDisconnected = _onDisconnected;
    client.onSubscribed = _onSubscribed;

    // 等待连接成功后再订阅主题
    client.onConnected = () async {
      print('Connected to MQTT server');
      // client.subscribe('AQ/request', MqttQos.atMostOnce);
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
      final decodedPayload = jsonDecode(payload);
      sensorsData = decodedPayload;

      _refreshList(); // Refresh the list display
    } catch (e) {
      print('Failed to parse message: $e'); // Use a high log level for errors
    }
  }

  void _refreshList() {
    setState(() {
      // Trigger a UI rebuild to display the updated sensorsData
    });
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

  void _sendDate(String date) {
    final payload = jsonEncode({
      "start_time": date,
      "end_time": date,
    });
    final builder = MqttClientPayloadBuilder();
    builder.addString(payload);
    client.publishMessage('AQ/request', MqttQos.atMostOnce, builder.payload!);
    print('Sent payload: $payload to AQ/request');
  }

  void _showSensorChangeMessage(BuildContext context, String sensorName) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Center(
        child: AnimatedOpacity(
          opacity: 1.0,
          duration: const Duration(milliseconds: 300),
          child: Material(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Changed to $sensorName',
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 1), () {
      overlayEntry.remove();
    });
  }

  void _updatePageTitle(String sensorName) {
    setState(() {
      _pageTitle = sensorName; // Update the page title
    });
  }

  @override
  void dispose() {
    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      client.disconnect(); // Disconnect MQTT connection
      print('MQTT connection disconnected');
    }
    sensorsData.clear(); // Clear the sensorsData list
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitle), // Use the updated page title
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: TextField(
                      controller: _dateController,
                      decoration: const InputDecoration(
                        hintText: 'Enter date (YYYY-MM-DD)',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    _sendDate(_dateController.text);
                  },
                  child: const Text('Confirm'),
                ),
              ],
            ),
          ),
          Expanded(
            child: sensorsData.isEmpty
                ? const Center(child: Text('Please select a date for history'))
                : ListView.builder(
                    itemCount: sensorsData.length,
                    itemBuilder: (context, index) {
                      final data = sensorsData[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const GraphScreen()), // Navigate to graph screen
                          );
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 1.0),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Timestamp: ${data[0]}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Dissolved Oxygen: ${data[1]}'),
                                          Text('TDS: ${data[2]}'),
                                          Text('Turbidity: ${data[3]}'),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('pH: ${data[4]}'),
                                          Text('Temperature: ${data[5]}'),
                                          Text('Coliform: ${data[6]}'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: MediaQuery.of(context).size.width / 6, // Make height equal to width for square buttons
                  child: ElevatedButton(
                    onPressed: () {
                      _updatePageTitle('Sensor 1 History Data'); // Update title to Sensor 1
                      _showSensorChangeMessage(context, 'Sensor 1');
                    },
                    child: const Text(
                      'Sensor 1',
                      style: TextStyle(fontSize: 24), // Increased font size
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SizedBox(
                  height: MediaQuery.of(context).size.width / 6, // Make height equal to width for square buttons
                  child: ElevatedButton(
                    onPressed: () {
                      _updatePageTitle('Sensor 2 History Data'); // Update title to Sensor 2
                      _showSensorChangeMessage(context, 'Sensor 2');
                    },
                    child: const Text(
                      'Sensor 2',
                      style: TextStyle(fontSize: 24), // Increased font size
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SizedBox(
                  height: MediaQuery.of(context).size.width / 6, // Make height equal to width for square buttons
                  child: ElevatedButton(
                    onPressed: () {
                      _updatePageTitle('Sensor 3 History Data'); // Update title to Sensor 3
                      _showSensorChangeMessage(context, 'Sensor 3');
                    },
                    child: const Text(
                      'Sensor 3',
                      style: TextStyle(fontSize: 24), // Increased font size
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
