import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:parqueadero_app/core/network/api_exception.dart';
import 'package:parqueadero_app/features/auth/domain/usuario.dart';
import 'package:parqueadero_app/features/usuarios/data/usuario_repository_impl.dart';

class MockDio extends Mock implements Dio {}

Response<dynamic> _jsonResponse(String path, Map<String, dynamic> data, {int statusCode = 201}) {
  return Response(requestOptions: RequestOptions(path: path), data: data, statusCode: statusCode);
}

DioException _dioError(String path, {required int statusCode, required Map<String, dynamic> errorBody}) {
  final requestOptions = RequestOptions(path: path);
  return DioException(
    requestOptions: requestOptions,
    type: DioExceptionType.badResponse,
    response: Response(requestOptions: requestOptions, statusCode: statusCode, data: errorBody),
  );
}

Map<String, dynamic> _usuarioJson({
  String id = 'u1',
  String rol = 'OPERADOR',
  bool activo = true,
  int? baseInicialTurno,
}) => {
  'id': id,
  'nombre': 'Ana',
  'email': 'ana@test.com',
  'rol': rol,
  'activo': activo,
  'baseInicialTurno': baseInicialTurno,
  'createdAt': '2026-01-01T06:00:00.000Z',
  'updatedAt': '2026-01-01T06:00:00.000Z',
};

void main() {
  late MockDio dio;
  late UsuarioRepositoryImpl repository;

  setUp(() {
    dio = MockDio();
    repository = UsuarioRepositoryImpl(dio);
  });

  group('listar', () {
    test('arma los query params y mapea la página', () async {
      when(
        () => dio.get('/usuarios', queryParameters: any(named: 'queryParameters')),
      ).thenAnswer(
        (_) async => _jsonResponse('/usuarios', {
          'data': [_usuarioJson(), _usuarioJson(id: 'u2', rol: 'ADMIN')],
          'meta': {'page': 1, 'perPage': 20, 'total': 2},
        }, statusCode: 200),
      );

      final pagina = await repository.listar(rol: RolUsuario.operador, activo: true);

      expect(pagina.data, hasLength(2));
      expect(pagina.total, 2);
      verify(
        () => dio.get(
          '/usuarios',
          queryParameters: {'rol': 'OPERADOR', 'activo': 'true', 'page': 1, 'perPage': 20},
        ),
      ).called(1);
    });

    test('sin filtros: solo manda page y perPage', () async {
      when(
        () => dio.get('/usuarios', queryParameters: any(named: 'queryParameters')),
      ).thenAnswer(
        (_) async => _jsonResponse('/usuarios', {
          'data': <dynamic>[],
          'meta': {'page': 1, 'perPage': 20, 'total': 0},
        }, statusCode: 200),
      );

      await repository.listar();

      verify(() => dio.get('/usuarios', queryParameters: {'page': 1, 'perPage': 20})).called(1);
    });
  });

  group('crear', () {
    test('éxito: envía los campos y mapea el usuario creado', () async {
      when(() => dio.post('/usuarios', data: any(named: 'data'))).thenAnswer(
        (_) async => _jsonResponse('/usuarios', _usuarioJson(rol: 'ADMIN')),
      );

      final usuario = await repository.crear(
        nombre: 'Ana',
        email: 'ana@test.com',
        password: 'Password123!',
        rol: RolUsuario.admin,
      );

      expect(usuario.rol, RolUsuario.admin);
      verify(
        () => dio.post(
          '/usuarios',
          data: {
            'nombre': 'Ana',
            'email': 'ana@test.com',
            'password': 'Password123!',
            'rol': 'ADMIN',
          },
        ),
      ).called(1);
    });

    test('409: email duplicado', () async {
      when(() => dio.post('/usuarios', data: any(named: 'data'))).thenThrow(
        _dioError(
          '/usuarios',
          statusCode: 409,
          errorBody: {
            'error': {'code': 'EMAIL_DUPLICADO', 'message': 'Ya existe un usuario con ese email', 'details': []},
          },
        ),
      );

      await expectLater(
        () => repository.crear(
          nombre: 'Ana',
          email: 'ana@test.com',
          password: 'Password123!',
          rol: RolUsuario.operador,
        ),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'EMAIL_DUPLICADO')),
      );
    });
  });

  group('actualizar', () {
    test('éxito: siempre manda nombre/email/rol/activo, omite password y baseInicialTurno si vienen null', () async {
      when(() => dio.patch('/usuarios/u1', data: any(named: 'data'))).thenAnswer(
        (_) async => _jsonResponse('/usuarios/u1', _usuarioJson(activo: false), statusCode: 200),
      );

      final usuario = await repository.actualizar(
        'u1',
        nombre: 'Ana',
        email: 'ana@test.com',
        rol: RolUsuario.operador,
        activo: false,
      );

      expect(usuario.activo, false);
      verify(
        () => dio.patch(
          '/usuarios/u1',
          data: {'nombre': 'Ana', 'email': 'ana@test.com', 'rol': 'OPERADOR', 'activo': false},
        ),
      ).called(1);
    });

    test('incluye password y baseInicialTurno cuando vienen', () async {
      when(() => dio.patch('/usuarios/u1', data: any(named: 'data'))).thenAnswer(
        (_) async => _jsonResponse(
          '/usuarios/u1',
          _usuarioJson(rol: 'ADMIN', baseInicialTurno: 40000),
          statusCode: 200,
        ),
      );

      final usuario = await repository.actualizar(
        'u1',
        nombre: 'Ana',
        email: 'ana@test.com',
        password: 'NuevaPassword123!',
        rol: RolUsuario.admin,
        activo: true,
        baseInicialTurno: 40000,
      );

      expect(usuario.baseInicialTurno, 40000);
      verify(
        () => dio.patch(
          '/usuarios/u1',
          data: {
            'nombre': 'Ana',
            'email': 'ana@test.com',
            'password': 'NuevaPassword123!',
            'rol': 'ADMIN',
            'activo': true,
            'baseInicialTurno': 40000,
          },
        ),
      ).called(1);
    });

    test('404: usuario no encontrado', () async {
      when(() => dio.patch('/usuarios/u1', data: any(named: 'data'))).thenThrow(
        _dioError(
          '/usuarios/u1',
          statusCode: 404,
          errorBody: {
            'error': {'code': 'NOT_FOUND', 'message': 'Usuario no encontrado', 'details': []},
          },
        ),
      );

      await expectLater(
        () => repository.actualizar('u1', nombre: 'Ana', email: 'ana@test.com', rol: RolUsuario.operador, activo: true),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
