import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:parqueadero_app/core/network/api_exception.dart';
import 'package:parqueadero_app/features/auth/domain/usuario.dart';
import 'package:parqueadero_app/features/usuarios/data/usuario_repository_impl.dart';
import 'package:parqueadero_app/features/usuarios/domain/usuario_repository.dart';
import 'package:parqueadero_app/features/usuarios/presentation/usuario_detail_notifier.dart';
import 'package:parqueadero_app/features/usuarios/presentation/usuario_list_notifier.dart';

class MockUsuarioRepository extends Mock implements UsuarioRepository {}

void main() {
  late MockUsuarioRepository usuarioRepository;
  late ProviderContainer container;

  Usuario usuario({RolUsuario rol = RolUsuario.admin, int? baseInicialTurno, bool activo = true}) => Usuario(
    id: 'u1',
    nombre: 'Ana',
    email: 'ana@test.com',
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
    when(
      () => usuarioRepository.listar(rol: any(named: 'rol'), activo: any(named: 'activo'), page: 1, perPage: 20),
    ).thenAnswer((_) async => const UsuarioPageResult(data: [], page: 1, perPage: 20, total: 0));
    container = ProviderContainer(
      overrides: [usuarioRepositoryProvider.overrideWithValue(usuarioRepository)],
    );
    addTearDown(container.dispose);
    container.listen(usuarioListNotifierProvider, (_, _) {});
  });

  test('éxito: guarda, retorna true y refleja el cambio en UsuarioListNotifier', () async {
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
    ).thenAnswer((_) async => usuario(baseInicialTurno: 40000));
    await Future<void>.delayed(Duration.zero);
    // El usuario ya debe estar en el listado para que reemplazarUsuario lo encuentre.
    container.read(usuarioListNotifierProvider.notifier).agregarUsuario(usuario());

    final ok = await container
        .read(usuarioDetailNotifierProvider('u1').notifier)
        .guardar(
          nombre: 'Ana',
          email: 'ana@test.com',
          rol: RolUsuario.admin,
          activo: true,
          baseInicialTurno: 40000,
        );

    expect(ok, isTrue);
    expect(container.read(usuarioDetailNotifierProvider('u1')).errorMessage, isNull);
    expect(container.read(usuarioListNotifierProvider).usuarios.single.baseInicialTurno, 40000);
  });

  test('409: email duplicado — retorna false con el mensaje del backend', () async {
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

    final ok = await container
        .read(usuarioDetailNotifierProvider('u1').notifier)
        .guardar(nombre: 'Ana', email: 'ana@test.com', rol: RolUsuario.admin, activo: true);

    expect(ok, isFalse);
    expect(container.read(usuarioDetailNotifierProvider('u1')).errorMessage, 'Ya existe un usuario con ese email');
  });
}
