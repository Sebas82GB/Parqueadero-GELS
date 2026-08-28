import 'turno.dart';

class TotalesPorMetodo {
  const TotalesPorMetodo({required this.efectivo, required this.tarjeta, required this.transferencia});

  final int efectivo;
  final int tarjeta;
  final int transferencia;
}

/// Resumen de caja de un turno: parcial y en vivo mientras el turno sigue
/// [EstadoTurno.abierto] (ahí [efectivoContado] y [diferencia] llegan en
/// `null`, porque todavía no se ha contado caja); [EstadoTurno.cerradoPendienteArqueo]
/// cuando el turno automático ya cerró la ventana horaria pero nadie ha
/// contado caja todavía (efectivoEsperado ya calculado, efectivoContado y
/// diferencia siguen en `null`); o final una vez [EstadoTurno.cerrado]. Lo
/// devuelven `GET /turnos/:id/arqueo`, `POST /turnos/:id/cierre` y
/// `POST /turnos/:id/completar-arqueo`.
class ArqueoTurno {
  const ArqueoTurno({
    required this.turnoId,
    required this.operadorId,
    required this.estado,
    required this.apertura,
    this.cierre,
    required this.baseInicial,
    required this.totalesPorMetodo,
    required this.totalRecaudado,
    required this.ticketsCerrados,
    required this.efectivoEsperado,
    this.efectivoContado,
    this.diferencia,
    this.validadoPorId,
    this.validadoEn,
  });

  final String turnoId;
  final String operadorId;
  final EstadoTurno estado;
  final DateTime apertura;
  final DateTime? cierre;
  final int baseInicial;
  final TotalesPorMetodo totalesPorMetodo;
  final int totalRecaudado;
  final int ticketsCerrados;
  final int efectivoEsperado;
  final int? efectivoContado;
  final int? diferencia;

  /// Solo distintos de `null` si el turno pasó por
  /// [EstadoTurno.cerradoPendienteArqueo] y un ADMIN ya completó el arqueo.
  final String? validadoPorId;
  final DateTime? validadoEn;
}
