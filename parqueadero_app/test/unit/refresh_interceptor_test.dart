import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:parqueadero_app/core/network/refresh_interceptor.dart';
import 'package:parqueadero_app/core/network/session_events.dart';
import 'package:parqueadero_app/features/auth/data/token_storage.dart';

class MockHttpClientAdapter extends Mock implements HttpClientAdapter {}

class MockTokenStorage extends Mock implements TokenStorage {}

ResponseBody _jsonBody(Map<String, dynamic> data, int statusCode) {
  return ResponseBody.fromString(
    jsonEncode(data),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

void main() {
  late Dio dio;
  late MockHttpClientAdapter adapter;
  late MockTokenStorage tokenStorage;
  late SessionEvents sessionEvents;

  setUpAll(() {
    registerFallbackValue(RequestOptions(path: ''));
  });

  setUp(() {
    adapter = MockHttpClientAdapter();
    tokenStorage = MockTokenStorage();
    sessionEvents = SessionEvents();
    dio = Dio(BaseOptions(baseUrl: 'http://test'))..httpClientAdapter = adapter;
    dio.interceptors.add(RefreshInterceptor(dio: dio, tokenStorage: tokenStorage, sessionEvents: sessionEvents));
  });

  tearDown(() => sessionEvents.dispose());

  test('dos 401 concurrentes disparan un solo refresh y ambas peticiones reintentan', () async {
    when(() => tokenStorage.readRefreshToken()).thenAnswer((_) async => 'refresh-token-1');
    when(
      () => tokenStorage.saveTokens(
        accessToken: any(named: 'accessToken'),
        refreshToken: any(named: 'refreshToken'),
      ),
    ).thenAnswer((_) async {});

    var refreshCalls = 0;
    when(() => adapter.fetch(any(), any(), any())).thenAnswer((invocation) async {
      final options = invocation.positionalArguments[0] as RequestOptions;
      if (options.path == '/auth/refresh') {
        refreshCalls++;
        // Retraso artificial: fuerza a que la segunda petición llegue a su
        // 401 mientras el primer refresh sigue en vuelo, para ejercitar de
        // verdad el camino single-flight en vez de dos refrescos serializados.
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return _jsonBody({'accessToken': 'new-access', 'refreshToken': 'new-refresh'}, 200);
      }
      if (options.extra['retriedAfterRefresh'] == true) {
        return _jsonBody({'ok': true}, 200);
      }
      return _jsonBody({
        'error': {'code': 'UNAUTHORIZED', 'message': 'Token inválido o expirado', 'details': []},
      }, 401);
    });

    final results = await Future.wait([dio.get<dynamic>('/protected'), dio.get<dynamic>('/protected')]);

    expect(refreshCalls, 1);
    expect(results.map((r) => r.statusCode), everyElement(200));
    verify(
      () => tokenStorage.saveTokens(accessToken: 'new-access', refreshToken: 'new-refresh'),
    ).called(1);
  });

  test('si el refresh también falla: limpia tokens y emite sessionExpired', () async {
    when(() => tokenStorage.readRefreshToken()).thenAnswer((_) async => 'refresh-token-1');
    when(() => tokenStorage.clear()).thenAnswer((_) async {});

    when(() => adapter.fetch(any(), any(), any())).thenAnswer((invocation) async {
      final options = invocation.positionalArguments[0] as RequestOptions;
      if (options.path == '/auth/refresh') {
        return _jsonBody({
          'error': {'code': 'REFRESH_TOKEN_INVALIDO', 'message': 'Refresh token inválido o expirado', 'details': []},
        }, 401);
      }
      return _jsonBody({
        'error': {'code': 'UNAUTHORIZED', 'message': 'Token inválido o expirado', 'details': []},
      }, 401);
    });

    final events = <SessionEventType>[];
    final subscription = sessionEvents.stream.listen(events.add);

    await expectLater(() => dio.get<dynamic>('/protected'), throwsA(isA<DioException>()));
    await Future<void>.delayed(Duration.zero);

    expect(events, [SessionEventType.sessionExpired]);
    verify(() => tokenStorage.clear()).called(1);
    await subscription.cancel();
  });
}
