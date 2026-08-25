import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../data/mensualidad_repository_impl.dart';
import 'mensualidad_accion_state.dart';
import 'mensualidad_list_notifier.dart';

/// Un estado por mensualidad abierta en detalle (`autoDispose.family<String>`
/// por `id`), mismo patrón que `CeldaAccionNotifier`/`TarifaAccionNotifier`.
/// Solo expone `cancelar()`: no hay `pagar()` en esta pantalla porque abrir
/// turno es estrictamente `OPERADOR` en el backend, así que un ADMIN nunca
/// tiene turno propio con el que pagar (`POST /mensualidades/:id/pagar`
/// exige uno).
class MensualidadAccionNotifier extends Notifier<MensualidadAccionState> {
  MensualidadAccionNotifier(this.mensualidadId);

  final String mensualidadId;

  @override
  MensualidadAccionState build() => const MensualidadAccionState();

  Future<void> cancelar() async {
    state = const MensualidadAccionState(isLoading: true);
    try {
      final actualizada = await ref.read(mensualidadRepositoryProvider).cancelar(mensualidadId);
      if (!ref.mounted) return;
      ref.read(mensualidadListNotifierProvider.notifier).reemplazarMensualidad(actualizada);
      state = const MensualidadAccionState();
    } on AppException catch (e) {
      if (!ref.mounted) return;
      state = MensualidadAccionState(errorMessage: e.message);
    }
  }
}

final mensualidadAccionNotifierProvider = NotifierProvider.autoDispose
    .family<MensualidadAccionNotifier, MensualidadAccionState, String>(MensualidadAccionNotifier.new);
