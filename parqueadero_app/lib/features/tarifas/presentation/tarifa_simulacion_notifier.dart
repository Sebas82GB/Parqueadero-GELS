import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/tipo_vehiculo.dart';
import '../../../core/network/api_exception.dart';
import '../data/tarifa_repository_impl.dart';
import 'tarifa_simulacion_state.dart';

/// Vista previa de `POST /tarifas/simular` en la pantalla de nueva tarifa.
/// Deliberadamente separado de `NuevaTarifaNotifier`: ese notifier reemplaza
/// todo su estado en cada transición de `crear()` (sin `copyWith`), así que
/// mezclar ahí un resultado de simulación se pisaría con cada intento de
/// creación. Este notifier no toca nada del backend salvo el propio
/// `simular`: no crea ni modifica tarifas.
class TarifaSimulacionNotifier extends Notifier<TarifaSimulacionState> {
  @override
  TarifaSimulacionState build() => const TarifaSimulacionState();

  Future<void> simular({
    required TipoVehiculo tipoVehiculo,
    required int valorMinuto,
    required int valorPlena,
    required int valorNocturna,
    required int duracionMinutos,
  }) async {
    state = const TarifaSimulacionState(isLoading: true);
    try {
      final valorTotal = await ref
          .read(tarifaRepositoryProvider)
          .simular(
            tipoVehiculo: tipoVehiculo,
            valorMinuto: valorMinuto,
            valorPlena: valorPlena,
            valorNocturna: valorNocturna,
            duracionMinutos: duracionMinutos,
          );
      if (!ref.mounted) return;
      state = TarifaSimulacionState(valorTotal: valorTotal, tieneResultado: true);
    } on AppException catch (e) {
      if (!ref.mounted) return;
      state = TarifaSimulacionState(errorMessage: e.message);
    }
  }

  /// El formulario quedó incompleto o inválido: no tiene sentido seguir
  /// mostrando el último resultado, que ya no corresponde a lo que hay en
  /// los campos.
  void limpiar() => state = const TarifaSimulacionState();
}

final tarifaSimulacionNotifierProvider =
    NotifierProvider.autoDispose<TarifaSimulacionNotifier, TarifaSimulacionState>(
      TarifaSimulacionNotifier.new,
    );
