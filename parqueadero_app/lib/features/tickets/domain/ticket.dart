import '../../celdas/domain/celda.dart';
import 'desglose_item.dart';
import 'pago.dart';
import 'recibo.dart';
import 'vehiculo.dart';

enum EstadoTicket {
  abierto,
  pagado,
  entregado,
  anulado;

  static EstadoTicket fromBackend(String value) => switch (value) {
    'ABIERTO' => EstadoTicket.abierto,
    'PAGADO' => EstadoTicket.pagado,
    'ENTREGADO' => EstadoTicket.entregado,
    'ANULADO' => EstadoTicket.anulado,
    _ => throw FormatException('estado de ticket desconocido recibido del backend: $value'),
  };

  String toBackend() => switch (this) {
    EstadoTicket.abierto => 'ABIERTO',
    EstadoTicket.pagado => 'PAGADO',
    EstadoTicket.entregado => 'ENTREGADO',
    EstadoTicket.anulado => 'ANULADO',
  };
}

/// Entidad de dominio. No incluye la tarifa aplicada: la app nunca necesita
/// mostrar sus valores, solo el `desglose` ya calculado por el backend.
class Ticket {
  const Ticket({
    required this.id,
    required this.codigo,
    required this.vehiculoId,
    required this.celdaId,
    required this.horaEntrada,
    this.horaSalida,
    required this.tarifaId,
    this.valorTotal,
    this.desglose = const [],
    required this.estado,
    required this.operadorEntradaId,
    this.operadorSalidaId,
    this.motivoAnulacion,
    this.anuladoPorId,
    this.anuladoEn,
    this.entregadoPorId,
    this.entregadoEn,
    required this.createdAt,
    required this.updatedAt,
    this.vehiculo,
    this.celda,
    this.pago,
    this.recibo,
  });

  final String id;
  final String codigo;
  final String vehiculoId;
  final String celdaId;
  final DateTime horaEntrada;
  final DateTime? horaSalida;
  final String tarifaId;
  final int? valorTotal;
  final List<DesgloseItem> desglose;
  final EstadoTicket estado;
  final String operadorEntradaId;
  final String? operadorSalidaId;
  final String? motivoAnulacion;
  final String? anuladoPorId;
  final DateTime? anuladoEn;
  final String? entregadoPorId;
  final DateTime? entregadoEn;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Vehiculo? vehiculo;
  final Celda? celda;
  final Pago? pago;

  /// `null` mientras el ticket sigue `ABIERTO`; una vez cerrado, el recibo
  /// listo para imprimir (`construirRecibo` en el backend).
  final Recibo? recibo;
}
