import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/acceso_restringido.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../auth/domain/usuario.dart';
import '../../auth/presentation/session_notifier.dart';
import 'usuario_list_notifier.dart';
import 'widgets/usuario_filtros_bar.dart';
import 'widgets/usuario_list_item.dart';

class UsuariosScreen extends ConsumerWidget {
  const UsuariosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final esAdmin = ref.watch(sessionNotifierProvider).usuario?.rol == RolUsuario.admin;
    if (!esAdmin) {
      return Scaffold(appBar: AppBar(title: const Text('Usuarios')), body: const AccesoRestringido());
    }

    final state = ref.watch(usuarioListNotifierProvider);
    final notifier = ref.read(usuarioListNotifierProvider.notifier);

    Widget body;
    if (state.usuarios.isEmpty && state.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (state.usuarios.isEmpty && state.errorMessage != null) {
      body = ErrorState(message: state.errorMessage!, onRetry: notifier.refrescar);
    } else if (state.usuarios.isEmpty) {
      body = const EmptyState(
        icon: Icons.people_outline,
        message: 'No hay usuarios que coincidan con los filtros.',
      );
    } else {
      body = RefreshIndicator(
        onRefresh: notifier.refrescar,
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
          itemCount: state.usuarios.length + (state.hayMas ? 1 : 0),
          itemBuilder: (context, i) {
            if (i == state.usuarios.length) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Center(
                  child: state.isLoadingMore
                      ? const CircularProgressIndicator()
                      : ElevatedButton(onPressed: notifier.cargarMas, child: const Text('Cargar más')),
                ),
              );
            }
            return UsuarioListItem(usuario: state.usuarios[i]);
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuarios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Nuevo usuario',
            onPressed: () => context.push('/usuarios/nuevo'),
          ),
        ],
      ),
      body: Column(
        children: [const UsuarioFiltrosBar(), Expanded(child: body)],
      ),
    );
  }
}
