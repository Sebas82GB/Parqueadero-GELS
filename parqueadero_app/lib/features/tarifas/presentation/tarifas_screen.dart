import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/acceso_restringido.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../auth/domain/usuario.dart';
import '../../auth/presentation/session_notifier.dart';
import 'tarifa_list_notifier.dart';
import 'widgets/tarifa_filtros_bar.dart';
import 'widgets/tarifa_grupo_card.dart';

class TarifasScreen extends ConsumerWidget {
  const TarifasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Se observa sin condición, antes de cualquier early-return: si quedara
    // detrás de un `if`, la restauración de sesión no arrancaría hasta que
    // el resto de la pantalla ya estuviera construido.
    final esAdmin = ref.watch(sessionNotifierProvider).usuario?.rol == RolUsuario.admin;

    if (!esAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tarifas')),
        body: const AccesoRestringido(),
      );
    }

    final state = ref.watch(tarifaListNotifierProvider);
    final notifier = ref.read(tarifaListNotifierProvider.notifier);

    Widget body;
    if (state.tarifas.isEmpty && state.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (state.tarifas.isEmpty && state.errorMessage != null) {
      body = ErrorState(message: state.errorMessage!, onRetry: notifier.refrescar);
    } else if (state.tarifas.isEmpty) {
      body = const EmptyState(icon: Icons.price_change, message: 'No hay tarifas registradas.');
    } else {
      final grupos = state.tarifasFiltradasPorTipo;
      body = RefreshIndicator(
        onRefresh: notifier.refrescar,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          children: [
            const TarifaFiltrosBar(),
            if (grupos.isEmpty)
              EmptyState(
                icon: Icons.filter_alt_off,
                message: 'Ningún resultado coincide con el filtro.',
                actionLabel: 'Limpiar filtro',
                onAction: () => notifier.setTipoFiltro(null),
              )
            else
              for (final entry in grupos.entries)
                TarifaGrupoCard(tipo: entry.key, tarifas: entry.value),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tarifas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Nueva tarifa',
            onPressed: () => context.push('/tarifas/nueva'),
          ),
        ],
      ),
      body: body,
    );
  }
}
