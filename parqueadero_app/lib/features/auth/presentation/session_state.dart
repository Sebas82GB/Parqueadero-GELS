import '../domain/usuario.dart';

enum SessionStatus { checking, authenticated, unauthenticated }

/// Estado de sesión de toda la app. Vive en `presentation/` porque es una
/// máquina de estados orientada a UI (lo que decide el redirect del router),
/// no una entidad de negocio en sí misma.
class SessionState {
  const SessionState._(this.status, this.usuario);

  const SessionState.checking() : this._(SessionStatus.checking, null);

  const SessionState.authenticated(Usuario usuario) : this._(SessionStatus.authenticated, usuario);

  const SessionState.unauthenticated() : this._(SessionStatus.unauthenticated, null);

  final SessionStatus status;

  /// No nulo únicamente cuando `status == authenticated`.
  final Usuario? usuario;
}
