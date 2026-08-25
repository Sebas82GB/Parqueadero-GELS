import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/button_spinner.dart';
import '../../../auth/domain/usuario.dart';
import '../../../auth/presentation/session_notifier.dart';
import '../../../tickets/presentation/ticket_abierto_de_celda_notifier.dart';
import '../../domain/celda.dart';
import '../celda_accion_notifier.dart';
import '../celda_list_notifier.dart';
import 'celda_estado_badge.dart';

/// Mismas acciones que ya existen en `celda_detail_screen.dart`, sobre los
/// mismos notifiers — un atajo desde la cuadrícula, no una ruta nueva ni
/// lógica nueva. Se abre con long-press sobre una tarjeta.
Future<void> showCeldaQuickActions(BuildContext context, String celdaId) {
  return showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (context) => CeldaQuickActionsSheet(celdaId: celdaId),
  );
}

class CeldaQuickActionsSheet extends ConsumerWidget {
  const CeldaQuickActionsSheet({super.key, required this.celdaId});

  final String celdaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final celda = ref.watch(
      celdaListNotifierProvider.select((s) {
        for (final c in s.celdas) {
          if (c.id == celdaId) return c;
        }
        return null;
      }),
    );
    if (celda == null) return const SizedBox.shrink();

    final esAdmin = ref.watch(sessionNotifierProvider).usuario?.rol == RolUsuario.admin;
    final esOperador = ref.watch(sessionNotifierProvider).usuario?.rol == RolUsuario.operador;
    final accion = ref.watch(celdaAccionNotifierProvider(celdaId));
    final buscarTicket = ref.watch(ticketAbiertoDeCeldaNotifierProvider(celdaId));

    // Cierra el sheet solo cuando una acción de mantenimiento/liberar
    // termina bien; si falla, se queda abierto mostrando el mensaje.
    ref.listen(celdaAccionNotifierProvider(celdaId), (previous, next) {
      if (previous != null && previous.isLoading && !next.isLoading && next.errorMessage == null) {
        Navigator.of(context).pop();
      }
    });

    final acciones = <Widget>[
      if (esOperador && celda.estado == EstadoCelda.ocupada)
        ListTile(
          leading: buscarTicket.isLoading ? const ButtonSpinner(size: 20) : const Icon(Icons.logout),
          title: const Text('Registrar salida'),
          onTap: buscarTicket.isLoading
              ? null
              : () async {
                  final ticketId = await ref.read(ticketAbiertoDeCeldaNotifierProvider(celdaId).notifier).buscar();
                  if (!context.mounted) return;
                  if (ticketId != null) {
                    Navigator.of(context).pop();
                    context.push('/tickets/$ticketId/salida');
                  } else if (buscarTicket.errorMessage == null) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No se encontró un ticket abierto para esta celda.')),
                    );
                  }
                },
        ),
      if (esAdmin && celda.estado == EstadoCelda.libre)
        ListTile(
          leading: accion.isLoading ? const ButtonSpinner(size: 20) : const Icon(Icons.build),
          title: const Text('Poner en mantenimiento'),
          onTap: accion.isLoading
              ? null
              : () => ref.read(celdaAccionNotifierProvider(celdaId).notifier).marcarMantenimiento(),
        ),
      if (esAdmin && celda.estado == EstadoCelda.mantenimiento)
        ListTile(
          leading: accion.isLoading ? const ButtonSpinner(size: 20) : const Icon(Icons.check_circle_outline),
          title: const Text('Volver a libre'),
          onTap: accion.isLoading
              ? null
              : () => ref.read(celdaAccionNotifierProvider(celdaId).notifier).volverALibre(),
        ),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  CeldaEstadoBadge(estado: celda.estado, size: 32),
                  const SizedBox(width: AppSpacing.sm),
                  Text(celda.codigo, style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (accion.errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                child: Text(accion.errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            if (buscarTicket.errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                child: Text(buscarTicket.errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            if (acciones.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                child: Text(
                  'Sin acciones rápidas disponibles para esta celda.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              )
            else
              ...acciones,
          ],
        ),
      ),
    );
  }
}
