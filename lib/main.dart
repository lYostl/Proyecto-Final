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
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', ''), // Español
      ],

      // --- CAMBIO CLAVE ---
      // Ahora el AuthWrapper es el hogar. Él decidirá si mostrar
      // la LandingPage o el AdminDashboard.
      home: const AuthWrapper(),

      // Mantenemos las rutas para navegación interna si es necesario,
      // pero la lógica principal la maneja el home.
      routes: {
        // La LandingPage ahora se muestra a través del AuthWrapper
        '/landing': (_) => const LandingPage(),
        '/auth': (_) => const AuthPage(),
        '/dashboard': (_) => const AdminDashboardPage(),
        '/wrapper': (_) => const AuthWrapper(),
      },
    );
  }
}
