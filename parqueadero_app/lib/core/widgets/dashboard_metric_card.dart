import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'animated_count_text.dart';

/// Tarjeta de métrica del dashboard de inicio (skill `diseno-parqueadero`):
/// generalizada de la "Celdas libres" original del Operador para que
/// Operador y Admin compartan el mismo molde en vez de cada uno con su
/// propia tarjeta. [dark] elige la variante: `true` es la tarjeta de ACENTO
/// (texto e ícono en `amarilloPastel`, sin borde) para un conteo en vivo como
/// "Celdas libres/ocupadas", y `false` la NEUTRA (texto en `blancoHueso`, con
/// borde `asfaltoClaro`) para algo más tranquilo.
///
/// Reforma "Asfalto y Demarcación" (2026-09-15): el nombre [dark] quedó del
/// tema claro, donde distinguía tarjeta sobre fondo oscuro de tarjeta sobre
/// fondo claro. Ahora **todo el tema es oscuro** y ambas variantes van sobre
/// `asfaltoMedio`: [dark] solo elige acento vs neutra. No se lee como un
/// resto del tema claro ni habilita texto oscuro, que sería invisible.
///
/// El valor es opcional a propósito: sin [value] y sin [isLoading]/
/// [errorMessage] muestra un placeholder "—", para una métrica que todavía
/// no tiene una fuente de dato real (ver "Ingresos de hoy" en
/// `AdminHomeDashboard`) sin inventar un número ni forzarle una máquina de
/// carga/error que no aplica.
class DashboardMetricCard extends StatelessWidget {
  const DashboardMetricCard({
    super.key,
    required this.label,
    required this.icon,
    this.dark = false,
    this.value,
    this.suffix,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
  });

  final String label;
  final IconData icon;
  final bool dark;

  /// Conteo a mostrar. `null` sin [isLoading] ni [errorMessage] se lee como
  /// "sin dato todavía" y cae al placeholder "—". Nunca se usa para montos
  /// de dinero (ver doc comment de [AnimatedCountText]).
  final int? value;
  final String? suffix;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colorLabel = dark ? AppColors.amarilloPastel : Theme.of(context).colorScheme.onSurfaceVariant;
    final colorValor = dark ? AppColors.amarilloPastel : AppColors.blancoHueso;
    final colorSufijo = dark ? AppColors.blancoHueso : Theme.of(context).colorScheme.onSurfaceVariant;
    final colorIcono = dark ? AppColors.amarilloPastel.withValues(alpha: 0.7) : AppColors.verdePastel;

    final String semanticsLabel;
    if (isLoading) {
      semanticsLabel = '$label: cargando';
    } else if (errorMessage != null) {
      semanticsLabel = '$label: error, $errorMessage';
    } else if (value == null) {
      semanticsLabel = '$label: sin dato';
    } else {
      semanticsLabel = suffix != null ? '$label: $value $suffix' : '$label: $value';
    }

    return Semantics(
      container: true,
      label: semanticsLabel,
      excludeSemantics: onRetry == null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.asfaltoMedio,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: dark ? null : Border.all(color: AppColors.asfaltoClaro, width: 0.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(color: colorLabel, fontSize: 11)),
                  const SizedBox(height: AppSpacing.xs),
                  _valor(colorValor, colorSufijo),
                ],
              ),
            ),
            Icon(icon, color: colorIcono, size: 28),
          ],
        ),
      ),
    );
  }

  Widget _valor(Color colorValor, Color colorSufijo) {
    if (value == null && isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(colorValor)),
      );
    }
    if (value == null && errorMessage != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: colorValor, size: 20),
          const SizedBox(width: AppSpacing.xs),
          if (onRetry != null)
            TextButton(
              style: TextButton.styleFrom(foregroundColor: colorValor),
              onPressed: onRetry,
              child: const Text('Reintentar'),
            ),
        ],
      );
    }
    if (value == null) {
      return Text('—', style: TextStyle(color: colorValor, fontSize: 28));
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        AnimatedCountText(value: value!, style: TextStyle(color: colorValor, fontSize: 28)),
        if (suffix != null) Text(suffix!, style: TextStyle(color: colorSufijo, fontSize: 15)),
      ],
    );
  }
}
