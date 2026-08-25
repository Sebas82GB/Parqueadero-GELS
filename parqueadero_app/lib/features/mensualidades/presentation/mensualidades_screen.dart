import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/acceso_restringido.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/list_item_skeleton.dart';
import '../../auth/domain/usuario.dart';
import '../../auth/presentation/session_notifier.dart';
import 'mensualidad_list_notifier.dart';
import 'widgets/mensualidad_filtros_bar.dart';
import 'widgets/mensualidad_list_item.dart';

class MensualidadesScreen extends ConsumerWidget {
  const MensualidadesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Se observa sin condición, antes de cualquier early-return (ver
    // `tarifas_screen.dart` / `celda_detail_screen.dart`).
    final esAdmin = ref.watch(sessionNotifierProvider).usuario?.rol == RolUsuario.admin;

    if (!esAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mensualidades')),
        body: const AccesoRestringido(),
      );
    }

    final state = ref.watch(mensualidadListNotifierProvider);
    final notifier = ref.read(mensualidadListNotifierProvider.notifier);

    Widget body;
    if (state.mensualidades.isEmpty && state.isLoading) {
      body = ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
        children: List.generate(
          4,
          (_) => const Padding(padding: EdgeInsets.only(bottom: AppSpacing.sm), child: ListItemSkeleton()),
        ),
      );
    } else if (state.mensualidades.isEmpty && state.errorMessage != null) {
      body = ErrorState(message: state.errorMessage!, onRetry: notifier.refrescar);
    } else if (state.mensualidades.isEmpty) {
      body = const EmptyState(
        icon: Icons.event_note,
        message: 'No hay mensualidades que coincidan con los filtros.',
      );
    } else {
      body = RefreshIndicator(
        onRefresh: notifier.refrescar,
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
          itemCount: state.mensualidades.length + (state.hayMas ? 1 : 0),
          itemBuilder: (context, i) {
            if (i == state.mensualidades.length) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Center(
                  child: state.isLoadingMore
                      ? const CircularProgressIndicator()
                      : ElevatedButton(onPressed: notifier.cargarMas, child: const Text('Cargar más')),
                ),
              );
            }
            return MensualidadListItem(mensualidad: state.mensualidades[i]);
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mensualidades'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Nueva mensualidad',
            onPressed: () => context.push('/mensualidades/nueva'),
          ),
        ],
      ),
      body: Column(
        children: [const MensualidadFiltrosBar(), Expanded(child: body)],
      ),
    );
  }
}
