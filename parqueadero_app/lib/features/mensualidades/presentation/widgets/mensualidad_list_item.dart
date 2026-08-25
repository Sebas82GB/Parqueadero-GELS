import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/bogota_time.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/material_hero.dart';
import '../../domain/mensualidad.dart';
import 'estado_pago_chip.dart';
import 'vigencia_chip.dart';

class MensualidadListItem extends StatelessWidget {
  const MensualidadListItem({super.key, required this.mensualidad});

  final Mensualidad mensualidad;

  @override
  Widget build(BuildContext context) {
    final vigencia = mensualidad.vigencia();
    return Card(
      child: ListTile(
        onTap: () => context.push('/mensualidades/${mensualidad.id}'),
        // La respuesta de `GET /mensualidades` no trae la placa del
        // vehículo, solo `vehiculoId` — no hay endpoint para resolverla.
        title: Text('Vehículo #${mensualidad.vehiculoId.substring(0, 8)}'),
        subtitle: Text(
          'Vence ${formatBogota(mensualidad.fechaFin, 'd MMM y')} · ${formatMoney(mensualidad.valorMensualidad)}',
        ),
        trailing: Wrap(
          spacing: AppSpacing.xs,
          children: [
            MaterialHero(
              tag: 'mensualidad-pago-${mensualidad.id}',
              child: EstadoPagoChip(estado: mensualidad.estadoPago),
            ),
            // Evita duplicar "Cancelada": ese estado ya lo muestra el chip
            // de estadoPago.
            if (vigencia != VigenciaMensualidad.cancelada)
              MaterialHero(
                tag: 'mensualidad-vigencia-${mensualidad.id}',
                child: VigenciaChip(vigencia: vigencia),
              ),
          ],
        ),
      ),
    );
  }
}
