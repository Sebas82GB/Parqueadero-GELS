import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:parqueadero_app/core/network/api_exception.dart';
import 'package:parqueadero_app/features/auth/data/auth_repository_impl.dart';
import 'package:parqueadero_app/features/auth/data/token_storage.dart';
import 'package:parqueadero_app/features/auth/domain/usuario.dart';

class MockDio extends Mock implements Dio {}

class MockTokenStorage extends Mock implements TokenStorage {}

Response<dynamic> _jsonResponse(String path, Map<String, dynamic> data, {int statusCode = 200}) {
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

void main() {
  late MockDio dio;
  late MockTokenStorage tokenStorage;
  late AuthRepositoryImpl repository;

  final usuarioJson = {
    'id': 'u1',
    'nombre': 'Ana',
    'email': 'ana@test.com',
    'rol': 'OPERADOR',
    'activo': true,
    'createdAt': '2026-01-01T00:00:00.000Z',
    'updatedAt': '2026-01-01T00:00:00.000Z',
  };

  setUp(() {
    dio = MockDio();
    tokenStorage = MockTokenStorage();
    repository = AuthRepositoryImpl(dio, tokenStorage);
  });

  group('login', () {
    test('éxito: devuelve el Usuario y guarda los tokens', () async {
      when(() => dio.post('/auth/login', data: any(named: 'data'))).thenAnswer(
        (_) async => _jsonResponse('/auth/login', {
          'usuario': usuarioJson,
          'accessToken': 'access-1',
          'refreshToken': 'refresh-1',
        }),
      );
      when(
        () => tokenStorage.saveTokens(
          accessToken: any(named: 'accessToken'),
          refreshToken: any(named: 'refreshToken'),
        ),
      ).thenAnswer((_) async {});

      final usuario = await repository.login(email: 'ana@test.com', password: '12345678');

      expect(usuario.id, 'u1');
      expect(usuario.nombre, 'Ana');
      expect(usuario.rol, RolUsuario.operador);
      verify(() => tokenStorage.saveTokens(accessToken: 'access-1', refreshToken: 'refresh-1')).called(1);
    });

    test('401 credenciales inválidas: lanza ApiException con el code y message del backend', () async {
      when(() => dio.post('/auth/login', data: any(named: 'data'))).thenThrow(
        _dioError(
          '/auth/login',
          statusCode: 401,
          errorBody: {
            'error': {'code': 'CREDENCIALES_INVALIDAS', 'message': 'Credenciales inválidas', 'details': []},
          },
        ),
      );

      await expectLater(
        () => repository.login(email: 'ana@test.com', password: 'mala'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.code, 'code', 'CREDENCIALES_INVALIDAS')
              .having((e) => e.message, 'message', 'Credenciales inválidas'),
        ),
      );
      verifyNever(
        () => tokenStorage.saveTokens(
          accessToken: any(named: 'accessToken'),
          refreshToken: any(named: 'refreshToken'),
        ),
      );
    });

    test('error de red: lanza NetworkException', () async {
      when(() => dio.post('/auth/login', data: any(named: 'data'))).thenThrow(
        DioException(requestOptions: RequestOptions(path: '/auth/login'), type: DioExceptionType.connectionError),
      );

      await expectLater(
        () => repository.login(email: 'ana@test.com', password: '12345678'),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('logout', () {
    test('éxito: llama al backend y limpia los tokens', () async {
      when(() => tokenStorage.readRefreshToken()).thenAnswer((_) async => 'refresh-1');
      when(() => tokenStorage.clear()).thenAnswer((_) async {});
      when(
        () => dio.post('/auth/logout', data: any(named: 'data')),
      ).thenAnswer((_) async => _jsonResponse('/auth/logout', {}, statusCode: 204));

      await repository.logout();

      verify(() => tokenStorage.clear()).called(1);
    });

    test('falla en el backend: igual limpia los tokens (best-effort, logout es idempotente)', () async {
      when(() => tokenStorage.readRefreshToken()).thenAnswer((_) async => 'refresh-1');
      when(() => tokenStorage.clear()).thenAnswer((_) async {});
      when(() => dio.post('/auth/logout', data: any(named: 'data'))).thenThrow(
        DioException(requestOptions: RequestOptions(path: '/auth/logout'), type: DioExceptionType.connectionError),
      );

      await repository.logout();

      verify(() => tokenStorage.clear()).called(1);
    });
  });

  group('restoreSession', () {
    test('sin access token guardado: no llama a la red y devuelve null', () async {
      when(() => tokenStorage.readAccessToken()).thenAnswer((_) async => null);

      final usuario = await repository.restoreSession();

      expect(usuario, isNull);
      verifyNever(() => dio.get(any()));
    });

    test('con token válido: devuelve el Usuario', () async {
      when(() => tokenStorage.readAccessToken()).thenAnswer((_) async => 'access-1');
      when(() => dio.get('/auth/me')).thenAnswer((_) async => _jsonResponse('/auth/me', usuarioJson));

      final usuario = await repository.restoreSession();

      expect(usuario, isNotNull);
      expect(usuario!.email, 'ana@test.com');
    });

    test('token inválido, incluso tras el refresh transparente: devuelve null', () async {
      when(() => tokenStorage.readAccessToken()).thenAnswer((_) async => 'access-1');
      when(() => dio.get('/auth/me')).thenThrow(
        _dioError(
          '/auth/me',
          statusCode: 401,
          errorBody: {
            'error': {'code': 'UNAUTHORIZED', 'message': 'Token inválido o expirado', 'details': []},
          },
        ),
      );

      final usuario = await repository.restoreSession();

      expect(usuario, isNull);
    });
  });
}
