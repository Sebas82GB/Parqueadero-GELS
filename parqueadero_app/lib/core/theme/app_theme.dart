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
  // uno derivado a mano de los ocho tokens de marca (mismo criterio de
  // contraste real que status_style_test.dart, no elegidos a ciegas).
  // Recalculados en la reforma "Asfalto y Demarcación" (2026-09-15): los
  // anteriores estaban derivados sobre concreto (superficie clara) y sobre
  // asfalto quedaban ilegibles. Contraste calculado como texto sobre
  // AppColors.asfaltoOscuro (superficie base), fórmula WCAG 2.x:
  //   primaryContainer: 18% verdePastel sobre asfaltoOscuro.
  //   secondary:        = asfaltoClaro, acción secundaria.
  //   onSurfaceVariant: = grisClaro — contraste 7.97:1.
  //   outline:          borde visible — contraste 4.02:1.
  // surfaceContainer ya no se deriva: es AppColors.asfaltoMedio directo.
  static const Color _primaryContainer = Color(0xFF2E4A34);
  static const Color _secondary = Color(0xFF3D3D3D);
  static const Color _onSurfaceVariant = Color(0xFFB0B0A8);
  static const Color _outline = Color(0xFF6E6E68);

  // Rojo de error para fondo oscuro. La skill de diseño no define un rojo de
  // marca, y status_style.dart ya deja explícito que la paleta de estados va
  // separada de AppColors — este rojo es el rol funcional de Material
  // (validación de formularios), no un tono de marca, así que vive acá y no
  // en AppColors.
  static const Color _error = Color(0xFFE88B7D); // 6.98:1 sobre asfaltoOscuro
  static const Color _onError = Color(0xFF1A1A1A);
  static const Color _errorContainer = Color(0xFF4A1A17);
  static const Color _onErrorContainer = Color(0xFFF5D6D1);

  static const ColorScheme _colorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.verdePastel,
    onPrimary: AppColors.asfaltoOscuro,
    primaryContainer: _primaryContainer,
    onPrimaryContainer: AppColors.blancoHueso,
    secondary: _secondary,
    onSecondary: AppColors.blancoHueso,
    secondaryContainer: AppColors.asfaltoMedio,
    onSecondaryContainer: AppColors.blancoHueso,
    error: _error,
    onError: _onError,
    errorContainer: _errorContainer,
    onErrorContainer: _onErrorContainer,
    surface: AppColors.asfaltoOscuro,
    onSurface: AppColors.blancoHueso,
    onSurfaceVariant: _onSurfaceVariant,
    outline: _outline,
    outlineVariant: AppColors.asfaltoClaro,
    surfaceContainer: AppColors.asfaltoMedio,
    surfaceContainerHigh: AppColors.asfaltoClaro,
  );

  // El nombre `light` es histórico: el tema ya es oscuro, pero renombrarlo
  // exige tocar main.dart (único consumidor), fuera del alcance de esta tarea.
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
