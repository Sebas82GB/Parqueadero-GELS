import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../data/tarifa_repository_impl.dart';
import '../domain/tarifa.dart';
import 'nueva_tarifa_state.dart';
import 'tarifa_list_notifier.dart';

class NuevaTarifaNotifier extends Notifier<NuevaTarifaState> {
  @override
  NuevaTarifaState build() => const NuevaTarifaState();

  Future<Tarifa?> crear({
    required TipoVehiculo tipoVehiculo,
    required int valorMinuto,
    required int valorPlena,
    required int valorNocturna,
    required int valorMes,
  }) async {
    state = const NuevaTarifaState(isLoading: true);
    try {
      final tarifa = await ref
          .read(tarifaRepositoryProvider)
          .crear(
            tipoVehiculo: tipoVehiculo,
            valorMinuto: valorMinuto,
            valorPlena: valorPlena,
            valorNocturna: valorNocturna,
            valorMes: valorMes,
          );
      if (!ref.mounted) return null;
      // El provider de la lista puede seguir vivo si la navegación a esta
      // pantalla fue un `push` (no se desechó); no basta con confiar en que
      // su propio autoDispose lo reconstruya al volver.
      await ref.read(tarifaListNotifierProvider.notifier).refrescar();
      if (!ref.mounted) return null;
      state = const NuevaTarifaState();
      return tarifa;
    } on AppException catch (e) {
      if (!ref.mounted) return null;
      state = NuevaTarifaState(errorMessage: e.message);
      return null;
    }
  }
}

final nuevaTarifaNotifierProvider =
    NotifierProvider.autoDispose<NuevaTarifaNotifier, NuevaTarifaState>(NuevaTarifaNotifier.new);
