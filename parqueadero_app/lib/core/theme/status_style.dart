import 'package:flutter/material.dart';

/// Los cinco significados de estado que existen hoy en la app, sin importar
/// la feature: celdas, mensualidades y tickets. Deliberadamente NO es un rol
/// de `ColorScheme` (Material 3 no trae tonos success/warning) ni comparte
/// hue/saturación con `AppColors` — no debe confundirse con la marca.
enum StatusTone { success, warning, danger, info, neutral }

/// Color + ícono por defecto de cada [StatusTone]. Cada feature (celdas,
/// mensualidades, tickets, tarifas) sigue definiendo su propio enum de
/// dominio, su propia etiqueta y, si hace falta, un ícono más específico —
/// pero el color siempre sale de acá. Antes de esto, cuatro archivos
/// (`celda_estado_style.dart`, `estado_pago_style.dart`, `vigencia_style.dart`,
/// `ticket_estado_style.dart`) declaraban casi los mismos hex por su cuenta,
/// con inconsistencias (dos grises distintos para "cancelada"/"entregado").
///
/// El estado nunca se comunica solo por color: todo consumidor de
/// [StatusStyle] debe mostrar también el ícono o la etiqueta.
class StatusStyle {
  const StatusStyle._(this.color, this.icon);

  final Color color;
  final IconData icon;

  // Los cinco tonos pasan AA (>= 4.5:1) como texto sobre AppColors.surface
  // (0xFFF6F5F1): success/warning/danger se oscurecieron manteniendo el
  // matiz (info y neutral ya pasaban y quedaron igual). Ver
  // status_style_test.dart, que verifica el contraste real en vez de solo
  // fijar el hex, para que esto no pueda regresar en silencio.
  static StatusStyle of(StatusTone tone) => switch (tone) {
    StatusTone.success => const StatusStyle._(Color(0xFF1B7F51), Icons.check_circle),
    StatusTone.warning => const StatusStyle._(Color(0xFFA85D10), Icons.warning_amber),
    StatusTone.danger => const StatusStyle._(Color(0xFFD0362D), Icons.cancel),
    StatusTone.info => const StatusStyle._(Color(0xFF2C6FBB), Icons.schedule),
    StatusTone.neutral => const StatusStyle._(Color(0xFF6B6F76), Icons.block),
  };
}
