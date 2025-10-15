import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../features/admin_dashboard/admin_dashboard.dart';
import '../features/landing/landing_page.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // Se suscribe a los cambios de estado de autenticación de Firebase
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Mientras espera la primera respuesta de Firebase, muestra un loader
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Si el snapshot tiene un usuario (sesión iniciada)...
        if (snapshot.hasData) {
          // ...lo manda al Panel de Administrador.
          return const AdminDashboardPage();
        }
        // Si no hay usuario (sesión cerrada o nunca iniciada)...
        else {
          // ...lo manda a la Página de Inicio (Landing Page).
          return const LandingPage();
        }
      },
    );
  }
}
