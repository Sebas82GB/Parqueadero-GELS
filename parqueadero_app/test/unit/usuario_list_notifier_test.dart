import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:parqueadero_app/core/network/api_exception.dart';
import 'package:parqueadero_app/features/auth/domain/usuario.dart';
import 'package:parqueadero_app/features/usuarios/data/usuario_repository_impl.dart';
import 'package:parqueadero_app/features/usuarios/domain/usuario_repository.dart';
import 'package:parqueadero_app/features/usuarios/presentation/usuario_list_notifier.dart';

class MockUsuarioRepository extends Mock implements UsuarioRepository {}

void main() {
  late MockUsuarioRepository usuarioRepository;
  late ProviderContainer container;

  Usuario usuario(String id, {RolUsuario rol = RolUsuario.operador}) => Usuario(
    id: id,
    nombre: 'Ana',
    email: 'ana@test.com',
    rol: rol,
    activo: true,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  setUp(() {
    usuarioRepository = MockUsuarioRepository();
    container = ProviderContainer(
      overrides: [usuarioRepositoryProvider.overrideWithValue(usuarioRepository)],
    );
    addTearDown(container.dispose);
  });

  void mantenerVivo() => container.listen(usuarioListNotifierProvider, (_, _) {});

  test('carga inicial exitosa: pasa de isLoading a la lista', () async {
    when(
      () => usuarioRepository.listar(
        rol: any(named: 'rol'),
        activo: any(named: 'activo'),
        page: 1,
        perPage: 20,
      ),
    ).thenAnswer(
      (_) async => UsuarioPageResult(data: [usuario('u1'), usuario('u2')], page: 1, perPage: 20, total: 2),
    );

    mantenerVivo();
    expect(container.read(usuarioListNotifierProvider).isLoading, isTrue);

    await Future<void>.delayed(Duration.zero);

    final state = container.read(usuarioListNotifierProvider);
    expect(state.isLoading, isFalse);
    expect(state.usuarios, hasLength(2));
    expect(state.hayMas, isFalse);
  });

  test('cambiar filtro de rol reinicia a página 1', () async {
    when(
      () => usuarioRepository.listar(
        rol: any(named: 'rol'),
        activo: any(named: 'activo'),
        page: 1,
        perPage: 20,
      ),
    ).thenAnswer((_) async => UsuarioPageResult(data: [usuario('u1')], page: 1, perPage: 20, total: 1));
    mantenerVivo();
    await Future<void>.delayed(Duration.zero);

    container.read(usuarioListNotifierProvider.notifier).setRolFiltro(RolUsuario.admin);
    await Future<void>.delayed(Duration.zero);

    verify(
      () => usuarioRepository.listar(rol: RolUsuario.admin, activo: any(named: 'activo'), page: 1, perPage: 20),
    ).called(1);
    expect(container.read(usuarioListNotifierProvider).rolFiltro, RolUsuario.admin);
  });

  test('carga inicial con error: expone el mensaje y lista vacía', () async {
    when(
      () => usuarioRepository.listar(
        rol: any(named: 'rol'),
        activo: any(named: 'activo'),
        page: 1,
        perPage: 20,
      ),
    ).thenThrow(const ApiException(code: 'UNKNOWN', message: 'Ha ocurrido un error', statusCode: 500));

    mantenerVivo();
    await Future<void>.delayed(Duration.zero);

    final state = container.read(usuarioListNotifierProvider);
    expect(state.errorMessage, 'Ha ocurrido un error');
    expect(state.usuarios, isEmpty);
  });

  test('reemplazarUsuario: actualiza en el listado sin volver a pedir la página', () async {
    when(
      () => usuarioRepository.listar(
        rol: any(named: 'rol'),
        activo: any(named: 'activo'),
        page: 1,
        perPage: 20,
      ),
    ).thenAnswer((_) async => UsuarioPageResult(data: [usuario('u1')], page: 1, perPage: 20, total: 1));
    mantenerVivo();
    await Future<void>.delayed(Duration.zero);

    final actualizado = usuario('u1', rol: RolUsuario.admin);
    container.read(usuarioListNotifierProvider.notifier).reemplazarUsuario(actualizado);

    final state = container.read(usuarioListNotifierProvider);
    expect(state.usuarios.single.rol, RolUsuario.admin);
  });

  test('agregarUsuario: lo antepone y suma al total', () async {
    when(
      () => usuarioRepository.listar(
        rol: any(named: 'rol'),
        activo: any(named: 'activo'),
        page: 1,
        perPage: 20,
      ),
    ).thenAnswer((_) async => UsuarioPageResult(data: [usuario('u1')], page: 1, perPage: 20, total: 1));
    mantenerVivo();
    await Future<void>.delayed(Duration.zero);

    container.read(usuarioListNotifierProvider.notifier).agregarUsuario(usuario('u2'));

    final state = container.read(usuarioListNotifierProvider);
    expect(state.usuarios.map((u) => u.id), ['u2', 'u1']);
    expect(state.total, 2);
  });
}
