import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../data/ticket_repository_impl.dart';
import 'ticket_detail_state.dart';

/// Un estado por ticket abierto en detalle o en salida
/// (`autoDispose.family<String>` por `id`), liberado en cuanto se sale de esa
/// pantalla. Sin polling: es una consulta puntual, no un dato que cambie
/// mientras el operador la mira.
class TicketDetailNotifier extends Notifier<TicketDetailState> {
  TicketDetailNotifier(this.ticketId);

  final String ticketId;

  @override
  TicketDetailState build() {
    Future.microtask(cargar);
    return const TicketDetailState(isLoading: true);
  }

  Future<void> cargar() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final ticket = await ref.read(ticketRepositoryProvider).obtenerPorId(ticketId);
      if (!ref.mounted) return;
      state = TicketDetailState(ticket: ticket);
    } on AppException catch (e) {
      if (!ref.mounted) return;
      state = TicketDetailState(errorMessage: e.message);
    }
  }
}

extension on TicketDetailState {
  TicketDetailState copyWith({bool? isLoading, String? errorMessage, bool clearError = false}) =>
      TicketDetailState(
        isLoading: isLoading ?? this.isLoading,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        ticket: ticket,
      );
}

final ticketDetailNotifierProvider = NotifierProvider.autoDispose
    .family<TicketDetailNotifier, TicketDetailState, String>(TicketDetailNotifier.new);
