import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/auth_repository.dart';
import '../domain/usuario.dart';
import 'dtos/login_response_dto.dart';
import 'dtos/usuario_dto.dart';
import 'token_storage.dart';

/// Único lugar que conoce la forma de la respuesta HTTP de `/auth`.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._dio, this._tokenStorage);

  final Dio _dio;
  final TokenStorage _tokenStorage;

  @override
  Future<Usuario> login({required String email, required String password}) async {
    try {
      final response = await _dio.post('/auth/login', data: {'email': email, 'password': password});
      final dto = LoginResponseDto.fromJson(response.data as Map<String, dynamic>);
      await _tokenStorage.saveTokens(accessToken: dto.accessToken, refreshToken: dto.refreshToken);
      return dto.usuario.toDomain();
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  @override
  Future<void> logout() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    try {
      if (refreshToken != null) {
        await _dio.post('/auth/logout', data: {'refreshToken': refreshToken});
      }
    } on DioException {
      // Best-effort: /auth/logout es idempotente en el backend; la sesión
      // local se limpia de todas formas en el `finally`.
    } finally {
      await _tokenStorage.clear();
    }
  }

  @override
  Future<Usuario?> restoreSession() async {
    if (await _tokenStorage.readAccessToken() == null) return null;
    try {
      final response = await _dio.get('/auth/me');
      return UsuarioDto.fromJson(response.data as Map<String, dynamic>).toDomain();
    } on DioException {
      // Cubre: token inválido y el refresh transparente (interceptor)
      // también falló. No hay nada que mostrar al usuario en el arranque,
      // por eso no se traduce a AppException aquí.
      return null;
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(ref.watch(dioProvider), ref.watch(tokenStorageProvider)),
);
