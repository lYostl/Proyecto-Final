import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel administrador'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final err = await auth.signOut();
              if (err == null) {
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(context, '/auth', (_) => false);
                }
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(err)),
                  );
                }
              }
            },
          )
        ],
      ),
      body: const Center(
        child: Text('Bienvenido 👋 — aquí irá tu dashboard (ventas, stock, etc.)'),
      ),
    );
  }
}
