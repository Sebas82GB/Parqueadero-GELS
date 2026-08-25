import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Estado vacío genérico: ícono dentro de un círculo con tinte suave (la
/// "ilustración" liviana) + mensaje útil, con una acción opcional (p.ej.
/// "Limpiar filtros"). Reutilizable por cualquier feature — un solo cambio
/// acá mejora las ~13 pantallas que ya lo usan.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.message, this.actionLabel, this.onAction});

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.outline;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.1)),
            child: Icon(icon, size: 44, color: color),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.md),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
