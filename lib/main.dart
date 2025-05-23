import 'package:flutter/material.dart';
import 'dart:async'; // Added for Timer
import 'package:flutter/widgets.dart'; // Added for Navigator
import 'package:shared_preferences/shared_preferences.dart'; // Added for SharedPreferences
import 'map_screen.dart'; // Import the new map screen
import 'settings_page.dart'; // Import the new settings page

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeDefaultSettings(); // Initialize default settings
  runApp(const MyApp());
}

Future<void> _initializeDefaultSettings() async {
  final prefs = await SharedPreferences.getInstance();
  if (!prefs.containsKey('mqtt_ip')) {
    await prefs.setString('mqtt_ip', '127.0.0.1'); // Default IP
  }
  if (!prefs.containsKey('mqtt_port')) {
    await prefs.setString('mqtt_port', '1883'); // Default Port
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BlueGuardian',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const SplashScreen(), // Updated to use SplashScreen
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();

    Timer(const Duration(seconds: 2), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MyHomePage(title: 'BlueGuardian Home Page')),
      );
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: Image.asset(
              'assets/Startpage.png',
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover, // Ensures the image covers the entire screen
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.25, // Position text towards the upper part of the screen
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  const Text(
                    'BlueGuardian',
                    style: TextStyle(
                      fontSize: 50,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          blurRadius: 10.0,
                          color: Colors.black54,
                          offset: Offset(2.0, 2.0),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Protecting Our Waters',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w300,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: GridView.count(
          crossAxisCount: 2,
          children: <Widget>[
            _buildGridItem('Thames River', 'assets/Thames.png'),
            _buildGridItem('Hammersmith River', 'assets/Hammersmith.png'),
            _buildGridItem('Add More River', null, isAddMore: true),
          ],
        ),
      ),
    );
  }

  Widget _buildGridItem(String name, String? imagePath, {bool isAddMore = false}) {
    return GestureDetector(
      onTap: () {
        if (isAddMore) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const ComingSoonScreen()),
          );
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => MapScreen(riverName: name)),
          );
        }
      },
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  image: imagePath != null
                      ? DecorationImage(
                          image: AssetImage(imagePath),
                          fit: BoxFit.cover,
                        )
                      : null,
                  color: isAddMore ? Colors.grey[300] : null,
                ),
                child: isAddMore
                    ? const Icon(
                        Icons.add,
                        size: 70,
                        color: Colors.black,
                      )
                    : null,
              ),
            ),
            Expanded(
              flex: 1,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
                ),
                alignment: Alignment.center,
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coming Soon'),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/commingsoon.png'), // Add a background image
                fit: BoxFit.cover,
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.construction,
                  size: 100,
                  color: Colors.orange,
                ),
                const SizedBox(height: 20),
                Column(
                  children: [
                  const Text(
                    'Coming Soon!',
                    style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                      blurRadius: 15.0,
                      color: Colors.black87,
                      offset: Offset(3.0, 3.0),
                      ),
                    ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Text(
                    'We are working hard to bring you new features. Stay tuned!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w300,
                      color: Colors.green,
                    ),
                    textAlign: TextAlign.center,
                    ),
                  ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
