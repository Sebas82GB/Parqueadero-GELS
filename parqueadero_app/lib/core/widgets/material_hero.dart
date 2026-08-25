import 'package:flutter/material.dart';

/// `Hero` cuyo `child` necesita un ancestro `Material` (p.ej. un `Chip`).
/// Durante el vuelo, Flutter reparenta el `child` al `Overlay` del
/// `Navigator`, fuera del `Scaffold`/`Material` de la ruta — sin este
/// envoltorio, cualquier widget Material dentro (`Chip`, `InkWell`, etc.)
/// truena con "No Material widget found" apenas empieza el vuelo.
class MaterialHero extends StatelessWidget {
  const MaterialHero({super.key, required this.tag, required this.child});

  final Object tag;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Hero(tag: tag, child: Material(type: MaterialType.transparency, child: child));
  }
}
