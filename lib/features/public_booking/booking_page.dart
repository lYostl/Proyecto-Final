import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// --- Clase Personal con igualdad implementada ---
class Personal {
  final String id;
  final String nombre;
  final String servicio;

  Personal({required this.id, required this.nombre, required this.servicio});

  factory Personal.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Personal(
      id: doc.id,
      nombre: data['nombre'] ?? 'Sin nombre',
      servicio: data['servicio'] ?? 'Sin servicio',
    );
  }

  // --- AÑADIDO: Lógica de igualdad ---
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true; // Si es el mismo objeto en memoria

    return other is Personal && // Si el otro objeto es de tipo Personal
        other.id == id; // Comparamos solo por ID (suficiente en este caso)
  }

  @override
  int get hashCode => id.hashCode; // El hashCode debe basarse en lo que usas para ==
  // --- FIN AÑADIDO ---
}
// --- Fin clase Personal ---

class BookingPage extends StatefulWidget {
  final String negocioId;
  const BookingPage({super.key, required this.negocioId});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  // --- CAMBIO 2: Actualizamos el tipo de la variable ---
  Personal? _selectedPersonal;
  // ----------------------------------------------------
  DateTime? _selectedDate;
  String? _selectedTime;
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  final List<String> _availableTimes = [
    '09:00',
    '10:00',
    '11:00',
    '12:00',
    '14:00',
    '15:00',
    '16:00',
    '17:00',
  ];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitBooking() async {
    // --- CAMBIO 3: Usamos la nueva variable ---
    if (_selectedPersonal == null ||
        _selectedDate == null ||
        _selectedTime == null ||
        _nombreController.text.isEmpty ||
        _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, completa todos los campos')),
      );
      return;
    }
    // ------------------------------------------

    setState(() => _isLoading = true);

    try {
      final format = DateFormat("yyyy-MM-dd HH:mm");
      final DateTime fullDateTime = format.parse(
        "${DateFormat('yyyy-MM-dd').format(_selectedDate!)} $_selectedTime",
      );

      final citasCollection = FirebaseFirestore.instance.collection('citas');

      // --- CAMBIO 4: Actualizamos los campos a guardar ---
      await citasCollection.add({
        'personalId': _selectedPersonal!.id, // <-- Campo actualizado
        'nombreCliente': _nombreController.text,
        'emailCliente': _emailController.text,
        'fecha': Timestamp.fromDate(fullDateTime),
        'servicio': _selectedPersonal!.servicio, // <-- Usamos el servicio real
        'estado': 'confirmada',
        'negocioId': widget.negocioId,
      });
      // -------------------------------------------------

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Cita agendada con éxito!'),
          backgroundColor: Colors.green,
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al agendar la cita: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agenda tu Cita')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StreamBuilder<QuerySnapshot>(
              // --- CAMBIO 5: Apuntamos a la nueva colección ---
              stream: FirebaseFirestore.instance
                  .collection('personal') // <-- ¡AQUÍ!
                  .where('negocioId', isEqualTo: widget.negocioId)
                  .snapshots(),
              // -----------------------------------------------
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  // Añadimos un mensaje de error más específico aquí
                  print('Error al cargar personal: ${snapshot.error}');
                  return const ListTile(
                    title: Text('Error al cargar el personal.'),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const ListTile(
                    // --- CAMBIO 6: Texto actualizado ---
                    title: Text('No hay personal disponible en este momento.'),
                    // ---------------------------------
                  );
                }

                // --- CAMBIO 7: Usamos la nueva clase y variables ---
                final personalList = snapshot.data!.docs
                    .map((doc) => Personal.fromFirestore(doc))
                    .toList();

                // Intentamos mantener la selección si ya existía y está en la nueva lista
                if (_selectedPersonal != null &&
                    !personalList.contains(_selectedPersonal)) {
                  _selectedPersonal =
                      null; // Resetea si el seleccionado ya no está
                }

                return DropdownButtonFormField<Personal>(
                  value: _selectedPersonal,
                  hint: const Text('Selecciona un Profesional'),
                  onChanged: (Personal? newValue) =>
                      setState(() => _selectedPersonal = newValue),
                  items: personalList.map((personal) {
                    return DropdownMenuItem<Personal>(
                      value: personal, // <-- El objeto Personal completo
                      child: Text(personal.nombre),
                    );
                  }).toList(),
                  // -------------------------------------------------
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(
                _selectedDate == null
                    ? 'Selecciona una Fecha'
                    : DateFormat('dd/MM/yyyy').format(_selectedDate!),
              ),
              onTap: () => _selectDate(context),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: _availableTimes.map((time) {
                final isSelected = _selectedTime == time;
                return ChoiceChip(
                  label: Text(time),
                  selected: isSelected,
                  onSelected: (selected) =>
                      setState(() => _selectedTime = time),
                  selectedColor: Theme.of(context).colorScheme.primary,
                );
              }).toList(),
            ),
            const Divider(height: 40),
            TextField(
              controller: _nombreController,
              decoration: const InputDecoration(labelText: 'Tu Nombre'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Tu Correo Electrónico',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitBooking,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Confirmar Cita'),
            ),
          ],
        ),
      ),
    );
  }
}
