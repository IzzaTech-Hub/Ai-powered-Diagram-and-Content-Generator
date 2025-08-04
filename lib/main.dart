// lib/main.dart

import 'package:flutter/material.dart';
import 'screens/content_generator_screen.dart';
// Removed Napkin AI Screen import
import 'screens/document_generator_screen.dart';
import 'constants/app_theme.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  ApiService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Content Generator Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getAppTheme(),
      home: const MainNavigationScreen(),
      routes: {
        '/content_generator': (context) => const ContentGeneratorScreen(),
        // Removed Napkin AI route
        // CORRECTED: No arguments passed to DocumentGeneratorScreen here
        '/document_generator': (context) => const DocumentGeneratorScreen(),
      },
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  // Lazy load screens to improve startup performance
  Widget _getScreen(int index) {
    switch (index) {
      case 0:
        return const ContentGeneratorScreen();
      case 1:
        return const DocumentGeneratorScreen();
      default:
        return const ContentGeneratorScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getScreen(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome),
            label: 'Content & Diagrams',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description),
            label: 'Documents',
          ),
        ],
      ),
    );
  }
}
