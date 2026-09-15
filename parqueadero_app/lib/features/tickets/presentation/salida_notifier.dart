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

  /// El `POST /tickets/:id/salida` es transaccional: cuando responde, el
  /// ticket YA quedó cerrado y cobrado en la base de datos. Por eso su
  /// resultado no se puede descartar como sí se descarta el de un GET — en
  /// `cobro_preview_notifier.dart` tirar un preview a la basura no cuesta
  /// nada (el siguiente refresco lo vuelve a pedir), pero acá lo que se
  /// pierde es el único recibo de un cobro que ya ocurrió: el operador no ve
  /// confirmación, asume que falló, reintenta, y el backend le responde
  /// `TICKET_NO_ABIERTO` sobre dinero que ya entró.
  ///
  /// Ese riesgo es real porque el provider es `autoDispose` y uno de sus dos
  /// consumidores es el bottom sheet de acción rápida, que el operador puede
  /// cerrar (o arrastrar sin querer) entre que toca "Confirmar" y que el
  /// servidor responde. [Ref.keepAlive] cubre exactamente esa ventana:
  /// mantiene vivo el notifier mientras la petición está en vuelo, así que
  /// el estado de éxito, el recibo y la actualización de la celda a LIBRE se
  /// escriben siempre, haya o no alguien mirando. El `finally` cierra el
  /// link pase lo que pase, para que el provider vuelva a comportarse como
  /// el `autoDispose` normal que es en cuanto la operación termina.
  Future<bool> confirmarSalida({MetodoPago? metodo, int? valorManual}) async {
    state = const SalidaState(step: SalidaStep.enviando);
    final link = ref.keepAlive();
    try {
      final ticket = await ref
          .read(ticketRepositoryProvider)
          .registrarSalida(ticketId, metodo: metodo, valorManual: valorManual);
      if (ticket.celda != null) {
        ref.read(celdaListNotifierProvider.notifier).reemplazarCelda(ticket.celda!);
      }
      state = SalidaState(step: SalidaStep.exito, ticketCerrado: ticket);
      return true;
    } on AppException catch (e) {
      state = SalidaState(error: e);
      return false;
    } finally {
      link.close();
    }
  }
}

final salidaNotifierProvider = NotifierProvider.autoDispose
    .family<SalidaNotifier, SalidaState, String>(SalidaNotifier.new);
