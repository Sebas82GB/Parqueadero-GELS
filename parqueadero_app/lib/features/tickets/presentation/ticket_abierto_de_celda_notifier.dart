import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../data/ticket_repository_impl.dart';
import '../domain/ticket.dart';
import 'ticket_abierto_de_celda_state.dart';

/// No hay endpoint directo celda→ticket: se resuelve componiendo
/// `listar(celdaId:, estado: abierto, perPage: 1)`. Usado inline desde
/// `celda_detail_screen.dart`, sin pantalla propia.
class TicketAbiertoDeCeldaNotifier extends Notifier<TicketAbiertoDeCeldaState> {
  TicketAbiertoDeCeldaNotifier(this.celdaId);

  final String celdaId;

  @override
  TicketAbiertoDeCeldaState build() => const TicketAbiertoDeCeldaState();

  /// Retorna el id del ticket abierto, o `null` si no se encuentra uno (caso
  /// raro de condición de carrera, no es un error de backend).
  Future<String?> buscar() async {
    state = const TicketAbiertoDeCeldaState(isLoading: true);
    try {
      final pagina = await ref
          .read(ticketRepositoryProvider)
          .listar(celdaId: celdaId, estado: EstadoTicket.abierto, perPage: 1);
      if (!ref.mounted) return null;
      state = const TicketAbiertoDeCeldaState();
      return pagina.data.isEmpty ? null : pagina.data.first.id;
    } on AppException catch (e) {
      if (!ref.mounted) return null;
      state = TicketAbiertoDeCeldaState(errorMessage: e.message);
      return null;
    }
  }
}

final ticketAbiertoDeCeldaNotifierProvider = NotifierProvider.autoDispose
    .family<TicketAbiertoDeCeldaNotifier, TicketAbiertoDeCeldaState, String>(
      TicketAbiertoDeCeldaNotifier.new,
    );
