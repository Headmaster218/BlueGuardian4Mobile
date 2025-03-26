import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: imagePath != null
                ? DecorationImage(
                    image: AssetImage(imagePath),
                    fit: BoxFit.cover,
                  )
                : null,
            color: isAddMore ? Colors.grey[300] : null,
          ),
          child: isAddMore
              ? Icon(
                  Icons.add,
                  size: 50,
                  color: Colors.black,
                )
              : null,
        ),
        SizedBox(height: 8),
        Text(name),
      ],
    );
  }
}
