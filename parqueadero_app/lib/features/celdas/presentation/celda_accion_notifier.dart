import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../data/celda_repository_impl.dart';
import '../domain/celda.dart';
import '../domain/celda_repository.dart';
import 'celda_accion_state.dart';
import 'celda_list_notifier.dart';

/// Un estado por celda abierta en detalle (`autoDispose.family<String>` por
/// `id`), liberado en cuanto se sale de esa pantalla. El id de la celda llega
/// por el constructor: es lo que la fábrica de la family le pasa a
/// `CeldaAccionNotifier.new`.
class CeldaAccionNotifier extends Notifier<CeldaAccionState> {
  CeldaAccionNotifier(this.celdaId);

  final String celdaId;

  @override
  CeldaAccionState build() => const CeldaAccionState();

  Future<void> marcarMantenimiento() => _ejecutar((repo) => repo.marcarMantenimiento(celdaId));

  Future<void> volverALibre() => _ejecutar((repo) => repo.volverALibre(celdaId));

  Future<void> _ejecutar(Future<Celda> Function(CeldaRepository repo) accion) async {
    state = const CeldaAccionState(isLoading: true);
    try {
      final actualizada = await accion(ref.read(celdaRepositoryProvider));
      if (!ref.mounted) return;
      // No espera al próximo poll de 30s: refleja el nuevo estado ya mismo.
      ref.read(celdaListNotifierProvider.notifier).reemplazarCelda(actualizada);
      state = const CeldaAccionState();
    } on AppException catch (e) {
      if (!ref.mounted) return;
      state = CeldaAccionState(errorMessage: e.message);
    }
  }
}

final celdaAccionNotifierProvider = NotifierProvider.autoDispose
    .family<CeldaAccionNotifier, CeldaAccionState, String>(CeldaAccionNotifier.new);
