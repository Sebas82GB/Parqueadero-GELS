/// Escala de espaciado — formaliza los valores que ya estaban en uso de
/// facto en todo el proyecto (4·8·12·16·24·32), no una escala nueva.
/// Ninguna pantalla debe volver a escribir un `EdgeInsets`/`SizedBox` con un
/// número suelto que no sea uno de estos.
class AppSpacing {
  const AppSpacing._();

  static const xs = 4.0;
  static const sm = 8.0;

  /// Padding interno de tarjetas/celdas del grid — no encaja en la
  /// progresión par de 8 en 8, pero ya era el valor real usado en
  /// `celda_card.dart` antes de este token.
  static const gutter = 12.0;

  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}
