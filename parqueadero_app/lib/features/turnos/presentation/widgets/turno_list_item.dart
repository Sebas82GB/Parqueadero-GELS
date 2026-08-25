import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/bogota_time.dart';
import '../../../../core/utils/money.dart';
import '../../domain/turno.dart';
import 'turno_estado_chip.dart';

class TurnoListItem extends StatelessWidget {
  const TurnoListItem({super.key, required this.turno});

  final Turno turno;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: () => context.push('/turnos/${turno.id}'),
        title: Text('Operador ${turno.operadorId}'),
        subtitle: Text(
          '${formatBogota(turno.apertura)}'
          '${turno.totalRecaudado != null ? ' · ${formatMoney(turno.totalRecaudado!)}' : ''}',
        ),
        trailing: TurnoEstadoChip(estado: turno.estado),
      ),
    );
  }
}
