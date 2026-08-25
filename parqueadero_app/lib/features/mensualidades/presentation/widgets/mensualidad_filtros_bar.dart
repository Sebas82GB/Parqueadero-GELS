import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/filtros_bar.dart';
import '../../domain/mensualidad.dart';
import '../mensualidad_list_notifier.dart';
import 'estado_pago_style.dart';
import 'vigencia_style.dart';

/// Los tres valores de vigencia que acepta el filtro del backend
/// (`VigenciaMensualidad.cancelada` no es un valor válido de ese query
/// param — ver `VigenciaMensualidad.toBackend()` — así que no se ofrece
/// aquí; para filtrar por canceladas se usa el dropdown de estadoPago).
const _vigenciasFiltrables = [
  VigenciaMensualidad.vigente,
  VigenciaMensualidad.porVencer,
  VigenciaMensualidad.vencida,
];

class MensualidadFiltrosBar extends ConsumerStatefulWidget {
  const MensualidadFiltrosBar({super.key});

  @override
  ConsumerState<MensualidadFiltrosBar> createState() => _MensualidadFiltrosBarState();
}

class _MensualidadFiltrosBarState extends ConsumerState<MensualidadFiltrosBar> {
  late final TextEditingController _placaController;

  @override
  void initState() {
    super.initState();
    _placaController = TextEditingController(
      text: ref.read(mensualidadListNotifierProvider).placaFiltro,
    );
  }

  @override
  void dispose() {
    _placaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mensualidadListNotifierProvider);
    final notifier = ref.read(mensualidadListNotifierProvider.notifier);
    final hayFiltrosActivos =
        state.estadoPagoFiltro != null || state.placaFiltro != null || state.vigenciaFiltro != null;

    return FiltrosBar(
      children: [
        DropdownButton<EstadoPagoMensualidad?>(
          value: state.estadoPagoFiltro,
          hint: const Text('Estado de pago'),
          items: [
            const DropdownMenuItem(value: null, child: Text('Todos los estados')),
            for (final estado in EstadoPagoMensualidad.values)
              DropdownMenuItem(value: estado, child: Text(EstadoPagoStyle.of(estado).label)),
          ],
          onChanged: notifier.setEstadoPagoFiltro,
        ),
        DropdownButton<VigenciaMensualidad?>(
          value: state.vigenciaFiltro,
          hint: const Text('Vigencia'),
          items: [
            const DropdownMenuItem(value: null, child: Text('Todas')),
            for (final vigencia in _vigenciasFiltrables)
              DropdownMenuItem(value: vigencia, child: Text(VigenciaStyle.of(vigencia).label)),
          ],
          onChanged: notifier.setVigenciaFiltro,
        ),
        SizedBox(
          width: 160,
          child: TextField(
            controller: _placaController,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(labelText: 'Placa', helperText: 'Coincidencia exacta'),
            onSubmitted: notifier.setPlacaFiltro,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.search),
          tooltip: 'Buscar por placa',
          onPressed: () => notifier.setPlacaFiltro(_placaController.text.trim()),
        ),
        if (hayFiltrosActivos)
          TextButton(
            onPressed: () {
              _placaController.clear();
              notifier.limpiarFiltros();
            },
            child: const Text('Limpiar filtros'),
          ),
      ],
    );
  }
}
