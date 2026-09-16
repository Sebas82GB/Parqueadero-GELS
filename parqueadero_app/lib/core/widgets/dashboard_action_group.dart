import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// Una fila de [DashboardActionGroup]: ícono + etiqueta + chevron.
class DashboardActionItem {
  const DashboardActionItem({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

/// Sección de navegación del dashboard de inicio (skill `diseno-parqueadero`):
/// una etiqueta de sección en mayúsculas seguida de una tarjeta que agrupa
/// varias filas de acción, divididas por una línea. No existía este patrón
/// en la app antes de `AdminHomeDashboard` — `_AccionSecundaria` del
/// dashboard del Operador es un patrón distinto (tile 2-up sin chevron ni
/// agrupar), así que este widget es nuevo, no una extracción de ese.
class DashboardActionGroup extends StatelessWidget {
  const DashboardActionGroup({super.key, required this.titulo, required this.items});

  final String titulo;
  final List<DashboardActionItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: AppColors.asfaltoMedio,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.asfaltoClaro, width: 0.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                _DashboardActionRow(item: items[i]),
                if (i != items.length - 1) const Divider(height: 0.5, thickness: 0.5, color: AppColors.asfaltoClaro),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DashboardActionRow extends StatelessWidget {
  const _DashboardActionRow({required this.item});

  final DashboardActionItem item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.gutter),
          child: Row(
            children: [
              Icon(item.icon, color: AppColors.verdePastel, size: 17),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(item.label, style: const TextStyle(color: AppColors.blancoHueso, fontSize: 13))),
              Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 15),
            ],
          ),
        ),
      ),
    );
  }
}
