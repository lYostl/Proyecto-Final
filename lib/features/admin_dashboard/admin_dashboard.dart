import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

// --- WIDGET PRINCIPAL DEL DASHBOARD (AHORA CON ESTADO) ---
// Convertimos el widget a StatefulWidget para poder manejar el estado de la
// sección seleccionada en el menú.
class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  // Índice de la página o sección actualmente seleccionada.
  int _selectedIndex = 0;
  // Controlador para el PageView, nos permite cambiar de página mediante código.
  final PageController _pageController = PageController();

  // Títulos para la barra de navegación superior (AppBar).
  final List<String> _pageTitles = [
    'Agenda de Turnos',
    'Gestión de Barberos',
    'Ventas y Servicios',
    'Configuración',
  ];

  // Lista de widgets (páginas) que se mostrarán en el cuerpo del dashboard.
  final List<Widget> _pages = [
    const AgendaPage(),
    const BarberosPage(),
    const VentasPage(),
    const ConfiguracionPage(),
  ];

  // Función para manejar el toque en un ítem del menú lateral.
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Cambia la página en el PageView.
    _pageController.jumpToPage(index);
    // Cierra el menú lateral automáticamente.
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    // Es importante liberar los recursos del controlador cuando el widget se destruye.
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    final theme = Theme.of(context); // Para acceder a los colores del tema.

    return Scaffold(
      appBar: AppBar(
        // El título cambia dinámicamente según la sección seleccionada.
        title: Text(_pageTitles[_selectedIndex]),
        backgroundColor: Colors.blueGrey[900], // Un color oscuro y elegante
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final err = await auth.signOut();
              if (err != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(err),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
        ],
      ),
      // --- MENÚ LATERAL (DRAWER) ---
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Cabecera del menú con información del usuario.
            UserAccountsDrawerHeader(
              accountName: const Text(
                'Administrador',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              accountEmail: Text(auth.currentUser?.email ?? 'Usuario'),
              decoration: BoxDecoration(color: Colors.blueGrey[900]),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  // Muestra la primera letra del email en mayúsculas.
                  auth.currentUser?.email?.substring(0, 1).toUpperCase() ?? 'A',
                  style: TextStyle(fontSize: 40.0, color: Colors.blueGrey[900]),
                ),
              ),
            ),
            // Items del menú.
            _buildDrawerItem(
              icon: Icons.calendar_month,
              text: 'Agenda de turnos',
              index: 0,
            ),
            _buildDrawerItem(
              icon: Icons.content_cut,
              text: 'Barberos',
              index: 1,
            ),
            _buildDrawerItem(
              icon: Icons.attach_money,
              text: 'Ventas / servicios',
              index: 2,
            ),
            const Divider(), // Un separador visual.
            _buildDrawerItem(
              icon: Icons.settings,
              text: 'Configuración',
              index: 3,
            ),
          ],
        ),
      ),
      // --- CUERPO DEL DASHBOARD ---
      // Usamos PageView para contener las diferentes secciones.
      body: PageView(
        controller: _pageController,
        // Esto permite actualizar el menú si el usuario desliza entre páginas.
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: _pages,
      ),
    );
  }

  // Método auxiliar para crear los items del menú y evitar repetir código.
  Widget _buildDrawerItem({
    required IconData icon,
    required String text,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;
    final selectedColor = Colors.blueGrey[800];

    return Container(
      // Resalta el item seleccionado con un color de fondo sutil.
      color: isSelected ? selectedColor?.withOpacity(0.1) : Colors.transparent,
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? selectedColor : Colors.grey[600],
        ),
        title: Text(
          text,
          style: TextStyle(
            color: isSelected ? selectedColor : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: () => _onItemTapped(index),
      ),
    );
  }
}

// --- PÁGINAS DE RELLENO (PLACEHOLDERS) PARA CADA SECCIÓN ---
// Aquí es donde desarrollarás el contenido específico de cada parte del dashboard.

class AgendaPage extends StatelessWidget {
  const AgendaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today, size: 80, color: Colors.grey),
          SizedBox(height: 20),
          Text(
            'Gestión de Agenda y Turnos',
            style: TextStyle(fontSize: 22, color: Colors.grey),
          ),
          Text(
            'Aquí se mostrará el calendario de citas.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class BarberosPage extends StatelessWidget {
  const BarberosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.content_cut, size: 80, color: Colors.grey),
          SizedBox(height: 20),
          Text(
            'Gestión de Barberos',
            style: TextStyle(fontSize: 22, color: Colors.grey),
          ),
          Text(
            'Aquí podrás añadir, editar o eliminar barberos.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class VentasPage extends StatelessWidget {
  const VentasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, size: 80, color: Colors.grey),
          SizedBox(height: 20),
          Text(
            'Reporte de Ventas y Servicios',
            style: TextStyle(fontSize: 22, color: Colors.grey),
          ),
          Text(
            'Aquí se mostrarán los reportes y estadísticas.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class ConfiguracionPage extends StatelessWidget {
  const ConfiguracionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.settings, size: 80, color: Colors.grey),
          SizedBox(height: 20),
          Text(
            'Configuración de la Cuenta',
            style: TextStyle(fontSize: 22, color: Colors.grey),
          ),
          Text(
            'Aquí podrás ajustar las configuraciones de la app.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
