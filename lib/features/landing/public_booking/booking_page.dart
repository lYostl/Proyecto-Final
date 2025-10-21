// lib/features/public_booking/booking_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'booking_flow.dart'; // <-- usa el flujo que ya creaste


class BookingPage extends StatelessWidget {
  const BookingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final col = FirebaseFirestore.instance.collection('negocios');

    return Scaffold(
      appBar: AppBar(title: const Text('Elige un negocio')),
      body: StreamBuilder<QuerySnapshot>(
        stream: col.orderBy('businessName', descending: false).snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Text('Error al cargar negocios: ${snap.error}'),
            );
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text('Aún no hay negocios configurados.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final d = docs[i];
              final m = d.data() as Map<String, dynamic>;
              final nombre  = (m['businessName'] ?? 'Negocio').toString();
              final address = (m['address'] ?? 'Sin dirección').toString();
              final logo    = (m['logoUrl'] ?? '').toString();

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PublicBookingFlow(negocioId: d.id),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        // avatar/logo
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: const Color(0xFF1F2340),
                          backgroundImage:
                              (logo.isNotEmpty) ? NetworkImage(logo) : null,
                          child: (logo.isEmpty)
                              ? const Icon(Icons.store, size: 28)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        // texto
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nombre,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 14),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      address,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
