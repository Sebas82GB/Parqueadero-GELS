import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../data/turno_repository_impl.dart';
import 'turno_activo_notifier.dart';
import 'turno_cierre_state.dart';

/// Cerrar un turno ABIERTO o completar el arqueo de uno
/// CERRADO_PENDIENTE_ARQUEO: mismo formulario, mismo resultado
/// (`ArqueoTurno`), solo cambia qué endpoint golpea. El "esperado" que se
/// muestra antes de confirmar sale de `turnoDetailNotifierProvider` (mismo
/// turno, ya lo pide esa pantalla), no se duplica la consulta acá. Mismo
/// espíritu que `SalidaNotifier` junto a `TicketDetailNotifier`.
class TurnoCierreNotifier extends Notifier<TurnoCierreState> {
  TurnoCierreNotifier(this.turnoId);

  final String turnoId;

  @override
  TurnoCierreState build() => const TurnoCierreState();

  Future<bool> cerrar(int efectivoContado) async {
    state = const TurnoCierreState(step: TurnoCierreStep.enviando);
    try {
      final arqueo = await ref.read(turnoRepositoryProvider).cerrar(turnoId, efectivoContado);
      if (!ref.mounted) return false;
      await ref.read(turnoActivoNotifierProvider.notifier).refrescar();
      state = TurnoCierreState(step: TurnoCierreStep.exito, resultado: arqueo);
      return true;
    } on AppException catch (e) {
      if (!ref.mounted) return false;
      state = TurnoCierreState(error: e);
      return false;
    }
  }

  /// Mismo formulario y pantalla que [cerrar], para un turno que el turno
  /// automático ya pasó a `CERRADO_PENDIENTE_ARQUEO`. No refresca
  /// `turnoActivoNotifierProvider`: quien completa un arqueo es un ADMIN, que
  /// nunca tiene turno propio.
  Future<bool> completarArqueo(int efectivoContado) async {
    state = const TurnoCierreState(step: TurnoCierreStep.enviando);
    try {
      final arqueo = await ref.read(turnoRepositoryProvider).completarArqueo(turnoId, efectivoContado);
      if (!ref.mounted) return false;
      state = TurnoCierreState(step: TurnoCierreStep.exito, resultado: arqueo);
      return true;
    } on AppException catch (e) {
      if (!ref.mounted) return false;
      state = TurnoCierreState(error: e);
      return false;
    }
  }
}

final turnoCierreNotifierProvider = NotifierProvider.autoDispose
    .family<TurnoCierreNotifier, TurnoCierreState, String>(TurnoCierreNotifier.new);
