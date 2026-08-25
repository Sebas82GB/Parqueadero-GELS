import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/list_item_skeleton.dart';
import 'ticket_list_notifier.dart';
import 'widgets/ticket_filtros_bar.dart';
import 'widgets/ticket_list_item.dart';

class TicketsHistorialScreen extends ConsumerWidget {
  const TicketsHistorialScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ticketListNotifierProvider);
    final notifier = ref.read(ticketListNotifierProvider.notifier);

    Widget body;
    if (state.tickets.isEmpty && state.isLoading) {
      body = ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
        children: List.generate(
          4,
          (_) => const Padding(padding: EdgeInsets.only(bottom: AppSpacing.sm), child: ListItemSkeleton()),
        ),
      );
    } else if (state.tickets.isEmpty && state.errorMessage != null) {
      body = ErrorState(message: state.errorMessage!, onRetry: notifier.refrescar);
    } else if (state.tickets.isEmpty) {
      body = const EmptyState(
        icon: Icons.receipt_long,
        message: 'No hay tickets que coincidan con los filtros.',
      );
    } else {
      body = RefreshIndicator(
        onRefresh: notifier.refrescar,
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
          itemCount: state.tickets.length + (state.hayMas ? 1 : 0),
          itemBuilder: (context, i) {
            if (i == state.tickets.length) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Center(
                  child: state.isLoadingMore
                      ? const CircularProgressIndicator()
                      : ElevatedButton(onPressed: notifier.cargarMas, child: const Text('Cargar más')),
                ),
              );
            }
            return TicketListItem(ticket: state.tickets[i]);
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Historial de tickets')),
      body: Column(
        children: [const TicketFiltrosBar(), Expanded(child: body)],
      ),
    );
  }
}
