import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parqueadero_app/core/network/api_exception.dart';
import 'package:parqueadero_app/core/widgets/acceso_restringido.dart';
import 'package:parqueadero_app/core/widgets/empty_state.dart';
import 'package:parqueadero_app/core/widgets/error_state.dart';
import 'package:parqueadero_app/features/auth/data/auth_repository_impl.dart';
import 'package:parqueadero_app/features/auth/domain/auth_repository.dart';
import 'package:parqueadero_app/features/auth/domain/usuario.dart';
import 'package:parqueadero_app/features/usuarios/data/usuario_repository_impl.dart';
import 'package:parqueadero_app/features/usuarios/domain/usuario_repository.dart';
import 'package:parqueadero_app/features/usuarios/presentation/usuarios_screen.dart';
import 'package:mocktail/mocktail.dart';

class MockUsuarioRepository extends Mock implements UsuarioRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockUsuarioRepository usuarioRepository;
  late MockAuthRepository authRepository;

  Usuario sesion({RolUsuario rol = RolUsuario.admin}) => Usuario(
    id: 'admin1',
    nombre: 'Ana',
    email: 'ana@test.com',
    rol: rol,
    activo: true,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  Usuario usuarioListado(String id) => Usuario(
    id: id,
    nombre: 'Operador $id',
    email: 'op-$id@test.com',
    rol: RolUsuario.operador,
    activo: true,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  setUp(() {
    usuarioRepository = MockUsuarioRepository();
    authRepository = MockAuthRepository();
  });

  Future<void> pumpScreen(WidgetTester tester, {RolUsuario rol = RolUsuario.admin}) async {
    when(() => authRepository.restoreSession()).thenAnswer((_) async => sesion(rol: rol));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          usuarioRepositoryProvider.overrideWithValue(usuarioRepository),
          authRepositoryProvider.overrideWithValue(authRepository),
        ],
        child: const MaterialApp(home: UsuariosScreen()),
      ),
    );
  }

  testWidgets('OPERADOR: ve el mensaje de acceso restringido', (tester) async {
    await pumpScreen(tester, rol: RolUsuario.operador);
    await tester.pumpAndSettle();

    expect(find.byType(AccesoRestringido), findsOneWidget);
  });

  testWidgets('error: muestra ErrorState con botón de reintentar', (tester) async {
    when(
      () => usuarioRepository.listar(
        rol: any(named: 'rol'),
        activo: any(named: 'activo'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenThrow(const ApiException(code: 'UNKNOWN', message: 'No hay conexión con el servidor.', statusCode: 0));

    await pumpScreen(tester);
    await tester.pumpAndSettle();

    expect(find.byType(ErrorState), findsOneWidget);
    expect(find.text('No hay conexión con el servidor.'), findsOneWidget);
  });

  testWidgets('vacío: sin usuarios que coincidan', (tester) async {
    when(
      () => usuarioRepository.listar(
        rol: any(named: 'rol'),
        activo: any(named: 'activo'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer((_) async => const UsuarioPageResult(data: [], page: 1, perPage: 20, total: 0));

    await pumpScreen(tester);
    await tester.pumpAndSettle();

    expect(find.byType(EmptyState), findsOneWidget);
  });

  testWidgets('éxito: lista los usuarios', (tester) async {
    when(
      () => usuarioRepository.listar(
        rol: any(named: 'rol'),
        activo: any(named: 'activo'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer(
      (_) async => UsuarioPageResult(data: [usuarioListado('u1')], page: 1, perPage: 20, total: 1),
    );

    await pumpScreen(tester);
    await tester.pumpAndSettle();

    expect(find.text('Operador u1'), findsOneWidget);
  });
}
