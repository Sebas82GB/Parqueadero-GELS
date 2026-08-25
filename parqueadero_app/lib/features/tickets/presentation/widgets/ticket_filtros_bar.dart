import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/filtros_bar.dart';
import '../../domain/ticket.dart';
import '../ticket_list_notifier.dart';
import 'ticket_estado_style.dart';

class TicketFiltrosBar extends ConsumerStatefulWidget {
  const TicketFiltrosBar({super.key});

  @override
  ConsumerState<TicketFiltrosBar> createState() => _TicketFiltrosBarState();
}

class _TicketFiltrosBarState extends ConsumerState<TicketFiltrosBar> {
  late final TextEditingController _placaController;

  @override
  void initState() {
    super.initState();
    _placaController = TextEditingController(text: ref.read(ticketListNotifierProvider).placaFiltro);
  }

  @override
  void dispose() {
    _placaController.dispose();
    super.dispose();
  }

  Future<void> _elegirRango() async {
    final state = ref.read(ticketListNotifierProvider);
    final rango = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: state.desdeFiltro != null && state.hastaFiltro != null
          ? DateTimeRange(start: state.desdeFiltro!, end: state.hastaFiltro!)
          : null,
    );
    if (rango == null) return;
    ref.read(ticketListNotifierProvider.notifier).setRangoFechas(rango.start, rango.end);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ticketListNotifierProvider);
    final notifier = ref.read(ticketListNotifierProvider.notifier);
    final hayFiltrosActivos =
        state.estadoFiltro != null ||
        state.placaFiltro != null ||
        state.desdeFiltro != null ||
        state.hastaFiltro != null;

    return FiltrosBar(
      children: [
        DropdownButton<EstadoTicket?>(
            value: state.estadoFiltro,
            hint: const Text('Estado'),
            items: [
              const DropdownMenuItem(value: null, child: Text('Todos los estados')),
              for (final estado in EstadoTicket.values)
                DropdownMenuItem(value: estado, child: Text(TicketEstadoStyle.of(estado).label)),
            ],
            onChanged: notifier.setEstadoFiltro,
          ),
        SizedBox(
          width: 140,
          child: TextField(
            controller: _placaController,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(labelText: 'Placa'),
            onSubmitted: notifier.setPlacaFiltro,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.search),
          tooltip: 'Buscar por placa',
          onPressed: () => notifier.setPlacaFiltro(_placaController.text.trim()),
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
              _placaController.clear();
              notifier.limpiarFiltros();
            },
            child: const Text('Limpiar filtros'),
          ),
      ],
    );
  }
}
