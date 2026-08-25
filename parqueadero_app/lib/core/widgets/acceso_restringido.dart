import 'package:flutter/material.dart';

import 'empty_state.dart';

/// Guard de rol para pantallas top-level restringidas a ADMIN. No hay guard
/// a nivel de router (ver `app_router.dart`): cada pantalla se protege con
/// un `if` al inicio de su único `build()`, mismo criterio ya usado en
/// `celda_detail_screen.dart` para gatear acciones por rol.
class AccesoRestringido extends StatelessWidget {
  const AccesoRestringido({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.lock_outline,
      message: 'Esta sección es solo para administradores.',
    );
  }
}
