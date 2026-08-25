import 'package:flutter/material.dart';

import '../../../../core/theme/status_style.dart';
import '../../domain/mensualidad.dart';

/// El color sale de `StatusStyle` (paleta de estados centralizada, separada
/// de la de marca) — mismo criterio que `CeldaEstadoStyle`. El estado nunca
/// se comunica solo por color: siempre va acompañado de la etiqueta.
class EstadoPagoStyle {
  const EstadoPagoStyle._(this.color, this.label);

  final Color color;
  final String label;

  static EstadoPagoStyle of(EstadoPagoMensualidad estado) => switch (estado) {
    EstadoPagoMensualidad.pagada => EstadoPagoStyle._(
      StatusStyle.of(StatusTone.success).color,
      'Pagada',
    ),
    EstadoPagoMensualidad.noPagada => EstadoPagoStyle._(
      StatusStyle.of(StatusTone.warning).color,
      'No pagada',
    ),
    EstadoPagoMensualidad.cancelada => EstadoPagoStyle._(
      StatusStyle.of(StatusTone.neutral).color,
      'Cancelada',
    ),
  };
}
