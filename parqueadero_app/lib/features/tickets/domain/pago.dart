enum MetodoPago {
  efectivo,
  tarjeta,
  transferencia;

  static MetodoPago fromBackend(String value) => switch (value) {
    'EFECTIVO' => MetodoPago.efectivo,
    'TARJETA' => MetodoPago.tarjeta,
    'TRANSFERENCIA' => MetodoPago.transferencia,
    _ => throw FormatException('método de pago desconocido recibido del backend: $value'),
  };

  String toBackend() => switch (this) {
    MetodoPago.efectivo => 'EFECTIVO',
    MetodoPago.tarjeta => 'TARJETA',
    MetodoPago.transferencia => 'TRANSFERENCIA',
  };
}

enum EstadoPago {
  valido,
  anulado;

  static EstadoPago fromBackend(String value) => switch (value) {
    'VALIDO' => EstadoPago.valido,
    'ANULADO' => EstadoPago.anulado,
    _ => throw FormatException('estado de pago desconocido recibido del backend: $value'),
  };
}

class Pago {
  const Pago({
    required this.id,
    required this.ticketId,
    this.mensualidadId,
    required this.monto,
    required this.metodo,
    required this.turnoId,
    required this.fecha,
    required this.estado,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String? ticketId;
  final String? mensualidadId;
  final int monto;
  final MetodoPago metodo;
  final String turnoId;
  final DateTime fecha;
  final EstadoPago estado;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Pago &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          ticketId == other.ticketId &&
          mensualidadId == other.mensualidadId &&
          monto == other.monto &&
          metodo == other.metodo &&
          turnoId == other.turnoId &&
          fecha == other.fecha &&
          estado == other.estado &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
    id,
    ticketId,
    mensualidadId,
    monto,
    metodo,
    turnoId,
    fecha,
    estado,
    createdAt,
    updatedAt,
  );
}
