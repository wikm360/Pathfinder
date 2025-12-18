import 'package:flutter/material.dart';
import 'screens/pathfinder_screen.dart';

void main() {
  runApp(const PathfinderApp());
}

class PathfinderApp extends StatelessWidget {
  const PathfinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مسیریاب هوشمند گراف',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
        fontFamily: 'Vazir',
        useMaterial3: true,
      ),
      home: const PathfinderScreen(),
    );
  }
}
