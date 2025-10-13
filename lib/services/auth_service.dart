import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Iniciar sesión
  Future<String?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      // Si el correo no está verificado, avisar
      if (!_auth.currentUser!.emailVerified) {
        return 'Tu correo no está verificado. Revisa tu email y confirma. ¿Reenviar enlace desde el login?';
      }
      return null; // éxito
    } on FirebaseAuthException catch (e) {
      return _mapError(e);
    } catch (_) {
      return 'Error inesperado al iniciar sesión.';
    }
  }

  // Registrar
  Future<String?> registerWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);

      // Enviar verificación
      await _auth.currentUser?.sendEmailVerification();
      return null; // éxito
    } on FirebaseAuthException catch (e) {
      return _mapError(e);
    } catch (_) {
      return 'Error inesperado al registrar.';
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
      return 'No hay usuario para verificar.';
    } catch (_) {
      return 'No se pudo enviar el correo de verificación.';
    }
  }

  // Cerrar sesión
  Future<String?> signOut() async {
    try {
      await _auth.signOut();
      return null;
    } catch (_) {
      return 'Error al cerrar sesión';
    }
  }

  User? get currentUser => _auth.currentUser;

  String _mapError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'El correo no es válido.';
      case 'user-disabled':
        return 'Este usuario fue deshabilitado.';
      case 'user-not-found':
        return 'Usuario no encontrado.';
      case 'wrong-password':
        return 'Contraseña incorrecta.';
      case 'email-already-in-use':
        return 'El correo ya está en uso.';
      case 'weak-password':
        return 'La contraseña es muy débil (mínimo 6 caracteres).';
      case 'operation-not-allowed':
        return 'Operación no permitida.';
      default:
        return 'Error: ${e.message ?? e.code}';
    }
  }
}