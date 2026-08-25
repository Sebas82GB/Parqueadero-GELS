import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/print/print_launcher.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import 'ticket_detail_notifier.dart';
import 'widgets/recibo_view.dart';

/// Ruta dedicada para (re)ver el recibo de un ticket ya cerrado — deep
/// linkable, a diferencia de `_ReciboSalida` (que solo aparece inline justo
/// después de registrar la salida). Reutiliza `ticketDetailNotifierProvider`,
/// que ya hace su propio `GET /tickets/:id`.
class ReciboScreen extends ConsumerWidget {
  const ReciboScreen({super.key, required this.ticketId});

  final String ticketId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ticketDetailNotifierProvider(ticketId));
    final notifier = ref.read(ticketDetailNotifierProvider(ticketId).notifier);

    Widget body;
    if (state.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (state.errorMessage != null) {
      body = Center(child: ErrorState(message: state.errorMessage!, onRetry: notifier.cargar));
    } else if (state.ticket?.recibo == null) {
      body = const Center(
        child: EmptyState(
          icon: Icons.receipt_long,
          message: 'Este ticket todavía está abierto: no tiene un recibo para mostrar.',
        ),
      );
    } else {
      final recibo = state.ticket!.recibo!;
      body = SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ReciboView(recibo: recibo),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                onPressed: triggerBrowserPrint,
                icon: const Icon(Icons.print),
                label: const Text('Imprimir'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(appBar: AppBar(title: const Text('Recibo')), body: body);
  }
}
