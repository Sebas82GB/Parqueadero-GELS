import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../auth/data/dtos/usuario_dto.dart';
import '../../auth/domain/usuario.dart';
import '../domain/usuario_repository.dart';
import 'dtos/usuario_page_dto.dart';

class UsuarioRepositoryImpl implements UsuarioRepository {
  UsuarioRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<UsuarioPageResult> listar({
    RolUsuario? rol,
    bool? activo,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/usuarios',
        queryParameters: {
          if (rol != null) 'rol': rol == RolUsuario.admin ? 'ADMIN' : 'OPERADOR',
          if (activo != null) 'activo': activo.toString(),
          'page': page,
          'perPage': perPage,
        },
      );
      final pageDto = UsuarioPageDto.fromJson(response.data as Map<String, dynamic>);
      return UsuarioPageResult(
        data: pageDto.data.map((dto) => dto.toDomain()).toList(),
        page: pageDto.meta.page,
        perPage: pageDto.meta.perPage,
        total: pageDto.meta.total,
      );
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  @override
  Future<Usuario> crear({
    required String nombre,
    required String email,
    required String password,
    required RolUsuario rol,
  }) async {
    try {
      final response = await _dio.post(
        '/usuarios',
        data: {
          'nombre': nombre,
          'email': email,
          'password': password,
          'rol': rol == RolUsuario.admin ? 'ADMIN' : 'OPERADOR',
        },
      );
      return UsuarioDto.fromJson(response.data as Map<String, dynamic>).toDomain();
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  @override
  Future<Usuario> actualizar(
    String id, {
    required String nombre,
    required String email,
    String? password,
    required RolUsuario rol,
    required bool activo,
    int? baseInicialTurno,
  }) async {
    try {
      final response = await _dio.patch(
        '/usuarios/$id',
        data: {
          'nombre': nombre,
          'email': email,
          if (password != null && password.isNotEmpty) 'password': password,
          'rol': rol == RolUsuario.admin ? 'ADMIN' : 'OPERADOR',
          'activo': activo,
          if (baseInicialTurno != null) 'baseInicialTurno': baseInicialTurno,
        },
      );
      return UsuarioDto.fromJson(response.data as Map<String, dynamic>).toDomain();
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }
}

final usuarioRepositoryProvider = Provider<UsuarioRepository>(
  (ref) => UsuarioRepositoryImpl(ref.watch(dioProvider)),
);
