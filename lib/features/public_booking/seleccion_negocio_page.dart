// lib/features/public_booking/seleccion_negocio_page.dart
import 'package:flutter/material.dart'; // <-- IMPORTACIÓN CORREGIDA
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

// Modelo simple para el Negocio
class Negocio {
  final String id;
  final String nombre;
  final String tipo; // El rubro

  Negocio({required this.id, required this.nombre, required this.tipo});

  factory Negocio.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Negocio(
      id: doc.id,
      nombre: data['businessName'] ?? 'Sin nombre',
      tipo: data['businessType'] ?? 'Sin rubro',
    );
  }
}

class SeleccionNegocioPage extends StatefulWidget {
  const SeleccionNegocioPage({super.key});

  @override
  State<SeleccionNegocioPage> createState() => _SeleccionNegocioPageState();
}

class _SeleccionNegocioPageState extends State<SeleccionNegocioPage> {
  // Stream para leer la colección 'negocios'
  final Stream<QuerySnapshot> _negociosStream = FirebaseFirestore.instance
      .collection('negocios')
      .snapshots();

  void _navegarAReserva(String negocioId) {
    // Usamos go_router para ir a la página de reserva con el ID
    context.push('/reservar/$negocioId');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Selecciona un Negocio')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _negociosStream,
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar los negocios.'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No hay negocios disponibles en este momento.'),
            );
          }

          // Si todo sale bien, construimos la lista
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              final negocio = Negocio.fromFirestore(document);

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16.0),
                  title: Text(
                    negocio.nombre,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(negocio.tipo),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _navegarAReserva(negocio.id),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
