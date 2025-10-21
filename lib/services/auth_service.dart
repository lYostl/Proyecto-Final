import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Future<String?> signUp({
    required String email,
    required String password,
    required String nombre,
    required String nombreNegocio,
    required String tipoNegocio,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = cred.user;
      if (user != null) {
        await _firestore.collection('negocios').doc(user.uid).set({
          'ownerId': user.uid,
          'ownerEmail': email,
          'ownerName': nombre,
          'businessName': nombreNegocio,
          'businessType': tipoNegocio,
          'createdAt': FieldValue.serverTimestamp(),
        });

        await user.sendEmailVerification();
      }
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'El correo ya está en uso por otra cuenta.';
        case 'invalid-email':
          return 'El formato del correo no es válido.';
        case 'weak-password':
          return 'La contraseña es demasiado débil (mínimo 6 caracteres).';
        default:
          return 'Error de registro: ${e.message ?? e.code}';
      }
    } catch (e) {
      return 'Ocurrió un error inesperado: $e';
    }
  }

  Future<String?> signIn({
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

      // 🔄 refrescar estado antes de validar verificación
      await cred.user?.reload();
      final user = _auth.currentUser;

      if (user != null && !user.emailVerified) {
        await _auth.signOut();
        return 'Tu correo no ha sido verificado. Revisa tu bandeja de entrada.';
      }

      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-email':
          return 'El formato del correo no es válido.';
        case 'user-not-found':
          return 'No se encontró una cuenta con ese correo.';
        case 'wrong-password':
          return 'La contraseña es incorrecta.';
        case 'user-disabled':
          return 'Esta cuenta ha sido deshabilitada.';
        default:
          return 'Error de inicio de sesión: ${e.message ?? e.code}';
      }
    } catch (e) {
      return 'Ocurrió un error inesperado: $e';
    }
  }

  Future<String?> signOut() async {
    try {
      await _auth.signOut();
      return null;
    } catch (e) {
      return 'Error al cerrar sesión: $e';
    }
  }

  User? get currentUser => _auth.currentUser;
}
