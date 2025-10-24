import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:fl_chart/fl_chart.dart'; // Paquete de gráficos
import '../../services/auth_service.dart';

// --- Modelo Cita (Sin cambios) ---
class Cita {
  final String id;
  final String nombreCliente;
  final String servicio;
  final DateTime fecha;
  final String negocioId;

  Cita({
    required this.id,
    required this.nombreCliente,
    required this.servicio,
    required this.fecha,
    required this.negocioId,
  });

  factory Cita.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Cita(
      id: doc.id,
      nombreCliente: data['nombreCliente'] ?? 'Cliente sin nombre',
      servicio: data['servicio'] ?? 'Servicio no especificado',
      fecha: (data['fecha'] as Timestamp).toDate(),
      negocioId: data['negocioId'] ?? '',
    );
  }
}

// --- Modelo Personal (Sin cambios) ---
class Personal {
  final String? id;
  final String nombre;
  final String servicio; // <-- Renombrado de 'especialidad'
  final String fotoUrl;
  final String negocioId;

  Personal({
    this.id,
    required this.nombre,
    required this.servicio, // <-- Renombrado de 'especialidad'
    required this.fotoUrl,
    required this.negocioId,
  });

  factory Personal.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Personal(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      servicio: data['servicio'] ?? '', // <-- Renombrado de 'especialidad'
      fotoUrl: data['fotoUrl'] ?? 'https://placehold.co/100x100/eee/000?text=?',
      negocioId: data['negocioId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'servicio': servicio, // <-- Renombrado de 'especialidad'
      'fotoUrl': fotoUrl,
      'negocioId': negocioId,
    };
  }
}

// --- Modelo Venta (Sin cambios) ---
class Venta {
  final String servicio;
  final String cliente;
  final double monto;
  final DateTime fecha;
  final String negocioId;

  Venta({
    required this.servicio,
    required this.cliente,
    required this.monto,
    required this.fecha,
    required this.negocioId,
  });

  factory Venta.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Venta(
      servicio: data['servicio'] ?? 'N/A',
      cliente: data['cliente'] ?? 'N/A',
      monto: (data['monto'] ?? 0.0).toDouble(),
      fecha: (data['fecha'] as Timestamp).toDate(),
      negocioId: data['negocioId'] ?? '',
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'servicio': servicio,
      'cliente': cliente,
      'monto': monto,
      'fecha': Timestamp.fromDate(fecha),
      'negocioId': negocioId,
    };
  }
}

