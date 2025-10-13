import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with SingleTickerProviderStateMixin {
  final _loginFormKey = GlobalKey<FormState>();
  final _regFormKey = GlobalKey<FormState>();

  final _loginEmailCtrl = TextEditingController();
  final _loginPassCtrl = TextEditingController();
  final _regEmailCtrl = TextEditingController();
  final _regPassCtrl = TextEditingController();

  bool _loading = false;
  late TabController _tab;
  final _auth = AuthService();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this); // 0: login, 1: register
  }

  @override
  void dispose() {
    _loginEmailCtrl.dispose();
    _loginPassCtrl.dispose();
    _regEmailCtrl.dispose();
    _regPassCtrl.dispose();
    _tab.dispose();
    super.dispose();
  }

  // Validadores
  String? _emailValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Faltan rellenar datos';
    if (!v.contains('@')) return 'El correo debe contener @';
    return null;
  }

  String? _passwordValidator(String? v) {
    if (v == null || v.isEmpty) return 'Faltan rellenar datos';
    if (v.length < 6) return 'Mínimo 6 caracteres';
    return null;
  }

  Future<void> _doLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final err = await _auth.signInWithEmail(
      email: _loginEmailCtrl.text.trim(),
      password: _loginPassCtrl.text.trim(),
    );
    setState(() => _loading = false);

    if (err == null) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      if (err.contains('no está verificado')) {
        _showSnack(err, action: TextButton(
          onPressed: () async {
            final e = await _auth.sendVerificationEmail();
            if (mounted) {
              _showSnack(e == null ? 'Enlace reenviado. Revisa tu correo.' : e);
            }
          },
          child: const Text('Reenviar', style: TextStyle(color: Colors.white)),
        ));
      } else {
        _showSnack(err);
      }
    }
  }

  Future<void> _doRegister() async {
    if (!_regFormKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final err = await _auth.registerWithEmail(
      email: _regEmailCtrl.text.trim(),
      password: _regPassCtrl.text.trim(),
    );
    setState(() => _loading = false);

    if (err == null) {
      if (!mounted) return;
      _showSnack('Te has registrado exitosamente. Verifica tu correo para poder iniciar sesión.');
      _tab.animateTo(0); // ir a Login
    } else {
      _showSnack(err);
    }
  }

  void _showSnack(String msg, {Widget? action}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), action: action == null ? null : SnackBarAction(label: '', onPressed: () {}), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final card = Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 460,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('TuEmpresa', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              TabBar(
                controller: _tab,
                tabs: const [Tab(text: 'Iniciar sesión'), Tab(text: 'Registrarse')],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 280,
                child: TabBarView(
                  controller: _tab,
                  children: [
                    // LOGIN
                    Form(
                      key: _loginFormKey,
                      child: Column(
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
                            validator: (v) => (v == null || v.isEmpty) ? 'Faltan rellenar datos' : null,
                            obscureText: true,
                          ),
                          const Spacer(),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _doLogin,
                              child: _loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Entrar'),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => _tab.animateTo(1),
                            child: const Text('¿No tienes cuenta? Regístrate'),
                          ),
                        ],
                      ),
                    ),

                    // REGISTRO
                    Form(
                      key: _regFormKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _regEmailCtrl,
                            decoration: const InputDecoration(labelText: 'Correo'),
                            validator: _emailValidator,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _regPassCtrl,
                            decoration: const InputDecoration(labelText: 'Contraseña (mínimo 6 caracteres)'),
                            validator: _passwordValidator,
                            obscureText: true,
                          ),
                          const Spacer(),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _doRegister,
                              child: _loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Crear cuenta'),
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: card,
        ),
      ),
    );
  }
}
