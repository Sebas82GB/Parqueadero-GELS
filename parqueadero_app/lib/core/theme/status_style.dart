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

  // Los cinco tonos pasan AA (>= 4.5:1) como texto sobre las dos superficies
  // donde se usan, AppColors.asfaltoOscuro y AppColors.asfaltoMedio.
  // Recalibrados para fondo oscuro en la reforma "Asfalto y Demarcación"
  // (2026-09-15): los tonos anteriores estaban oscurecidos para superficie
  // clara y sobre asfalto daban ~3.4:1, por debajo de AA. Contraste sobre
  // asfaltoMedio, que es el peor de los dos: success 7.77 · warning 7.57 ·
  // danger 5.68 · info 6.42 · neutral 6.49. Ver status_style_test.dart, que
  // verifica el contraste real en vez de solo fijar el hex, para que esto no
  // pueda regresar en silencio.
  static StatusStyle of(StatusTone tone) => switch (tone) {
    StatusTone.success => const StatusStyle._(Color(0xFF7FD1A0), Icons.check_circle),
    StatusTone.warning => const StatusStyle._(Color(0xFFE8B563), Icons.warning_amber),
    StatusTone.danger => const StatusStyle._(Color(0xFFE88B7D), Icons.cancel),
    StatusTone.info => const StatusStyle._(Color(0xFF7FB3E8), Icons.schedule),
    StatusTone.neutral => const StatusStyle._(Color(0xFFB0B0A8), Icons.block),
  };
}
