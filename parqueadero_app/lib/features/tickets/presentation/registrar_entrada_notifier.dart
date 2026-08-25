import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/tipo_vehiculo.dart';
import '../../../core/network/api_exception.dart';
import '../../celdas/presentation/celda_list_notifier.dart';
import '../data/ticket_repository_impl.dart';
import '../domain/ticket.dart';
import 'registrar_entrada_state.dart';

class RegistrarEntradaNotifier extends Notifier<RegistrarEntradaState> {
  @override
  RegistrarEntradaState build() => const RegistrarEntradaState();

  Future<Ticket?> registrar({
    required String placa,
    required TipoVehiculo tipoVehiculo,
    required String celdaId,
    String? propietarioNombre,
    String? propietarioTelefono,
  }) async {
    state = const RegistrarEntradaState(isLoading: true);
    try {
      final ticket = await ref
          .read(ticketRepositoryProvider)
          .registrarEntrada(
            placa: placa,
            tipoVehiculo: tipoVehiculo,
            celdaId: celdaId,
            propietarioNombre: propietarioNombre,
            propietarioTelefono: propietarioTelefono,
          );
      if (!ref.mounted) return null;
      if (ticket.celda != null) {
        ref.read(celdaListNotifierProvider.notifier).reemplazarCelda(ticket.celda!);
      }
      state = const RegistrarEntradaState();
      return ticket;
    } on AppException catch (e) {
      if (!ref.mounted) return null;
      state = RegistrarEntradaState(errorMessage: e.message);
      return null;
    }
  }
}

final registrarEntradaNotifierProvider =
    NotifierProvider.autoDispose<RegistrarEntradaNotifier, RegistrarEntradaState>(
      RegistrarEntradaNotifier.new,
    );
