import 'dart:async';

import 'package:dio/dio.dart';

import '../../features/auth/data/dtos/refresh_response_dto.dart';
import '../../features/auth/data/token_storage.dart';
import 'session_events.dart';

/// Ante un 401, intenta `POST /auth/refresh` una sola vez y reintenta la
/// petición original. Si varias peticiones llegan en 401 al mismo tiempo,
/// una sola dispara el refresh y las demás esperan ese resultado
/// (single-flight vía [_refreshCompleter]). Si el refresh también falla,
/// borra los tokens y emite `sessionExpired` para que el resto de la app
/// (fuera de `core/`) reaccione.
class RefreshInterceptor extends Interceptor {
  RefreshInterceptor({required Dio dio, required TokenStorage tokenStorage, required SessionEvents sessionEvents})
    : _dio = dio,
      _tokenStorage = tokenStorage,
      _sessionEvents = sessionEvents;

  final Dio _dio;
  final TokenStorage _tokenStorage;
  final SessionEvents _sessionEvents;

  Completer<String>? _refreshCompleter;

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final isRefreshCall = err.requestOptions.extra['isRefreshCall'] == true;
    final alreadyRetried = err.requestOptions.extra['retriedAfterRefresh'] == true;

    if (err.response?.statusCode != 401 || isRefreshCall || alreadyRetried) {
      handler.next(err);
      return;
    }

    try {
      final newAccessToken = await _refreshAccessToken();
      final retryOptions = err.requestOptions
        ..headers['Authorization'] = 'Bearer $newAccessToken'
        ..extra['retriedAfterRefresh'] = true;
      final response = await _dio.fetch(retryOptions);
      handler.resolve(response);
    } catch (_) {
      await _tokenStorage.clear();
      _sessionEvents.emit(SessionEventType.sessionExpired);
      handler.next(err);
    }
  }

  Future<String> _refreshAccessToken() {
    final inFlight = _refreshCompleter;
    if (inFlight != null) return inFlight.future;

    final completer = Completer<String>();
    _refreshCompleter = completer;
    _doRefresh().then(completer.complete).catchError(completer.completeError).whenComplete(() {
      _refreshCompleter = null;
    });
    return completer.future;
  }

  Future<String> _doRefresh() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null) {
      throw StateError('No hay refresh token guardado');
    }

    final response = await _dio.post(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
      options: Options(extra: {'isRefreshCall': true, 'skipAuth': true}),
    );
    final dto = RefreshResponseDto.fromJson(response.data as Map<String, dynamic>);
    await _tokenStorage.saveTokens(accessToken: dto.accessToken, refreshToken: dto.refreshToken);
    return dto.accessToken;
  }
}
