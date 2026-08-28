import '../../auth/domain/usuario.dart';

/// Página de resultados de [UsuarioRepository.listar]. Mismo criterio que
/// `TurnoPageResult`/`TicketPageResult`: la lista de usuarios crece sin
/// límite, así que la paginación se expone hasta presentación.
class UsuarioPageResult {
  const UsuarioPageResult({required this.data, required this.page, required this.perPage, required this.total});

  final List<Usuario> data;
  final int page;
  final int perPage;
  final int total;

  bool get hayMas => page * perPage < total;
}

/// Sin dependencias de Flutter ni de dio.
abstract interface class UsuarioRepository {
  /// `GET /usuarios` (ADMIN only).
  Future<UsuarioPageResult> listar({RolUsuario? rol, bool? activo, int page = 1, int perPage = 20});

  /// `POST /usuarios` (ADMIN only). Lanza [ApiException] con code
  /// `EMAIL_DUPLICADO` (409) si el email ya existe.
  Future<Usuario> crear({
    required String nombre,
    required String email,
    required String password,
    required RolUsuario rol,
  });

  /// `PATCH /usuarios/:id` (ADMIN only). La pantalla de edición siempre
  /// muestra y reenvía el estado completo (nombre, email, rol, activo); solo
  /// `password` (dejar vacío para no cambiarla) y `baseInicialTurno` (solo
  /// tiene efecto si `rol` es ADMIN) son realmente opcionales, y se omiten
  /// del body si llegan en `null`. Lanza [ApiException] con code
  /// `EMAIL_DUPLICADO` (409) si el nuevo email ya pertenece a otro usuario,
  /// o `NOT_FOUND` (404) si el usuario no existe.
  Future<Usuario> actualizar(
    String id, {
    required String nombre,
    required String email,
    String? password,
    required RolUsuario rol,
    required bool activo,
    int? baseInicialTurno,
  });
}
