import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Added for date formatting
import 'package:fl_chart/fl_chart.dart'; // Add this dependency for charts

class GraphScreen extends StatefulWidget {
  const GraphScreen({super.key});

  @override
  State<GraphScreen> createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<DateTime> _timePoints = [];
  late DateTime _currentDateTime;

  @override
  void initState() {
    super.initState();
    _currentDateTime = _getRoundedCurrentHour(); // Start with the rounded current hour
    _generateTimePoints(); // Generate all time points for the past week
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent); // Remove extra offset
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

  Widget _buildLineChart(String title, List<FlSpot> dataPoints) {
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
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: SideTitles(showTitles: true), // Use SideTitles directly
                    bottomTitles: SideTitles(showTitles: false), // Hide horizontal axis titles
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

  List<FlSpot> _generateDummyData() {
    // Generate 5 dummy data points for demonstration
    return List.generate(5, (index) => FlSpot(index.toDouble(), (index * 2).toDouble()));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Graph View'),
      ),
      body: Column(
        children: [
          // Time bar with pre-generated time points
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0), // 只留左右，不留上下！
            child: NotificationListener<ScrollEndNotification>(
              onNotification: (notification) {
                _onScrollEnd(); // Trigger selection when scrolling stops
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
                _buildLineChart('Dissolved Oxygen (DO)', _generateDummyData()),
                _buildLineChart('Total Dissolved Solids (TDS)', _generateDummyData()),
                _buildLineChart('Turbidity (Turb)', _generateDummyData()),
                _buildLineChart('pH Level', _generateDummyData()),
                _buildLineChart('Temperature (Temp)', _generateDummyData()),
                _buildLineChart('Coliform (Coli)', _generateDummyData()),
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
                      print('Sensor 1 selected');
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
                      print('Sensor 2 selected');
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
                      print('Sensor 3 selected');
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
