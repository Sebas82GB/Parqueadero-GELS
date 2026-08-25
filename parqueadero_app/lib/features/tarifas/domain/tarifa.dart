import '../../../core/domain/tipo_vehiculo.dart';

export '../../../core/domain/tipo_vehiculo.dart';

/// Entidad de dominio. Sin `copyWith`: la sustitución tras crear/cerrar se
/// hace con lo que devuelve el propio backend.
class Tarifa {
  const Tarifa({
    required this.id,
    required this.tipoVehiculo,
    required this.valorMinuto,
    required this.valorPlena,
    required this.valorNocturna,
    required this.valorMes,
    required this.vigenteDesde,
    required this.vigenteHasta,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final TipoVehiculo tipoVehiculo;
  final int valorMinuto;
  final int valorPlena;
  final int valorNocturna;
  final int valorMes;
  final DateTime vigenteDesde;
  final DateTime? vigenteHasta;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Misma definición de "vigente" que el filtro `?vigente=true` del backend
  /// (`vigenteDesde <= ahora` y `vigenteHasta` nulo o futuro): comparación de
  /// fechas, no de dinero — mismo criterio ya aceptado para
  /// `Mensualidad.vigencia()`.
  bool esVigente([DateTime? ahora]) {
    final now = (ahora ?? DateTime.now()).toUtc();
    return !vigenteDesde.isAfter(now) && (vigenteHasta == null || vigenteHasta!.isAfter(now));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Tarifa &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          tipoVehiculo == other.tipoVehiculo &&
          valorMinuto == other.valorMinuto &&
          valorPlena == other.valorPlena &&
          valorNocturna == other.valorNocturna &&
          valorMes == other.valorMes &&
          vigenteDesde == other.vigenteDesde &&
          vigenteHasta == other.vigenteHasta &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
    id,
    tipoVehiculo,
    valorMinuto,
    valorPlena,
    valorNocturna,
    valorMes,
    vigenteDesde,
    vigenteHasta,
    createdAt,
    updatedAt,
  );
}
