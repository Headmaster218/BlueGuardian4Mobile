import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Added for date formatting
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:fl_chart/fl_chart.dart'; // Add this dependency for charts
import 'dart:convert'; // Added for JSON encoding and decoding

List<dynamic> sensorsData = [];

class GraphScreen extends StatefulWidget {
  const GraphScreen({super.key});

  @override
  State<GraphScreen> createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<DateTime> _timePoints = [];
  late DateTime _currentDateTime;
  late MqttServerClient client;
  String _pageTitle = 'Sensor 1 Graphic view'; // Add a variable to track the page title

  @override
  void initState() {
    super.initState();
    _currentDateTime = _getRoundedCurrentHour(); // Start with the rounded current hour
    _generateTimePoints(); // Generate all time points for the past week
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent); // Remove extra offset
    });
    _connectToMqtt();
  }

  Future<void> _connectToMqtt() async {
    client = MqttServerClient('127.0.0.1', 'flutter_client');
    client.logging(on: true);
    client.onConnected = _onConnected;

    // 等待连接成功后再订阅主题
    client.onConnected = () async {
      client.subscribe('AQ/response', MqttQos.atMostOnce);
      client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
        final MqttPublishMessage message = messages[0].payload as MqttPublishMessage;
        final payload = MqttPublishPayload.bytesToStringAsString(message.payload.message);
        _onMessage(payload); // 处理接收到的消息
      });
      _sendDate(DateFormat('yyyy-MM-dd').format(_currentDateTime));
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
      sensorsData = jsonDecode(payload);
    } catch (e) {
      print('Failed to parse message: $e'); // Use a high log level for errors
    }
  }

  void _onConnected() {
    print('Connected to MQTT server');
    client.subscribe('AQ/request', MqttQos.atMostOnce);
    client.subscribe('AQ/response', MqttQos.atMostOnce);
    print('Subscribed to topics: AQ/send, AQ/request, AQ/response');
  }

  void _sendDate(String date) {
    final startDate = DateFormat('yyyy-MM-dd').format(DateTime.parse(date).subtract(const Duration(days: 7)));
    final payload = jsonEncode({
      "start_time": startDate,
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

  DateTime _getRoundedCurrentHour() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, now.hour); // Round down to the nearest hour
  }

  void _generateTimePoints() {
    // Generate time points for the past 7 days at hourly intervals
    for (int i = 7 * 24; i >= 0; i--) {
      _timePoints.add(_currentDateTime.subtract(Duration(hours: i)));
    }
  }

  double _getCenterOffset() {
    // Calculate the offset to center the first or last item
    return MediaQuery.of(context).size.width / 2 - 68 / 2; // 68 is the width of each time slot
  }

  String _formatDate(DateTime dateTime) {
    return DateFormat('MM-dd').format(dateTime); // Format for the date
  }

  String _formatTime(DateTime dateTime) {
    return DateFormat('HH:00').format(dateTime); // Format for the time
  }

  List<FlSpot> _generateChartData(int index) {
    // Generate chart data for the given index from sensorsData
    List<FlSpot> chartData = [];
    if (sensorsData.isEmpty) return chartData;

    // Find the closest index in sensorsData to the current time
    int closestIndex = sensorsData.indexWhere((data) {
      final time = DateTime.parse(data[0]);
      return time.isAtSameMomentAs(_currentDateTime);
    });

    // If no exact match, find the nearest index
    if (closestIndex == -1) {
      closestIndex = sensorsData.indexWhere((data) {
        final time = DateTime.parse(data[0]);
        return time.isAfter(_currentDateTime);
      });
      if (closestIndex == -1) closestIndex = sensorsData.length - 1; // Use the last index if no match
    }

    // Extract seven data points centered around the closest index
    int start = (closestIndex - 3).clamp(0, sensorsData.length - 1);
    int end = (closestIndex + 3).clamp(0, sensorsData.length - 1);

    for (int i = start; i <= end; i++) {
      final time = DateTime.parse(sensorsData[i][0]); // First item is the timestamp
      final value = sensorsData[i][index + 1]; // Subsequent items are sensor values
      chartData.add(FlSpot(time.millisecondsSinceEpoch.toDouble(), value.toDouble()));
    }

    return chartData;
  }

  void _onScrollEnd() {
    final centerOffset = _scrollController.offset + MediaQuery.of(context).size.width / 2 - 68 * 3.4;
    final closestIndex = (centerOffset / 68).round();

    if (closestIndex >= 0 && closestIndex < _timePoints.length) {
      setState(() {
        _currentDateTime = _timePoints[closestIndex];
      });

      // 🔥 核心改动，加一个小延迟再 animateTo
      Future.delayed(const Duration(milliseconds: 50), () {
        final targetOffset = closestIndex * 68 - MediaQuery.of(context).size.width / 2 + 68 * 3.4;
        _scrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

double _xOffset = 0.0; // Add a variable to track the scroll offset

void _onScrollUpdate() {
  final screenWidth = MediaQuery.of(context).size.width;
  final itemWidth = 68.0; // 每个时间格子宽度（你的设定）

  final centerOffset = _scrollController.offset + screenWidth / 2 - itemWidth * 3.4;
  final closestIndex = (centerOffset / itemWidth).round();

  if (closestIndex >= 0 && closestIndex < _timePoints.length) {
    setState(() {
      _currentDateTime = _timePoints[closestIndex];
      _xOffset = (centerOffset - (closestIndex * itemWidth)) / itemWidth * 3600000; 
      // 说明：一小时3600000毫秒，线性比例偏移
    });
  }
}



  Widget _buildLineChart(String title, List<FlSpot> dataPoints) {
    if (dataPoints.isEmpty) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: Text(
              'No data available',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
        ),
      );
    }

    // Calculate minY and maxY with 20% padding
    final double minY = dataPoints.map((e) => e.y).reduce((a, b) => a < b ? a : b);
    final double maxY = dataPoints.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    final double padding = (maxY - minY) * 0.2; // 20% of the range

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minY: minY - padding, // Apply dynamic padding to the lower bound
                  maxY: maxY + padding, // Apply dynamic padding to the upper bound
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: SideTitles(showTitles: true), // Show left axis titles
                    bottomTitles: SideTitles(showTitles: false), // Hide bottom axis titles
                    topTitles: SideTitles(showTitles: false), // Hide top axis titles
                    rightTitles: SideTitles(showTitles: false), // Hide right axis titles
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: dataPoints,
                      isCurved: true,
                      colors: [Colors.blue],
                      barWidth: 4,
                      isStrokeCapRound: true,
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      client.disconnect(); // Disconnect MQTT connection
      print('MQTT connection disconnected');
    }
    sensorsData.clear(); // Clear the sensors data
    _scrollController.dispose();
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
          // Time bar with pre-generated time points
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0), // 只留左右，不留上下！
            child: NotificationListener<ScrollNotification>(
  onNotification: (notification) {
    if (notification is ScrollUpdateNotification) {
      _onScrollUpdate();
    } else if (notification is ScrollEndNotification) {
      _onScrollEnd();
    }
    return true;
  },

              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Time line
                  SizedBox(
                    height: 50, // Increased height to accommodate arrows
                    child: ListView.builder(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      itemCount: _timePoints.length,
                      padding: EdgeInsets.symmetric(horizontal: _getCenterOffset()), // Ensure proper centering
                      itemBuilder: (context, index) {
                        final dateTime = _timePoints[index];
                        final isCurrent = dateTime.isAtSameMomentAs(_currentDateTime);
                        return Container(
                          width: 60,
                          margin: const EdgeInsets.symmetric(horizontal: 4.0),
                          decoration: BoxDecoration(
                            color: isCurrent ? Colors.blue[50] : Colors.white,
                            border: Border.all(
                              color: isCurrent ? Colors.blue : Colors.grey,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _formatDate(dateTime),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                  color: isCurrent ? Colors.blue : Colors.black,
                                ),
                              ),
                              Text(
                                _formatTime(dateTime),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                  color: isCurrent ? Colors.blue : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.translate(
                        offset: const Offset(0, 13), // 上移一点
                        child: Icon(Icons.arrow_drop_down, color: Colors.red, size: 30),
                      ),
                      Container(
                        width: 2,
                        height: 55,
                        color: Colors.red,
                      ),
                      Transform.translate(
                        offset: const Offset(0, -13), // 下移一点
                        child: Icon(Icons.arrow_drop_up, color: Colors.red, size: 30),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                _buildLineChart('Dissolved Oxygen (DO)', _generateChartData(0)),
                _buildLineChart('Total Dissolved Solids (TDS)', _generateChartData(1)),
                _buildLineChart('Turbidity (Turb)', _generateChartData(2)),
                _buildLineChart('pH Level', _generateChartData(3)),
                _buildLineChart('Temperature (Temp)', _generateChartData(4)),
                _buildLineChart('Coliform (Coli)', _generateChartData(5)),
              ],
            ),
          ),
          // Sensor buttons at the bottom
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: MediaQuery.of(context).size.width / 6,
                  child: ElevatedButton(
                    onPressed: () {
                      _showSensorChangeMessage(context, 'Sensor 1'); // Show sensor change message
                      _updatePageTitle('Sensor 1 Graphic view'); // Update the page title
                    },
                    child: const Text(
                      'Sensor 1',
                      style: TextStyle(fontSize: 24),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SizedBox(
                  height: MediaQuery.of(context).size.width / 6,
                  child: ElevatedButton(
                    onPressed: () {
                      _showSensorChangeMessage(context, 'Sensor 2'); // Show sensor change message
                      _updatePageTitle('Sensor 2 Graphic view'); // Update the page title
                    },
                    child: const Text(
                      'Sensor 2',
                      style: TextStyle(fontSize: 24),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SizedBox(
                  height: MediaQuery.of(context).size.width / 6,
                  child: ElevatedButton(
                    onPressed: () {
                      _showSensorChangeMessage(context, 'Sensor 3'); // Show sensor change message
                      _updatePageTitle('Sensor 3 Graphic view'); // Update the page title
                    },
                    child: const Text(
                      'Sensor 3',
                      style: TextStyle(fontSize: 24),
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
