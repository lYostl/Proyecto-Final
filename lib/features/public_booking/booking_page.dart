import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// --- Clase Personal (Sin cambios respecto a tu versión anterior) ---
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Personal && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
// --- Fin clase Personal ---

class BookingPage extends StatefulWidget {
  final String negocioId;
  const BookingPage({super.key, required this.negocioId});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  // --- AÑADIDO: Clave para el Formulario ---
  final _formKey = GlobalKey<FormState>();
  // ----------------------------------------

  Personal? _selectedPersonal;
  DateTime? _selectedDate;
  String? _selectedTime;
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  final List<String> _availableTimes = [
    '09:00', '10:00', '11:00', '12:00', '14:00', '15:00', '16:00', '17:00',
  ];

  // --- AÑADIDO: Validadores ---
  String? _validateNotEmpty(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName no puede estar vacío';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El correo no puede estar vacío';
    }
    // Expresión regular simple para validar email
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value)) {
      return 'Ingresa un correo válido';
    }
    return null;
  }
  // ---------------------------

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _selectedTime = null; // Resetea la hora al cambiar la fecha
      });
    }
  }

  Future<void> _submitBooking() async {
    // --- MODIFICADO: Usamos _formKey.currentState!.validate() ---
    // Y verificamos los campos no asociados al Form (Personal, Fecha, Hora)
    if (!(_formKey.currentState?.validate() ?? false)) {
      // Si la validación del Form falla, no hacemos nada más
      return;
    }
    if (_selectedPersonal == null || _selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Por favor, selecciona profesional, fecha y hora')),
      );
      return;
    }
    // ------------------------------------------------------------

    setState(() => _isLoading = true);

    try {
      final format = DateFormat("yyyy-MM-dd HH:mm");
      final DateTime fullDateTime = format.parse(
        "${DateFormat('yyyy-MM-dd').format(_selectedDate!)} $_selectedTime",
      );

      final citasCollection = FirebaseFirestore.instance.collection('citas');

      // --- Verificación de hora ocupada (Validación Cruzada) ---
      final querySnapshot = await citasCollection
          .where('personalId', isEqualTo: _selectedPersonal!.id)
          .where('fecha', isEqualTo: Timestamp.fromDate(fullDateTime))
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Si ya existe una cita para ese personal a esa hora
        throw Exception('Lo sentimos, esa hora ya está ocupada.');
      }
      // --- Fin Verificación ---

      await citasCollection.add({
        'personalId': _selectedPersonal!.id,
        'nombreCliente': _nombreController.text.trim(),
        'emailCliente': _emailController.text.trim(),
        'fecha': Timestamp.fromDate(fullDateTime),
        'servicio': _selectedPersonal!.servicio,
        'estado': 'confirmada',
        'negocioId': widget.negocioId,
      });

      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Cita agendada con éxito!'),
              backgroundColor: Colors.green,
            ),
          );
        Navigator.of(context).pop(); // Cierra la pantalla de booking
      }
    } catch (e) {
       if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al agendar: ${e.toString().replaceFirst("Exception: ", "")}'), // Limpia el mensaje
              backgroundColor: Colors.red,
            ),
          );
       }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

   @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agenda tu Cita')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        // --- AÑADIDO: Widget Form ---
        child: Form(
          key: _formKey, // Asignamos la clave
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Dropdown de Personal (sin cambios) ---
              StreamBuilder<QuerySnapshot>(
                 stream: FirebaseFirestore.instance
                    .collection('personal')
                    .where('negocioId', isEqualTo: widget.negocioId)
                    .snapshots(),
                 builder: (context, snapshot) {
                   if (snapshot.connectionState == ConnectionState.waiting) {
                     return const Center(child: CircularProgressIndicator());
                   }
                   if (snapshot.hasError) {
                     print('Error al cargar personal: ${snapshot.error}');
                     return const ListTile( title: Text('Error al cargar el personal.'),);
                   }
                   if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                     return const ListTile( title: Text('No hay personal disponible.'), );
                   }
                   final personalList = snapshot.data!.docs
                       .map((doc) => Personal.fromFirestore(doc))
                       .toList();
                   if (_selectedPersonal != null && !personalList.contains(_selectedPersonal)) {
                     _selectedPersonal = null;
                   }
                   return DropdownButtonFormField<Personal>(
                     value: _selectedPersonal,
                     hint: const Text('Selecciona un Profesional'),
                     onChanged: (Personal? newValue) => setState(() => _selectedPersonal = newValue),
                     items: personalList.map((personal) {
                       return DropdownMenuItem<Personal>(
                         value: personal,
                         child: Text(personal.nombre),
                       );
                     }).toList(),
                    // --- AÑADIDO: Validación para el Dropdown ---
                    validator: (value) => value == null ? 'Selecciona un profesional' : null,
                    // --------------------------------------------
                     decoration: const InputDecoration(
                       border: OutlineInputBorder(),
                       contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12,),
                     ),
                   );
                 },
               ),
              const SizedBox(height: 20),
              // --- Selector de Fecha (sin cambios) ---
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(
                  _selectedDate == null
                      ? 'Selecciona una Fecha'
                      : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                ),
                onTap: () => _selectDate(context),
                 shape: RoundedRectangleBorder(
                    side: BorderSide(color: Theme.of(context).dividerColor),
                    borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 20),
               // --- Selector de Hora (sin cambios) ---
               // Opcional: Mostrar solo si se ha seleccionado fecha
               if (_selectedDate != null)
                 Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: _availableTimes.map((time) {
                    final isSelected = _selectedTime == time;
                    return ChoiceChip(
                      label: Text(time),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                           setState(() => _selectedTime = time);
                        }
                      },
                      selectedColor: Theme.of(context).colorScheme.primary,
                       labelStyle: TextStyle(
                        color: isSelected ? Theme.of(context).colorScheme.onPrimary : null,
                      ),
                    );
                  }).toList(),
                )
               else
                 const Text('Selecciona una fecha para ver las horas disponibles.', style: TextStyle(color: Colors.grey)),

              const Divider(height: 40),

              // --- MODIFICADO: TextField a TextFormField con validator ---
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Tu Nombre'),
                validator: (value) => _validateNotEmpty(value, 'Tu Nombre'), // Validación
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Tu Correo Electrónico',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail, // Validación
              ),
              // ---------------------------------------------------------

              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitBooking,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox( // Para controlar el tamaño del indicador
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white)
                      )
                    : const Text('Confirmar Cita'),
              ),
            ],
          ),
        ),
        // --- Fin del Form ---
      ),
    );
  }
}