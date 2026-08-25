enum EstadoPagoMensualidad {
  pagada,
  noPagada,
  cancelada;

  static EstadoPagoMensualidad fromBackend(String value) => switch (value) {
    'PAGADA' => EstadoPagoMensualidad.pagada,
    'NO_PAGADA' => EstadoPagoMensualidad.noPagada,
    'CANCELADA' => EstadoPagoMensualidad.cancelada,
    _ => throw FormatException('estado de pago de mensualidad desconocido recibido del backend: $value'),
  };

  String toBackend() => switch (this) {
    EstadoPagoMensualidad.pagada => 'PAGADA',
    EstadoPagoMensualidad.noPagada => 'NO_PAGADA',
    EstadoPagoMensualidad.cancelada => 'CANCELADA',
  };
}

/// Clasificación de vigencia calculada en el cliente para el semáforo del
/// listado. No es un campo que devuelva el backend: se deriva de
/// `fechaFin`/`estadoPago` comparados contra "ahora", con la misma
/// semántica de fechas que el filtro `?vigencia=` del backend (comparación
/// de fechas, no de dinero ni de disponibilidad — mismo criterio ya
/// aceptado para `Tarifa.esVigente`). `CANCELADA` tiene prioridad absoluta:
/// una mensualidad cancelada nunca se muestra como vencida o por vencer,
/// aunque sus fechas ya hayan pasado.
enum VigenciaMensualidad {
  vigente,
  porVencer,
  vencida,
  cancelada;

  /// Solo para el filtro `?vigencia=` de `GET /mensualidades`, que únicamente
  /// acepta `VIGENTE`/`POR_VENCER`/`VENCIDA` (`listarMensualidadesQuerySchema`
  /// en el backend). `cancelada` nunca se ofrece en el dropdown de filtro de
  /// vigencia — para filtrar por canceladas se usa el filtro de
  /// `estadoPago`, que sí incluye ese valor — así que este caso no debería
  /// alcanzarse nunca en la práctica.
  String toBackend() => switch (this) {
    VigenciaMensualidad.vigente => 'VIGENTE',
    VigenciaMensualidad.porVencer => 'POR_VENCER',
    VigenciaMensualidad.vencida => 'VENCIDA',
    VigenciaMensualidad.cancelada =>
      throw UnsupportedError('cancelada no es un valor válido del filtro de vigencia del backend'),
  };
}

/// Entidad de dominio. Sin `copyWith`: la sustitución tras crear/cancelar se
/// hace con lo que devuelve el propio backend.
class Mensualidad {
  const Mensualidad({
    required this.id,
    required this.vehiculoId,
    required this.celdaId,
    required this.fechaInicio,
    required this.fechaFin,
    required this.valorMensualidad,
    required this.estadoPago,
    required this.fechaPago,
    required this.createdAt,
    required this.updatedAt,
  });

  static const diasPorVencerDefault = 7;

  final String id;
  final String vehiculoId;
  final String? celdaId;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final int valorMensualidad;
  final EstadoPagoMensualidad estadoPago;
  final DateTime? fechaPago;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// `diasPorVencer` debe coincidir con el default del backend (7, ver
  /// `listarMensualidadesQuerySchema`) para que el badge mostrado en la
  /// pantalla coincida con lo que devolvería `?vigencia=POR_VENCER` sin
  /// pasar `diasPorVencer` explícito. `ahora` es un parámetro opcional (no
  /// `DateTime.now()` interno) para que los tests puedan fijar el borde de
  /// forma determinística.
  VigenciaMensualidad vigencia({DateTime? ahora, int diasPorVencer = diasPorVencerDefault}) {
    if (estadoPago == EstadoPagoMensualidad.cancelada) return VigenciaMensualidad.cancelada;
    final now = (ahora ?? DateTime.now()).toUtc();
    if (fechaFin.isBefore(now)) return VigenciaMensualidad.vencida;
    if (fechaFin.isBefore(now.add(Duration(days: diasPorVencer)))) return VigenciaMensualidad.porVencer;
    return VigenciaMensualidad.vigente;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Mensualidad &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          vehiculoId == other.vehiculoId &&
          celdaId == other.celdaId &&
          fechaInicio == other.fechaInicio &&
          fechaFin == other.fechaFin &&
          valorMensualidad == other.valorMensualidad &&
          estadoPago == other.estadoPago &&
          fechaPago == other.fechaPago &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
    id,
    vehiculoId,
    celdaId,
    fechaInicio,
    fechaFin,
    valorMensualidad,
    estadoPago,
    fechaPago,
    createdAt,
    updatedAt,
  );
}
