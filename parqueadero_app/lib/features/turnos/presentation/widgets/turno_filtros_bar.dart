import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/filtros_bar.dart';
import '../../../auth/domain/usuario.dart';
import '../../../auth/presentation/session_notifier.dart';
import '../../domain/turno.dart';
import '../turno_list_notifier.dart';

/// El campo de `operadorId` solo se muestra para ADMIN: un OPERADOR ya ve
/// solo los suyos (el backend lo fuerza), y no hay endpoint para listar
/// usuarios con el que ofrecer un selector por nombre — se filtra por id.
class TurnoFiltrosBar extends ConsumerStatefulWidget {
  const TurnoFiltrosBar({super.key});

  @override
  ConsumerState<TurnoFiltrosBar> createState() => _TurnoFiltrosBarState();
}

class _TurnoFiltrosBarState extends ConsumerState<TurnoFiltrosBar> {
  late final TextEditingController _operadorIdController;

  @override
  void initState() {
    super.initState();
    _operadorIdController = TextEditingController(text: ref.read(turnoListNotifierProvider).operadorIdFiltro);
  }

  @override
  void dispose() {
    _operadorIdController.dispose();
    super.dispose();
  }

  Future<void> _elegirRango() async {
    final state = ref.read(turnoListNotifierProvider);
    final rango = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: state.desdeFiltro != null && state.hastaFiltro != null
          ? DateTimeRange(start: state.desdeFiltro!, end: state.hastaFiltro!)
          : null,
    );
    if (rango == null) return;
    ref.read(turnoListNotifierProvider.notifier).setRangoFechas(rango.start, rango.end);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(turnoListNotifierProvider);
    final notifier = ref.read(turnoListNotifierProvider.notifier);
    final esAdmin = ref.watch(sessionNotifierProvider).usuario?.rol == RolUsuario.admin;
    final hayFiltrosActivos =
        state.estadoFiltro != null ||
        state.operadorIdFiltro != null ||
        state.desdeFiltro != null ||
        state.hastaFiltro != null;

    return FiltrosBar(
      children: [
        DropdownButton<EstadoTurno?>(
          value: state.estadoFiltro,
          hint: const Text('Estado'),
          items: [
            const DropdownMenuItem(value: null, child: Text('Todos los estados')),
            for (final estado in EstadoTurno.values)
              DropdownMenuItem(value: estado, child: Text(estado == EstadoTurno.abierto ? 'Abierto' : 'Cerrado')),
          ],
          onChanged: notifier.setEstadoFiltro,
        ),
        if (esAdmin)
          SizedBox(
            width: 160,
            child: TextField(
              controller: _operadorIdController,
              decoration: const InputDecoration(labelText: 'ID de operador'),
              onSubmitted: notifier.setOperadorIdFiltro,
            ),
          ),
        OutlinedButton.icon(
          onPressed: _elegirRango,
          icon: const Icon(Icons.date_range),
          label: Text(
            state.desdeFiltro != null && state.hastaFiltro != null
                ? '${DateFormat('d MMM', 'es_CO').format(state.desdeFiltro!)} – ${DateFormat('d MMM', 'es_CO').format(state.hastaFiltro!)}'
                : 'Rango de fechas',
          ),
        ),
        if (hayFiltrosActivos)
          TextButton(
            onPressed: () {
              _operadorIdController.clear();
              notifier.limpiarFiltros();
            },
            child: const Text('Limpiar filtros'),
          ),
      ],
    );
  }
}
