import 'package:flutter/material.dart';

import '../../domain/celda.dart';
import 'celda_estado_style.dart';

/// Círculo ícono+color de un estado de celda. Misma forma en la cuadrícula
/// y en el detalle/entrada a propósito: es el elemento que viaja en el
/// `Hero` entre pantallas — si origen y destino tuvieran formas distintas
/// (un ícono suelto vs. un `Chip` con texto), el vuelo se vería como un
/// salto en vez de una transición limpia.
class CeldaEstadoBadge extends StatelessWidget {
  const CeldaEstadoBadge({super.key, required this.estado, this.size = 40});

  final EstadoCelda estado;
  final double size;

  @override
  Widget build(BuildContext context) {
    final style = CeldaEstadoStyle.of(estado);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: style.color.withValues(alpha: 0.15)),
      child: Icon(style.icon, color: style.color, size: size * 0.55),
    );
  }
}
