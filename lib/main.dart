import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/pathfinder_screen.dart';

void main() {
  runApp(const PathfinderApp());
}

class PathfinderApp extends StatelessWidget {
  const PathfinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "مسیر یاب",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: 'Vazir',
        scaffoldBackgroundColor: const Color(
          0xFF0B0C15,
        ), // Deep Space Black/Blue
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00F0FF), // Neon Cyan
          secondary: Color(0xFF7000FF), // Neon Purple
          surface: Color(0xFF151628), // Lighter Space Blue
          background: Color(0xFF0B0C15),
          error: Color(0xFFFF0055),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('fa', 'IR')],
      locale: const Locale('fa', 'IR'),
      home: const PathfinderScreen(),
    );
  }
}
