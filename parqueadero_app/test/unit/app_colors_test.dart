import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parqueadero_app/core/theme/app_colors.dart';

/// Luminancia relativa y contraste WCAG 2.x — misma fórmula que usa
/// cualquier verificador de accesibilidad. Se reimplementa acá (en vez de
/// depender de un paquete) para poder assertar el contraste real de cada
/// token de marca en vez de solo fijar el hex, y así detectar una regresión
/// de contraste aunque el valor exacto del color cambie.
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
  // Los cinco tokens de contenido (texto, íconos, acentos) de la reforma
  // "Asfalto y Demarcación" viven siempre sobre una de las dos superficies
  // de asfalto. La tabla de contraste de la skill `diseno-parqueadero` no
  // son estimaciones: se verifican acá, sobre los dos fondos reales, para
  // que aclarar u oscurecer un token por estética rompa el test en vez de
  // degradar la legibilidad en silencio.
  final contenido = <String, Color>{
    'blancoHueso': AppColors.blancoHueso,
    'amarilloPastel': AppColors.amarilloPastel,
    'verdePastel': AppColors.verdePastel,
    'grisClaro': AppColors.grisClaro,
    // terracota sobre asfaltoMedio da 4.64:1 — pasa AA con sólo 0.14 de
    // margen. Es el token que primero se rompe si alguien lo aclara.
    'terracota': AppColors.terracota,
  };

  for (final entrada in contenido.entries) {
    test('${entrada.key}: pasa AA (>= 4.5:1) como texto sobre AppColors.asfaltoOscuro', () {
      final contraste = _contraste(entrada.value, AppColors.asfaltoOscuro);

      expect(
        contraste,
        greaterThanOrEqualTo(4.5),
        reason: 'sobre asfaltoOscuro, contraste real: $contraste',
      );
    });
  }

  for (final entrada in contenido.entries) {
    test('${entrada.key}: pasa AA (>= 4.5:1) como texto sobre AppColors.asfaltoMedio', () {
      final contraste = _contraste(entrada.value, AppColors.asfaltoMedio);

      expect(
        contraste,
        greaterThanOrEqualTo(4.5),
        reason: 'sobre asfaltoMedio, contraste real: $contraste',
      );
    });
  }

  // Regla de color innegociable de la skill: `amarilloPastel` NUNCA es texto
  // sobre fondo claro. Sobre blanco puro da 1.27:1, ilegible — se afirma el
  // hecho (no el umbral AA) para que quede escrito por qué el amarillo solo
  // vive sobre asfalto, o como línea, borde y relleno.
  test('amarilloPastel sobre blanco puro es ilegible (1.27:1): por eso nunca va sobre fondo claro', () {
    final contraste = _contraste(AppColors.amarilloPastel, const Color(0xFFFFFFFF));

    expect(contraste, lessThan(2.0), reason: 'contraste real: $contraste');
  });

  test('los ocho tokens son colores distintos entre sí', () {
    final colores = <Color>{
      AppColors.asfaltoOscuro,
      AppColors.asfaltoMedio,
      AppColors.asfaltoClaro,
      AppColors.amarilloPastel,
      AppColors.verdePastel,
      AppColors.blancoHueso,
      AppColors.grisClaro,
      AppColors.terracota,
    };

    expect(colores, hasLength(8));
  });
}
