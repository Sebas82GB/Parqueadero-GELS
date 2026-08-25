import 'package:dio/dio.dart';

import '../../features/auth/data/token_storage.dart';

/// Inyecta `Authorization: Bearer <token>` en cada petición saliente, salvo
/// que venga marcada con `extra['skipAuth'] = true` (usado por
/// [RefreshInterceptor] para su propia llamada a `/auth/refresh`, que no
/// lleva ese header).
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._tokenStorage);

  final TokenStorage _tokenStorage;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (options.extra['skipAuth'] != true) {
      final token = await _tokenStorage.readAccessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }
}
