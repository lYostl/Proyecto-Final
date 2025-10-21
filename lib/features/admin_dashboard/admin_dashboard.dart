import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:fl_chart/fl_chart.dart'; // Paquete de gráficos
import '../../services/auth_service.dart';

/// ===============================
/// MODELOS
/// ===============================

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

// --- Modelo para los Barberos / Staff ---
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

// --- Modelo para los Servicios del Staff ---
class StaffService {
  final String id;
  final String nombre;
  final int duracionMin;
  final num precio; // num para permitir int o double
  final bool activo;

  StaffService({
    required this.id,
    required this.nombre,
    required this.duracionMin,
    required this.precio,
    required this.activo,
  });

  factory StaffService.fromDoc(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>;
    return StaffService(
      id: doc.id,
      nombre: m['nombre'] ?? 'Servicio',
      duracionMin: (m['duracionMin'] ?? 60) is int
          ? (m['duracionMin'] ?? 60)
          : int.tryParse('${m['duracionMin']}') ?? 60,
      precio: m['precio'] ?? 0,
      activo: m['activo'] ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
        'nombre': nombre,
        'duracionMin': duracionMin,
        'precio': precio,
        'activo': activo,
      };
}

// --- Modelo para las Ventas ---
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

  factory Venta.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Venta(
      servicio: data['servicio'] ?? 'N/A',
      cliente: data['cliente'] ?? 'N/A',
      monto: (data['monto'] ?? 0.0).toDouble(),
      fecha: (data['fecha'] as Timestamp).toDate(),
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'servicio': servicio,
      'cliente': cliente,
      'monto': monto,
      'fecha': Timestamp.fromDate(fecha),
    };
  }
}

