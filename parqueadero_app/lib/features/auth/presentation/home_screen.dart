import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/usuario.dart';
import 'session_notifier.dart';
import 'widgets/admin_home_dashboard.dart';
import 'widgets/operador_home_dashboard.dart';

/// Cada rol tiene su propio dashboard (skill `diseno-parqueadero`): OPERADOR
/// ve `OperadorHomeDashboard` (Registrar entrada/salida como flujo
/// principal), ADMIN ve `AdminHomeDashboard` (panel agrupado por función).
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

    return switch (usuario.rol) {
      RolUsuario.operador => const OperadorHomeDashboard(),
      RolUsuario.admin => const AdminHomeDashboard(),
    };
  }
}
