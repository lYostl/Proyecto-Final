// lib/features/public_booking/booking_flow.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PublicBookingFlow extends StatefulWidget {
  const PublicBookingFlow({super.key, required this.negocioId});
  final String negocioId;

  @override
  State<PublicBookingFlow> createState() => _PublicBookingFlowState();
}

class _PublicBookingFlowState extends State<PublicBookingFlow> {
  // 0) Info del negocio
  Map<String, dynamic>? negocio;

  // 1) Selección de staff y servicio
  String? staffId, staffNombre, servicioId, servicioNombre;
  int duracionMin = 60;

  // 2) Fecha y hora
  DateTime? fecha; // solo fecha (00:00)
  TimeOfDay? hora; // solo hora

  /// Slots base (puedes mover esto a Firestore luego)
  final List<String> slots = const [
    '09:00',
    '10:00',
    '11:00',
    '12:00',
    '14:00',
    '15:00',
    '16:00',
    '17:00',
  ];

  /// Horarios ya ocupados para el día / staff seleccionado (minutos desde medianoche)
  final Set<int> _ocupados = {};

  // 3) Datos del cliente
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _fonoCtrl = TextEditingController();

  bool saving = false;

  FirebaseFirestore get db => FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadNegocio();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _emailCtrl.dispose();
    _fonoCtrl.dispose();
    super.dispose();
  }

  // ────────────────────────────────────────────────────────────────────────────
  // CARGA NEGOCIO + DISPONIBILIDAD
  // ────────────────────────────────────────────────────────────────────────────

  Future<void> _loadNegocio() async {
    final doc = await db.collection('negocios').doc(widget.negocioId).get();
    if (doc.exists && mounted) {
      setState(() => negocio = doc.data());
    }
  }

  Future<void> _loadDisponibilidadDelDia() async {
    _ocupados.clear();
    hora = null;

    if (fecha == null || staffId == null) {
      if (mounted) setState(() {});
      return;
    }

    final inicio = DateTime(fecha!.year, fecha!.month, fecha!.day);
    final fin = inicio.add(const Duration(days: 1));

    final q = await db
        .collection('negocios')
        .doc(widget.negocioId)
        .collection('citas')
        .where('staffId', isEqualTo: staffId)
        .where('fechaInicio', isGreaterThanOrEqualTo: Timestamp.fromDate(inicio))
        .where('fechaInicio', isLessThan: Timestamp.fromDate(fin))
        .get();

    for (final d in q.docs) {
      final data = d.data();
      final DateTime ini = (data['fechaInicio'] as Timestamp).toDate();
      final DateTime end = (data['fechaFin'] as Timestamp).toDate();
      // Marcamos como ocupados todos los bloques que intersecan con la duración
      var cursor = DateTime(ini.year, ini.month, ini.day, ini.hour, ini.minute);
      while (cursor.isBefore(end)) {
        _ocupados.add(cursor.hour * 60 + cursor.minute);
        cursor = cursor.add(const Duration(minutes: 5));
      }
    }

    if (mounted) setState(() {});
  }

  // ────────────────────────────────────────────────────────────────────────────
  // HELPERS
  // ────────────────────────────────────────────────────────────────────────────

  TimeOfDay _parseHHmm(String s) {
    final hh = int.parse(s.split(':')[0]);
    final mm = int.parse(s.split(':')[1]);
    return TimeOfDay(hour: hh, minute: mm);
  }

  bool _sameTime(TimeOfDay a, TimeOfDay b) =>
      a.hour == b.hour && a.minute == b.minute;

  int _toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  String _fmtDate(DateTime d) => DateFormat('EEE d MMM', 'es').format(d);

  // ────────────────────────────────────────────────────────────────────────────
  // GUARDAR CITA
  // ────────────────────────────────────────────────────────────────────────────

  Future<void> _confirmar() async {
    if (staffId == null ||
        servicioId == null ||
        fecha == null ||
        hora == null ||
        !_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa los pasos antes de confirmar')),
      );
      return;
    }

    final inicio = DateTime(
      fecha!.year,
      fecha!.month,
      fecha!.day,
      hora!.hour,
      hora!.minute,
    );
    final fin = inicio.add(Duration(minutes: duracionMin));

    // chequeo rápido de choque
    final probe = await db
        .collection('negocios')
        .doc(widget.negocioId)
        .collection('citas')
        .where('staffId', isEqualTo: staffId)
        .where('fechaInicio', isLessThan: Timestamp.fromDate(fin))
        .where('fechaFin', isGreaterThan: Timestamp.fromDate(inicio))
        .limit(1)
        .get();

    if (probe.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ese horario ya fue tomado. Elige otro.')),
      );
      await _loadDisponibilidadDelDia();
      return;
    }

    setState(() => saving = true);
    try {
      await db
          .collection('negocios')
          .doc(widget.negocioId)
          .collection('citas')
          .add({
        'staffId': staffId,
        'staffNombre': staffNombre,
        'servicioId': servicioId,
        'servicioNombre': servicioNombre,
        'duracionMin': duracionMin,
        'fechaInicio': Timestamp.fromDate(inicio),
        'fechaFin': Timestamp.fromDate(fin),
        'clienteNombre': _nombreCtrl.text.trim(),
        'clienteEmail': _emailCtrl.text.trim(),
        'clienteTelefono': _fonoCtrl.text.trim(),
        'estado': 'pendiente',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Cita creada! Te llegará el detalle al correo.'),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al crear cita: $e')),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // UI
  // ────────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (negocio == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final canPickDate = staffId != null && servicioId != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Agenda tu Cita')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // 0) Cabecera negocio (nombre + dirección)
            Text(
              negocio!['businessName'] ?? '',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            if (negocio!['address'] != null)
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16),
                  const SizedBox(width: 6),
                  Expanded(child: Text(negocio!['address'])),
                ],
              ),
            const SizedBox(height: 16),
            const Divider(),

            // 1) STAFF
            const _SectionTitle('1. Selecciona un profesional'),
            _StaffList(
              negocioId: widget.negocioId,
              selectedId: staffId,
              onSelected: (id, nombre) async {
                setState(() {
                  staffId = id;
                  staffNombre = nombre;
                  // reset pasos dependientes
                  servicioId = null;
                  servicioNombre = null;
                  fecha = null;
                  hora = null;
                });
                await _loadDisponibilidadDelDia();
              },
            ),
            const SizedBox(height: 16),

            // 2) SERVICIO
            const _SectionTitle('2. Selecciona un servicio'),
            _ServiciosList(
              negocioId: widget.negocioId,
              staffId: staffId,
              selectedId: servicioId,
              onSelected: (id, nombre, duracion) async {
                setState(() {
                  servicioId = id;
                  servicioNombre = nombre;
                  duracionMin = duracion;
                  // reset pasos dependientes
                  fecha = null;
                  hora = null;
                });
                await _loadDisponibilidadDelDia();
              },
            ),
            const SizedBox(height: 16),

            // 3) FECHA
            const _SectionTitle('3. Selecciona una fecha'),
            Stack(
              children: [
                CalendarDatePicker(
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 60)),
                  initialDate: fecha ?? DateTime.now(),
                  onDateChanged: (d) async {
                    if (!canPickDate) return; // bloquea interacción real
                    setState(() => fecha = d);
                    await _loadDisponibilidadDelDia();
                  },
                ),
                if (!canPickDate)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.35),
                      alignment: Alignment.center,
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Elige profesional y servicio para habilitar el calendario',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // 4) HORA
            const _SectionTitle('4. Selecciona una hora'),
            if (!canPickDate || fecha == null)
              const Text('Elige profesional, servicio y fecha para ver horarios.'),
            if (canPickDate && fecha != null)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: slots.map((s) {
                  final parsed = _parseHHmm(s);
                  final minutos = _toMinutes(parsed);

                  // Bloquea si algún minuto del rango cae en _ocupados
                  bool bloqueado = false;
                  for (int m = 0; m < duracionMin; m += 5) {
                    if (_ocupados.contains(minutos + m)) {
                      bloqueado = true;
                      break;
                    }
                  }

                  final selected = hora != null && _sameTime(hora!, parsed);

                  return ChoiceChip(
                    label: Text(s),
                    selected: selected,
                    onSelected: bloqueado
                        ? null
                        : (_) => setState(() => hora = parsed),
                    avatar: bloqueado
                        ? const Icon(Icons.lock_clock, size: 16)
                        : null,
                  );
                }).toList(),
              ),
            const SizedBox(height: 16),

            // 5) DATOS CLIENTE
            const _SectionTitle('5. Tus datos'),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nombreCtrl,
                    decoration: const InputDecoration(labelText: 'Tu nombre'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Tu correo electrónico'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                        (v == null || !v.contains('@')) ? 'Correo inválido' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _fonoCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Teléfono (opcional)'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // RESUMEN
            if (servicioNombre != null && staffNombre != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Resumen',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text('Servicio: $servicioNombre ($duracionMin min)'),
                      Text('Profesional: $staffNombre'),
                      if (fecha != null && hora != null)
                        Text(
                          'Fecha: ${_fmtDate(fecha!)} • ${hora!.format(context)}',
                        ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),

            // CONFIRMAR
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (saving ||
                        staffId == null ||
                        servicioId == null ||
                        fecha == null ||
                        hora == null)
                    ? null
                    : _confirmar,
                child: saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Confirmar Cita'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// WIDGETS AUXILIARES
// ──────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// STAFF con fallback:
/// 1) negocios/{negocioId}/staff (activo=true)
/// 2) si no hay, usa barberos (sin filtros para hotfix)
class _StaffList extends StatelessWidget {
  const _StaffList({
    required this.negocioId,
    required this.onSelected,
    this.selectedId,
  });

  final String negocioId;
  final void Function(String id, String nombre) onSelected;
  final String? selectedId;

  Future<bool> _existsNestedStaff() async {
    final q = await FirebaseFirestore.instance
        .collection('negocios')
        .doc(negocioId)
        .collection('staff')
        .limit(1)
        .get();
    return q.docs.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _existsNestedStaff(),
      builder: (_, existsSnap) {
        if (existsSnap.connectionState == ConnectionState.waiting) {
          return const LinearProgressIndicator();
        }
        final useNested = existsSnap.data == true;

        // HOTFIX: si no existe staff anidado, mostramos TODOS los barberos top-level
        // (sin filtros). Cuando agregues negocioId/activo, podemos volver a:
        // .where('negocioId', isEqualTo: negocioId).where('activo', isEqualTo: true)
        final Stream<QuerySnapshot> stream = useNested
            ? FirebaseFirestore.instance
                .collection('negocios')
                .doc(negocioId)
                .collection('staff')
                .where('activo', isEqualTo: true)
                .snapshots()
            : FirebaseFirestore.instance
                .collection('barberos')
                .snapshots();

        return StreamBuilder<QuerySnapshot>(
          stream: stream,
          builder: (_, snap) {
            if (!snap.hasData) return const LinearProgressIndicator();
            final docs = snap.data!.docs;
            if (docs.isEmpty) {
              return const Text('Este negocio aún no tiene personal registrado.');
            }
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: docs.map((d) {
                final data = d.data() as Map<String, dynamic>;
                final sel = selectedId == d.id;
                final nombre = (data['nombre'] ?? 'Profesional').toString();
                final foto = (data['fotoUrl'] ?? '').toString();

                return ChoiceChip(
                  selected: sel,
                  avatar: foto.isEmpty
                      ? const CircleAvatar(child: Icon(Icons.person, size: 16))
                      : CircleAvatar(backgroundImage: NetworkImage(foto)),
                  label: Text(nombre),
                  onSelected: (_) => onSelected(d.id, nombre),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }
}

/// SERVICIOS por profesional con fallback:
/// 1) negocios/{negocioId}/staff/{staffId}/servicios (activo=true)
/// 2) si no hay, barberos/{staffId}/servicios (activo=true)
class _ServiciosList extends StatelessWidget {
  const _ServiciosList({
    required this.negocioId,
    required this.onSelected,
    required this.staffId,
    this.selectedId,
  });

  final String negocioId;
  final String? staffId;
  final void Function(String id, String nombre, int duracionMin) onSelected;
  final String? selectedId;

  Future<bool> _existsNestedServices(String sid) async {
    final q = await FirebaseFirestore.instance
        .collection('negocios')
        .doc(negocioId)
        .collection('staff')
        .doc(sid)
        .collection('servicios')
        .limit(1)
        .get();
    return q.docs.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    if (staffId == null) {
      return const Text('Primero elige un profesional.');
    }

    return FutureBuilder<bool>(
      future: _existsNestedServices(staffId!),
      builder: (_, existsSnap) {
        if (existsSnap.connectionState == ConnectionState.waiting) {
          return const LinearProgressIndicator();
        }
        final useNested = existsSnap.data == true;

        final Stream<QuerySnapshot> stream = useNested
            ? FirebaseFirestore.instance
                .collection('negocios')
                .doc(negocioId)
                .collection('staff')
                .doc(staffId!)
                .collection('servicios')
                .where('activo', isEqualTo: true)
                .snapshots()
            : FirebaseFirestore.instance
                .collection('barberos')
                .doc(staffId!)
                .collection('servicios')
                .where('activo', isEqualTo: true)
                .snapshots();

        return StreamBuilder<QuerySnapshot>(
          stream: stream,
          builder: (_, snap) {
            if (!snap.hasData) return const LinearProgressIndicator();
            final docs = snap.data!.docs;
            if (docs.isEmpty) {
              return const Text('Este profesional aún no tiene servicios.');
            }

            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: docs.map((d) {
                final m = d.data() as Map<String, dynamic>;
                final sel = selectedId == d.id;
                final nombre = (m['nombre'] ?? 'Servicio').toString();
                final dur = (m['duracionMin'] ?? 60) as int;
                final precio = (m['precio'] ?? 0).toString();

                return ChoiceChip(
                  selected: sel,
                  label: Text('$nombre · ${dur}min · \$$precio'),
                  onSelected: (_) => onSelected(d.id, nombre, dur),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }
}
