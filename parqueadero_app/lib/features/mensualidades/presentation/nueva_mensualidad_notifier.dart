import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/tipo_vehiculo.dart';
import '../../../core/network/api_exception.dart';
import '../data/mensualidad_repository_impl.dart';
import '../domain/mensualidad.dart';
import 'mensualidad_list_notifier.dart';
import 'nueva_mensualidad_state.dart';

class NuevaMensualidadNotifier extends Notifier<NuevaMensualidadState> {
  @override
  NuevaMensualidadState build() => const NuevaMensualidadState();

  Future<Mensualidad?> crear({
    required String placa,
    required TipoVehiculo tipoVehiculo,
    String? propietarioNombre,
    String? propietarioTelefono,
    String? celdaId,
    required DateTime fechaInicio,
    required DateTime fechaFin,
    required int valorMensualidad,
  }) async {
    state = const NuevaMensualidadState(isLoading: true);
    try {
      final mensualidad = await ref
          .read(mensualidadRepositoryProvider)
          .crear(
            placa: placa,
            tipoVehiculo: tipoVehiculo,
            propietarioNombre: propietarioNombre,
            propietarioTelefono: propietarioTelefono,
            celdaId: celdaId,
            fechaInicio: fechaInicio,
            fechaFin: fechaFin,
            valorMensualidad: valorMensualidad,
          );
      if (!ref.mounted) return null;
      // El provider de la lista puede seguir vivo si la navegación a esta
      // pantalla fue un `push`; no basta con confiar en su propio
      // autoDispose para que se refresque solo al volver.
      await ref.read(mensualidadListNotifierProvider.notifier).refrescar();
      if (!ref.mounted) return null;
      state = const NuevaMensualidadState();
      return mensualidad;
    } on AppException catch (e) {
      if (!ref.mounted) return null;
      state = NuevaMensualidadState(errorMessage: e.message);
      return null;
    }
  }
}

final nuevaMensualidadNotifierProvider =
    NotifierProvider.autoDispose<NuevaMensualidadNotifier, NuevaMensualidadState>(
      NuevaMensualidadNotifier.new,
    );