// =========================================================================
// === ESTRUCTURA PRINCIPAL DEL DASHBOARD (MODIFICADA) ===
// =========================================================================
class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  // --- NUEVAS VARIABLES DE ESTADO ---
  final AuthService _auth = AuthService();
  late Future<String?> _negocioIdFuture;
  String? _userId; // El ID de autenticación (ownerId)

  final List<String> _pageTitles = [
    'Calendario de Clientes',
    'Gestión de Personal',
    'Dashboard',
    'Configuración',
  ];

  // --- NUEVO: INICIALIZAMOS LA BÚSQUEDA DEL ID DEL NEGOCIO ---
  @override
  void initState() {
    super.initState();
    _userId = _auth.currentUser?.uid;
    if (_userId != null) {
      _negocioIdFuture = _getNegocioId(_userId!);
    } else {
      _negocioIdFuture = Future.value(null);
    }
  }

  // --- NUEVA FUNCIÓN ---
  // Esta función busca en la colección 'negocios' el documento
  // que le pertenece al 'ownerId' (que es nuestro _userId)
  // y devuelve el ID de ESE DOCUMENTO.
  Future<String?> _getNegocioId(String ownerId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('negocios')
          .where('ownerId', isEqualTo: ownerId)
          .limit(1) // Solo debería haber uno
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // ¡Este es el ID que necesitamos! El ID del documento.
        return querySnapshot.docs.first.id;
      } else {
        // El usuario está logueado pero no tiene un negocio asignado
        print("Error: No se encontró un negocio para el ownerId: $ownerId");
        return null;
      }
    } catch (e) {
      print("==== ERROR AL BUSCAR NEGOCIO ID ====");
      print(e);
      print("====================================");
      return null;
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    _pageController.jumpToPage(index);
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // Si el _userId (auth id) es nulo, mostramos error de "no logueado".
    // (Esta lógica ya la tenías y estaba bien).
    if (_userId == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Error: No se pudo identificar al usuario.'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  await _auth.signOut();
                  if (context.mounted) {
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/wrapper', (route) => false);
                  }
                },
                child: const Text('Volver al inicio'),
              ),
            ],
          ),
        ),
      );
    }

    // --- CAMBIO CLAVE: Usamos un FutureBuilder ---
    // Ahora, esperamos a que la función _getNegocioId termine.
    return FutureBuilder<String?>(
      future: _negocioIdFuture,
      builder: (context, snapshot) {
        // --- CASO 1: Esperando ---
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // --- CASO 2: Error o sin datos ---
        // Si no se pudo encontrar el negocioId (null) o hubo un error
        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Error: No se pudo encontrar un negocio asociado a esta cuenta.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        // --- CASO 3: ¡Éxito! ---
        // Tenemos el ID del negocio (el ID del documento)
        final String negocioId = snapshot.data!;

        // Ahora sí construimos la página principal,
        // porque ya tenemos el 'negocioId' correcto.
        return Scaffold(
          appBar: AppBar(
            title: Text(_pageTitles[_selectedIndex]),
            actions: [
              IconButton(
                tooltip: 'Cerrar sesión',
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await _auth.signOut();
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
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: Text(
                          _auth.currentUser?.email
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
                        _auth.currentUser?.email ?? 'Usuario desconocido',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                _buildDrawerItem(
                    Icons.calendar_month, 'Calendario de Clientes', 0),
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
            children: [
              // --- ¡AQUÍ ESTÁ LA MAGIA! ---
              // Ahora pasamos el ID del documento del negocio, no el ID del usuario.
              AgendaPage(negocioId: negocioId),
              PersonalPage(negocioId: negocioId),
              VentasDashboardPage(negocioId: negocioId),
              const ConfiguracionPage(),
            ],
          ),
        );
      },
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

// =========================================================================
// === PISO 1: PÁGINA DE AGENDA (Sin cambios) ===
// =========================================================================
class AgendaPage extends StatefulWidget {
  final String negocioId;
  const AgendaPage({super.key, required this.negocioId});

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
      // Esta consulta AHORA funcionará, porque widget.negocioId
      // es el ID del documento (ej: "2c55QdM..."), que es
      // lo que tienes en la colección 'citas'.
      stream: FirebaseFirestore.instance
          .collection('citas')
          .where('negocioId', isEqualTo: widget.negocioId)
          .orderBy('fecha')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        // Este es el bloque de depuración que agregaste, ¡está perfecto!
        if (snapshot.hasError) {
          print("==== ERROR StreamBuilder Citas ===="); 
          print("Error: ${snapshot.error}");
          print("Negocio ID usado en where: ${widget.negocioId}"); // Ahora imprimirá el ID correcto
          print("Stack trace: ${snapshot.stackTrace}");
          print("===================================");
          return const Center(
              child: Text(
                  'Error al cargar las citas.\nRevisa la consola de debug para detalles.'));
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

// =========================================================================
// === PÁGINA DE GESTIÓN DE PERSONAL (Sin cambios) ===
// =========================================================================
class PersonalPage extends StatefulWidget {
  final String negocioId;
  const PersonalPage({super.key, required this.negocioId});

  @override
  State<PersonalPage> createState() => _PersonalPageState();
}

class _PersonalPageState extends State<PersonalPage> {
  final CollectionReference _personalCollection =
      FirebaseFirestore.instance.collection('personal');

  void _showPersonalDialog({Personal? personal}) {
    final _nombreController = TextEditingController(text: personal?.nombre);
    final _servicioController = TextEditingController(text: personal?.servicio);
    final _fotoUrlController = TextEditingController(text: personal?.fotoUrl);
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
                  personal == null ? 'Añadir Personal' : 'Editar Personal',
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
                  controller: _servicioController,
                  decoration: const InputDecoration(
                    labelText: 'Servicio',
                  ),
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'El servicio es obligatorio'
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
                      final newPersonal = Personal(
                        id: personal?.id,
                        nombre: _nombreController.text,
                        servicio: _servicioController.text,
                        fotoUrl: _fotoUrlController.text,
                        negocioId: widget.negocioId, // <-- Esto ahora funcionará
                      );
                      if (personal == null) {
                        await _personalCollection.add(newPersonal.toMap());
                      } else {
                        await _personalCollection
                            .doc(personal.id)
                            .update(newPersonal.toMap());
                      }
                      if (mounted) Navigator.of(context).pop();
                    }
                  },
                  child: Text(personal == null ? 'Guardar' : 'Actualizar'),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  void _deletePersonal(String id) {
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
              await _personalCollection.doc(id).delete();
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
        stream: _personalCollection
            .where('negocioId', isEqualTo: widget.negocioId) // <-- Esto ahora funcionará
            .snapshots(),
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
          final personalList = snapshot.data!.docs
              .map((doc) => Personal.fromFirestore(doc))
              .toList();

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: personalList.length,
            itemBuilder: (context, index) {
              final personal = personalList[index];
              return Card(
                margin: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 8.0,
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12.0),
                  leading: CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(personal.fotoUrl),
                    onBackgroundImageError: (exception, stackTrace) {},
                  ),
                  title: Text(
                    personal.nombre,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(personal.servicio),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blueAccent),
                        onPressed: () =>
                            _showPersonalDialog(personal: personal),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () => _deletePersonal(personal.id!),
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
        onPressed: () => _showPersonalDialog(),
        child: const Icon(Icons.add),
        tooltip: 'Añadir Personal',
      ),
    );
  }
}

// =========================================================================
// === PÁGINA DE DASHBOARD DE VENTAS (Sin cambios) ===
// =========================================================================
class VentasDashboardPage extends StatefulWidget {
  final String negocioId;
  const VentasDashboardPage({super.key, required this.negocioId});

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
                    if (double.tryParse(v) == null)
                      return 'Ingrese un número válido';
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
                        negocioId: widget.negocioId, // <-- Esto ahora funcionará
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
      stream: FirebaseFirestore.instance
          .collection('ventas')
          .where('negocioId', isEqualTo: widget.negocioId) // <-- Esto ahora funcionará
          .snapshots(),
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

        final ventas = snapshot.data!.docs
            .map((doc) => Venta.fromFirestore(doc))
            .toList();
        final double totalVentas = ventas.fold(
          0,
          (sum, item) => sum + item.monto,
        );
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
                                .touchedSection!.touchedSectionIndex;
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

// =========================================================================
// === PÁGINA DE CONFIGURACIÓN (Sin cambios) ===
// =========================================================================
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
  ) =>
      ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      );
}