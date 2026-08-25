import 'turno.dart';

class TotalesPorMetodo {
  const TotalesPorMetodo({required this.efectivo, required this.tarjeta, required this.transferencia});

  final int efectivo;
  final int tarjeta;
  final int transferencia;
}

/// Resumen de caja de un turno: parcial y en vivo mientras el turno sigue
/// [EstadoTurno.abierto] (ahí [efectivoContado] y [diferencia] llegan en
/// `null`, porque todavía no se ha contado caja), o final una vez
/// [EstadoTurno.cerrado]. Lo devuelven tanto `GET /turnos/:id/arqueo` como
/// `POST /turnos/:id/cierre`.
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
}
