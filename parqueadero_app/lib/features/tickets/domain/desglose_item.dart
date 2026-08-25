enum TipoCobro {
  parcial,
  plena,
  nocturna;

  static TipoCobro fromBackend(String value) => switch (value) {
    'PARCIAL' => TipoCobro.parcial,
    'PLENA' => TipoCobro.plena,
    'NOCTURNA' => TipoCobro.nocturna,
    _ => throw FormatException('tipo de cobro desconocido recibido del backend: $value'),
  };
}

/// Representa un elemento del `desglose` que devuelve el backend, tanto al
/// cerrar un ticket (`POST /tickets/:id/salida`) como al previsualizar el
/// cobro sin cerrarlo (`GET /tickets/:id/preview-cobro`,
/// `POST /tarifas/simular`). Puro dominio: no sabe nada de JSON, ese parseo
/// vive en `data/dtos/desglose_item_dto.dart`. El backend nunca recalcula ni
/// la app replica la regla de cobro: esto solo modela la forma que ya llegó
/// calculada.
sealed class DesgloseItem {
  const DesgloseItem({required this.valor});

  /// Nullable solo por [DesgloseManual] en un preview de un vehículo OTRO:
  /// ahí el backend todavía no tiene un valor que mostrar (ver [DesgloseManual.motivo]).
  /// En el desglose de una salida ya cerrada siempre es un valor concreto.
  final int? valor;
}

/// El vehículo tiene una mensualidad vigente que cubre la estadía: no hubo
/// cobro por tiempo (`valor` siempre 0).
class DesgloseMensualidad extends DesgloseItem {
  const DesgloseMensualidad() : super(valor: 0);

  @override
  bool operator ==(Object other) => identical(this, other) || other is DesgloseMensualidad;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// Vehículo tipo OTRO. En el desglose de una salida ya cerrada, `valor` es
/// el monto que el operador digitó y `motivo` es null. En un preview
/// (`GET /tickets/:id/preview-cobro`, `POST /tarifas/simular`), `valor` es
/// null y `motivo` explica que el operador todavía no lo ha digitado.
class DesgloseManual extends DesgloseItem {
  const DesgloseManual({super.valor, this.motivo});

  final String? motivo;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DesgloseManual && valor == other.valor && motivo == other.motivo;

  @override
  int get hashCode => Object.hash(runtimeType, valor, motivo);
}

/// Un bloque de 6 horas cobrado dentro de la estadía (CARRO/MOTO/BICICLETA).
class DesgloseBloque extends DesgloseItem {
  const DesgloseBloque({
    required this.dia,
    required this.bloqueNumero,
    required this.inicio,
    required this.fin,
    required this.minutos,
    required this.tipoCobro,
    required super.valor,
  });

  final int dia;
  final int bloqueNumero;
  final DateTime inicio;
  final DateTime fin;
  final int minutos;
  final TipoCobro tipoCobro;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DesgloseBloque &&
          dia == other.dia &&
          bloqueNumero == other.bloqueNumero &&
          inicio == other.inicio &&
          fin == other.fin &&
          minutos == other.minutos &&
          tipoCobro == other.tipoCobro &&
          valor == other.valor;

  @override
  int get hashCode =>
      Object.hash(runtimeType, dia, bloqueNumero, inicio, fin, minutos, tipoCobro, valor);
}
