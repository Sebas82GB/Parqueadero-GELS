import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../data/horario_repository_impl.dart';
import '../domain/horario.dart';
import 'horario_list_notifier.dart';
import 'nuevo_horario_state.dart';

class NuevoHorarioNotifier extends Notifier<NuevoHorarioState> {
  @override
  NuevoHorarioState build() => const NuevoHorarioState();

  Future<Horario?> crear({required String apertura, required String cierre}) async {
    state = const NuevoHorarioState(isLoading: true);
    try {
      final horario = await ref.read(horarioRepositoryProvider).crear(apertura: apertura, cierre: cierre);
      if (!ref.mounted) return null;
      // El provider de la lista puede seguir vivo si la navegación a esta
      // pantalla fue un `push` (no se desechó); no basta con confiar en que
      // su propio autoDispose lo reconstruya al volver.
      await ref.read(horarioListNotifierProvider.notifier).refrescar();
      if (!ref.mounted) return null;
      state = const NuevoHorarioState();
      return horario;
    } on AppException catch (e) {
      if (!ref.mounted) return null;
      state = NuevoHorarioState(errorMessage: e.message);
      return null;
    }
  }
}

final nuevoHorarioNotifierProvider =
    NotifierProvider.autoDispose<NuevoHorarioNotifier, NuevoHorarioState>(NuevoHorarioNotifier.new);
