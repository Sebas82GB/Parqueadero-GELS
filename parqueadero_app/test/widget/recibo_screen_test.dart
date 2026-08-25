import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:parqueadero_app/core/domain/tipo_vehiculo.dart';
import 'package:parqueadero_app/core/network/api_exception.dart';
import 'package:parqueadero_app/core/widgets/empty_state.dart';
import 'package:parqueadero_app/core/widgets/error_state.dart';
import 'package:parqueadero_app/features/tickets/data/ticket_repository_impl.dart';
import 'package:parqueadero_app/features/tickets/domain/desglose_item.dart';
import 'package:parqueadero_app/features/tickets/domain/recibo.dart';
import 'package:parqueadero_app/features/tickets/domain/ticket.dart';
import 'package:parqueadero_app/features/tickets/domain/ticket_repository.dart';
import 'package:parqueadero_app/features/tickets/presentation/recibo_screen.dart';

class MockTicketRepository extends Mock implements TicketRepository {}

void main() {
  late MockTicketRepository ticketRepository;

  Establecimiento establecimiento() => const Establecimiento(
    nombre: 'Parqueadero Ejemplo S.A.S.',
    nit: '900.123.456-7',
    direccion: 'Calle 100 # 15-20',
    telefono: '(601) 555-0000',
    ciudad: 'Bogotá D.C.',
    regimenTributario: 'Régimen común',
    numeroResolucion: 'Resolución DIAN 000000000000',
    textoResponsabilidad: 'El establecimiento no se hace responsable...',
    textoSeguro: 'Este parqueadero cuenta con póliza de seguro...',
    textoHorario: 'Horario de atención: 6:00 a.m. a 9:00 p.m.',
    textoReclamos: 'Reclamos dentro de las 24 horas siguientes...',
  );

  Recibo recibo() => Recibo(
    consecutivo: 123,
    fechaEmision: DateTime.utc(2026, 1, 1, 18),
    establecimiento: establecimiento(),
    placa: 'ABC123',
    tipoVehiculo: TipoVehiculo.carro,
    celda: 'A-01',
    horaEntrada: DateTime.utc(2026, 1, 1, 16, 30),
    horaSalida: DateTime.utc(2026, 1, 1, 18),
    tiempoTotal: '1h 30min',
    desglose: const [DesgloseManual(valor: 9000)],
    total: 9000,
    metodoPago: null,
    operador: 'Ana',
  );

  Ticket ticketCerrado() => Ticket(
    id: 't1',
    codigo: 'T-260101-ABC123',
    vehiculoId: 'veh1',
    celdaId: 'cel1',
    horaEntrada: DateTime.utc(2026, 1, 1, 16, 30),
    horaSalida: DateTime.utc(2026, 1, 1, 18),
    tarifaId: 'tar1',
    valorTotal: 9000,
    estado: EstadoTicket.pagado,
    operadorEntradaId: 'op1',
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
    recibo: recibo(),
  );

  Ticket ticketAbierto() => Ticket(
    id: 't1',
    codigo: 'T-260101-ABC123',
    vehiculoId: 'veh1',
    celdaId: 'cel1',
    horaEntrada: DateTime.utc(2026, 1, 1, 16, 30),
    tarifaId: 'tar1',
    estado: EstadoTicket.abierto,
    operadorEntradaId: 'op1',
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  setUpAll(() async {
    await initializeDateFormatting('es_CO');
  });

  setUp(() {
    ticketRepository = MockTicketRepository();
  });

  Future<void> pumpReciboScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [ticketRepositoryProvider.overrideWithValue(ticketRepository)],
        child: const MaterialApp(home: ReciboScreen(ticketId: 't1')),
      ),
    );
  }

  testWidgets('cargando: muestra el spinner', (tester) async {
    when(() => ticketRepository.obtenerPorId('t1')).thenAnswer(
      (_) => Future.delayed(const Duration(milliseconds: 50), ticketCerrado),
    );

    await pumpReciboScreen(tester);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
  });

  testWidgets('error: muestra el mensaje del backend con reintentar', (tester) async {
    when(
      () => ticketRepository.obtenerPorId('t1'),
    ).thenThrow(const ApiException(code: 'TICKET_NO_ENCONTRADO', message: 'Ticket no encontrado', statusCode: 404));

    await pumpReciboScreen(tester);
    await tester.pumpAndSettle();

    expect(find.byType(ErrorState), findsOneWidget);
    expect(find.text('Ticket no encontrado'), findsOneWidget);
  });

  testWidgets('ticket todavía abierto (sin recibo): muestra el mensaje de vacío', (tester) async {
    when(() => ticketRepository.obtenerPorId('t1')).thenAnswer((_) async => ticketAbierto());

    await pumpReciboScreen(tester);
    await tester.pumpAndSettle();

    expect(find.byType(EmptyState), findsOneWidget);
  });

  testWidgets('éxito: muestra los datos del recibo y el botón Imprimir', (tester) async {
    when(() => ticketRepository.obtenerPorId('t1')).thenAnswer((_) async => ticketCerrado());

    await pumpReciboScreen(tester);
    await tester.pumpAndSettle();

    expect(find.text('Parqueadero Ejemplo S.A.S.'), findsOneWidget);
    expect(find.text('Recibo No. 123'), findsOneWidget);
    expect(find.text('Placa: ABC123'), findsOneWidget);
    expect(find.text('Imprimir'), findsOneWidget);
    expect(find.byIcon(Icons.print), findsOneWidget);
  });
}
