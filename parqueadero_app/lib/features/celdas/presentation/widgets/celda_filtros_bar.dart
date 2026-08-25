import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/tipo_vehiculo_label.dart';
import '../../../../core/widgets/filtros_bar.dart';
import '../../domain/celda.dart';
import '../celda_list_notifier.dart';
import 'celda_estado_style.dart';

class CeldaFiltrosBar extends ConsumerWidget {
  const CeldaFiltrosBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(celdaListNotifierProvider);
    final notifier = ref.read(celdaListNotifierProvider.notifier);
    final hayFiltrosActivos =
        state.zonaFiltro != null || state.estadoFiltro != null || state.tipoFiltro != null;

    return FiltrosBar(
      children: [
        DropdownButton<String?>(
          value: state.zonaFiltro,
          hint: const Text('Zona'),
          items: [
            const DropdownMenuItem(value: null, child: Text('Todas las zonas')),
            for (final zona in state.zonas) DropdownMenuItem(value: zona, child: Text(zona)),
          ],
          onChanged: notifier.setZonaFiltro,
        ),
        DropdownButton<EstadoCelda?>(
          value: state.estadoFiltro,
          hint: const Text('Estado'),
          items: [
            const DropdownMenuItem(value: null, child: Text('Todos los estados')),
            for (final estado in EstadoCelda.values)
              DropdownMenuItem(value: estado, child: Text(CeldaEstadoStyle.of(estado).label)),
          ],
          onChanged: notifier.setEstadoFiltro,
        ),
        DropdownButton<TipoVehiculo?>(
          value: state.tipoFiltro,
          hint: const Text('Tipo de vehículo'),
          items: [
            const DropdownMenuItem(value: null, child: Text('Todos los tipos')),
            for (final tipo in TipoVehiculo.values)
              DropdownMenuItem(value: tipo, child: Text(tipoVehiculoLabel(tipo))),
          ],
          onChanged: notifier.setTipoFiltro,
        ),
        if (hayFiltrosActivos)
          TextButton(onPressed: notifier.limpiarFiltros, child: const Text('Limpiar filtros')),
      ],
    );
  }
}
