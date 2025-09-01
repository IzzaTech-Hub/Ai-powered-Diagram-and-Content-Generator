// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:my_flutter_app/widgets/connection_test_widget.dart';
import 'screens/content_generator_screen.dart';
import 'screens/document_generator_screen.dart';
import 'constants/app_theme.dart';
import 'services/api_service.dart';
import 'services/config_service.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase Core
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Initialize Firebase Analytics
  FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  
  // Log app_open event
  await analytics.logAppOpen();

  // Initialize configuration service first
  await ConfigService().initialize();

  // Then initialize API service with config
  ApiService.initialize();

  runApp(MyApp(analytics: analytics));
}

class MyApp extends StatelessWidget {
  final FirebaseAnalytics analytics;
  
  const MyApp({super.key, required this.analytics});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Content Generator Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getAppTheme(),
      home: const MainNavigationScreen(),
      navigatorObservers: [
        FirebaseAnalyticsObserver(analytics: analytics),
      ],
      routes: {
        '/content_generator': (context) => const ContentGeneratorScreen(),
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
      appBar: AppBar(
        title: const Text('AI Content Generator Pro'),
        actions: [
          IconButton(
            icon: const Icon(Icons.network_check),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ConnectionTestWidget(),
                ),
              );
            },
            tooltip: 'Test Connection',
          ),
        ],
      ),
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

