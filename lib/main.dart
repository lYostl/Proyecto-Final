import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'features/landing/landing_page.dart';
import 'auth/auth_page.dart';
import 'features/admin_dashboard/admin_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TuEmpresa',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D0F1A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C3AED),
          brightness: Brightness.dark,
        ),
      ),
      routes: {
        '/': (_) => const LandingPage(),
        '/auth': (_) => const AuthPage(), // Login/Registro
        '/dashboard': (_) => const AdminDashboardPage(), // Home admin
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
