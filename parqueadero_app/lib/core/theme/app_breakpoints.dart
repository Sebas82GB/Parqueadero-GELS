/// Puntos de corte y anchos máximos de contenido para que la app se vea bien
/// también en web/escritorio, no solo en el móvil angosto para el que se
/// diseñó originalmente. No existía ningún sistema responsive antes de esto
/// (el único precedente era `maxWidth: 420` repetido como literal, sin
/// compartir, en `login_screen.dart`, `abrir_turno_screen.dart` y
/// `buscar_placa_screen.dart` — esos tres quedan fuera de este cambio).
class AppBreakpoints {
  const AppBreakpoints._();

  /// Por debajo de esto es un teléfono: el bottom sheet de acción rápida se
  /// queda pegado abajo, a todo el ancho.
  static const mobile = 600.0;

  /// Entre [mobile] y esto es tablet; por encima, escritorio. Ninguna
  /// pantalla de esta app distingue tablet de escritorio hoy — el corte
  /// existe para no tener que inventarlo si hace falta más adelante.
  static const tablet = 1024.0;

  /// Ancho máximo de las pantallas tipo formulario/lista/dashboard (login,
  /// dashboard del operador, Celdas) y del bottom sheet de acción rápida
  /// cuando se presenta como diálogo centrado en pantallas ≥ [mobile].
  static const contentMaxWidth = 560.0;

  /// Ancho máximo del contenedor de la cuadrícula de Celdas — más generoso
  /// que [contentMaxWidth] porque `SliverGridDelegateWithMaxCrossAxisExtent`
  /// ya agrega columnas solo al crecer el ancho disponible; esto solo evita
  /// que ese ancho crezca sin límite en un monitor ultra-wide.
  static const gridMaxWidth = 900.0;
}
