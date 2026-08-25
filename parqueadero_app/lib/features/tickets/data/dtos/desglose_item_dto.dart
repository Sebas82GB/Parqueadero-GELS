import '../../domain/desglose_item.dart';

/// El JSON de `desglose` es heterogéneo (tres formas posibles, ver
/// `domain/desglose_item.dart`), así que no se puede modelar con un DTO
/// plano de `json_serializable`. El discriminador seguro es la presencia de
/// `bloqueNumero`: los bloques de cobro por tiempo lo tienen y nunca tienen
/// `tipo`; las variantes MENSUALIDAD/MANUAL tienen `tipo` y nunca
/// `bloqueNumero`.
List<DesgloseItem> desgloseFromJson(List<dynamic>? raw) {
  if (raw == null) return const [];
  return raw.map((item) {
    final map = item as Map<String, dynamic>;
    if (map.containsKey('bloqueNumero')) {
      return DesgloseBloque(
        dia: map['dia'] as int,
        bloqueNumero: map['bloqueNumero'] as int,
        inicio: DateTime.parse(map['inicio'] as String),
        fin: DateTime.parse(map['fin'] as String),
        minutos: map['minutos'] as int,
        tipoCobro: TipoCobro.fromBackend(map['tipoCobro'] as String),
        valor: map['valor'] as int,
      );
    }
    return switch (map['tipo']) {
      'MENSUALIDAD' => const DesgloseMensualidad(),
      'MANUAL' => DesgloseManual(
        valor: map['valor'] as int?,
        motivo: map['motivo'] as String?,
      ),
      final tipo => throw FormatException('tipo de desglose desconocido recibido del backend: $tipo'),
    };
  }).toList();
}
