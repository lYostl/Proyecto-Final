import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../services/auth_service.dart';

// --- Modelo para las Citas (sin cambios) ---
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

// --- NUEVO: Modelo para los Barberos ---
class Barbero {
  final String? id;
  final String nombre;
  final String especialidad;
  final String fotoUrl;

  Barbero({
    this.id,
    required this.nombre,
    required this.especialidad,
    required this.fotoUrl,
  });

  factory Barbero.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Barbero(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      especialidad: data['especialidad'] ?? '',
      fotoUrl: data['fotoUrl'] ?? 'https://placehold.co/100x100/eee/000?text=?',
    );
  }

  Map<String, dynamic> toMap() {
    return {'nombre': nombre, 'especialidad': especialidad, 'fotoUrl': fotoUrl};
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
    'Calendario de Clientes',
    'Gestión de Personal',
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
              if (context.mounted) {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/wrapper', (route) => false);
              }
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
            _buildDrawerItem(Icons.calendar_month, 'Calendario de Clientes', 0),
            _buildDrawerItem(
              Icons.content_cut,
              'Gestión de Personal',
              1,
            ), // Nombre actualizado
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

// --- PÁGINA DE AGENDA (sin cambios) ---
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
            if (_citas[normalizedDate] == null) _citas[normalizedDate] = [];
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
                locale: 'es_ES',
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
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Citas del día',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Expanded(
                child: ValueListenableBuilder<List<Cita>>(
                  valueListenable: _selectedEvents,
                  builder: (context, value, _) {
                    if (value.isEmpty)
                      return const Center(
                        child: Text('No hay citas para este día.'),
                      );
                    return ListView.builder(
                      itemCount: value.length,
                      itemBuilder: (context, index) {
                        final cita = value[index];
                        return ListTile(
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
        );
      },
    );
  }
}

// --- PÁGINA DE GESTIÓN DE BARBEROS (COMPLETAMENTE NUEVA) ---
class BarberosPage extends StatefulWidget {
  const BarberosPage({super.key});

  @override
  State<BarberosPage> createState() => _BarberosPageState();
}

class _BarberosPageState extends State<BarberosPage> {
  final CollectionReference _barberosCollection = FirebaseFirestore.instance
      .collection('barberos');

  // Function to show the add/edit dialog
  void _showBarberoDialog({Barbero? barbero}) {
    final _nombreController = TextEditingController(text: barbero?.nombre);
    final _especialidadController = TextEditingController(
      text: barbero?.especialidad,
    );
    final _fotoUrlController = TextEditingController(text: barbero?.fotoUrl);
    final _formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  barbero == null ? 'Añadir Personal' : 'Editar Personal',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre Completo',
                  ),
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'El nombre es obligatorio'
                      : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _especialidadController,
                  decoration: const InputDecoration(labelText: 'Especialidad'),
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'La especialidad es obligatoria'
                      : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _fotoUrlController,
                  decoration: const InputDecoration(
                    labelText: 'URL de la foto',
                  ),
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'La URL de la foto es obligatoria'
                      : null,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final newBarbero = Barbero(
                        id: barbero?.id,
                        nombre: _nombreController.text,
                        especialidad: _especialidadController.text,
                        fotoUrl: _fotoUrlController.text,
                      );
                      if (barbero == null) {
                        await _barberosCollection.add(newBarbero.toMap());
                      } else {
                        await _barberosCollection
                            .doc(barbero.id)
                            .update(newBarbero.toMap());
                      }
                      if (mounted) Navigator.of(context).pop();
                    }
                  },
                  child: Text(barbero == null ? 'Guardar' : 'Actualizar'),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  void _deleteBarbero(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: const Text(
          '¿Estás seguro de que quieres eliminar a este miembro del personal? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              await _barberosCollection.doc(id).delete();
              if (mounted) Navigator.of(context).pop();
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: _barberosCollection.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar los datos.'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No hay personal registrado.'));
          }

          final barberos = snapshot.data!.docs
              .map((doc) => Barbero.fromFirestore(doc))
              .toList();

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: barberos.length,
            itemBuilder: (context, index) {
              final barbero = barberos[index];
              return Card(
                margin: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 8.0,
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12.0),
                  leading: CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(barbero.fotoUrl),
                    onBackgroundImageError:
                        (exception, stackTrace) {}, // Handle image load error
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
                        onPressed: () => _showBarberoDialog(barbero: barbero),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () => _deleteBarbero(barbero.id!),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showBarberoDialog(),
        child: const Icon(Icons.add),
        tooltip: 'Añadir Personal',
      ),
    );
  }
}

// --- PÁGINAS DE VENTAS Y CONFIGURACIÓN (sin cambios) ---
class VentasPage extends StatelessWidget {
  const VentasPage({super.key}); /* ... */
  @override
  Widget build(BuildContext context) {
    // El código de esta página no cambia
    return const Center(child: Text('Sección de Ventas'));
  }
}

class ConfiguracionPage extends StatelessWidget {
  const ConfiguracionPage({super.key}); /* ... */
  @override
  Widget build(BuildContext context) {
    // El código de esta página no cambia
    return const Center(child: Text('Sección de Configuración'));
  }
}
