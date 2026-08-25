import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../auth/presentation/session_notifier.dart';
import '../data/turno_repository_impl.dart';
import '../domain/turno.dart';
import 'turno_activo_state.dart';

/// Estado transversal a varias pantallas (Home, Celdas, registrar
/// entrada/salida): a propósito **no** es `autoDispose`, para no repetir la
/// consulta ni el parpadeo de carga cada vez que el operador navega entre
/// ellas. Se refresca explícitamente (`refrescar()`) cuando algo lo
/// invalida: abrir o cerrar un turno.
class TurnoActivoNotifier extends Notifier<TurnoActivoState> {
  bool _isLoading = false;

  @override
  TurnoActivoState build() {
    Future.microtask(cargar);
    return const TurnoActivoState(isLoading: true);
  }

  Future<void> cargar() async {
    // Sin este guard, un `refrescar()` disparado justo después de que se
    // construye el provider (que ya programó su propia carga inicial vía
    // `Future.microtask`) duplica la consulta al backend.
    if (_isLoading) return;
    final usuario = ref.read(sessionNotifierProvider).usuario;
    if (usuario == null) return;

    _isLoading = true;
    state = const TurnoActivoState(isLoading: true);
    try {
      final pagina = await ref
          .read(turnoRepositoryProvider)
          .listar(operadorId: usuario.id, estado: EstadoTurno.abierto, perPage: 1);
      if (!ref.mounted) return;
      state = TurnoActivoState(turno: pagina.data.isEmpty ? null : pagina.data.first);
    } on AppException catch (e) {
      if (!ref.mounted) return;
      state = TurnoActivoState(errorMessage: e.message);
    } finally {
      _isLoading = false;
    }
  }

  Future<void> refrescar() => cargar();
}

final turnoActivoNotifierProvider = NotifierProvider<TurnoActivoNotifier, TurnoActivoState>(
  TurnoActivoNotifier.new,
);
