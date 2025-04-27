import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _ipController.text = prefs.getString('mqtt_ip') ?? '';
      _portController.text = prefs.getString('mqtt_port') ?? '';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mqtt_ip', _ipController.text);
    await prefs.setString('mqtt_port', _portController.text);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved!'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _testConnection() async {
    final ip = _ipController.text;
    final port = int.tryParse(_portController.text);

    if (ip.isEmpty || port == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid IP and Port'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    final client = MqttServerClient(ip, '');
    client.port = port;
    client.logging(on: false);
    client.keepAlivePeriod = 20;
    client.onDisconnected = () {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Disconnected from MQTT server'),
          duration: Duration(seconds: 1),
        ),
      );
    };

    try {
      client.connectionMessage = MqttConnectMessage()
          .withClientIdentifier('BlueGuardianClient')
          .startClean();
      client.setProtocolV311();
      client.connectTimeoutPeriod = 2; // Set timeout to 3 seconds

      // Wrap the connection attempt in a timeout
      await client.connect().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          throw Exception('Connection attempt timed out');
        },
      );

      if (client.connectionStatus?.state == MqttConnectionState.connected) {
        final builder = MqttClientPayloadBuilder();
        builder.addString('Test message');
        client.publishMessage('AQ/send', MqttQos.atLeastOnce, builder.payload!);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully connected to $ip:$port and sent test message'),
            duration: const Duration(seconds: 1),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect to $ip:$port'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (e.toString().contains('timed out')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connection timed out. Please try again.'),
            duration: Duration(seconds: 1),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } finally {
      client.disconnect();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _ipController,
              decoration: const InputDecoration(labelText: 'MQTT IP'),
            ),
            TextField(
              controller: _portController,
              decoration: const InputDecoration(labelText: 'MQTT Port'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveSettings,
              child: const Text('Save'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _testConnection,
              child: const Text('Test Connection'),
            ),
          ],
        ),
      ),
    );
  }
}
