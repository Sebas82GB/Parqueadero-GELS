import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/session_events.dart';
import '../data/auth_repository_impl.dart';
import 'session_state.dart';

/// Fuente de verdad del estado de sesión de toda la app. Arranca en
/// `checking`, intenta restaurar la sesión guardada, y termina en
/// `authenticated`/`unauthenticated`. También escucha `SessionEvents` para
/// forzar el cierre de sesión cuando el refresh transparente falla en medio
/// de la app (ver `core/network/refresh_interceptor.dart`).
class SessionNotifier extends Notifier<SessionState> {
  @override
  SessionState build() {
    final subscription = ref.read(sessionEventsProvider).stream.listen((event) {
      if (event == SessionEventType.sessionExpired) {
        state = const SessionState.unauthenticated();
      }
    });
    ref.onDispose(subscription.cancel);

    _restore();
    return const SessionState.checking();
  }

  Future<void> _restore() async {
    final usuario = await ref.read(authRepositoryProvider).restoreSession();
    if (!ref.mounted) return;
    state = usuario == null ? const SessionState.unauthenticated() : SessionState.authenticated(usuario);
  }

  /// Lanza [AppException] si las credenciales son inválidas o hay un error de
  /// red — a propósito, para que quien llame (el controller de la pantalla de
  /// login) lo capture y muestre el mensaje. El estado de sesión no cambia si
  /// falla.
  Future<void> login({required String email, required String password}) async {
    final usuario = await ref.read(authRepositoryProvider).login(email: email, password: password);
    state = SessionState.authenticated(usuario);
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const SessionState.unauthenticated();
  }
}

final sessionNotifierProvider = NotifierProvider<SessionNotifier, SessionState>(SessionNotifier.new);
