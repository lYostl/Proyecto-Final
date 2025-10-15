import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// Modelo para los barberos, para que el cliente pueda elegir
class Barbero {
  final String id;
  final String nombre;
  final String especialidad;
  Barbero({required this.id, required this.nombre, required this.especialidad});
}

class BookingPage extends StatefulWidget {
  const BookingPage({super.key});
  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  // Estado del formulario
  Barbero? _selectedBarbero;
  DateTime? _selectedDate;
  String? _selectedTime;
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  // Datos de ejemplo (en una app real, vendrían de Firestore)
  final List<Barbero> _barberos = [
    Barbero(
      id: '1',
      nombre: 'Carlos Gutierrez',
      especialidad: 'Cortes clásicos',
    ),
    Barbero(
      id: '2',
      nombre: 'Matias Rodriguez',
      especialidad: 'Diseños y Color',
    ),
  ];
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
    // Validaciones simples
    if (_selectedBarbero == null ||
        _selectedDate == null ||
        _selectedTime == null ||
        _nombreController.text.isEmpty ||
        _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, completa todos los campos')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Combinar fecha y hora
      final format = DateFormat("yyyy-MM-dd HH:mm");
      final DateTime fullDateTime = format.parse(
        "${DateFormat('yyyy-MM-dd').format(_selectedDate!)} $_selectedTime",
      );

      // Referencia a la colección 'citas' en Firestore
      final citasCollection = FirebaseFirestore.instance.collection('citas');

      // Crear el nuevo documento con los datos que definiste
      await citasCollection.add({
        'barberoId': _selectedBarbero!.id,
        'nombreCliente': _nombreController.text,
        'emailCliente': _emailController.text,
        'fecha': Timestamp.fromDate(fullDateTime), // Guardamos como Timestamp
        'servicio': 'Corte de Pelo', // Ejemplo, podría ser un selector
        'estado': 'confirmada',
      });

      // Mensaje de éxito y volver a la página anterior
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
            DropdownButtonFormField<Barbero>(
              value: _selectedBarbero,
              hint: const Text('Selecciona un Barbero'),
              onChanged: (Barbero? newValue) =>
                  setState(() => _selectedBarbero = newValue),
              items: _barberos.map((barbero) {
                return DropdownMenuItem<Barbero>(
                  value: barbero,
                  child: Text(barbero.nombre),
                );
              }).toList(),
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
