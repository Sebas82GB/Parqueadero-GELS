import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/bogota_time.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/acceso_restringido.dart';
import '../../../core/widgets/button_spinner.dart';
import '../../../core/widgets/detail_skeleton.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/material_hero.dart';
import '../../auth/domain/usuario.dart';
import '../../auth/presentation/session_notifier.dart';
import '../domain/mensualidad.dart';
import 'mensualidad_accion_notifier.dart';
import 'mensualidad_list_notifier.dart';
import 'widgets/estado_pago_chip.dart';
import 'widgets/vigencia_chip.dart';

/// Ruta completa (deep-linkable), no bottom sheet. Lee la mensualidad de
/// [mensualidadListNotifierProvider] por id — ya la tiene cargada si se
/// llegó desde el listado — mismo patrón que `CeldaDetailScreen`, sin volver
/// a pegarle a `GET /mensualidades/:id`.
class MensualidadDetailScreen extends ConsumerWidget {
  const MensualidadDetailScreen({super.key, required this.mensualidadId});

  final String mensualidadId;

  Future<void> _confirmarCancelar(BuildContext context, WidgetRef ref) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cancelar mensualidad?'),
        content: const Text(
          'La mensualidad dejará de cubrir la estadía del vehículo desde ahora. '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Confirmar')),
        ],
      ),
    );
    if (confirmado != true) return;
    await ref.read(mensualidadAccionNotifierProvider(mensualidadId).notifier).cancelar();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final esAdmin = ref.watch(sessionNotifierProvider).usuario?.rol == RolUsuario.admin;
    if (!esAdmin) {
      return Scaffold(appBar: AppBar(), body: const AccesoRestringido());
    }

    final listState = ref.watch(mensualidadListNotifierProvider);
    Mensualidad? mensualidad;
    for (final m in listState.mensualidades) {
      if (m.id == mensualidadId) {
        mensualidad = m;
        break;
      }
    }

    if (mensualidad == null) {
      Widget body;
      if (listState.isLoading) {
        body = const DetailSkeleton();
      } else if (listState.errorMessage != null) {
        body = ErrorState(
          message: listState.errorMessage!,
          onRetry: ref.read(mensualidadListNotifierProvider.notifier).refrescar,
        );
      } else {
        body = const EmptyState(icon: Icons.search_off, message: 'Mensualidad no encontrada.');
      }
      return Scaffold(appBar: AppBar(), body: body);
    }

    final accion = ref.watch(mensualidadAccionNotifierProvider(mensualidadId));
    final vigencia = mensualidad.vigencia();
    final puedeCancelar = mensualidad.estadoPago != EstadoPagoMensualidad.cancelada;

    return Scaffold(
      appBar: AppBar(title: Text('Vehículo #${mensualidad.vehiculoId.substring(0, 8)}')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              MaterialHero(
                tag: 'mensualidad-pago-${mensualidad.id}',
                child: EstadoPagoChip(estado: mensualidad.estadoPago),
              ),
              if (vigencia != VigenciaMensualidad.cancelada)
                MaterialHero(
                  tag: 'mensualidad-vigencia-${mensualidad.id}',
                  child: VigenciaChip(vigencia: vigencia),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Vigencia', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${formatBogota(mensualidad.fechaInicio, 'd MMM y')} – ${formatBogota(mensualidad.fechaFin, 'd MMM y')}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Valor', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(formatMoney(mensualidad.valorMensualidad), style: Theme.of(context).textTheme.bodyLarge),
          if (mensualidad.celdaId != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text('Celda asignada', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(mensualidad.celdaId!, style: Theme.of(context).textTheme.bodyLarge),
          ],
          if (mensualidad.fechaPago != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text('Fecha de pago', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(formatBogota(mensualidad.fechaPago!), style: Theme.of(context).textTheme.bodyLarge),
          ],
          if (accion.errorMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              accion.errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          if (puedeCancelar) ...[
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: accion.isLoading ? null : () => _confirmarCancelar(context, ref),
              child: accion.isLoading ? const ButtonSpinner() : const Text('Cancelar mensualidad'),
            ),
          ],
        ],
      ),
    );
  }
}
