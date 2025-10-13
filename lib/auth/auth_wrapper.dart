// lib/auth/auth_wrapper.dart
import 'package:agendamientos/features/admin_dashboard/admin_dashboard.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'auth_page.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // StreamBuilder escucha los cambios en el estado de autenticación en tiempo real
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Mientras espera la primera respuesta de Firebase, muestra un loader
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Si el snapshot TIENE DATOS (un objeto User), el usuario ha iniciado sesión
        if (snapshot.hasData) {
          // Así que lo mandamos al Dashboard
          return const AdminDashboardPage(); 
        } 
        
        // Si el snapshot NO TIENE DATOS (es null), no hay sesión
        else {
          // Así que lo mandamos a la página de Login/Registro
          return const AuthPage();
        }
      },
    );
  }
}