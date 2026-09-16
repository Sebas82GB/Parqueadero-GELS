import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parqueadero_app/core/theme/app_colors.dart';
import 'package:parqueadero_app/core/theme/status_style.dart';

/// Luminancia relativa y contraste WCAG 2.x — misma fórmula que usa
/// cualquier verificador de accesibilidad. Se reimplementa acá (en vez de
/// depender de un paquete) para poder assertar el contraste real de cada
/// tono en vez de solo fijar el hex, y así detectar una regresión de
/// contraste aunque el valor exacto del color cambie.
double _luminanciaRelativa(Color color) {
  double canal(double c) => c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  final r = canal(color.r);
  final g = canal(color.g);
  final b = canal(color.b);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

double _contraste(Color a, Color b) {
  final la = _luminanciaRelativa(a);
  final lb = _luminanciaRelativa(b);
  final claro = la > lb ? la : lb;
  final oscuro = la > lb ? lb : la;
  return (claro + 0.05) / (oscuro + 0.05);
}

void main() {
  test('success: verde con check_circle', () {
    final style = StatusStyle.of(StatusTone.success);

    expect(style.color, const Color(0xFF7FD1A0));
    expect(style.icon, Icons.check_circle);
  });

  test('warning: ámbar con warning_amber', () {
    final style = StatusStyle.of(StatusTone.warning);

    expect(style.color, const Color(0xFFE8B563));
    expect(style.icon, Icons.warning_amber);
  });

  test('danger: rojo con cancel', () {
    final style = StatusStyle.of(StatusTone.danger);

    expect(style.color, const Color(0xFFE88B7D));
    expect(style.icon, Icons.cancel);
  });

  test('info: azul con schedule', () {
    final style = StatusStyle.of(StatusTone.info);

    expect(style.color, const Color(0xFF7FB3E8));
    expect(style.icon, Icons.schedule);
  });

  test('neutral: gris con block', () {
    final style = StatusStyle.of(StatusTone.neutral);

    expect(style.color, const Color(0xFFB0B0A8));
    expect(style.icon, Icons.block);
  });

  test('los cinco tonos son colores distintos entre sí', () {
    final colores = StatusTone.values.map((t) => StatusStyle.of(t).color).toSet();

    expect(colores, hasLength(StatusTone.values.length));
  });

  // Regresión del hallazgo de contraste de la auditoría UX: la app se usa
  // con luz solar directa, y estos tonos son los que marcan la información
  // más urgente (mantenimiento, sin turno abierto, tiempo excedido). Si
  // algún tono vuelve a oscurecerse por debajo de AA, este test lo detecta
  // sin depender de que alguien recuerde revisar el contraste a mano.
  //
  // Reforma "Asfalto y Demarcación" (2026-09-15): antes se medía contra la
  // única superficie clara que había; ahora el tema es oscuro y los tonos
  // viven sobre las DOS superficies donde los pinta la app —
  // `asfaltoOscuro` (fondo raíz) y `asfaltoMedio` (tarjetas, banners) — así
  // que se verifican ambas por separado.
  for (final tone in StatusTone.values) {
    test('$tone: pasa AA (>= 4.5:1) como texto sobre AppColors.asfaltoOscuro', () {
      final contraste = _contraste(StatusStyle.of(tone).color, AppColors.asfaltoOscuro);

      expect(
        contraste,
        greaterThanOrEqualTo(4.5),
        reason: 'sobre asfaltoOscuro, contraste real: $contraste',
      );
    });
  }

  for (final tone in StatusTone.values) {
    test('$tone: pasa AA (>= 4.5:1) como texto sobre AppColors.asfaltoMedio', () {
      final contraste = _contraste(StatusStyle.of(tone).color, AppColors.asfaltoMedio);

      expect(
        contraste,
        greaterThanOrEqualTo(4.5),
        reason: 'sobre asfaltoMedio, contraste real: $contraste',
      );
    });
  }
}
