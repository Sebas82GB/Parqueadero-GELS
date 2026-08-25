import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../data/ticket_repository_impl.dart';
import 'buscar_placa_state.dart';

class BuscarPlacaNotifier extends Notifier<BuscarPlacaState> {
  @override
  BuscarPlacaState build() => const BuscarPlacaState();

  /// Sin fijar `estado`: el backend siempre devuelve los tickets de una
  /// placa ordenados por `horaEntrada` descendente, así que el primero de
  /// `perPage: 1` es el más reciente sea que esté abierto o ya cerrado. Eso
  /// es justo lo que necesita "¿está adentro?" — distinguir "adentro"
  /// (`estado == abierto`), "ya salió" (`pagado`/`entregado`/`anulado`) y
  /// "nunca entró" (sin resultados), no solo "hay un ticket abierto".
  Future<void> buscar(String placa) async {
    state = const BuscarPlacaState(isLoading: true);
    try {
      final pagina = await ref.read(ticketRepositoryProvider).listar(placa: placa, perPage: 1);
      if (!ref.mounted) return;
      state = BuscarPlacaState(buscado: true, ticket: pagina.data.isEmpty ? null : pagina.data.first);
    } on AppException catch (e) {
      if (!ref.mounted) return;
      state = BuscarPlacaState(errorMessage: e.message);
    }
  }
}

final buscarPlacaNotifierProvider =
    NotifierProvider.autoDispose<BuscarPlacaNotifier, BuscarPlacaState>(BuscarPlacaNotifier.new);
