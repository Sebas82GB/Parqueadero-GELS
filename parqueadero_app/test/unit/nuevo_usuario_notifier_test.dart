import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:parqueadero_app/core/network/api_exception.dart';
import 'package:parqueadero_app/features/auth/domain/usuario.dart';
import 'package:parqueadero_app/features/usuarios/data/usuario_repository_impl.dart';
import 'package:parqueadero_app/features/usuarios/domain/usuario_repository.dart';
import 'package:parqueadero_app/features/usuarios/presentation/nuevo_usuario_notifier.dart';
import 'package:parqueadero_app/features/usuarios/presentation/usuario_list_notifier.dart';

class MockUsuarioRepository extends Mock implements UsuarioRepository {}

void main() {
  late MockUsuarioRepository usuarioRepository;
  late ProviderContainer container;

  Usuario usuario() => Usuario(
    id: 'u1',
    nombre: 'Ana',
    email: 'ana@test.com',
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
    // usuarioListNotifierProvider arranca su propia carga al construirse.
    when(
      () => usuarioRepository.listar(rol: any(named: 'rol'), activo: any(named: 'activo'), page: 1, perPage: 20),
    ).thenAnswer((_) async => const UsuarioPageResult(data: [], page: 1, perPage: 20, total: 0));
    container = ProviderContainer(
      overrides: [usuarioRepositoryProvider.overrideWithValue(usuarioRepository)],
    );
    addTearDown(container.dispose);
    container.listen(usuarioListNotifierProvider, (_, _) {});
  });

  test('éxito: retorna el Usuario creado y lo antepone en UsuarioListNotifier', () async {
    when(
      () => usuarioRepository.crear(
        nombre: any(named: 'nombre'),
        email: any(named: 'email'),
        password: any(named: 'password'),
        rol: any(named: 'rol'),
      ),
    ).thenAnswer((_) async => usuario());
    await Future<void>.delayed(Duration.zero);

    final resultado = await container
        .read(nuevoUsuarioNotifierProvider.notifier)
        .crear(nombre: 'Ana', email: 'ana@test.com', password: 'Password123!', rol: RolUsuario.operador);

    expect(resultado?.id, 'u1');
    expect(container.read(nuevoUsuarioNotifierProvider).errorMessage, isNull);
    expect(container.read(usuarioListNotifierProvider).usuarios.map((u) => u.id), ['u1']);
  });

  test('409: email duplicado — expone el mensaje del backend y retorna null', () async {
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

    final resultado = await container
        .read(nuevoUsuarioNotifierProvider.notifier)
        .crear(nombre: 'Ana', email: 'ana@test.com', password: 'Password123!', rol: RolUsuario.operador);

    expect(resultado, isNull);
    expect(container.read(nuevoUsuarioNotifierProvider).errorMessage, 'Ya existe un usuario con ese email');
  });
}
