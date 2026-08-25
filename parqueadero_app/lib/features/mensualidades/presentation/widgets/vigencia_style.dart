import 'package:flutter/material.dart';

import '../../../../core/theme/status_style.dart';
import '../../domain/mensualidad.dart';

/// El color sale de `StatusStyle` (paleta de estados centralizada, separada
/// de la de marca) — mismo criterio que `CeldaEstadoStyle`.
class VigenciaStyle {
  const VigenciaStyle._(this.color, this.label);

  final Color color;
  final String label;

  static VigenciaStyle of(VigenciaMensualidad vigencia) => switch (vigencia) {
    VigenciaMensualidad.vigente => VigenciaStyle._(StatusStyle.of(StatusTone.success).color, 'Vigente'),
    VigenciaMensualidad.porVencer => VigenciaStyle._(
      StatusStyle.of(StatusTone.warning).color,
      'Por vencer',
    ),
    VigenciaMensualidad.vencida => VigenciaStyle._(StatusStyle.of(StatusTone.danger).color, 'Vencida'),
    VigenciaMensualidad.cancelada => VigenciaStyle._(
      StatusStyle.of(StatusTone.neutral).color,
      'Cancelada',
    ),
  };
}
