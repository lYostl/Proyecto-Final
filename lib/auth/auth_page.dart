import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage>
    with SingleTickerProviderStateMixin {
  // Claves para los formularios de validación
  final _loginFormKey = GlobalKey<FormState>();
  final _regFormKey = GlobalKey<FormState>();

  // Controladores para Login
  final _loginEmailCtrl = TextEditingController();
  final _loginPassCtrl = TextEditingController();

  // Controladores para Registro
  final _regNombreCtrl = TextEditingController();
  final _regNegocioNombreCtrl = TextEditingController();
  final _regEmailCtrl = TextEditingController();
  final _regPassCtrl = TextEditingController();
  String? _tipoNegocioSeleccionado;
  final List<String> _tiposDeNegocio = [
    'Barbería',
    'Peluquería',
    'Salón de Belleza',
    'Spa',
    'Manicure',
    'Otro',
  ];

  bool _loading = false;
  late TabController _tab;
  final _auth = AuthService();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _loginEmailCtrl.dispose();
    _loginPassCtrl.dispose();
    _regNombreCtrl.dispose();
    _regNegocioNombreCtrl.dispose();
    _regEmailCtrl.dispose();
    _regPassCtrl.dispose();
    _tab.dispose();
    super.dispose();
  }

  // Validadores
  String? _textValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Este campo es obligatorio';
    return null;
  }

  String? _emailValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'El correo es obligatorio';
    if (!v.contains('@')) return 'El correo no es válido';
    return null;
  }

  String? _passwordValidator(String? v) {
    if (v == null || v.isEmpty) return 'La contraseña es obligatoria';
    if (v.length < 6) return 'Mínimo 6 caracteres';
    return null;
  }

  // =================================================================
  // === FUNCIÓN _doLogin ACTUALIZADA CON NAVEGACIÓN ===
  // =================================================================
  Future<void> _doLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final err = await _auth.signIn(
      email: _loginEmailCtrl.text.trim(),
      password: _loginPassCtrl.text.trim(),
    );

    if (!mounted) return;

    if (err != null) {
      // Error: Oculta el spinner y muestra el mensaje
      setState(() => _loading = false);
      _showSnack(err);
    } else {
      // Éxito: Cierra la página (el spinner desaparece con ella)
      // AuthWrapper se encargará de mostrar el Dashboard.
      Navigator.of(context).pop();
    }
  }
  // =================================================================
  // === FIN DE LA FUNCIÓN ACTUALIZADA ===
  // =================================================================

  Future<void> _doRegister() async {
    if (!_regFormKey.currentState!.validate()) return;
    if (_tipoNegocioSeleccionado == null) {
      _showSnack('Por favor, selecciona un tipo de negocio.');
      return;
    }

    setState(() => _loading = true);

    final err = await _auth.signUp(
      email: _regEmailCtrl.text.trim(),
      password: _regPassCtrl.text.trim(),
      nombre: _regNombreCtrl.text.trim(),
      nombreNegocio: _regNegocioNombreCtrl.text.trim(),
      tipoNegocio: _tipoNegocioSeleccionado!,
    );

    if (mounted) {
      setState(() => _loading = false);
      if (err != null) {
        _showSnack(err);
      } else {
        _showSnack(
          '¡Registro exitoso! Revisa tu correo para verificar la cuenta y poder iniciar sesión.',
        );
        _tab.animateTo(0);
      }
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 12.0,
              ),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: SizedBox(
                  width: 460,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'TuEmpresa',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TabBar(
                          controller: _tab,
                          tabs: const [
                            Tab(text: 'Iniciar sesión'),
                            Tab(text: 'Registrarse'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 450,
                          child: TabBarView(
                            controller: _tab,
                            children: [_buildLoginForm(), _buildRegisterForm()],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _loginFormKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextFormField(
            controller: _loginEmailCtrl,
            decoration: const InputDecoration(labelText: 'Correo'),
            validator: _emailValidator,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _loginPassCtrl,
            decoration: const InputDecoration(labelText: 'Contraseña'),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Ingresa tu contraseña' : null,
            obscureText: true,
          ),

          // =================================================================
          // === ¡BOTÓN AÑADIDO! ===
          // =================================================================
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _showPasswordResetDialog,
                child: const Text('¿Olvidaste tu contraseña?'),
              ),
            ],
          ),
          // =================================================================
          
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _doLogin,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Entrar'),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => _tab.animateTo(1),
            child: const Text('¿No tienes cuenta? Regístrate'),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm() {
    return Form(
      key: _regFormKey,
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20), // Espacio extra al inicio
            TextFormField(
              controller: _regNombreCtrl,
              decoration: const InputDecoration(
                labelText: 'Tu Nombre y Apellido',
              ),
              validator: _textValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _regNegocioNombreCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre de tu Negocio',
              ),
              validator: _textValidator,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _tipoNegocioSeleccionado,
              hint: const Text('Tipo de Negocio'),
              onChanged: (String? newValue) =>
                  setState(() => _tipoNegocioSeleccionado = newValue),
              items: _tiposDeNegocio.map((tipo) {
                return DropdownMenuItem<String>(value: tipo, child: Text(tipo));
              }).toList(),
              validator: (value) => value == null ? 'Selecciona un tipo' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _regEmailCtrl,
              decoration: const InputDecoration(
                labelText: 'Correo Electrónico',
              ),
              validator: _emailValidator,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _regPassCtrl,
              decoration: const InputDecoration(
                labelText: 'Crea una Contraseña',
              ),
              validator: _passwordValidator,
              obscureText: true,
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _doRegister,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Crear Cuenta Gratis'),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _tab.animateTo(0),
              child: const Text('¿Ya tienes cuenta? Inicia sesión'),
            ),
          ],
        ),
      ),
    );
  }

  // =================================================================
  // === ¡NUEVA FUNCIÓN AÑADIDA! ===
  // =================================================================
  Future<void> _showPasswordResetDialog() async {
    final _resetEmailCtrl = TextEditingController();
    // Pre-llenamos el correo si el usuario ya lo escribió en el login
    _resetEmailCtrl.text = _loginEmailCtrl.text.trim();

    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Restablecer Contraseña'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text(
                  'Ingresa tu correo y te enviaremos un enlace para restablecer tu contraseña.',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _resetEmailCtrl,
                  autofocus: true,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Cierra el pop-up
              },
            ),
            ElevatedButton(
              child: const Text('Enviar'),
              onPressed: () async {
                final email = _resetEmailCtrl.text.trim();
                if (email.isEmpty) {
                  _showSnack("Por favor, ingresa un correo.");
                  return; // Mantenemos el pop-up abierto
                }
                
                // Mostramos un snackbar de "enviando..."
                _showSnack("Enviando correo...");

                // Llamamos al servicio
                final err = await _auth.sendPasswordReset(email);

                if (!mounted) return; // Chequeo de seguridad

                Navigator.of(dialogContext).pop(); // Cierra el pop-up

                if (err != null) {
                  // Si hubo un error
                  _showSnack(err);
                } else {
                  // Si tuvo éxito
                  _showSnack('¡Correo enviado! Revisa tu bandeja de entrada.');
                }
              },
            ),
          ],
        );
      },
    );
  }
}