import 'package:agendamientos/auth/auth_page.dart';
import 'package:agendamientos/features/admin_dashboard/admin_dashboard.dart';
import 'package:agendamientos/features/landing/landing_page.dart';
import 'package:agendamientos/features/public_booking/booking_page.dart';
// --- CAMBIO 1: Importamos la nueva página que creamos ---
import 'package:agendamientos/features/public_booking/seleccion_negocio_page.dart';
// --- FIN CAMBIO 1 ---
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async'; // Necesario para StreamSubscription

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

// --- Definir el Router ---
final GoRouter _router = GoRouter(
  initialLocation: '/', // Ruta inicial
  routes: [
    // Ruta principal (Landing Page pública)
    GoRoute(path: '/', builder: (context, state) => const LandingPage()),
    // Ruta para la página de autenticación (Login/Registro)
    GoRoute(path: '/auth', builder: (context, state) => const AuthPage()),

    // --- CAMBIO 2: Añadimos la ruta para la nueva página ---
    GoRoute(
      path: '/seleccionar-negocio',
      builder: (context, state) => const SeleccionNegocioPage(),
    ),
    // --- FIN CAMBIO 2 ---

    // Ruta para la página de reserva pública, con ID de negocio como parámetro
    GoRoute(
      path: '/reservar/:negocioId', // :negocioId es el parámetro
      builder: (context, state) {
        // Extraemos el negocioId de la URL
        final negocioId = state.pathParameters['negocioId'];
        // Si no hay ID en la URL (poco probable pero posible), mostramos error
        if (negocioId == null || negocioId.isEmpty) {
          // Puedes mostrar una página de error más elaborada si quieres
          return const Scaffold(
            body: Center(
              child: Text('Error: ID de negocio inválido en la URL'),
            ),
          );
        }
        // Pasamos el ID extraído a la BookingPage
        return BookingPage(negocioId: negocioId);
      },
    ),
    // Ruta para el Dashboard del Administrador
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const AdminDashboardPage(),
      // --- Protección de Ruta ---
      // Redirige al login si el usuario no está autenticado
      redirect: (context, state) async {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          // No hay usuario logueado, redirige a la página de autenticación
          return '/auth';
        }
        // Hay usuario logueado, permite el acceso al dashboard
        return null;
      },
    ),
  ],
  // --- Manejo de redirección global basado en AuthWrapper ---
  // Esto escucha cambios de autenticación y redirige automáticamente
  refreshListenable: GoRouterRefreshStream(
    FirebaseAuth.instance.authStateChanges(),
  ),
  redirect: (context, state) async {
    final user = FirebaseAuth.instance.currentUser;
    final loggingIn =
        state.matchedLocation == '/auth'; // ¿Estamos en la página de auth?
    final isPublicBooking = state.matchedLocation.startsWith(
      '/reservar/',
    ); // ¿Estamos en una página pública de reserva?
    final isLanding = state.matchedLocation == '/'; // ¿Estamos en la landing?

    // --- CAMBIO 3: Añadimos la nueva ruta a las rutas públicas permitidas ---
    final isBusinessSelection = state.matchedLocation == '/seleccionar-negocio';
    // --- FIN CAMBIO 3 ---

    // Si no hay usuario logueado...
    if (user == null) {
      // ...permite el acceso solo a las rutas públicas
      // Si intenta ir a otro lado (ej: /dashboard), redirige a '/'
      return (isLanding || loggingIn || isPublicBooking || isBusinessSelection)
          ? null
          : '/';
    }

    // Si hay usuario logueado Y está intentando ir a /auth o /, redirige al dashboard
    if (loggingIn || isLanding) return '/dashboard';

    // En cualquier otro caso (usuario logueado y no está en una ruta pública), permite continuar
    return null;
  },
  // Opcional: Manejo de errores de ruta (si escriben una URL que no existe)
  errorBuilder: (context, state) =>
      Scaffold(body: Center(child: Text('Ruta no encontrada: ${state.error}'))),
);
// ------------------------------

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // --- Usar MaterialApp.router ---
    return MaterialApp.router(
      routerConfig: _router, // Usamos la configuración del router
      // ---------------------------------
      title: 'TuEmpresa',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D0F1A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C3AED),
          brightness: Brightness.dark,
        ),
        // Puedes añadir más personalización del tema aquí si lo necesitas
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', ''), // Español
      ],
    );
  }
}

// --- Clase auxiliar para refrescar GoRouter con Streams (necesaria) ---
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
