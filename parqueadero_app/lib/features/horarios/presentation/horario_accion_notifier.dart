import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../data/horario_repository_impl.dart';
import 'horario_accion_state.dart';
import 'horario_list_notifier.dart';

/// Un estado por horario vigente con las acciones de "Cerrar vigencia" y
/// "Editar" abiertas (`autoDispose.family<String>` por `id`), mismo patrón
/// que `TarifaAccionNotifier`.
class HorarioAccionNotifier extends Notifier<HorarioAccionState> {
  HorarioAccionNotifier(this.horarioId);

  final String horarioId;

  @override
  HorarioAccionState build() => const HorarioAccionState();

  Future<void> cerrar() async {
    state = const HorarioAccionState(isLoading: true);
    try {
      await ref.read(horarioRepositoryProvider).cerrar(horarioId);
      if (!ref.mounted) return;
      // Refresca la lista completa: cerrar puede dejar el parqueadero sin
      // vigente, lo que cambia el mensaje de aviso mostrado en la pantalla.
      await ref.read(horarioListNotifierProvider.notifier).refrescar();
      if (!ref.mounted) return;
      state = const HorarioAccionState();
    } on AppException catch (e) {
      if (!ref.mounted) return;
      state = HorarioAccionState(errorMessage: e.message);
    }
  }

  Future<bool> actualizar({String? apertura, String? cierre}) async {
    state = const HorarioAccionState(isLoading: true);
    try {
      await ref.read(horarioRepositoryProvider).actualizar(horarioId, apertura: apertura, cierre: cierre);
      if (!ref.mounted) return false;
      // Refresca la lista completa: los nuevos valores deben verse en la
      // tarjeta sin esperar a que autoDispose reconstruya la pantalla.
      await ref.read(horarioListNotifierProvider.notifier).refrescar();
      if (!ref.mounted) return false;
      state = const HorarioAccionState();
      return true;
    } on AppException catch (e) {
      if (!ref.mounted) return false;
      state = HorarioAccionState(errorMessage: e.message);
      return false;
    }
  }
}

final horarioAccionNotifierProvider = NotifierProvider.autoDispose
    .family<HorarioAccionNotifier, HorarioAccionState, String>(HorarioAccionNotifier.new);
