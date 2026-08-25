import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/tipo_vehiculo_label.dart';
import '../../../../core/widgets/filtros_bar.dart';
import '../../domain/tarifa.dart';
import '../tarifa_list_notifier.dart';

class TarifaFiltrosBar extends ConsumerWidget {
  const TarifaFiltrosBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tarifaListNotifierProvider);
    final notifier = ref.read(tarifaListNotifierProvider.notifier);

    return FiltrosBar(
      children: [
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
        if (state.tipoFiltro != null)
          TextButton(
            onPressed: () => notifier.setTipoFiltro(null),
            child: const Text('Limpiar filtro'),
          ),
      ],
    );
  }
}
