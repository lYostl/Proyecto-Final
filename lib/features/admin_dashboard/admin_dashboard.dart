import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../services/auth_service.dart';

// --- Modelo para las Citas ---
class Cita {
  final String id;
  final String nombreCliente;
  final String servicio;
  final DateTime fecha;

  Cita({
    required this.id,
    required this.nombreCliente,
    required this.servicio,
    required this.fecha,
  });

  factory Cita.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Cita(
      id: doc.id,
      nombreCliente: data['nombreCliente'] ?? 'Cliente sin nombre',
      servicio: data['servicio'] ?? 'Servicio no especificado',
      fecha: (data['fecha'] as Timestamp).toDate(),
    );
  }
}

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  final List<String> _pageTitles = [
    'Agenda de Turnos',
    'Gestión de Barberos',
    'Ventas y Servicios',
    'Configuración',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.jumpToPage(index);
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitles[_selectedIndex]),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.signOut();
              // El AuthWrapper debería manejar la navegación
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Text(
                      auth.currentUser?.email?.substring(0, 1).toUpperCase() ??
                          'U',
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Administrador',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    auth.currentUser?.email ?? 'Usuario desconocido',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(Icons.calendar_month, 'Agenda de turnos', 0),
            _buildDrawerItem(Icons.content_cut, 'Barberos', 1),
            _buildDrawerItem(Icons.attach_money, 'Ventas / servicios', 2),
            const Divider(),
            _buildDrawerItem(Icons.settings, 'Configuración', 3),
          ],
        ),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: const [
          AgendaPage(),
          BarberosPage(),
          VentasPage(),
          ConfiguracionPage(),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, int index) {
    final isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : Colors.white70,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.white,
        ),
      ),
      selected: isSelected,
      onTap: () => _onItemTapped(index),
      selectedTileColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
    );
  }
}

// --- SECCIÓN DE AGENDA (MODIFICADA PARA LEER DE FIREBASE) ---
class AgendaPage extends StatefulWidget {
  const AgendaPage({super.key});

