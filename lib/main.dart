// Filename: main.dart
// Purpose: Main entry point for Infinitum Down Detector application
// Author: Kevin Doyle Jr. / Infinitum Imagery LLC
// Last Modified: 2025-01-27
// Dependencies: Flutter SDK, Firebase Core, Provider
// Platform Compatibility: Web, iOS, Android

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'firebase_options.dart';
import 'core/logger.dart';
import 'services/health_check_service.dart';
import 'services/report_service.dart';
import 'providers/service_status_provider.dart';
import 'screens/status_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // MARK: - Firebase Initialization
  // Initialize Firebase with platform-specific options
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    Logger.logInfo('Firebase initialized successfully', 'main.dart', 'main');
  } catch (e) {
    Logger.logError('Firebase initialization failed: $e', 'main.dart', 'main', e);
    Logger.logInfo('Continuing without Firebase - reports will be logged only', 'main.dart', 'main');
  }
  
  runApp(const InfinitumDownDetectorApp());
}

class InfinitumDownDetectorApp extends StatelessWidget {
  const InfinitumDownDetectorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ServiceStatusProvider()),
        Provider(create: (_) => HealthCheckService()),
        Provider(create: (_) => ReportService()),
      ],
      child: MaterialApp(
        title: 'Infinitum Down Detector',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6366F1),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          textTheme: GoogleFonts.interTextTheme(),
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6366F1),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        ),
        themeMode: ThemeMode.system,
        home: const StatusPage(),
      ),
    );
  }
}

// Suggestions For Features and Additions Later:
// - Add push notifications for service outages
// - Implement historical status data and charts
// - Add custom alert thresholds per service
// - Export status reports to PDF/CSV
// - Add service grouping and categorization
// - Implement webhook notifications
// - Add maintenance mode scheduling
// - Create API endpoints for status data
// - Add multi-language support
// - Implement service dependency mapping

