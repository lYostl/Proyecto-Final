import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:agendamientos/main.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Evitar llamadas nativas de Firebase
    const MethodChannel('plugins.flutter.io/firebase_core')
        .setMockMethodCallHandler((MethodCall methodCall) async {
      if (methodCall.method == 'Firebase#initializeCore' ||
          methodCall.method == 'Firebase#initializeApp') {
        return {
          'name': 'default',
          'options': {
            'apiKey': 'fakeKey',
            'appId': 'fakeApp',
            'messagingSenderId': 'fakeSender',
            'projectId': 'fakeProject',
          },
          'pluginConstants': {},
        };
      }
      return null;
    });

    await Firebase.initializeApp();
  });

  testWidgets('Flujo principal carga correctamente', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Cambia este texto por algo visible en tu pantalla principal
    expect(find.textContaining('Iniciar sesión'), findsOneWidget);

    // Simular interacción básica: pulsar botón (si existe)
    final loginButton = find.byType(ElevatedButton);
    if (loginButton.evaluate().isNotEmpty) {
      await tester.tap(loginButton);
      await tester.pump();
    }

    // Validar que se mostró algo después de pulsar
    expect(find.textContaining('Cargando'), findsNothing);
  });
}
