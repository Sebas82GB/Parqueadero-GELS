import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:parqueadero_app/core/network/api_exception.dart';
import 'package:parqueadero_app/features/celdas/data/celda_repository_impl.dart';
import 'package:parqueadero_app/features/celdas/domain/celda.dart';
import 'package:parqueadero_app/features/celdas/domain/celda_repository.dart';
import 'package:parqueadero_app/features/celdas/presentation/celda_list_notifier.dart';
import 'package:parqueadero_app/features/tickets/data/ticket_repository_impl.dart';
import 'package:parqueadero_app/features/tickets/domain/desglose_item.dart';
import 'package:parqueadero_app/features/tickets/domain/pago.dart';
import 'package:parqueadero_app/features/tickets/domain/ticket.dart';
import 'package:parqueadero_app/features/tickets/domain/ticket_repository.dart';
import 'package:parqueadero_app/features/tickets/presentation/salida_notifier.dart';
import 'package:parqueadero_app/features/tickets/presentation/salida_state.dart';

class MockTicketRepository extends Mock implements TicketRepository {}

class MockCeldaRepository extends Mock implements CeldaRepository {}

void main() {
  late MockTicketRepository ticketRepository;
  late MockCeldaRepository celdaRepository;
  late ProviderContainer container;

  Celda celdaLibre() => Celda(
    id: 'cel1',
    codigo: 'A-01',
    zona: 'Zona A',
    tipoPermitido: TipoVehiculo.carro,
    estado: EstadoCelda.libre,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  Ticket ticketCerrado({required int valorTotal, required List<DesgloseItem> desglose}) => Ticket(
    id: 't1',
    codigo: 'T-260101-ABC123',
    vehiculoId: 'veh1',
    celdaId: 'cel1',
    horaEntrada: DateTime.utc(2026, 1, 1, 13),
    horaSalida: DateTime.utc(2026, 1, 1, 14, 30),
    tarifaId: 'tar1',
    valorTotal: valorTotal,
    desglose: desglose,
    estado: EstadoTicket.pagado,
    operadorEntradaId: 'op1',
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
    celda: celdaLibre(),
  );

  setUp(() {
    ticketRepository = MockTicketRepository();
    celdaRepository = MockCeldaRepository();
    container = ProviderContainer(
      overrides: [
        ticketRepositoryProvider.overrideWithValue(ticketRepository),
        celdaRepositoryProvider.overrideWithValue(celdaRepository),
      ],
    );
    addTearDown(container.dispose);
    when(() => celdaRepository.listarTodas()).thenAnswer((_) async => []);
    container.listen(celdaListNotifierProvider, (_, _) {});
  });

  test('éxito con desglose por bloques: pasa a exito con el ticket cerrado', () async {
    when(
      () => ticketRepository.registrarSalida('t1', metodo: any(named: 'metodo'), valorManual: any(named: 'valorManual')),
    ).thenAnswer(
      (_) async => ticketCerrado(
        valorTotal: 9000,
        desglose: [
          DesgloseBloque(
            dia: 1,
            bloqueNumero: 1,
            inicio: DateTime.utc(2026, 1, 1, 13),
            fin: DateTime.utc(2026, 1, 1, 14, 30),
            minutos: 90,
            tipoCobro: TipoCobro.parcial,
            valor: 9000,
          ),
        ],
      ),
    );

    final ok = await container
        .read(salidaNotifierProvider('t1').notifier)
        .confirmarSalida(metodo: MetodoPago.efectivo);

    expect(ok, isTrue);
    final state = container.read(salidaNotifierProvider('t1'));
    expect(state.step, SalidaStep.exito);
    expect(state.ticketCerrado?.valorTotal, 9000);
  });

  test('éxito con mensualidad: desglose MENSUALIDAD y valorTotal 0', () async {
    when(
      () => ticketRepository.registrarSalida('t1', metodo: any(named: 'metodo'), valorManual: any(named: 'valorManual')),
    ).thenAnswer((_) async => ticketCerrado(valorTotal: 0, desglose: const [DesgloseMensualidad()]));

    final ok = await container.read(salidaNotifierProvider('t1').notifier).confirmarSalida();

    expect(ok, isTrue);
    final state = container.read(salidaNotifierProvider('t1'));
    expect(state.ticketCerrado?.desglose.single, const DesgloseMensualidad());
  });

  test('éxito con valor manual: desglose MANUAL', () async {
    when(
      () => ticketRepository.registrarSalida('t1', metodo: any(named: 'metodo'), valorManual: any(named: 'valorManual')),
    ).thenAnswer(
      (_) async => ticketCerrado(valorTotal: 15000, desglose: const [DesgloseManual(valor: 15000)]),
    );

    final ok = await container
        .read(salidaNotifierProvider('t1').notifier)
        .confirmarSalida(metodo: MetodoPago.tarjeta, valorManual: 15000);

    expect(ok, isTrue);
    final state = container.read(salidaNotifierProvider('t1'));
    expect(state.ticketCerrado?.desglose.single, const DesgloseManual(valor: 15000));
  });

  test('422 VALOR_MANUAL_REQUERIDO: vuelve a formulario con el error', () async {
    when(
      () => ticketRepository.registrarSalida('t1', metodo: any(named: 'metodo'), valorManual: any(named: 'valorManual')),
    ).thenThrow(
      const ApiException(code: 'VALOR_MANUAL_REQUERIDO', message: 'Falta el valor manual', statusCode: 422),
    );

    final ok = await container.read(salidaNotifierProvider('t1').notifier).confirmarSalida();

    expect(ok, isFalse);
    final state = container.read(salidaNotifierProvider('t1'));
    expect(state.step, SalidaStep.formulario);
    expect(state.error?.message, 'Falta el valor manual');
  });

  test('422 METODO_PAGO_REQUERIDO: vuelve a formulario con el error', () async {
    when(
      () => ticketRepository.registrarSalida('t1', metodo: any(named: 'metodo'), valorManual: any(named: 'valorManual')),
    ).thenThrow(
      const ApiException(code: 'METODO_PAGO_REQUERIDO', message: 'Falta el método de pago', statusCode: 422),
    );

    final ok = await container.read(salidaNotifierProvider('t1').notifier).confirmarSalida();

    expect(ok, isFalse);
    expect(container.read(salidaNotifierProvider('t1')).step, SalidaStep.formulario);
  });

  test('409 OPERADOR_SIN_TURNO_ABIERTO: expone el code para que la UI ofrezca abrir turno', () async {
    when(
      () => ticketRepository.registrarSalida('t1', metodo: any(named: 'metodo'), valorManual: any(named: 'valorManual')),
    ).thenThrow(
      const ApiException(code: 'OPERADOR_SIN_TURNO_ABIERTO', message: 'No tiene un turno abierto', statusCode: 409),
    );

    final ok = await container
        .read(salidaNotifierProvider('t1').notifier)
        .confirmarSalida(metodo: MetodoPago.efectivo);

    expect(ok, isFalse);
    final state = container.read(salidaNotifierProvider('t1'));
    expect(state.step, SalidaStep.formulario);
    expect(state.error, isA<ApiException>().having((e) => e.code, 'code', 'OPERADOR_SIN_TURNO_ABIERTO'));
  });
}
