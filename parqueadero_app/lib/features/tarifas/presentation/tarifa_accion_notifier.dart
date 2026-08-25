import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../data/tarifa_repository_impl.dart';
import 'tarifa_accion_state.dart';
import 'tarifa_list_notifier.dart';

/// Un estado por tarifa vigente con la acción de "Cerrar vigencia" abierta
/// (`autoDispose.family<String>` por `id`), mismo patrón que
/// `CeldaAccionNotifier`.
class TarifaAccionNotifier extends Notifier<TarifaAccionState> {
  TarifaAccionNotifier(this.tarifaId);

  final String tarifaId;

  @override
  TarifaAccionState build() => const TarifaAccionState();

  Future<void> cerrar() async {
    state = const TarifaAccionState(isLoading: true);
    try {
      await ref.read(tarifaRepositoryProvider).cerrar(tarifaId);
      if (!ref.mounted) return;
      // Refresca la lista completa: cerrar puede dejar el grupo sin vigente,
      // lo que cambia el mensaje de aviso mostrado en la tarjeta.
      await ref.read(tarifaListNotifierProvider.notifier).refrescar();
      if (!ref.mounted) return;
      state = const TarifaAccionState();
    } on AppException catch (e) {
      if (!ref.mounted) return;
      state = TarifaAccionState(errorMessage: e.message);
    }
  }
}

final tarifaAccionNotifierProvider = NotifierProvider.autoDispose
    .family<TarifaAccionNotifier, TarifaAccionState, String>(TarifaAccionNotifier.new);
