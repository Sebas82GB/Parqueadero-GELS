import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:parqueadero_app/core/network/api_exception.dart';
import 'package:parqueadero_app/core/theme/app_colors.dart';
import 'package:parqueadero_app/features/auth/data/auth_repository_impl.dart';
import 'package:parqueadero_app/features/auth/domain/auth_repository.dart';
import 'package:parqueadero_app/features/auth/domain/usuario.dart';
import 'package:parqueadero_app/features/auth/presentation/login_screen.dart';

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

  // Hallazgo de la auditoría UX: la pantalla no llevaba ningún token de
  // marca. El acento vive solo en el borde de foco (demarcación), sin
  // agregar ningún elemento decorativo nuevo a una pantalla que debe
  // quedarse tranquila fuera de la cuadrícula de celdas.
  testWidgets('acento de marca: el borde de foco de ambos campos es demarcación', (tester) async {
    await pumpLoginScreen(tester);

    // TextFormField no expone `decoration` directamente (igual que
    // obscureText/autofocus arriba): se verifica en el TextField interno.
    for (final campo in tester.widgetList<TextField>(find.byType(TextField))) {
      final focusedBorder = campo.decoration?.focusedBorder as OutlineInputBorder?;
      expect(focusedBorder?.borderSide.color, AppColors.demarcacion);
    }
  });
}
