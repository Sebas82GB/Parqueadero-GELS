import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_elevation.dart';
import 'app_page_transitions.dart';
import 'app_radius.dart';
import 'app_spacing.dart';

/// Único `ThemeData` de la app. Todo lo visual sale de tokens (`AppColors`,
/// `AppRadius`, `AppSpacing`, `AppMotion`, `StatusStyle`) — ninguna pantalla
/// define un color, radio o duración suelto por su cuenta.
///
/// `ColorScheme` explícito (no `ColorScheme.fromSeed`): un seed de Material 3
/// genera tonos más vivos que lo que pide este diseño (colores apagados para
/// jornadas largas frente a la pantalla).
class AppTheme {
  const AppTheme._();

  // Tonos que Material exige y que no tienen un token 1:1 en AppColors, cada
  // uno derivado a mano de los seis tokens de marca (mismo criterio de
  // contraste real que status_style_test.dart, no elegidos a ciegas).
  // Contraste calculado como texto sobre AppColors.concreto (superficie
  // base), fórmula WCAG 2.x:
  //   primaryContainer: 18% verdeSenal sobre concreto.
  //   secondary:        18% asfalto sobre concreto.
  //   surfaceContainer: 6% asfalto sobre concreto (elevación sutil).
  //   onSurfaceVariant: 75% tinta sobre concreto — contraste 7.95:1.
  //   outline:          62% tinta sobre concreto — contraste 5.03:1.
  static const Color _primaryContainer = Color(0xFFD0DED3);
  static const Color _secondary = Color(0xFFCECFCA);
  static const Color _surfaceContainer = Color(0xFFEAEAE5);
  static const Color _onSurfaceVariant = Color(0xFF4C4D48);
  static const Color _outline = Color(0xFF696B65);

  // Rojo de error: sin cambios respecto al esquema anterior. La skill de
  // diseño no define un rojo de marca, y status_style.dart ya deja explícito
  // que la paleta de estados va separada de AppColors — este rojo es el rol
  // funcional de Material (validación de formularios), no un tono de marca,
  // así que vive acá y no en AppColors.
  static const Color _error = Color(0xFF8E3B35);
  static const Color _onError = Color(0xFFFFFFFF);
  static const Color _errorContainer = Color(0xFFF3DCD9);
  static const Color _onErrorContainer = Color(0xFF3C120E);

  static const ColorScheme _colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.verdeSenal,
    onPrimary: AppColors.concreto,
    primaryContainer: _primaryContainer,
    onPrimaryContainer: AppColors.tinta,
    secondary: _secondary,
    onSecondary: AppColors.tinta,
    secondaryContainer: AppColors.linea,
    onSecondaryContainer: AppColors.tinta,
    error: _error,
    onError: _onError,
    errorContainer: _errorContainer,
    onErrorContainer: _onErrorContainer,
    surface: AppColors.concreto,
    onSurface: AppColors.tinta,
    onSurfaceVariant: _onSurfaceVariant,
    outline: _outline,
    outlineVariant: AppColors.linea,
    surfaceContainer: _surfaceContainer,
    surfaceContainerHigh: AppColors.linea,
  );

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: _colorScheme,
    scaffoldBackgroundColor: _colorScheme.surface,
    visualDensity: VisualDensity.standard,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: AppPageTransitionsBuilder(),
        TargetPlatform.iOS: AppPageTransitionsBuilder(),
        TargetPlatform.linux: AppPageTransitionsBuilder(),
        TargetPlatform.macOS: AppPageTransitionsBuilder(),
        TargetPlatform.windows: AppPageTransitionsBuilder(),
      },
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: _colorScheme.surfaceContainer,
      foregroundColor: _colorScheme.onSurface,
      elevation: AppElevation.flat,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: _colorScheme.surfaceContainer,
      elevation: AppElevation.low,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      labelStyle: const TextStyle(fontWeight: FontWeight.w500),
    ),
    dividerTheme: DividerThemeData(color: _colorScheme.outlineVariant),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
      ),
    ),
    // Sin esto, TextButton/FilledButton usan el tamaño mínimo de Material
    // por defecto (más chico que el resto de botones de la app) — y son
    // justo los que arman "Cancelar"/"Confirmar" en los diálogos donde se
    // cobra o se cierra caja. 48dp de alto para igualar a OutlinedButton
    // (no 56dp como ElevatedButton: estos van en fila dentro del diálogo,
    // no ocupan el ancho completo de la pantalla).
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(minimumSize: const Size(64, 48))),
    filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(minimumSize: const Size(64, 48))),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
    ),
  );
}
