import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/bogota_time.dart';
import '../../../core/utils/tipo_vehiculo_label.dart';
import '../../../core/widgets/button_spinner.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../auth/domain/usuario.dart';
import '../../auth/presentation/session_notifier.dart';
import '../../tickets/presentation/ticket_abierto_de_celda_notifier.dart';
import '../domain/celda.dart';
import 'celda_accion_notifier.dart';
import 'celda_list_notifier.dart';
import 'widgets/celda_estado_badge.dart';
import 'widgets/celda_estado_chip.dart';

/// Ruta completa (no bottom sheet): deep-linkable en web, back nativo de
/// go_router. Lee la celda de [celdaListNotifierProvider] por id — ya la
/// tiene cargada, no vuelve a pegarle a `GET /celdas/:id`.
class CeldaDetailScreen extends ConsumerWidget {
  const CeldaDetailScreen({super.key, required this.celdaId});

  final String celdaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listState = ref.watch(celdaListNotifierProvider);
    // Se observa sin condición, aunque solo se use más abajo: si quedara
    // detrás del `if (celda == null) return ...`, la restauración de sesión
    // no arrancaría hasta que la celda ya estuviera cargada, dejando una
    // ventana donde `usuario` sigue siendo null al llegar a esa línea.
    final esAdmin = ref.watch(sessionNotifierProvider).usuario?.rol == RolUsuario.admin;
    final esOperador = ref.watch(sessionNotifierProvider).usuario?.rol == RolUsuario.operador;

    Celda? celda;
    for (final c in listState.celdas) {
      if (c.id == celdaId) {
        celda = c;
        break;
      }
    }

    if (celda == null) {
      Widget body;
      if (listState.isLoading) {
        body = const Center(child: CircularProgressIndicator());
      } else if (listState.errorMessage != null) {
        body = ErrorState(
          message: listState.errorMessage!,
          onRetry: ref.read(celdaListNotifierProvider.notifier).refrescar,
        );
      } else {
        body = const EmptyState(icon: Icons.search_off, message: 'Celda no encontrada.');
      }
      return Scaffold(appBar: AppBar(), body: body);
    }

    final accion = ref.watch(celdaAccionNotifierProvider(celdaId));
    final buscarTicket = ref.watch(ticketAbiertoDeCeldaNotifierProvider(celdaId));

    return Scaffold(
      appBar: AppBar(title: Text(celda.codigo)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Hero(
            tag: 'celda-estado-${celda.id}',
            child: CeldaEstadoBadge(estado: celda.estado, size: 48),
          ),
          const SizedBox(height: AppSpacing.sm),
          CeldaEstadoChip(estado: celda.estado),
          const SizedBox(height: AppSpacing.lg),
          Text('Zona: ${celda.zona}', style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Tipo permitido: ${tipoVehiculoLabel(celda.tipoPermitido)}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Actualizada: ${formatBogota(celda.updatedAt)}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          if (accion.errorMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              accion.errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          if (buscarTicket.errorMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              buscarTicket.errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          if (esOperador && celda.estado == EstadoCelda.ocupada) ...[
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: buscarTicket.isLoading
                  ? null
                  : () async {
                      final ticketId = await ref
                          .read(ticketAbiertoDeCeldaNotifierProvider(celdaId).notifier)
                          .buscar();
                      if (!context.mounted) return;
                      if (ticketId != null) {
                        context.push('/tickets/$ticketId/salida');
                      } else if (buscarTicket.errorMessage == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No se encontró un ticket abierto para esta celda.')),
                        );
                      }
                    },
              child: buscarTicket.isLoading ? const ButtonSpinner() : const Text('Registrar salida'),
            ),
          ],
          if (esAdmin) ...[
            const SizedBox(height: AppSpacing.lg),
            if (celda.estado == EstadoCelda.libre)
              ElevatedButton(
                onPressed: accion.isLoading
                    ? null
                    : () => ref.read(celdaAccionNotifierProvider(celdaId).notifier).marcarMantenimiento(),
                child: accion.isLoading ? const ButtonSpinner() : const Text('Poner en mantenimiento'),
              ),
            if (celda.estado == EstadoCelda.mantenimiento)
              ElevatedButton(
                onPressed: accion.isLoading
                    ? null
                    : () => ref.read(celdaAccionNotifierProvider(celdaId).notifier).volverALibre(),
                child: accion.isLoading ? const ButtonSpinner() : const Text('Volver a libre'),
              ),
          ],
        ],
      ),
    );
  }
}
