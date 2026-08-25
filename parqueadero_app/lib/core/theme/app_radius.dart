/// Radios de borde — formaliza los dos valores que ya estaban en uso
/// (8 para banners/chips, 12 para tarjetas) y agrega uno más grande para
/// superficies como diálogos/sheets que todavía no existen en la app.
class AppRadius {
  const AppRadius._();

  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
}
