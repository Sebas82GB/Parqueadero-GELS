import 'dart:async';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:parqueadero_app/core/network/api_exception.dart';
import 'package:parqueadero_app/core/theme/app_breakpoints.dart';
import 'package:parqueadero_app/core/theme/app_colors.dart';
import 'package:parqueadero_app/features/auth/data/auth_repository_impl.dart';
import 'package:parqueadero_app/features/auth/domain/auth_repository.dart';
import 'package:parqueadero_app/features/auth/domain/usuario.dart';
import 'package:parqueadero_app/features/auth/presentation/login_screen.dart';

/// Luminancia relativa y contraste WCAG 2.x — misma fórmula reimplementada en
/// `status_style_test.dart`, repetida acá (en vez de compartirse) para poder
/// assertar el contraste real de los colores del panel de marca en vez de
/// solo fijar los hex.
double _luminanciaRelativa(Color color) {
  double canal(double c) => c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * canal(color.r) + 0.7152 * canal(color.g) + 0.0722 * canal(color.b);
}

double _contraste(Color a, Color b) {
  final la = _luminanciaRelativa(a);
  final lb = _luminanciaRelativa(b);
  final claro = la > lb ? la : lb;
  final oscuro = la > lb ? lb : la;
  return (claro + 0.05) / (oscuro + 0.05);
}

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository authRepository;

  final usuario = Usuario(
    id: 'u1',
    nombre: 'Ana',
    email: 'ana@test.com',
    rol: RolUsuario.operador,
    activo: true,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  setUp(() {
    authRepository = MockAuthRepository();
    // SessionNotifier intenta restaurar la sesión apenas se construye el
    // árbol; sin este stub cualquier test lanzaría MissingStubError.
    when(() => authRepository.restoreSession()).thenAnswer((_) async => null);
  });

  // Solo se sobrescribe authRepositoryProvider: es lo que permite testear la
  // pantalla sin construir dioProvider/tokenStorageProvider (y por lo tanto
  // sin tocar flutter_secure_storage, que no tiene canal de plataforma en
  // los widget tests) — pago directo de la regla "los widgets nunca tocan dio".
  Future<void> pumpLoginScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(authRepository)],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pump();
  }

  Future<void> fillAndSubmit(WidgetTester tester) async {
    await tester.enterText(find.byType(TextFormField).at(0), 'ana@test.com');
    await tester.enterText(find.byType(TextFormField).at(1), '12345678');
    await tester.tap(find.byType(ElevatedButton));
  }

  testWidgets('cargando: muestra spinner y deshabilita el botón mientras el login está pendiente', (tester) async {
    final completer = Completer<Usuario>();
    when(
      () => authRepository.login(email: any(named: 'email'), password: any(named: 'password')),
    ).thenAnswer((_) => completer.future);

    await pumpLoginScreen(tester);
    await fillAndSubmit(tester);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);

    completer.complete(usuario);
    await tester.pumpAndSettle();
  });

  testWidgets('error: muestra el mensaje del backend tal cual, sin reescribirlo', (tester) async {
    when(() => authRepository.login(email: any(named: 'email'), password: any(named: 'password'))).thenThrow(
      const ApiException(code: 'CREDENCIALES_INVALIDAS', message: 'Credenciales inválidas', statusCode: 401),
    );

    await pumpLoginScreen(tester);
    await fillAndSubmit(tester);
    await tester.pumpAndSettle();

    expect(find.text('Credenciales inválidas'), findsOneWidget);
  });

  testWidgets('éxito: sin mensaje de error ni spinner luego de un login exitoso', (tester) async {
    when(
      () => authRepository.login(email: any(named: 'email'), password: any(named: 'password')),
    ).thenAnswer((_) async => usuario);

    await pumpLoginScreen(tester);
    await fillAndSubmit(tester);
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.textContaining('inválidas'), findsNothing);
  });

  testWidgets('validación en vivo: un correo con formato inválido muestra error sin necesidad de enviar', (
    tester,
  ) async {
    await pumpLoginScreen(tester);

    await tester.enterText(find.byType(TextFormField).at(0), 'no-es-un-correo');
    await tester.pump();

    expect(find.text('Ingresa un correo válido'), findsOneWidget);
    verifyNever(() => authRepository.login(email: any(named: 'email'), password: any(named: 'password')));
  });

  testWidgets('toggle de contraseña: cambia obscureText y el ícono al tocar el sufijo', (tester) async {
    await pumpLoginScreen(tester);

    // TextFormField no expone obscureText/autofocus directamente: delega en
    // el TextField interno que sí los tiene como campos públicos.
    final passwordFieldFinder = find.byType(TextField).at(1);
    expect(tester.widget<TextField>(passwordFieldFinder).obscureText, isTrue);
    expect(find.byIcon(Icons.visibility), findsOneWidget);

    await tester.tap(find.byIcon(Icons.visibility));
    await tester.pump();

    expect(tester.widget<TextField>(passwordFieldFinder).obscureText, isFalse);
    expect(find.byIcon(Icons.visibility_off), findsOneWidget);
  });

  testWidgets('error de red: se distingue visualmente del error de credenciales, mismo mensaje', (tester) async {
    when(() => authRepository.login(email: any(named: 'email'), password: any(named: 'password'))).thenThrow(
      const NetworkException(message: 'No hay conexión con el servidor.', type: DioExceptionType.connectionError),
    );

    await pumpLoginScreen(tester);
    await fillAndSubmit(tester);
    await tester.pumpAndSettle();

    expect(find.text('No hay conexión con el servidor.'), findsOneWidget);
    expect(find.byIcon(Icons.wifi_off), findsOneWidget);
  });

  testWidgets('autofocus: el campo de correo tiene el foco al entrar a la pantalla', (tester) async {
    await pumpLoginScreen(tester);

    final emailField = tester.widget<TextField>(find.byType(TextField).at(0));
    expect(emailField.autofocus, isTrue);
  });

  // Hallazgo de la auditoría UX original: la pantalla no llevaba ningún
  // token de marca. Sigue valiendo con el panel de marca del rediseño: el
  // foco de ambos campos se tiñe de demarcación, no del verdeSenal genérico
  // del tema.
  testWidgets('acento de marca: el borde de foco de ambos campos es demarcación', (tester) async {
    await pumpLoginScreen(tester);

    // TextFormField no expone `decoration` directamente (igual que
    // obscureText/autofocus arriba): se verifica en el TextField interno.
    for (final campo in tester.widgetList<TextField>(find.byType(TextField))) {
      final focusedBorder = campo.decoration?.focusedBorder as OutlineInputBorder?;
      expect(focusedBorder?.borderSide.color, AppColors.demarcacion);
    }
  });

  // Regresión responsive: el viewport de test por defecto (800×600) ya cae
  // en la rama angosta, así que sin el segundo test acá nada ejercita
  // realmente el split screen de escritorio.
  group('responsive según ancho de pantalla', () {
    Future<void> conAncho(WidgetTester tester, double width) async {
      final view = tester.view;
      view.physicalSize = Size(width, 800);
      view.devicePixelRatio = 1.0;
      addTearDown(view.resetPhysicalSize);
      addTearDown(view.resetDevicePixelRatio);
      await pumpLoginScreen(tester);
    }

    testWidgets('angosta (<1024): panel de marca apilado arriba del formulario', (tester) async {
      await conAncho(tester, AppBreakpoints.tablet - 1);

      expect(find.byKey(const ValueKey('loginLayoutAngosto')), findsOneWidget);
      expect(find.byKey(const ValueKey('loginLayoutAncho')), findsNothing);
    });

    testWidgets('ancha (≥1024, escritorio/web): split screen con el panel de marca al lado', (tester) async {
      await conAncho(tester, AppBreakpoints.tablet);

      expect(find.byKey(const ValueKey('loginLayoutAncho')), findsOneWidget);
      expect(find.byKey(const ValueKey('loginLayoutAngosto')), findsNothing);
    });
  });

  // Regresión de contraste: `demarcacion` solo puede vivir como texto sobre
  // `asfalto` (nunca sobre una superficie clara). El panel de marca la usa
  // como texto en dos combinaciones — opacidad plena y la bajada al 80% — y
  // ambas deben pasar WCAG AA (4.5:1) sobre el fondo real donde se pintan.
  group('contraste AA del panel de marca', () {
    test('demarcación a opacidad plena sobre asfalto', () {
      final contraste = _contraste(AppColors.demarcacion, AppColors.asfalto);
      expect(contraste, greaterThanOrEqualTo(4.5), reason: 'contraste real: $contraste');
    });

    test('demarcación al 80% de opacidad sobre asfalto', () {
      final colorEfectivo = Color.alphaBlend(AppColors.demarcacion.withValues(alpha: 0.8), AppColors.asfalto);
      final contraste = _contraste(colorEfectivo, AppColors.asfalto);
      expect(contraste, greaterThanOrEqualTo(4.5), reason: 'contraste real: $contraste');
    });

    test('concreto sobre asfalto', () {
      final contraste = _contraste(AppColors.concreto, AppColors.asfalto);
      expect(contraste, greaterThanOrEqualTo(4.5), reason: 'contraste real: $contraste');
    });
  });
}
