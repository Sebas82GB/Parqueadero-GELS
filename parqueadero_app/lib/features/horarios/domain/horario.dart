/// Entidad de dominio. Sin `copyWith`: la sustitución tras crear se hace con
/// lo que devuelve el propio backend.
class Horario {
  const Horario({
    required this.id,
    required this.apertura,
    required this.cierre,
    required this.vigenteDesde,
    required this.vigenteHasta,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;

  /// Hora local pura, formato `HH:mm` (24h). No es un timestamp UTC: nunca
  /// pasa por `bogota_time.dart`, se muestra tal cual llega del backend.
  final String apertura;
  final String cierre;

  final DateTime vigenteDesde;
  final DateTime? vigenteHasta;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Mismo criterio que `Tarifa.esVigente()`: `vigenteDesde <= ahora` y
  /// `vigenteHasta` nulo o futuro. Sin discriminador (a diferencia de
  /// Tarifa): solo existe un horario vigente global a la vez.
  bool esVigente([DateTime? ahora]) {
    final now = (ahora ?? DateTime.now()).toUtc();
    return !vigenteDesde.isAfter(now) && (vigenteHasta == null || vigenteHasta!.isAfter(now));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Horario &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          apertura == other.apertura &&
          cierre == other.cierre &&
          vigenteDesde == other.vigenteDesde &&
          vigenteHasta == other.vigenteHasta &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      Object.hash(id, apertura, cierre, vigenteDesde, vigenteHasta, createdAt, updatedAt);
}
