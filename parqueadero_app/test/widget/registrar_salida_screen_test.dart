import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:parqueadero_app/core/network/api_exception.dart';
import 'package:parqueadero_app/core/utils/money.dart';
import 'package:parqueadero_app/features/auth/data/auth_repository_impl.dart';
import 'package:parqueadero_app/features/auth/domain/auth_repository.dart';
import 'package:parqueadero_app/features/auth/domain/usuario.dart';
import 'package:parqueadero_app/features/celdas/data/celda_repository_impl.dart';
import 'package:parqueadero_app/features/celdas/domain/celda.dart';
import 'package:parqueadero_app/features/celdas/domain/celda_repository.dart';
import 'package:parqueadero_app/features/tickets/data/ticket_repository_impl.dart';
import 'package:parqueadero_app/features/tickets/domain/cobro_preview.dart';
import 'package:parqueadero_app/features/tickets/domain/desglose_item.dart';
import 'package:parqueadero_app/features/tickets/domain/pago.dart';
import 'package:parqueadero_app/features/tickets/domain/recibo.dart';
import 'package:parqueadero_app/features/tickets/domain/ticket.dart';
import 'package:parqueadero_app/features/tickets/domain/ticket_repository.dart';
import 'package:parqueadero_app/features/tickets/domain/vehiculo.dart';
import 'package:parqueadero_app/features/tickets/presentation/registrar_salida_screen.dart';
import 'package:parqueadero_app/features/turnos/data/turno_repository_impl.dart';
import 'package:parqueadero_app/features/turnos/domain/turno_repository.dart';

class MockTicketRepository extends Mock implements TicketRepository {}

class MockCeldaRepository extends Mock implements CeldaRepository {}