  @override
  State<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends State<AgendaPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  Map<DateTime, List<Cita>> _citas = {};
  late final ValueNotifier<List<Cita>> _selectedEvents;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  List<Cita> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _citas[normalizedDay] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
      _selectedEvents.value = _getEventsForDay(selectedDay);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('citas')
          .orderBy('fecha')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error al cargar las citas.'));
        }

        if (snapshot.hasData) {
          _citas = {};
          for (var doc in snapshot.data!.docs) {
            final cita = Cita.fromFirestore(doc);
            final normalizedDate = DateTime(
              cita.fecha.year,
              cita.fecha.month,
              cita.fecha.day,
            );
            if (_citas[normalizedDate] == null) {
              _citas[normalizedDate] = [];
            }
            _citas[normalizedDate]!.add(cita);
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _selectedDay != null) {
              _selectedEvents.value = _getEventsForDay(_selectedDay!);
            }
          });
        }

        return Scaffold(
          body: Column(
            children: [
              TableCalendar<Cita>(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                calendarFormat: _calendarFormat,
                eventLoader: _getEventsForDay,
                startingDayOfWeek: StartingDayOfWeek.monday,
                onDaySelected: _onDaySelected,
                onFormatChanged: (format) {
                  if (_calendarFormat != format)
                    setState(() => _calendarFormat = format);
                },
                onPageChanged: (focusedDay) => _focusedDay = focusedDay,
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Colors.deepOrange.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: BoxDecoration(
                    color: Colors.blue[400],
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
              ),
              const SizedBox(height: 8.0),
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Turnos del día',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Expanded(
                child: ValueListenableBuilder<List<Cita>>(
                  valueListenable: _selectedEvents,
                  builder: (context, value, _) {
                    if (value.isEmpty)
                      return const Center(
                        child: Text('No hay turnos para este día.'),
                      );
                    return ListView.builder(
                      itemCount: value.length,
                      itemBuilder: (context, index) {
                        final cita = value[index];
                        return ListTile(
                          leading: const Icon(Icons.content_cut),
                          title: Text(
                            '${cita.servicio} - ${cita.nombreCliente}',
                          ),
                          subtitle: Text(
                            DateFormat('HH:mm a').format(cita.fecha),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {},
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}

// --- (El resto de las páginas: Barberos, Ventas, Configuración, se mantienen igual que antes) ---
// --- El código de estas secciones no se modifica ---
class Barbero {
  final String id;
  final String nombre;
  final String fotoUrl;
  final String especialidad;

  Barbero({
    required this.id,
    required this.nombre,
    required this.fotoUrl,
    required this.especialidad,
  });
}

class BarberosPage extends StatefulWidget {
  const BarberosPage({super.key});
  @override
  State<BarberosPage> createState() => _BarberosPageState();
}

class _BarberosPageState extends State<BarberosPage> {
  final List<Barbero> _barberos = [
    Barbero(
      id: '1',
      nombre: 'Carlos Gutierrez',
      fotoUrl: 'https://placehold.co/100x100/222/FFF?text=CG',
      especialidad: 'Cortes clásicos y Barba',
    ),
    Barbero(
      id: '2',
      nombre: 'Matias Rodriguez',
      fotoUrl: 'https://placehold.co/100x100/333/FFF?text=MR',
      especialidad: 'Diseños y Color',
    ),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _barberos.length,
        itemBuilder: (context, index) {
          final barbero = _barberos[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
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
                    icon: const Icon(Icons.edit, color: Colors.blueAccent),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () => setState(() => _barberos.removeAt(index)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}

class Venta {
  final String servicio;
  final String cliente;
  final double monto;
  final DateTime fecha;
  Venta({
    required this.servicio,
    required this.cliente,
    required this.monto,
    required this.fecha,
  });
}

class VentasPage extends StatelessWidget {
  const VentasPage({super.key});
  @override
  Widget build(BuildContext context) {
    final List<Venta> _ventas = [
      Venta(
        servicio: 'Corte de Pelo',
        cliente: 'Juan Perez',
        monto: 15000,
        fecha: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      Venta(
        servicio: 'Barba',
        cliente: 'Carlos Gomez',
        monto: 8000,
        fecha: DateTime.now().subtract(const Duration(hours: 4)),
      ),
    ];
    final double totalVentas = _ventas.fold(0, (sum, item) => sum + item.monto);
    final int totalServicios = _ventas.length;
    final double ticketPromedio = totalServicios > 0
        ? totalVentas / totalServicios
        : 0;
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: SummaryCard(
                    title: 'Ventas Totales',
                    value: NumberFormat.simpleCurrency(
                      locale: 'es_CL',
                      decimalDigits: 0,
                    ).format(totalVentas),
                    icon: Icons.monetization_on,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SummaryCard(
                    title: 'Servicios',
                    value: totalServicios.toString(),
                    icon: Icons.content_cut,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: SummaryCard(
                title: 'Ticket Promedio',
                value: NumberFormat.simpleCurrency(
                  locale: 'es_CL',
                  decimalDigits: 0,
                ).format(ticketPromedio),
                icon: Icons.receipt_long,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Historial Reciente',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            ..._ventas
                .map(
                  (venta) => Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: const Icon(Icons.receipt),
                      title: Text('${venta.servicio} - ${venta.cliente}'),
                      subtitle: Text(
                        DateFormat('dd/MM/yyyy, HH:mm a').format(venta.fecha),
                      ),
                      trailing: Text(
                        NumberFormat.simpleCurrency(
                          locale: 'es_CL',
                          decimalDigits: 0,
                        ).format(venta.monto),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                )
                .toList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}

class SummaryCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;
  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class ConfiguracionPage extends StatefulWidget {
  const ConfiguracionPage({super.key});
  @override
  _ConfiguracionPageState createState() => _ConfiguracionPageState();
}

class _ConfiguracionPageState extends State<ConfiguracionPage> {
  bool _notificacionesPush = true;
  bool _modoOscuro = true;
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildSectionTitle('Cuenta'),
        _buildConfigOption('Editar Perfil', Icons.person, () {}),
        _buildConfigOption('Cambiar Contraseña', Icons.lock, () {}),
        const Divider(height: 40),
        _buildSectionTitle('Aplicación'),
        SwitchListTile(
          title: const Text('Notificaciones Push'),
          secondary: const Icon(Icons.notifications),
          value: _notificacionesPush,
          onChanged: (bool value) =>
              setState(() => _notificacionesPush = value),
        ),
        SwitchListTile(
          title: const Text('Modo Oscuro'),
          secondary: const Icon(Icons.dark_mode),
          value: _modoOscuro,
          onChanged: (bool value) => setState(() => _modoOscuro = value),
        ),
        const Divider(height: 40),
        _buildSectionTitle('Información'),
        _buildConfigOption('Términos de Servicio', Icons.description, () {}),
        _buildConfigOption('Política de Privacidad', Icons.privacy_tip, () {}),
      ],
    );
  }

  Padding _buildSectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 8.0),
    child: Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
  );
  ListTile _buildConfigOption(
    String title,
    IconData icon,
    VoidCallback onTap,
  ) => ListTile(
    leading: Icon(icon),
    title: Text(title),
    trailing: const Icon(Icons.chevron_right),
    onTap: onTap,
  );
}