/// ===============================
/// DASHBOARD SHELL
/// ===============================
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
    'Dashboard',
    'Configuración',
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
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
                      AuthService()
                              .currentUser
                              ?.email
                              ?.substring(0, 1)
                              .toUpperCase() ??
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
                    AuthService().currentUser?.email ?? 'Usuario desconocido',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(Icons.calendar_month, 'Calendario de Clientes', 0),
            _buildDrawerItem(Icons.content_cut, 'Gestión de Personal', 1),
            _buildDrawerItem(Icons.dashboard, 'Dashboard', 2),
            const Divider(),
            _buildDrawerItem(Icons.settings, 'Configuración', 3),
          ],
        ),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _selectedIndex = index),
        children: const [
          AgendaPage(),
          BarberosPage(),
          VentasDashboardPage(),
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

/// ===============================
/// PISO 1: AGENDA
/// ===============================
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
            _citas.putIfAbsent(normalizedDate, () => []);
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
                    if (value.isEmpty) {
                      return const Center(
                        child: Text('No hay citas para este día.'),
                      );
                    }
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

/// ===============================
/// PISO 2: GESTIÓN DE PERSONAL
/// ===============================
class BarberosPage extends StatefulWidget {
  const BarberosPage({super.key});

  @override
  State<BarberosPage> createState() => _BarberosPageState();
}

class _BarberosPageState extends State<BarberosPage> {
  final CollectionReference _barberosCollection =
      FirebaseFirestore.instance.collection('barberos');

  void _showBarberoDialog({Barbero? barbero}) {
    final _nombreController = TextEditingController(text: barbero?.nombre);
    final _especialidadController =
        TextEditingController(text: barbero?.especialidad);
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
                  decoration:
                      const InputDecoration(labelText: 'Nombre Completo'),
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'El nombre es obligatorio'
                      : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _especialidadController,
                  decoration:
                      const InputDecoration(labelText: 'Especialidad'),
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'La especialidad es obligatoria'
                      : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _fotoUrlController,
                  decoration: const InputDecoration(labelText: 'URL de la foto'),
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
                        nombre: _nombreController.text.trim(),
                        especialidad: _especialidadController.text.trim(),
                        fotoUrl: _fotoUrlController.text.trim(),
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
            '¿Eliminar a este miembro del personal? Esta acción no se puede deshacer.'),
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
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
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
                margin:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12.0),
                  leading: CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(barbero.fotoUrl),
                    onBackgroundImageError: (exception, stackTrace) {},
                  ),
                  title: Text(
                    barbero.nombre,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(barbero.especialidad),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // NUEVO: botón de servicios del trabajador
                      IconButton(
                        tooltip: 'Servicios del personal',
                        icon: const Icon(Icons.design_services_rounded,
                            color: Colors.amber),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StaffServicesPage(
                                barberoId: barbero.id!,
                                barberoNombre: barbero.nombre,
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blueAccent),
                        tooltip: 'Editar personal',
                        onPressed: () => _showBarberoDialog(barbero: barbero),
                      ),
                      IconButton(
                        icon:
                            const Icon(Icons.delete, color: Colors.redAccent),
                        tooltip: 'Eliminar personal',
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

/// ===============================
/// PÁGINA: SERVICIOS POR TRABAJADOR
/// ===============================
class StaffServicesPage extends StatefulWidget {
  const StaffServicesPage({
    super.key,
    required this.barberoId,
    required this.barberoNombre,
  });

  final String barberoId;
  final String barberoNombre;

  @override
  State<StaffServicesPage> createState() => _StaffServicesPageState();
}

class _StaffServicesPageState extends State<StaffServicesPage> {
  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance
          .collection('barberos')
          .doc(widget.barberoId)
          .collection('servicios');

  void _showServicioDialog({StaffService? s}) {
    final _nombre = TextEditingController(text: s?.nombre);
    final _dur = TextEditingController(text: (s?.duracionMin ?? 60).toString());
    final _precio = TextEditingController(text: (s?.precio ?? 0).toString());
    bool activo = s?.activo ?? true;
    final _f = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Form(
          key: _f,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                s == null
                    ? 'Nuevo servicio para ${widget.barberoNombre}'
                    : 'Editar servicio',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nombre,
                decoration:
                    const InputDecoration(labelText: 'Nombre del servicio'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _dur,
                decoration: const InputDecoration(
                  labelText: 'Duración (min)',
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requerido';
                  final n = int.tryParse(v);
                  if (n == null || n <= 0) return 'Minutos inválidos';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _precio,
                decoration: const InputDecoration(
                  labelText: 'Precio',
                  prefixText: '\$ ',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requerido';
                  if (num.tryParse(v) == null) return 'Precio inválido';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                value: activo,
                onChanged: (val) => setState(() => activo = val),
                title: const Text('Activo (visible para tomar reservas)'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  if (!_f.currentState!.validate()) return;
                  final data = StaffService(
                    id: s?.id ?? '',
                    nombre: _nombre.text.trim(),
                    duracionMin: int.parse(_dur.text.trim()),
                    precio: num.parse(_precio.text.trim()),
                    activo: activo,
                  ).toMap();

                  if (s == null) {
                    await _col.add(data);
                  } else {
                    await _col.doc(s.id).update(data);
                  }
                  if (mounted) Navigator.pop(context);
                },
                child: Text(s == null ? 'Guardar servicio' : 'Actualizar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _deleteServicio(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar servicio'),
        content: const Text('¿Seguro que deseas eliminar este servicio?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true) await _col.doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Servicios · ${widget.barberoNombre}'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _col.orderBy('nombre').snapshots(),
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('Aún no hay servicios.'));
          }
          final servicios =
              docs.map((d) => StaffService.fromDoc(d)).toList();

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemBuilder: (_, i) {
              final s = servicios[i];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text('${s.duracionMin}m'),
                  ),
                  title: Text(s.nombre),
                  subtitle: Text(
                      'Precio: \$${NumberFormat.decimalPattern().format(s.precio)} · ${s.activo ? 'Activo' : 'Inactivo'}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Editar',
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showServicioDialog(s: s),
                      ),
                      IconButton(
                        tooltip: 'Eliminar',
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteServicio(s.id),
                      ),
                    ],
                  ),
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemCount: servicios.length,
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showServicioDialog(),
        child: const Icon(Icons.add),
        tooltip: 'Añadir servicio',
      ),
    );
  }
}

/// ===============================
/// PISO 3: DASHBOARD DE VENTAS
/// ===============================
class VentasDashboardPage extends StatefulWidget {
  const VentasDashboardPage({super.key});

  @override
  State<VentasDashboardPage> createState() => _VentasDashboardPageState();
}

class _VentasDashboardPageState extends State<VentasDashboardPage> {
  int touchedIndex = -1;

  void _showVentaDialog() {
    final _servicioController = TextEditingController();
    final _clienteController = TextEditingController();
    final _montoController = TextEditingController();
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
                  'Registrar Nueva Venta',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _servicioController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del Servicio',
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _clienteController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del Cliente',
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _montoController,
                  decoration: const InputDecoration(
                    labelText: 'Monto',
                    prefixText: '\$ ',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Campo requerido';
                    if (double.tryParse(v) == null) {
                      return 'Ingrese un número válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final nuevaVenta = Venta(
                        servicio: _servicioController.text,
                        cliente: _clienteController.text,
                        monto: double.parse(_montoController.text),
                        fecha: DateTime.now(),
                      );
                      await FirebaseFirestore.instance
                          .collection('ventas')
                          .add(nuevaVenta.toMap());
                      if (mounted) Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Guardar Venta'),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('ventas').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error al cargar las ventas.'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Scaffold(
            body: const Center(child: Text('Aún no hay ventas registradas.')),
            floatingActionButton: FloatingActionButton(
              onPressed: _showVentaDialog,
              child: const Icon(Icons.add),
              tooltip: 'Añadir Venta',
            ),
          );
        }

        final ventas =
            snapshot.data!.docs.map((doc) => Venta.fromFirestore(doc)).toList();
        final double totalVentas =
            ventas.fold(0, (sum, item) => sum + item.monto);
        final int totalServicios = ventas.length;
        final double ticketPromedio =
            totalServicios > 0 ? totalVentas / totalServicios : 0;
        final Map<String, double> ventasPorServicio = {};
        for (var venta in ventas) {
          ventasPorServicio.update(
            venta.servicio,
            (value) => value + venta.monto,
            ifAbsent: () => venta.monto,
          );
        }
        final List<Color> pieColors = [
          Colors.blue,
          Colors.green,
          Colors.orange,
          Colors.red,
          Colors.purple,
          Colors.yellow,
        ];

        return Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
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
                      child: _SummaryCard(
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
                  child: _SummaryCard(
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
                  'Ventas por Servicio',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              touchedIndex = -1;
                              return;
                            }
                            touchedIndex = pieTouchResponse
                                .touchedSection!
                                .touchedSectionIndex;
                          });
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: List.generate(ventasPorServicio.length, (i) {
                        final isTouched = i == touchedIndex;
                        final entry = ventasPorServicio.entries.elementAt(i);
                        final percentage = totalVentas > 0
                            ? (entry.value / totalVentas) * 100
                            : 0;
                        return PieChartSectionData(
                          color: pieColors[i % pieColors.length],
                          value: entry.value,
                          title: '${percentage.toStringAsFixed(1)}%',
                          radius: isTouched ? 60.0 : 50.0,
                          titleStyle: TextStyle(
                            fontSize: isTouched ? 16.0 : 14.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                Wrap(
                  spacing: 8.0,
                  children: List.generate(ventasPorServicio.length, (i) {
                    return Chip(
                      avatar: CircleAvatar(
                        backgroundColor: pieColors[i % pieColors.length],
                      ),
                      label: Text(ventasPorServicio.keys.elementAt(i)),
                    );
                  }),
                ),
                const SizedBox(height: 24),
                Text(
                  'Historial de Ventas',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Fecha')),
                      DataColumn(label: Text('Servicio')),
                      DataColumn(label: Text('Monto')),
                    ],
                    rows: ventas
                        .map(
                          (venta) => DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  DateFormat('dd/MM/yy').format(venta.fecha),
                                ),
                              ),
                              DataCell(Text(venta.servicio)),
                              DataCell(
                                Text(
                                  NumberFormat.simpleCurrency(
                                    locale: 'es_CL',
                                    decimalDigits: 0,
                                  ).format(venta.monto),
                                ),
                              ),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _showVentaDialog,
            child: const Icon(Icons.add),
            tooltip: 'Añadir Venta',
          ),
        );
      },
    );
  }
}

// Widget auxiliar para las tarjetas de resumen
class _SummaryCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;
  const _SummaryCard({
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
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

/// ===============================
/// PISO 4: CONFIGURACIÓN
/// ===============================
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
          String title, IconData icon, VoidCallback onTap) =>
      ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      );
}
