import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Estructura de datos usada:
/// - Catálogo del negocio:  negocios/{negocioId}/servicios/{servicioId}
///     { nombre, duracionMin, precio, activo }
/// - Servicios de un staff: negocios/{negocioId}/staff/{staffId}/servicios/{servicioId}
///     { nombre, duracionMin, precio, activo }
///
/// Esta pantalla administra la subcolección del staff.
/// Incluye: listar, crear/editar, activar/desactivar, eliminar e importar
/// servicios desde el catálogo del negocio.

class StaffServicesPage extends StatelessWidget {
  const StaffServicesPage({
    super.key,
    required this.negocioId,
    required this.staffId,
    required this.staffNombre,
  });

  final String negocioId;
  final String staffId;
  final String staffNombre;

  CollectionReference<Map<String, dynamic>> get _staffServiciosCol =>
      FirebaseFirestore.instance
          .collection('negocios')
          .doc(negocioId)
          .collection('staff')
          .doc(staffId)
          .collection('servicios');

  CollectionReference<Map<String, dynamic>> get _catalogoCol =>
      FirebaseFirestore.instance
          .collection('negocios')
          .doc(negocioId)
          .collection('servicios');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Servicios de $staffNombre'),
        actions: [
          IconButton(
            tooltip: 'Importar desde catálogo',
            onPressed: () => _importarDesdeCatalogo(context),
            icon: const Icon(Icons.download),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(context),
        label: const Text('Nuevo servicio'),
        icon: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _staffServiciosCol.orderBy('nombre').snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const LinearProgressIndicator();
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const _EmptyState();
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final doc = docs[i];
              final m = doc.data();
              final activo = (m['activo'] ?? true) as bool;
              final nombre = (m['nombre'] ?? 'Servicio').toString();
              final dur = (m['duracionMin'] ?? 60).toString();
              final precio = (m['precio'] ?? 0).toString();

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
                    ),
                  ),
                  title: Text(nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('Duración: ${dur}min  ·  Precio: \$${precio}'),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      Switch(
                        value: activo,
                        onChanged: (v) => doc.reference.update({'activo': v}),
                      ),
                      IconButton(
                        tooltip: 'Editar',
                        icon: const Icon(Icons.edit),
                        onPressed: () => _abrirFormulario(context, docId: doc.id, data: m),
                      ),
                      IconButton(
                        tooltip: 'Eliminar',
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final ok = await _confirm(context, '¿Eliminar "$nombre"?');
                          if (ok == true) await doc.reference.delete();
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _abrirFormulario(
    BuildContext context, {
    String? docId,
    Map<String, dynamic>? data,
  }) async {
    final isEdit = docId != null;
    final nombreCtrl = TextEditingController(text: data?['nombre']?.toString() ?? '');
    final durCtrl = TextEditingController(text: '${data?['duracionMin'] ?? 60}');
    final precioCtrl = TextEditingController(text: '${data?['precio'] ?? 0}');
    bool activo = (data?['activo'] ?? true) as bool;

    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isEdit ? 'Editar servicio' : 'Nuevo servicio'),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nombreCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: durCtrl,
                  decoration: const InputDecoration(labelText: 'Duración (min)'),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    if (n == null || n <= 0) return 'Ingresa un número válido';
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: precioCtrl,
                  decoration: const InputDecoration(labelText: 'Precio'),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final n = num.tryParse(v ?? '');
                    if (n == null || n < 0) return 'Ingresa un precio válido';
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text('Activo'),
                    const SizedBox(width: 8),
                    Switch(value: activo, onChanged: (v) {
                      activo = v;
                    }),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              final payload = {
                'nombre': nombreCtrl.text.trim(),
                'duracionMin': int.parse(durCtrl.text),
                'precio': num.parse(precioCtrl.text),
                'activo': activo,
                'updatedAt': FieldValue.serverTimestamp(),
                if (!isEdit) 'createdAt': FieldValue.serverTimestamp(),
              };

              if (isEdit) {
                await _staffServiciosCol.doc(docId).update(payload);
              } else {
                await _staffServiciosCol.add(payload);
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(isEdit ? 'Guardar' : 'Crear'),
          ),
        ],
      ),
    );
  }

  Future<void> _importarDesdeCatalogo(BuildContext context) async {
    final snap = await _catalogoCol.get();
    if (snap.docs.isEmpty) {
      _snack(context, 'El catálogo del negocio está vacío.');
      return;
    }

    final ya = await _staffServiciosCol.get();
    final existentes = ya.docs.map((d) => (d.data()['nombre'] ?? '').toString().toLowerCase()).toSet();

    int creados = 0;
    final batch = FirebaseFirestore.instance.batch();

    for (final d in snap.docs) {
      final m = d.data();
      final nombre = (m['nombre'] ?? '').toString();
      if (nombre.isEmpty) continue;
      // Evita duplicados por nombre
      if (existentes.contains(nombre.toLowerCase())) continue;

      final ref = _staffServiciosCol.doc();
      batch.set(ref, {
        'nombre': nombre,
        'duracionMin': (m['duracionMin'] ?? 60),
        'precio': (m['precio'] ?? 0),
        'activo': (m['activo'] ?? true),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      creados++;
    }

    if (creados == 0) {
      _snack(context, 'Nada para importar (posibles duplicados).');
      return;
    }

    await batch.commit();
    _snack(context, 'Importados $creados servicio(s).');
  }

  Future<bool?> _confirm(BuildContext context, String msg) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar'),
        content: Text(msg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );
  }

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.design_services, size: 48),
            const SizedBox(height: 12),
            const Text('Aún no hay servicios asignados a este profesional.'),
            const SizedBox(height: 8),
            Text(
              'Toca “Nuevo servicio” para crear uno o usa el botón de la barra superior '
              'para importar desde el catálogo del negocio.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
