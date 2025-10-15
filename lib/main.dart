// lib/main.dart
import 'package:agendamientos/auth/auth_wrapper.dart';
import 'package:agendamientos/features/admin_dashboard/admin_dashboard.dart';
import 'package:flutter/material.dart';
import 'features/landing/landing_page.dart';
import 'auth/auth_page.dart';

import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:flutter_localizations/flutter_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TuEmpresa',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D0F1A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C3AED),
          brightness: Brightness.dark,
        ),
      ),

      // Localización al español
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', ''), // Español
      ],

      // En lugar de `initialRoute`, usamos `home` para que el AuthWrapper decida.
      home: const LandingPage(), // Siempre empezamos en la Landing

      // Mantenemos las rutas para la navegación manual
      routes: {
        // No necesitamos '/', ya que 'home' lo maneja.
        '/auth': (_) => const AuthPage(),
        '/dashboard': (_) => const AdminDashboardPage(),
        '/wrapper': (_) => const AuthWrapper(), // Ruta para el guardián
      },
    );
  }
}
