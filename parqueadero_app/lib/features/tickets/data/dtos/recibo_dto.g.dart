// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recibo_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EstablecimientoDto _$EstablecimientoDtoFromJson(Map<String, dynamic> json) =>
    EstablecimientoDto(
      nombre: json['nombre'] as String,
      nit: json['nit'] as String,
      direccion: json['direccion'] as String,
      telefono: json['telefono'] as String,
      ciudad: json['ciudad'] as String,
      regimenTributario: json['regimenTributario'] as String,
      numeroResolucion: json['numeroResolucion'] as String,
      textoResponsabilidad: json['textoResponsabilidad'] as String,
      textoSeguro: json['textoSeguro'] as String,
      textoHorario: json['textoHorario'] as String,
      textoReclamos: json['textoReclamos'] as String,
    );

ReciboDto _$ReciboDtoFromJson(Map<String, dynamic> json) => ReciboDto(
  consecutivo: (json['consecutivo'] as num).toInt(),
  fechaEmision: json['fechaEmision'] as String,
  establecimiento: EstablecimientoDto.fromJson(
    json['establecimiento'] as Map<String, dynamic>,
  ),
  placa: json['placa'] as String,
  tipoVehiculo: json['tipoVehiculo'] as String,
  celda: json['celda'] as String,
  horaEntrada: json['horaEntrada'] as String,
  horaSalida: json['horaSalida'] as String,
  tiempoTotal: json['tiempoTotal'] as String,
  desglose: json['desglose'] == null
      ? const []
      : desgloseFromJson(json['desglose'] as List?),
  total: (json['total'] as num).toInt(),
  metodoPago: json['metodoPago'] as String?,
  operador: json['operador'] as String?,
);
