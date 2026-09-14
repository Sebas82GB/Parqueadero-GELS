import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/bogota_time.dart';
import '../../../../core/utils/money.dart';
import '../../../auth/domain/usuario.dart';
import '../../../auth/presentation/session_notifier.dart';
import '../../domain/turno.dart';
import 'diferencia_texto.dart';
import 'turno_estado_chip.dart';
import 'turno_filtros_bar.dart';

class TurnoListItem extends ConsumerWidget {
  const TurnoListItem({super.key, required this.turno});

  final Turno turno;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        onTap: () => context.push('/turnos/${turno.id}'),
        title: Text(_nombreOperador(ref, turno.operadorId)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Apertura: ${formatBogota(turno.apertura)}'),
              Text(
                turno.cierre == null ? 'En curso' : 'Cierre: ${formatBogota(turno.cierre!)}',
              ),
              Text('Base inicial: ${formatMoney(turno.baseInicial)}'),
              if (turno.diferencia != null) Text(diferenciaTexto(turno.diferencia!)),
            ],
          ),
        ),
        isThreeLine: true,
        trailing: TurnoEstadoChip(estado: turno.estado),
      ),
    );
  }

  /// Un OPERADOR nunca puede pedir `GET /usuarios` (403), pero un turno
  /// suyo siempre tiene `operadorId == usuario.id`: se resuelve con la
  /// propia sesión, sin llamar al endpoint. Un ADMIN sí puede resolver
  /// cualquier operador vía `operadoresProvider` (un solo mapa para toda la
  /// lista, no una llamada por fila). Si el id no aparece en ninguna de las
  /// dos fuentes, cae a un texto legible en vez de mostrar el UUID crudo.
  String _nombreOperador(WidgetRef ref, String operadorId) {
    final sesion = ref.watch(sessionNotifierProvider).usuario;
    if (sesion != null && sesion.id == operadorId) {
      return sesion.rol == RolUsuario.operador ? 'Mi turno' : sesion.nombre;
    }
    final operadores = ref.watch(operadoresProvider).value ?? const [];
    for (final operador in operadores) {
      if (operador.id == operadorId) return operador.nombre;
    }
    return 'Operador sin datos';
  }
}
