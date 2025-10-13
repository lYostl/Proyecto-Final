// lib/features/admin_dashboard/admin_dashboard.dart

import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Administrador'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final err = await auth.signOut();

              // --- LÓGICA SIMPLIFICADA ---
              // Ya no navegamos manualmente. El AuthWrapper lo hará por nosotros.
              // Solo nos preocupamos de mostrar un error si el signOut falla.
              if (err != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(err),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '¡Bienvenido! 👋',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Sesión iniciada como: ${auth.currentUser?.email ?? "Usuario desconocido"}',
            ),
            const SizedBox(height: 20),
            const Text('Aquí irá tu dashboard (calendario, ventas, etc.)'),
          ],
        ),
      ),
    );
  }
}