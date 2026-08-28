import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:parqueadero_app/core/network/api_exception.dart';
import 'package:parqueadero_app/core/widgets/acceso_restringido.dart';
import 'package:parqueadero_app/features/auth/data/auth_repository_impl.dart';
import 'package:parqueadero_app/features/auth/domain/auth_repository.dart';
import 'package:parqueadero_app/features/auth/domain/usuario.dart';
import 'package:parqueadero_app/features/usuarios/data/usuario_repository_impl.dart';
import 'package:parqueadero_app/features/usuarios/domain/usuario_repository.dart';
import 'package:parqueadero_app/features/usuarios/presentation/nuevo_usuario_screen.dart';

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

  Usuario usuarioCreado() => Usuario(
    id: 'u1',
    nombre: 'Carlos',
    email: 'carlos@test.com',
    rol: RolUsuario.operador,
    activo: true,
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
    when(
      () => usuarioRepository.listar(rol: any(named: 'rol'), activo: any(named: 'activo'), page: 1, perPage: 20),
    ).thenAnswer((_) async => const UsuarioPageResult(data: [], page: 1, perPage: 20, total: 0));
  });

  Future<GoRouter> pumpNuevoUsuarioScreen(WidgetTester tester, {RolUsuario rol = RolUsuario.admin}) async {
    when(() => authRepository.restoreSession()).thenAnswer((_) async => sesion(rol));
    final router = GoRouter(
      initialLocation: '/usuarios',
      routes: [
        GoRoute(
          path: '/usuarios',
          builder: (context, state) => Scaffold(
            body: Center(
              child: TextButton(onPressed: () => context.push('/usuarios/nuevo'), child: const Text('IR')),
            ),
          ),
        ),
        GoRoute(path: '/usuarios/nuevo', builder: (context, state) => const NuevoUsuarioScreen()),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          usuarioRepositoryProvider.overrideWithValue(usuarioRepository),
          authRepositoryProvider.overrideWithValue(authRepository),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('IR'));
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('OPERADOR: ve el mensaje de acceso restringido', (tester) async {
    await pumpNuevoUsuarioScreen(tester, rol: RolUsuario.operador);

    expect(find.byType(AccesoRestringido), findsOneWidget);
  });

  testWidgets('éxito: crea el usuario y vuelve atrás', (tester) async {
    when(
      () => usuarioRepository.crear(
        nombre: any(named: 'nombre'),
        email: any(named: 'email'),
        password: any(named: 'password'),
        rol: any(named: 'rol'),
      ),
    ).thenAnswer((_) async => usuarioCreado());

    final router = await pumpNuevoUsuarioScreen(tester);

    await tester.enterText(find.widgetWithText(TextFormField, 'Nombre'), 'Carlos');
    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'carlos@test.com');
    await tester.enterText(find.widgetWithText(TextFormField, 'Contraseña'), 'Password123!');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Crear usuario'));
    await tester.pumpAndSettle();

    verify(
      () => usuarioRepository.crear(
        nombre: 'Carlos',
        email: 'carlos@test.com',
        password: 'Password123!',
        rol: RolUsuario.operador,
      ),
    ).called(1);
    expect(router.routerDelegate.currentConfiguration.uri.toString(), '/usuarios');
  });

  testWidgets('400: contraseña muy corta bloquea el envío sin llamar al backend', (tester) async {
    await pumpNuevoUsuarioScreen(tester);

    await tester.enterText(find.widgetWithText(TextFormField, 'Nombre'), 'Carlos');
    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'carlos@test.com');
    await tester.enterText(find.widgetWithText(TextFormField, 'Contraseña'), '123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Crear usuario'));
    await tester.pumpAndSettle();

    verifyNever(
      () => usuarioRepository.crear(
        nombre: any(named: 'nombre'),
        email: any(named: 'email'),
        password: any(named: 'password'),
        rol: any(named: 'rol'),
      ),
    );
  });

  testWidgets('409: email duplicado — muestra el mensaje del backend', (tester) async {
    when(
      () => usuarioRepository.crear(
        nombre: any(named: 'nombre'),
        email: any(named: 'email'),
        password: any(named: 'password'),
        rol: any(named: 'rol'),
      ),
    ).thenThrow(
      const ApiException(code: 'EMAIL_DUPLICADO', message: 'Ya existe un usuario con ese email', statusCode: 409),
    );

    await pumpNuevoUsuarioScreen(tester);

    await tester.enterText(find.widgetWithText(TextFormField, 'Nombre'), 'Carlos');
    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'carlos@test.com');
    await tester.enterText(find.widgetWithText(TextFormField, 'Contraseña'), 'Password123!');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Crear usuario'));
    await tester.pumpAndSettle();

    expect(find.text('Ya existe un usuario con ese email'), findsOneWidget);
  });
}
