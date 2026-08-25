import 'usuario.dart';

/// Sin dependencias de Flutter ni de dio. `refresh` no se expone aquí a
/// propósito: es un detalle interno de los interceptores de red, nada en la
/// capa de presentación necesita dispararlo manualmente.
abstract interface class AuthRepository {
  Future<Usuario> login({required String email, required String password});

  Future<void> logout();

  /// Intenta restaurar la sesión a partir de los tokens guardados
  /// (validando contra `GET /auth/me`, que ya pasa por el refresh
  /// transparente si el access token expiró). `null` si no hay una sesión
  /// válida.
  Future<Usuario?> restoreSession();
}
