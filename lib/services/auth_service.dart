import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;

  // Registrar nuevo usuario
  Future<String?> registerWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      // Validaciones básicas antes de Firebase
      if (email.trim().isEmpty || password.isEmpty) {
        return 'Faltan rellenar datos';
      }
      if (!email.contains('@')) {
        return 'El correo debe contener @';
      }
      if (password.length < 6) {
        return 'La contraseña debe tener al menos 6 caracteres';
      }

      // Crear usuario en Firebase
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Enviar verificación (opcional)
      await _auth.currentUser?.sendEmailVerification();

      return null; // éxito
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'El correo ya está en uso';
        case 'invalid-email':
          return 'El correo no es válido';
        case 'weak-password':
          return 'La contraseña es demasiado débil (mínimo 6 caracteres)';
        case 'operation-not-allowed':
          return 'El método Email/Password no está habilitado en Firebase';
        default:
          return 'Error: ${e.message ?? e.code}';
      }
    } catch (e) {
      return 'Error desconocido: $e';
    }
  }

  // Iniciar sesión existente
  Future<String?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      if (email.trim().isEmpty || password.isEmpty) {
        return 'Faltan rellenar datos';
      }

      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Si quieres requerir verificación de correo:
      if (cred.user != null && !cred.user!.emailVerified) {
        return 'El correo no está verificado';
      }

      return null; // éxito
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-email':
          return 'Correo no válido';
        case 'user-not-found':
          return 'No existe una cuenta con ese correo';
        case 'wrong-password':
          return 'Contraseña incorrecta';
        case 'user-disabled':
          return 'La cuenta fue deshabilitada';
        default:
          return 'Error: ${e.message ?? e.code}';
      }
    } catch (e) {
      return 'Error desconocido: $e';
    }
  }

  // Cerrar sesión
  Future<String?> signOut() async {
    try {
      await _auth.signOut();
      return null;
    } catch (e) {
      return 'Error al cerrar sesión: $e';
    }
  }

  // Reenviar verificación
  Future<String?> sendVerificationEmail() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        return null;
      }
      return 'El usuario no existe o ya está verificado';
    } catch (e) {
      return 'Error al reenviar correo de verificación: $e';
    }
  }

  // Obtener usuario actual
  User? get currentUser => _auth.currentUser;
}
