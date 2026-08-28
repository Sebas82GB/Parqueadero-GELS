import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../data/turno_repository_impl.dart';
import 'abrir_turno_state.dart';
import 'turno_activo_notifier.dart';

class AbrirTurnoNotifier extends Notifier<AbrirTurnoState> {
  @override
  AbrirTurnoState build() => const AbrirTurnoState();

  /// Sin [baseInicial]: usa la automática que configuró un ADMIN (flujo del
  /// diálogo "Iniciar" en `OperadorHomeDashboard`). Con [baseInicial]:
  /// apertura manual con el valor que digitó el operador (`AbrirTurnoScreen`).
  Future<bool> abrir([int? baseInicial]) async {
    state = const AbrirTurnoState(isLoading: true);
    try {
      await ref.read(turnoRepositoryProvider).abrir(baseInicial);
      if (!ref.mounted) return false;
      state = const AbrirTurnoState();
      await ref.read(turnoActivoNotifierProvider.notifier).refrescar();
      return true;
    } on AppException catch (e) {
      if (!ref.mounted) return false;
      state = AbrirTurnoState(errorMessage: e.message);
      return false;
    }
  }
}

final abrirTurnoNotifierProvider =
    NotifierProvider.autoDispose<AbrirTurnoNotifier, AbrirTurnoState>(AbrirTurnoNotifier.new);
