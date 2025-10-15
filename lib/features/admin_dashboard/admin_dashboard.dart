import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
// ¡Importante! Debes agregar 'table_calendar' a tu pubspec.yaml para que esto funcione.
import 'package:table_calendar/table_calendar.dart';

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

// --- PÁGINA DE AGENDA (SECCIÓN ACTUALIZADA) ---

class AgendaPage extends StatefulWidget {
  const AgendaPage({super.key});

  @override
  State<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends State<AgendaPage> {
  // Variables de estado para el calendario
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<String> _selectedEvents = [];

  // Datos de ejemplo para los turnos. En una app real, esto vendría de una base de datos.
  final Map<DateTime, List<String>> _events = {
    DateTime.utc(2025, 10, 15): [
      '10:00 - Corte - Juan Perez',
      '11:30 - Barba - Carlos Gomez',
    ],
    DateTime.utc(2025, 10, 16): ['09:00 - Corte y Barba - Luis Rodriguez'],
    DateTime.utc(2025, 10, 20): [
      '14:00 - Corte - Miguel Angel',
      '15:00 - Corte - Fernando Diaz',
      '17:30 - Barba - Pedro Pascal',
    ],
  };

  // Función para obtener los eventos de un día específico.
  List<String> _getEventsForDay(DateTime day) {
    // La comparación se hace con DateTime.utc para evitar problemas de zona horaria.
    return _events[DateTime.utc(day.year, day.month, day.day)] ?? [];
  }

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedEvents = _getEventsForDay(_selectedDay!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- WIDGET DEL CALENDARIO ---
          Card(
            margin: const EdgeInsets.all(8.0),
            elevation: 4.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: TableCalendar(
              locale: 'es_ES', // Para mostrar el calendario en español
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: CalendarFormat.month,
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Colors.blueGrey.shade200,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Colors.blueGrey.shade600,
                  shape: BoxShape.circle,
                ),
              ),
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                if (!isSameDay(_selectedDay, selectedDay)) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                    _selectedEvents = _getEventsForDay(selectedDay);
                  });
                }
              },
              eventLoader: _getEventsForDay,
            ),
          ),
          const SizedBox(height: 8.0),

          // --- LISTA DE TURNOS DEL DÍA SELECCIONADO ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Turnos del día',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: _selectedEvents.isEmpty
                ? const Center(child: Text('No hay turnos para este día.'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    itemCount: _selectedEvents.length,
                    itemBuilder: (context, index) {
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        child: ListTile(
                          leading: const Icon(
                            Icons.cut,
                            color: Colors.blueGrey,
                          ),
                          title: Text(_selectedEvents[index]),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                          ),
                          onTap: () {
                            // Aquí podrías navegar a una pantalla de detalle del turno
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      // --- BOTÓN PARA AÑADIR NUEVO TURNO ---
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Lógica para abrir un formulario o diálogo para crear un nuevo turno.
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Aquí se abrirá el formulario para un nuevo turno.',
              ),
            ),
          );
        },
        backgroundColor: Colors.blueGrey[800],
        foregroundColor: Colors.white,
        tooltip: 'Añadir Turno',
        child: const Icon(Icons.add),
      ),
    );
  }
}

// --- CLASE MODELO PARA UN BARBERO ---
// Esto nos ayuda a organizar los datos de cada barbero.
class Barbero {
  final String nombre;
  final String especialidad;
  final String fotoUrl; // URL de la foto del barbero.

  Barbero({
    required this.nombre,
    required this.especialidad,
    required this.fotoUrl,
  });
}

// --- PÁGINA DE GESTIÓN DE BARBEROS (SECCIÓN ACTUALIZADA) ---

class BarberosPage extends StatefulWidget {
  const BarberosPage({super.key});

  @override
  State<BarberosPage> createState() => _BarberosPageState();
}

class _BarberosPageState extends State<BarberosPage> {
  // Lista de barberos. En una app real, esto vendría de una base de datos.
  final List<Barbero> _barberos = [
    Barbero(
      nombre: 'Carlos Gutierrez',
      especialidad: 'Cortes clásicos, Afeitado',
      fotoUrl: 'https://placehold.co/100x100/E8117F/white?text=CG',
    ),
    Barbero(
      nombre: 'Matias Rodriguez',
      especialidad: 'Diseños, Coloración',
      fotoUrl: 'https://placehold.co/100x100/114DE8/white?text=MR',
    ),
    Barbero(
      nombre: 'Javier Nuñez',
      especialidad: 'Corte moderno, Barba',
      fotoUrl: 'https://placehold.co/100x100/E89111/white?text=JN',
    ),
    Barbero(
      nombre: 'Ricardo Soto',
      especialidad: 'Todo tipo de cortes',
      fotoUrl: 'https://placehold.co/100x100/8411E8/white?text=RS',
    ),
  ];

  void _editarBarbero(Barbero barbero) {
    // Lógica para abrir un formulario de edición para el barbero seleccionado.
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Editando a ${barbero.nombre}')));
  }

  void _eliminarBarbero(int index) {
    // Lógica para eliminar el barbero.
    final barberoEliminado = _barberos[index].nombre;
    setState(() {
      _barberos.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$barberoEliminado ha sido eliminado.')),
    );
  }

  void _agregarBarbero() {
    // Lógica para abrir un formulario y agregar un nuevo barbero.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Aquí se abriría el formulario para agregar un nuevo barbero.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _barberos.length,
        itemBuilder: (context, index) {
          final barbero = _barberos[index];
          return Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12.0),
              leading: CircleAvatar(
                radius: 30,
                backgroundImage: NetworkImage(barbero.fotoUrl),
              ),
              title: Text(
                barbero.nombre,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(barbero.especialidad),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.blueGrey[600]),
                    tooltip: 'Editar',
                    onPressed: () => _editarBarbero(barbero),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red[400]),
                    tooltip: 'Eliminar',
                    onPressed: () => _eliminarBarbero(index),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _agregarBarbero,
        backgroundColor: Colors.blueGrey[800],
        foregroundColor: Colors.white,
        tooltip: 'Añadir Barbero',
        child: const Icon(Icons.add),
      ),
    );
  }
}

// --- PÁGINAS DE RELLENO (PLACEHOLDERS) PARA LAS OTRAS SECCIONES ---

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
