import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bus genérico y neutral: `core/network` nunca importa nada de `features/`.
/// El interceptor de refresh emite eventos aquí cuando la sesión muere; quien
/// escucha (el notifier de sesión, en `features/auth/presentation`) decide
/// qué hacer. Un enum en vez de un tipo específico de auth, por si más
/// adelante hace falta otra señal de este estilo.
enum SessionEventType { sessionExpired }

class SessionEvents {
  final _controller = StreamController<SessionEventType>.broadcast();

  Stream<SessionEventType> get stream => _controller.stream;

  void emit(SessionEventType event) => _controller.add(event);

  void dispose() => _controller.close();
}

final sessionEventsProvider = Provider<SessionEvents>((ref) {
  final events = SessionEvents();
  ref.onDispose(events.dispose);
  return events;
});