class MockTurnoRepository extends Mock implements TurnoRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockTicketRepository ticketRepository;
  late MockCeldaRepository celdaRepository;
  late MockTurnoRepository turnoRepository;
  late MockAuthRepository authRepository;

  final operador = Usuario(
    id: 'op1',
    nombre: 'Ana',
    email: 'ana@test.com',
    rol: RolUsuario.operador,
    activo: true,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  Vehiculo vehiculo({TipoVehiculo tipo = TipoVehiculo.carro}) => Vehiculo(
    id: 'veh1',
    placa: 'ABC123',
    tipo: tipo,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  Celda celda({EstadoCelda estado = EstadoCelda.ocupada}) => Celda(
    id: 'cel1',
    codigo: 'A-01',
    zona: 'Zona A',
    tipoPermitido: TipoVehiculo.carro,
    estado: estado,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  Ticket ticketAbierto({TipoVehiculo tipoVehiculo = TipoVehiculo.carro}) => Ticket(
    id: 't1',
    codigo: 'T-260101-ABC123',
    vehiculoId: 'veh1',
    celdaId: 'cel1',
    horaEntrada: DateTime.now().toUtc().subtract(const Duration(minutes: 90)),
    tarifaId: 'tar1',
    estado: EstadoTicket.abierto,
    operadorEntradaId: 'op1',
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
    vehiculo: vehiculo(tipo: tipoVehiculo),
    celda: celda(),
  );

  Establecimiento establecimiento() => const Establecimiento(
    nombre: 'Parqueadero Ejemplo',
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

  Recibo recibo({required int total, required List<DesgloseItem> desglose, MetodoPago? metodoPago}) => Recibo(
    consecutivo: 1,
    fechaEmision: DateTime.utc(2026, 1, 1, 14, 30),
    establecimiento: establecimiento(),
    placa: 'ABC123',
    tipoVehiculo: TipoVehiculo.carro,
    celda: 'A-01',
    horaEntrada: DateTime.utc(2026, 1, 1, 13),
    horaSalida: DateTime.utc(2026, 1, 1, 14, 30),
    tiempoTotal: '1h 30min',
    desglose: desglose,
    total: total,
    metodoPago: metodoPago,
    operador: 'Ana',
  );

  Ticket ticketCerrado({required int valorTotal, required List<DesgloseItem> desglose, MetodoPago? metodoPago}) =>
      Ticket(
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
        vehiculo: vehiculo(),
        celda: celda(estado: EstadoCelda.libre),
        recibo: recibo(total: valorTotal, desglose: desglose, metodoPago: metodoPago),
      );

  CobroPreview previewBloques({int valorTotal = 9000}) => CobroPreview(
    valorTotal: valorTotal,
    desglose: [
      DesgloseBloque(
        dia: 1,
        bloqueNumero: 1,
        inicio: DateTime.utc(2026, 1, 1, 13),
        fin: DateTime.utc(2026, 1, 1, 14, 30),
        minutos: 90,
        tipoCobro: TipoCobro.parcial,
        valor: valorTotal,
      ),
    ],
    horaEntrada: DateTime.utc(2026, 1, 1, 13),
    horaSalida: DateTime.utc(2026, 1, 1, 14, 30),
  );

  setUpAll(() async {
    await initializeDateFormatting('es_CO');
  });

  setUp(() {
    ticketRepository = MockTicketRepository();
    celdaRepository = MockCeldaRepository();
    turnoRepository = MockTurnoRepository();
    authRepository = MockAuthRepository();
    when(() => celdaRepository.listarTodas()).thenAnswer((_) async => []);
    when(() => authRepository.restoreSession()).thenAnswer((_) async => operador);
    when(
      () => turnoRepository.listar(
        operadorId: any(named: 'operadorId'),
        estado: any(named: 'estado'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer((_) async => const TurnoPageResult(data: [], page: 1, perPage: 1, total: 0));
    // Default: la mayoría de los tests no le importa el preview, solo que
    // exista uno para que la pantalla no se quede cargando. Los tests que sí
    // lo verifican re-estuban esto con un valor distinto.
    when(() => ticketRepository.previsualizarCobro(any())).thenAnswer((_) async => previewBloques());
  });

  Future<void> pumpSalidaScreen(WidgetTester tester, {TipoVehiculo tipoVehiculo = TipoVehiculo.carro}) async {
    when(() => ticketRepository.obtenerPorId('t1')).thenAnswer((_) async => ticketAbierto(tipoVehiculo: tipoVehiculo));

    final router = GoRouter(
      initialLocation: '/celda',
      routes: [
        GoRoute(
          path: '/celda',
          builder: (context, state) => Scaffold(
            body: Center(
              child: TextButton(onPressed: () => context.push('/salida'), child: const Text('IR_A_SALIDA')),
            ),
          ),
        ),
        GoRoute(path: '/salida', builder: (context, state) => const RegistrarSalidaScreen(ticketId: 't1')),
        GoRoute(
          path: '/turnos/abrir',
          builder: (context, state) =>
              Scaffold(body: Center(child: TextButton(onPressed: () => context.pop(), child: const Text('POP_TURNO')))),
        ),
        GoRoute(path: '/celdas', builder: (context, state) => const Scaffold(body: Text('CELDAS_STUB'))),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ticketRepositoryProvider.overrideWithValue(ticketRepository),
          celdaRepositoryProvider.overrideWithValue(celdaRepository),
          turnoRepositoryProvider.overrideWithValue(turnoRepository),
          authRepositoryProvider.overrideWithValue(authRepository),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('IR_A_SALIDA'));
    await tester.pumpAndSettle();
  }

  testWidgets('muestra los datos del ticket: placa, tipo y celda', (tester) async {
    await pumpSalidaScreen(tester);

    expect(find.textContaining('ABC123'), findsWidgets);
    expect(find.textContaining('Celda: A-01'), findsOneWidget);
    expect(find.textContaining('Tiempo transcurrido'), findsOneWidget);
  });

  testWidgets('muestra el indicador de turno activo antes de intentar la salida', (tester) async {
    await pumpSalidaScreen(tester);

    expect(find.text('Sin turno abierto'), findsOneWidget);
  });

  testWidgets('vehículo tipo OTRO: muestra el campo de valor manual', (tester) async {
    await pumpSalidaScreen(tester, tipoVehiculo: TipoVehiculo.otro);

    expect(find.widgetWithText(TextFormField, 'Valor a cobrar (vehículo tipo Otro)'), findsOneWidget);
  });

  testWidgets('vehículo normal: no muestra el campo de valor manual', (tester) async {
    await pumpSalidaScreen(tester);

    expect(find.widgetWithText(TextFormField, 'Valor a cobrar (vehículo tipo Otro)'), findsNothing);
  });

  testWidgets('cancelar el diálogo de confirmación no llama al repositorio', (tester) async {
    await pumpSalidaScreen(tester);

    await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Registrar salida'));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Registrar salida'));
    await tester.pumpAndSettle();
    expect(find.text('¿Confirmar salida?'), findsOneWidget);

    // Los botones del diálogo donde se confirma el cobro no deben ser más
    // chicos que el resto de botones de la app (mínimo 48dp de alto).
    expect(tester.getSize(find.widgetWithText(TextButton, 'Cancelar')).height, greaterThanOrEqualTo(48));
    expect(tester.getSize(find.widgetWithText(FilledButton, 'Confirmar')).height, greaterThanOrEqualTo(48));

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    verifyNever(
      () => ticketRepository.registrarSalida('t1', metodo: any(named: 'metodo'), valorManual: any(named: 'valorManual')),
    );
    expect(find.widgetWithText(ElevatedButton, 'Registrar salida'), findsOneWidget);
  });

  testWidgets('confirmar: recibo con desglose de bloques', (tester) async {
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

    await pumpSalidaScreen(tester);
    await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Registrar salida'));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Registrar salida'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();

    expect(find.text('Salida registrada'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
    verify(() => ticketRepository.registrarSalida('t1', metodo: null, valorManual: null)).called(1);
  });

  testWidgets('confirmar: recibo con mensualidad muestra el mensaje explícito, no un \$0 sin contexto', (tester) async {
    when(
      () => ticketRepository.registrarSalida('t1', metodo: any(named: 'metodo'), valorManual: any(named: 'valorManual')),
    ).thenAnswer((_) async => ticketCerrado(valorTotal: 0, desglose: const [DesgloseMensualidad()]));

    await pumpSalidaScreen(tester);
    await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Registrar salida'));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Registrar salida'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();

    expect(find.text('Cubierto por mensualidad vigente'), findsOneWidget);
  });

  testWidgets('confirmar con valor manual: recibo con desglose MANUAL', (tester) async {
    when(
      () => ticketRepository.registrarSalida('t1', metodo: any(named: 'metodo'), valorManual: any(named: 'valorManual')),
    ).thenAnswer((_) async => ticketCerrado(valorTotal: 15000, desglose: const [DesgloseManual(valor: 15000)]));

    await pumpSalidaScreen(tester, tipoVehiculo: TipoVehiculo.otro);
    await tester.enterText(find.widgetWithText(TextFormField, 'Valor a cobrar (vehículo tipo Otro)'), '15000');
    await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Registrar salida'));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Registrar salida'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();

    expect(find.text('Valor manual'), findsOneWidget);
    verify(() => ticketRepository.registrarSalida('t1', metodo: null, valorManual: 15000)).called(1);
  });

  testWidgets('422 VALOR_MANUAL_REQUERIDO: vuelve al formulario y permite reintentar', (tester) async {
    when(
      () => ticketRepository.registrarSalida('t1', metodo: any(named: 'metodo'), valorManual: any(named: 'valorManual')),
    ).thenThrow(
      const ApiException(code: 'VALOR_MANUAL_REQUERIDO', message: 'Falta el valor manual', statusCode: 422),
    );

    await pumpSalidaScreen(tester, tipoVehiculo: TipoVehiculo.otro);
    await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Registrar salida'));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Registrar salida'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();

    expect(find.text('Falta el valor manual'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Registrar salida'), findsOneWidget);
  });

  testWidgets('409 OPERADOR_SIN_TURNO_ABIERTO: ofrece abrir turno y navega', (tester) async {
    when(
      () => ticketRepository.registrarSalida('t1', metodo: any(named: 'metodo'), valorManual: any(named: 'valorManual')),
    ).thenThrow(
      const ApiException(code: 'OPERADOR_SIN_TURNO_ABIERTO', message: 'No tiene un turno abierto', statusCode: 409),
    );

    await pumpSalidaScreen(tester);
    await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Registrar salida'));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Registrar salida'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();

    expect(find.text('No tiene un turno abierto'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Abrir turno'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Abrir turno'));
    await tester.pumpAndSettle();

    expect(find.text('POP_TURNO'), findsOneWidget);
  });

  group('preview de cobro (GET /tickets/:id/preview-cobro)', () {
    testWidgets('cobro normal: muestra el desglose por bloque antes de confirmar', (tester) async {
      when(() => ticketRepository.previsualizarCobro('t1')).thenAnswer((_) async => previewBloques());

      await pumpSalidaScreen(tester);

      expect(find.text('Vista previa del cobro'), findsOneWidget);
      expect(find.textContaining('Parcial'), findsOneWidget);
      expect(find.text(formatMoney(9000)), findsWidgets);
    });

    testWidgets('mensualidad vigente: "Cubierto por mensualidad", nunca un \$0 sin contexto', (tester) async {
      when(() => ticketRepository.previsualizarCobro('t1')).thenAnswer(
        (_) async => CobroPreview(
          valorTotal: 0,
          desglose: const [DesgloseMensualidad()],
          horaEntrada: DateTime.utc(2026, 1, 1, 13),
          horaSalida: DateTime.utc(2026, 1, 1, 14, 30),
        ),
      );

      await pumpSalidaScreen(tester);

      expect(find.text('Cubierto por mensualidad vigente'), findsOneWidget);
    });

    testWidgets('vehículo OTRO: indica que el valor lo digita el operador', (tester) async {
      when(() => ticketRepository.previsualizarCobro('t1')).thenAnswer(
        (_) async => CobroPreview(
          valorTotal: null,
          desglose: const [
            DesgloseManual(valor: null, motivo: 'El operador digita el valor al registrar la salida'),
          ],
          horaEntrada: DateTime.utc(2026, 1, 1, 13),
          horaSalida: DateTime.utc(2026, 1, 1, 14, 30),
        ),
      );

      await pumpSalidaScreen(tester, tipoVehiculo: TipoVehiculo.otro);

      expect(find.text('Valor manual'), findsOneWidget);
      expect(find.text('El operador digita el valor al registrar la salida'), findsOneWidget);
      // "Por definir" aparece dos veces: en la fila del item y en el Total.
      expect(find.text('Por definir'), findsNWidgets(2));
    });

    testWidgets('el diálogo de confirmación incluye el monto exacto del preview', (tester) async {
      when(() => ticketRepository.previsualizarCobro('t1')).thenAnswer((_) async => previewBloques(valorTotal: 12345));

      await pumpSalidaScreen(tester);
      await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Registrar salida'));
      await tester.tap(find.widgetWithText(ElevatedButton, 'Registrar salida'));
      await tester.pumpAndSettle();

      expect(
        find.text('El ticket se cerrará con un cobro de ${formatMoney(12345)}. Esta acción no se puede deshacer.'),
        findsOneWidget,
      );
    });

    testWidgets('vehículo OTRO: el diálogo usa el valor que el operador ya escribió', (tester) async {
      await pumpSalidaScreen(tester, tipoVehiculo: TipoVehiculo.otro);
      await tester.enterText(find.widgetWithText(TextFormField, 'Valor a cobrar (vehículo tipo Otro)'), '15000');
      await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Registrar salida'));
      await tester.tap(find.widgetWithText(ElevatedButton, 'Registrar salida'));
      await tester.pumpAndSettle();

      expect(
        find.text('El ticket se cerrará con un cobro de ${formatMoney(15000)}. Esta acción no se puede deshacer.'),
        findsOneWidget,
      );
    });

    testWidgets('ticket cerrado por otro operador mientras tanto (409): bloquea "Registrar salida"', (tester) async {
      when(() => ticketRepository.previsualizarCobro('t1')).thenThrow(
        const ApiException(code: 'TICKET_NO_ABIERTO', message: 'El ticket ya no está abierto', statusCode: 409),
      );

      await pumpSalidaScreen(tester);

      expect(find.text('El ticket ya no está abierto'), findsOneWidget);
      final boton = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Registrar salida'));
      expect(boton.onPressed, isNull);
    });
  });

  group('método de pago efectivo', () {
    // El preview usado en setUp() (previewBloques) calcula un total de 9000.
    Future<void> seleccionarEfectivo(WidgetTester tester) async {
      await tester.tap(find.byType(DropdownButtonFormField<MetodoPago?>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Efectivo').last);
      await tester.pumpAndSettle();
    }

    testWidgets('al elegir Efectivo aparece el campo de monto recibido', (tester) async {
      await pumpSalidaScreen(tester);
      await seleccionarEfectivo(tester);

      expect(find.widgetWithText(TextFormField, 'Monto recibido'), findsOneWidget);
    });

    testWidgets('monto recibido mayor al total: muestra el cambio a devolver en vivo', (tester) async {
      await pumpSalidaScreen(tester);
      await seleccionarEfectivo(tester);

      await tester.enterText(find.widgetWithText(TextFormField, 'Monto recibido'), '10000');
      await tester.pump();

      expect(find.text('Cambio a devolver: ${formatMoney(1000)}'), findsOneWidget);
    });

    testWidgets('monto recibido menor al total: avisa que falta y bloquea "Registrar salida"', (tester) async {
      await pumpSalidaScreen(tester);
      await seleccionarEfectivo(tester);

      await tester.enterText(find.widgetWithText(TextFormField, 'Monto recibido'), '5000');
      await tester.pump();

      expect(find.text('Faltan ${formatMoney(4000)} para cubrir el total'), findsOneWidget);
      final boton = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Registrar salida'));
      expect(boton.onPressed, isNull);
    });

    testWidgets('el diálogo de confirmación incluye cuánto recibe y cuánto cambio debe dar', (tester) async {
      await pumpSalidaScreen(tester);
      await seleccionarEfectivo(tester);
      await tester.enterText(find.widgetWithText(TextFormField, 'Monto recibido'), '10000');
      await tester.pump();

      await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Registrar salida'));
      await tester.tap(find.widgetWithText(ElevatedButton, 'Registrar salida'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'El ticket se cerrará con un cobro de ${formatMoney(9000)}. '
          'Recibe ${formatMoney(10000)} y debe dar ${formatMoney(1000)} de cambio. '
          'Esta acción no se puede deshacer.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('confirmar en efectivo: el resumen final muestra lo recibido y el cambio a devolver', (tester) async {
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
          metodoPago: MetodoPago.efectivo,
        ),
      );

      await pumpSalidaScreen(tester);
      await seleccionarEfectivo(tester);
      await tester.enterText(find.widgetWithText(TextFormField, 'Monto recibido'), '10000');
      await tester.pump();
      await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Registrar salida'));
      await tester.tap(find.widgetWithText(ElevatedButton, 'Registrar salida'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();

      expect(find.text('Recibido: ${formatMoney(10000)}'), findsOneWidget);
      expect(find.text('Cambio a devolver: ${formatMoney(1000)}'), findsOneWidget);
      verify(() => ticketRepository.registrarSalida('t1', metodo: MetodoPago.efectivo, valorManual: null)).called(1);
    });
  });
}
