import '../../../core/domain/tipo_vehiculo.dart';
import 'cobro_preview.dart';
import 'pago.dart';
import 'ticket.dart';

/// Página de resultados de [TicketRepository.listar]. A diferencia de
/// `CeldaRepository.listarTodas()` (que aplana toda la paginación porque un
/// parqueadero tiene a lo sumo unos cientos de celdas), el historial de
/// tickets crece sin límite: la paginación se expone hasta presentación.
class TicketPageResult {
  const TicketPageResult({required this.data, required this.page, required this.perPage, required this.total});

  final List<Ticket> data;
  final int page;
  final int perPage;
  final int total;

  bool get hayMas => page * perPage < total;
}

/// Sin dependencias de Flutter ni de dio.
abstract interface class TicketRepository {
  /// `POST /tickets`. Lanza [ApiException] con el code correspondiente
  /// (`CELDA_NO_ENCONTRADA`, `CELDA_OCUPADA`, `CELDA_EN_MANTENIMIENTO`,
  /// `VEHICULO_CON_TICKET_ABIERTO`, `CELDA_TIPO_INCOMPATIBLE`,
  /// `TARIFA_NO_VIGENTE`, entre otros) — la decide el backend, no este
  /// repositorio.
  Future<Ticket> registrarEntrada({
    required String placa,
    required TipoVehiculo tipoVehiculo,
    required String celdaId,
    String? propietarioNombre,
    String? propietarioTelefono,
  });

  /// `POST /tickets/:id/salida`. Cierra el ticket transaccionalmente con el
  /// cobro calculado en ese momento. Puede lanzar `VALOR_MANUAL_REQUERIDO`,
  /// `METODO_PAGO_REQUERIDO` o `OPERADOR_SIN_TURNO_ABIERTO` si falta algo que
  /// la app no puede saber de antemano (el turno abierto sí se puede
  /// consultar de antemano con `TurnoRepository.listar`, pero esta llamada
  /// igual puede fallar si se cerró justo entre medio). Para saber cuánto
  /// cobrará ANTES de llamar esto, usar [previsualizarCobro].
  Future<Ticket> registrarSalida(String ticketId, {MetodoPago? metodo, int? valorManual});

  /// `GET /tickets/:id/preview-cobro`. Solo lectura: no cierra el ticket ni
  /// modifica nada, cualquier rol autenticado puede llamarlo. Devuelve lo que
  /// cobraría [registrarSalida] si se llamara en este instante. Lanza
  /// [ApiException] `TICKET_NO_ENCONTRADO` (404) o `TICKET_NO_ABIERTO` (409)
  /// si el ticket ya no está abierto.
  Future<CobroPreview> previsualizarCobro(String ticketId);

  /// `GET /tickets/:id`, con detalle completo (vehiculo, celda, pago).
  Future<Ticket> obtenerPorId(String id);

  /// `GET /tickets` con filtros. Sin restricción de rol.
  Future<TicketPageResult> listar({
    EstadoTicket? estado,
    String? vehiculoId,
    String? celdaId,
    String? placa,
    DateTime? desde,
    DateTime? hasta,
    int page = 1,
    int perPage = 20,
  });
}
