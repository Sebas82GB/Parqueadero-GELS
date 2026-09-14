import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/filtros_bar.dart';
import '../../../auth/domain/usuario.dart';
import '../../../auth/presentation/session_notifier.dart';
import '../../../usuarios/data/usuario_repository_impl.dart';
import '../../domain/turno.dart';
import '../turno_list_notifier.dart';
import 'turno_estado_style.dart';

/// Listado de operadores (`GET /usuarios` filtrado a rol OPERADOR): alimenta
/// el selector por nombre de este filtro y el mapa id->nombre que usa
/// `TurnoListItem` para no mostrar el UUID crudo del turno. `GET /usuarios`
/// es ADMIN-only (403 para un OPERADOR), así que si la sesión no es ADMIN
/// este provider ni siquiera intenta la llamada — un OPERADOR solo ve sus
/// propios turnos y no necesita resolver nombres ajenos. No es `.family`
/// a propósito: una sola instancia compartida por toda la pantalla, para
/// que la lista completa resuelva los nombres con una única llamada.
final operadoresProvider = FutureProvider.autoDispose<List<Usuario>>((ref) async {
  final usuario = ref.watch(sessionNotifierProvider).usuario;
  if (usuario == null || usuario.rol != RolUsuario.admin) return const [];
  final pagina = await ref.watch(usuarioRepositoryProvider).listar(rol: RolUsuario.operador, perPage: 100);
  return pagina.data;
});

/// El selector de operador solo se muestra para ADMIN: un OPERADOR ya ve
/// solo los suyos (el backend lo fuerza), así que filtrar por operador no
/// tiene sentido para él.
class TurnoFiltrosBar extends ConsumerStatefulWidget {
  const TurnoFiltrosBar({super.key});

  @override
  ConsumerState<TurnoFiltrosBar> createState() => _TurnoFiltrosBarState();
}

class _TurnoFiltrosBarState extends ConsumerState<TurnoFiltrosBar> {
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
              DropdownMenuItem(value: estado, child: Text(TurnoEstadoStyle.of(estado).label)),
          ],
          onChanged: notifier.setEstadoFiltro,
        ),
        if (esAdmin) _OperadorDropdown(value: state.operadorIdFiltro, onChanged: notifier.setOperadorIdFiltro),
        OutlinedButton.icon(
          onPressed: _elegirRango,
          icon: const Icon(Icons.date_range),
          label: Text(
            state.desdeFiltro != null && state.hastaFiltro != null
                ? '${DateFormat('d MMM', 'es_CO').format(state.desdeFiltro!)} – ${DateFormat('d MMM', 'es_CO').format(state.hastaFiltro!)}'
                : 'Rango de fechas',
          ),
        ),
        if (hayFiltrosActivos) TextButton(onPressed: notifier.limpiarFiltros, child: const Text('Limpiar filtros')),
      ],
    );
  }
}

class _OperadorDropdown extends ConsumerWidget {
  const _OperadorDropdown({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final operadoresAsync = ref.watch(operadoresProvider);
    return operadoresAsync.when(
      data: (operadores) => DropdownButton<String?>(
        value: value,
        hint: const Text('Operador'),
        items: [
          const DropdownMenuItem(value: null, child: Text('Todos los operadores')),
          for (final operador in operadores) DropdownMenuItem(value: operador.id, child: Text(operador.nombre)),
        ],
        onChanged: onChanged,
      ),
      loading: () => const SizedBox(
        width: 24,
        height: 24,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      // Sin lista de operadores no hay con qué armar el selector; el resto
      // de filtros sigue funcionando igual.
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
