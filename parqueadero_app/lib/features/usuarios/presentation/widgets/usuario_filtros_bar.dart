import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/rol_usuario_label.dart';
import '../../../../core/widgets/filtros_bar.dart';
import '../../../auth/domain/usuario.dart';
import '../usuario_list_notifier.dart';

class UsuarioFiltrosBar extends ConsumerWidget {
  const UsuarioFiltrosBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(usuarioListNotifierProvider);
    final notifier = ref.read(usuarioListNotifierProvider.notifier);
    final hayFiltrosActivos = state.rolFiltro != null || state.activoFiltro != null;

    return FiltrosBar(
      children: [
        DropdownButton<RolUsuario?>(
          value: state.rolFiltro,
          hint: const Text('Rol'),
          items: [
            const DropdownMenuItem(value: null, child: Text('Todos los roles')),
            for (final rol in RolUsuario.values)
              DropdownMenuItem(value: rol, child: Text(rolUsuarioLabel(rol))),
          ],
          onChanged: notifier.setRolFiltro,
        ),
        DropdownButton<bool?>(
          value: state.activoFiltro,
          hint: const Text('Estado'),
          items: const [
            DropdownMenuItem(value: null, child: Text('Todos')),
            DropdownMenuItem(value: true, child: Text('Activos')),
            DropdownMenuItem(value: false, child: Text('Inactivos')),
          ],
          onChanged: notifier.setActivoFiltro,
        ),
        if (hayFiltrosActivos)
          TextButton(onPressed: notifier.limpiarFiltros, child: const Text('Limpiar filtros')),
      ],
    );
  }
}
