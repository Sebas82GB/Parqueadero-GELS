import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../data/turno_repository_impl.dart';
import 'turno_detail_state.dart';

/// Un estado por turno abierto en detalle (`autoDispose.family<String>` por
/// `id`), liberado en cuanto se sale de esa pantalla. Sirve tanto para el
/// arqueo parcial (turno ABIERTO) como el final (CERRADO): el backend decide
/// cuál devolver, esta capa solo lo muestra.
class TurnoDetailNotifier extends Notifier<TurnoDetailState> {
  TurnoDetailNotifier(this.turnoId);

  final String turnoId;

  @override
  TurnoDetailState build() {
    Future.microtask(cargar);
    return const TurnoDetailState(isLoading: true);
  }

  Future<void> cargar() async {
    state = const TurnoDetailState(isLoading: true);
    try {
      final arqueo = await ref.read(turnoRepositoryProvider).obtenerArqueo(turnoId);
      if (!ref.mounted) return;
      state = TurnoDetailState(arqueo: arqueo);
    } on AppException catch (e) {
      if (!ref.mounted) return;
      state = TurnoDetailState(errorMessage: e.message);
    }
  }
}

final turnoDetailNotifierProvider = NotifierProvider.autoDispose
    .family<TurnoDetailNotifier, TurnoDetailState, String>(TurnoDetailNotifier.new);
