import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import 'turno_list_notifier.dart';
import 'widgets/turno_filtros_bar.dart';
import 'widgets/turno_list_item.dart';

class TurnosHistorialScreen extends ConsumerWidget {
  const TurnosHistorialScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(turnoListNotifierProvider);
    final notifier = ref.read(turnoListNotifierProvider.notifier);

    Widget body;
    if (state.turnos.isEmpty && state.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (state.turnos.isEmpty && state.errorMessage != null) {
      body = ErrorState(message: state.errorMessage!, onRetry: notifier.refrescar);
    } else if (state.turnos.isEmpty) {
      body = const EmptyState(
        icon: Icons.point_of_sale,
        message: 'No hay turnos que coincidan con los filtros.',
      );
    } else {
      body = RefreshIndicator(
        onRefresh: notifier.refrescar,
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
          itemCount: state.turnos.length + (state.hayMas ? 1 : 0),
          itemBuilder: (context, i) {
            if (i == state.turnos.length) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Center(
                  child: state.isLoadingMore
                      ? const CircularProgressIndicator()
                      : ElevatedButton(onPressed: notifier.cargarMas, child: const Text('Cargar más')),
                ),
              );
            }
            return TurnoListItem(turno: state.turnos[i]);
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Historial de turnos')),
      body: Column(
        children: [const TurnoFiltrosBar(), Expanded(child: body)],
      ),
    );
  }
}
