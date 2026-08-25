import 'package:json_annotation/json_annotation.dart';

import '../../../../core/domain/tipo_vehiculo.dart';
import '../../domain/desglose_item.dart';
import '../../domain/pago.dart';
import '../../domain/recibo.dart';
import 'desglose_item_dto.dart';

part 'recibo_dto.g.dart';

@JsonSerializable(createToJson: false)
class EstablecimientoDto {
  EstablecimientoDto({
    required this.nombre,
    required this.nit,
    required this.direccion,
    required this.telefono,
    required this.ciudad,
    required this.regimenTributario,
    required this.numeroResolucion,
    required this.textoResponsabilidad,
    required this.textoSeguro,
    required this.textoHorario,
    required this.textoReclamos,
  });

  factory EstablecimientoDto.fromJson(Map<String, dynamic> json) =>
      _$EstablecimientoDtoFromJson(json);

  final String nombre;
  final String nit;
  final String direccion;
  final String telefono;
  final String ciudad;
  final String regimenTributario;
  final String numeroResolucion;
  final String textoResponsabilidad;
  final String textoSeguro;
  final String textoHorario;
  final String textoReclamos;

  Establecimiento toDomain() => Establecimiento(
    nombre: nombre,
    nit: nit,
    direccion: direccion,
    telefono: telefono,
    ciudad: ciudad,
    regimenTributario: regimenTributario,
    numeroResolucion: numeroResolucion,
    textoResponsabilidad: textoResponsabilidad,
    textoSeguro: textoSeguro,
    textoHorario: textoHorario,
    textoReclamos: textoReclamos,
  );
}

/// `null` mientras el ticket sigue `ABIERTO` (ver `Ticket.recibo`), por eso
/// vive como campo opcional de `TicketDto` en vez de tener su propio
/// endpoint. `establecimiento` viaja siempre anidado acá — no hace falta
/// pegarle a `GET /establecimiento` por separado.
@JsonSerializable(createToJson: false)
class ReciboDto {
  ReciboDto({
    required this.consecutivo,
    required this.fechaEmision,
    required this.establecimiento,
    required this.placa,
    required this.tipoVehiculo,
    required this.celda,
    required this.horaEntrada,
    required this.horaSalida,
    required this.tiempoTotal,
    this.desglose = const [],
    required this.total,
    this.metodoPago,
    this.operador,
  });

  factory ReciboDto.fromJson(Map<String, dynamic> json) => _$ReciboDtoFromJson(json);

  final int consecutivo;
  final String fechaEmision;
  final EstablecimientoDto establecimiento;
  final String placa;
  final String tipoVehiculo;

  /// Código de la celda (p. ej. "A-01"), no su id.
  final String celda;
  final String horaEntrada;
  final String horaSalida;
  final String tiempoTotal;
  @JsonKey(fromJson: desgloseFromJson)
  final List<DesgloseItem> desglose;
  final int total;
  final String? metodoPago;
  final String? operador;

  Recibo toDomain() => Recibo(
    consecutivo: consecutivo,
    fechaEmision: DateTime.parse(fechaEmision),
    establecimiento: establecimiento.toDomain(),
    placa: placa,
    tipoVehiculo: TipoVehiculo.fromBackend(tipoVehiculo),
    celda: celda,
    horaEntrada: DateTime.parse(horaEntrada),
    horaSalida: DateTime.parse(horaSalida),
    tiempoTotal: tiempoTotal,
    desglose: desglose,
    total: total,
    metodoPago: metodoPago == null ? null : MetodoPago.fromBackend(metodoPago!),
    operador: operador,
  );
}
