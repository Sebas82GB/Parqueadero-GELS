import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../turnos/presentation/widgets/turno_activo_indicator.dart';
import '../domain/usuario.dart';
import 'session_notifier.dart';

/// Provisional: solo nombre, rol y cerrar sesión.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.watch(sessionNotifierProvider).usuario;
    // El router solo navega aquí una vez autenticado, pero justo en esa
    // transición puede haber un frame donde esta pantalla ya se construye
    // con el estado todavía sin propagar (visto en pruebas manuales en
    // Chrome: un `usuario!` forzado aquí crashea la app en ese frame).
    if (usuario == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Parqueadero')),
      body: Column(
        children: [
          const TurnoActivoIndicator(),
          Expanded(
            // `SingleChildScrollView` en vez de solo `Center`: la lista de
            // botones ya no cabe siempre en pantallas bajas (visto al
            // agregar "Horario de operación" — desbordaba 48px en el test
            // widget con el viewport por defecto).
            child: SingleChildScrollView(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(usuario.nombre, style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: AppSpacing.sm),
                    Text(_rolLabel(usuario.rol), style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: AppSpacing.xl),
                    ElevatedButton(
                      onPressed: () => context.push('/celdas'),
                      child: const Text('Ver celdas'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ElevatedButton(
                      onPressed: () => context.push('/tickets'),
                      child: const Text('Historial'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ElevatedButton(
                      onPressed: () => context.push('/turnos'),
                      child: const Text('Turnos'),
                    ),
                    // Responde "¿está adentro?" para cualquier rol; solo la
                    // acción secundaria de registrar salida, dentro de esa
                    // pantalla, queda gateada a OPERADOR (es 403 para ADMIN).
                    const SizedBox(height: AppSpacing.md),
                    ElevatedButton(
                      onPressed: () => context.push('/tickets/buscar'),
                      child: const Text('Buscar por placa'),
                    ),
                    if (usuario.rol == RolUsuario.admin) ...[
                      const SizedBox(height: AppSpacing.md),
                      ElevatedButton(
                        onPressed: () => context.push('/tarifas'),
                        child: const Text('Tarifas'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ElevatedButton(
                        onPressed: () => context.push('/mensualidades'),
                        child: const Text('Mensualidades'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ElevatedButton(
                        onPressed: () => context.push('/horarios'),
                        child: const Text('Horario de operación'),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    ElevatedButton(
                      onPressed: () => ref.read(sessionNotifierProvider.notifier).logout(),
                      child: const Text('Cerrar sesión'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _rolLabel(RolUsuario rol) => switch (rol) {
    RolUsuario.admin => 'Administrador',
    RolUsuario.operador => 'Operador',
  };
}
