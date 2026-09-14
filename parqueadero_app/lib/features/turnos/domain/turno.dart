enum EstadoTurno {
  abierto,
  cerradoPendienteArqueo,
  cerrado;

  static EstadoTurno fromBackend(String value) => switch (value) {
    'ABIERTO' => EstadoTurno.abierto,
    'CERRADO_PENDIENTE_ARQUEO' => EstadoTurno.cerradoPendienteArqueo,
    'CERRADO' => EstadoTurno.cerrado,
    _ => throw FormatException('estado de turno desconocido recibido del backend: $value'),
  };

  String toBackend() => switch (this) {
    EstadoTurno.abierto => 'ABIERTO',
    EstadoTurno.cerradoPendienteArqueo => 'CERRADO_PENDIENTE_ARQUEO',
    EstadoTurno.cerrado => 'CERRADO',
  };
}

class Turno {
  const Turno({
    required this.id,
    required this.operadorId,
    required this.apertura,
    this.cierre,
    required this.baseInicial,
    this.totalRecaudado,
    this.efectivoContado,
    this.efectivoEsperado,
    this.diferencia,
    required this.estado,
    this.validadoPorId,
    this.validadoEn,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String operadorId;
  final DateTime apertura;
  final DateTime? cierre;
  final int baseInicial;
  final int? totalRecaudado;
  /// Los siguientes tres solo se llenan al cerrar el turno.
  final int? efectivoContado;
  final int? efectivoEsperado;
  final int? diferencia;
  final EstadoTurno estado;

  /// Solo distintos de `null` si el turno pasó por
  /// [EstadoTurno.cerradoPendienteArqueo] y un ADMIN ya completó el arqueo
  /// (mismo criterio que en `ArqueoTurno`).
  final String? validadoPorId;
  final DateTime? validadoEn;
  final DateTime createdAt;
  final DateTime updatedAt;
}
