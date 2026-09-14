import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:parqueadero_app/core/network/api_exception.dart';
import 'package:parqueadero_app/features/celdas/data/celda_repository_impl.dart';
import 'package:parqueadero_app/features/celdas/domain/celda.dart';
import 'package:parqueadero_app/features/celdas/domain/celda_repository.dart';
import 'package:parqueadero_app/features/celdas/presentation/celda_list_notifier.dart';
import 'package:parqueadero_app/features/tickets/data/ticket_repository_impl.dart';
import 'package:parqueadero_app/features/tickets/domain/ticket.dart';
import 'package:parqueadero_app/features/tickets/domain/ticket_repository.dart';
import 'package:parqueadero_app/features/tickets/domain/vehiculo.dart';
import 'package:parqueadero_app/features/tickets/presentation/registrar_entrada_notifier.dart';

class MockTicketRepository extends Mock implements TicketRepository {}

class MockCeldaRepository extends Mock implements CeldaRepository {}

void main() {
  late MockTicketRepository ticketRepository;
  late MockCeldaRepository celdaRepository;
  late ProviderContainer container;

  Celda celda({String id = 'cel1', EstadoCelda estado = EstadoCelda.ocupada}) => Celda(
    id: id,
    codigo: 'A-01',
    zona: 'Zona A',
    tipoPermitido: TipoVehiculo.carro,
    estado: estado,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  Ticket ticket({Celda? celdaAnidada}) => Ticket(
    id: 't1',
    codigo: 'T-260101-ABC123',
    vehiculoId: 'veh1',
    celdaId: 'cel1',
    horaEntrada: DateTime.utc(2026, 1, 1, 13),
    tarifaId: 'tar1',
    estado: EstadoTicket.abierto,
    operadorEntradaId: 'op1',
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
    vehiculo: Vehiculo(
      id: 'veh1',
      placa: 'ABC123',
      tipo: TipoVehiculo.carro,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
    ),
    celda: celdaAnidada ?? celda(),
  );

  setUpAll(() {
    registerFallbackValue(TipoVehiculo.carro);
  });

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
  });

  test('éxito: retorna el Ticket y parcha CeldaListNotifier con la celda OCUPADA', () async {
    when(
      () => ticketRepository.registrarEntrada(
        placa: any(named: 'placa'),
        tipoVehiculo: any(named: 'tipoVehiculo'),
        celdaId: any(named: 'celdaId'),
        propietarioNombre: any(named: 'propietarioNombre'),
        propietarioTelefono: any(named: 'propietarioTelefono'),
      ),
    ).thenAnswer((_) async => ticket());

    // Se mantiene vivo celdaListNotifierProvider para poder observar el parche.
    container.listen(celdaListNotifierProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);

    final resultado = await container
        .read(registrarEntradaNotifierProvider.notifier)
        .registrar(placa: 'ABC123', tipoVehiculo: TipoVehiculo.carro, celdaId: 'cel1');

    expect(resultado?.codigo, 'T-260101-ABC123');
    expect(container.read(registrarEntradaNotifierProvider).error, isNull);
  });

  for (final code in [
    'CELDA_NO_ENCONTRADA',
    'CELDA_OCUPADA',
    'CELDA_EN_MANTENIMIENTO',
    'VEHICULO_CON_TICKET_ABIERTO',
    'CELDA_TIPO_INCOMPATIBLE',
    'TARIFA_NO_VIGENTE',
    'TICKET_CODIGO_DUPLICADO',
    'TICKET_CONFLICTO_UNICIDAD',
  ]) {
    test('$code: expone el mensaje del backend y retorna null', () async {
      when(
        () => ticketRepository.registrarEntrada(
          placa: any(named: 'placa'),
          tipoVehiculo: any(named: 'tipoVehiculo'),
          celdaId: any(named: 'celdaId'),
          propietarioNombre: any(named: 'propietarioNombre'),
          propietarioTelefono: any(named: 'propietarioTelefono'),
        ),
      ).thenThrow(ApiException(code: code, message: 'mensaje $code', statusCode: 409));

      final resultado = await container
          .read(registrarEntradaNotifierProvider.notifier)
          .registrar(placa: 'ABC123', tipoVehiculo: TipoVehiculo.carro, celdaId: 'cel1');

      expect(resultado, isNull);
      expect(container.read(registrarEntradaNotifierProvider).error?.message, 'mensaje $code');
    });
  }
}
