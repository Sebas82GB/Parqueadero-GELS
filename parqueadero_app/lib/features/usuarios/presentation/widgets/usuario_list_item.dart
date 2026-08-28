import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/status_style.dart';
import '../../../../core/utils/rol_usuario_label.dart';
import '../../../auth/domain/usuario.dart';

class UsuarioListItem extends StatelessWidget {
  const UsuarioListItem({super.key, required this.usuario});

  final Usuario usuario;

  @override
  Widget build(BuildContext context) {
    final inactivoColor = StatusStyle.of(StatusTone.neutral).color;
    return Card(
      child: ListTile(
        onTap: () => context.push('/usuarios/${usuario.id}'),
        title: Text(usuario.nombre),
        subtitle: Text('${usuario.email} · ${rolUsuarioLabel(usuario.rol)}'),
        trailing: usuario.activo
            ? null
            : Chip(
                label: const Text('Inactivo'),
                backgroundColor: inactivoColor.withValues(alpha: 0.12),
                side: BorderSide(color: inactivoColor.withValues(alpha: 0.4)),
              ),
      ),
    );
  }
}
