import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../celdas/presentation/celda_list_notifier.dart';
import '../data/ticket_repository_impl.dart';
import '../domain/pago.dart';
import 'salida_state.dart';

/// `registrarSalida` calcula el cobro y cierra el ticket en la misma
/// llamada (transaccional en el backend); este notifier solo modela ESA
/// llamada, no la vista previa (ver `cobro_preview_notifier.dart` para el
/// `GET /tickets/:id/preview-cobro` que se refresca sola mientras la
/// pantalla está abierta). Por eso este notifier no tiene un estado de
/// "confirmando" — la confirmación ("¿Confirmar salida? Esta acción no se
/// puede deshacer", con el monto que muestra el preview) es un diálogo
/// imperativo en la pantalla, antes de llamar a [confirmarSalida]. Lo que sí
/// modela este estado es el resultado: el recibo con el desglose solo se
/// conoce después de que la llamada tuvo éxito.
class SalidaNotifier extends Notifier<SalidaState> {
  SalidaNotifier(this.ticketId);

  final String ticketId;

  @override
  SalidaState build() => const SalidaState();

  Future<bool> confirmarSalida({MetodoPago? metodo, int? valorManual}) async {
    state = const SalidaState(step: SalidaStep.enviando);
    try {
      final ticket = await ref
          .read(ticketRepositoryProvider)
          .registrarSalida(ticketId, metodo: metodo, valorManual: valorManual);
      if (!ref.mounted) return false;
      if (ticket.celda != null) {
        ref.read(celdaListNotifierProvider.notifier).reemplazarCelda(ticket.celda!);
      }
      state = SalidaState(step: SalidaStep.exito, ticketCerrado: ticket);
      return true;
    } on AppException catch (e) {
      if (!ref.mounted) return false;
      state = SalidaState(error: e);
      return false;
    }
  }
}

final salidaNotifierProvider = NotifierProvider.autoDispose
    .family<SalidaNotifier, SalidaState, String>(SalidaNotifier.new);
