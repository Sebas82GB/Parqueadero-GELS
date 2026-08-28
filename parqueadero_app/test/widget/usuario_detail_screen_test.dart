import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:parqueadero_app/core/network/api_exception.dart';
import 'package:parqueadero_app/core/widgets/acceso_restringido.dart';
import 'package:parqueadero_app/core/widgets/empty_state.dart';
import 'package:parqueadero_app/features/auth/data/auth_repository_impl.dart';
import 'package:parqueadero_app/features/auth/domain/auth_repository.dart';
import 'package:parqueadero_app/features/auth/domain/usuario.dart';
import 'package:parqueadero_app/features/usuarios/data/usuario_repository_impl.dart';
import 'package:parqueadero_app/features/usuarios/domain/usuario_repository.dart';
import 'package:parqueadero_app/features/usuarios/presentation/usuario_detail_screen.dart';

class MockUsuarioRepository extends Mock implements UsuarioRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockUsuarioRepository usuarioRepository;
  late MockAuthRepository authRepository;

  Usuario sesion(RolUsuario rol) => Usuario(
    id: 'admin1',
    nombre: 'Ana',
    email: 'ana@test.com',
    rol: rol,
    activo: true,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  Usuario usuarioEditado({RolUsuario rol = RolUsuario.operador, int? baseInicialTurno, bool activo = true}) =>
      Usuario(
        id: 'u1',
        nombre: 'Carlos',
        email: 'carlos@test.com',
        rol: rol,
        activo: activo,
        baseInicialTurno: baseInicialTurno,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      );

  setUpAll(() {
    registerFallbackValue(RolUsuario.operador);
  });

  setUp(() {
    usuarioRepository = MockUsuarioRepository();
    authRepository = MockAuthRepository();
    when(() => authRepository.restoreSession()).thenAnswer((_) async => sesion(RolUsuario.admin));
  });

  Future<void> pumpDetailScreen(
    WidgetTester tester, {
    RolUsuario sesionRol = RolUsuario.admin,
    Usuario? usuarioInicial,
  }) async {
    when(() => authRepository.restoreSession()).thenAnswer((_) async => sesion(sesionRol));
    when(
      () => usuarioRepository.listar(rol: any(named: 'rol'), activo: any(named: 'activo'), page: 1, perPage: 20),
    ).thenAnswer(
      (_) async => UsuarioPageResult(data: [usuarioInicial ?? usuarioEditado()], page: 1, perPage: 20, total: 1),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          usuarioRepositoryProvider.overrideWithValue(usuarioRepository),
          authRepositoryProvider.overrideWithValue(authRepository),
        ],
        child: const MaterialApp(home: UsuarioDetailScreen(usuarioId: 'u1')),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('OPERADOR: ve el mensaje de acceso restringido', (tester) async {
    await pumpDetailScreen(tester, sesionRol: RolUsuario.operador);

    expect(find.byType(AccesoRestringido), findsOneWidget);
  });

  testWidgets('usuario no encontrado: muestra el estado vacío', (tester) async {
    when(
      () => usuarioRepository.listar(rol: any(named: 'rol'), activo: any(named: 'activo'), page: 1, perPage: 20),
    ).thenAnswer((_) async => const UsuarioPageResult(data: [], page: 1, perPage: 20, total: 0));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          usuarioRepositoryProvider.overrideWithValue(usuarioRepository),
          authRepositoryProvider.overrideWithValue(authRepository),
        ],
        child: const MaterialApp(home: UsuarioDetailScreen(usuarioId: 'inexistente')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(EmptyState), findsOneWidget);
  });

  testWidgets('precarga el formulario con los datos del usuario', (tester) async {
    await pumpDetailScreen(tester, usuarioInicial: usuarioEditado());

    // 'Carlos' aparece dos veces a propósito: el título del AppBar y el
    // campo de texto precargado.
    expect(find.text('Carlos'), findsNWidgets(2));
    expect(find.text('carlos@test.com'), findsOneWidget);
  });

  testWidgets('OPERADOR editado: no muestra el campo de base inicial', (tester) async {
    await pumpDetailScreen(tester, usuarioInicial: usuarioEditado(rol: RolUsuario.operador));

    expect(find.widgetWithText(TextFormField, 'Base inicial para turno automático'), findsNothing);
  });

  testWidgets('ADMIN editado: muestra el campo de base inicial precargado', (tester) async {
    await pumpDetailScreen(
      tester,
      usuarioInicial: usuarioEditado(rol: RolUsuario.admin, baseInicialTurno: 40000),
    );

    expect(find.widgetWithText(TextFormField, 'Base inicial para turno automático'), findsOneWidget);
    expect(find.text('40000'), findsOneWidget);
  });

  testWidgets('cambiar el rol a ADMIN revela el campo de base inicial', (tester) async {
    await pumpDetailScreen(tester, usuarioInicial: usuarioEditado(rol: RolUsuario.operador));
    expect(find.widgetWithText(TextFormField, 'Base inicial para turno automático'), findsNothing);

    await tester.tap(find.widgetWithText(DropdownButtonFormField<RolUsuario>, 'Operador'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Administrador').last);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextFormField, 'Base inicial para turno automático'), findsOneWidget);
  });

  testWidgets('éxito: guarda y muestra confirmación', (tester) async {
    when(
      () => usuarioRepository.actualizar(
        'u1',
        nombre: any(named: 'nombre'),
        email: any(named: 'email'),
        password: any(named: 'password'),
        rol: any(named: 'rol'),
        activo: any(named: 'activo'),
        baseInicialTurno: any(named: 'baseInicialTurno'),
      ),
    ).thenAnswer((_) async => usuarioEditado());

    await pumpDetailScreen(tester);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Guardar cambios'));
    await tester.pumpAndSettle();

    verify(
      () => usuarioRepository.actualizar(
        'u1',
        nombre: 'Carlos',
        email: 'carlos@test.com',
        password: null,
        rol: RolUsuario.operador,
        activo: true,
        baseInicialTurno: null,
      ),
    ).called(1);
    expect(find.text('Cambios guardados.'), findsOneWidget);
  });

  testWidgets('409: email duplicado — muestra el mensaje del backend', (tester) async {
    when(
      () => usuarioRepository.actualizar(
        'u1',
        nombre: any(named: 'nombre'),
        email: any(named: 'email'),
        password: any(named: 'password'),
        rol: any(named: 'rol'),
        activo: any(named: 'activo'),
        baseInicialTurno: any(named: 'baseInicialTurno'),
      ),
    ).thenThrow(
      const ApiException(code: 'EMAIL_DUPLICADO', message: 'Ya existe un usuario con ese email', statusCode: 409),
    );

    await pumpDetailScreen(tester);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Guardar cambios'));
    await tester.pumpAndSettle();

    expect(find.text('Ya existe un usuario con ese email'), findsOneWidget);
  });
}
