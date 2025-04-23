import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Added for date formatting

class SensorScreen extends StatefulWidget {
  const SensorScreen({super.key});

  @override
  State<SensorScreen> createState() => _SensorScreenState();
}

class _SensorScreenState extends State<SensorScreen> {
  final TextEditingController _dateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now()); // Default to today's date
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sensor Data'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // Reduced vertical padding
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40, // Reduced height of the input field
                    child: TextField(
                      controller: _dateController,
                      decoration: const InputDecoration(
                        hintText: 'Enter date (YYYY-MM-DD)',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0), // Adjusted content padding
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    // Add functionality for confirming the date
                    print('Selected date: ${_dateController.text}');
                  },
                  child: const Text('Confirm'),
                ),
              ],
            ),
          ),
          const Spacer(), // Push buttons to the bottom
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: MediaQuery.of(context).size.width / 4, // Make height equal to width for square buttons
                  child: ElevatedButton(
                    onPressed: () {
                      // Add functionality for Sensor 1
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
                  height: MediaQuery.of(context).size.width / 4, // Make height equal to width for square buttons
                  child: ElevatedButton(
                    onPressed: () {
                      // Add functionality for Sensor 2
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
                  height: MediaQuery.of(context).size.width / 4, // Make height equal to width for square buttons
                  child: ElevatedButton(
                    onPressed: () {
                      // Add functionality for Sensor 3
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
