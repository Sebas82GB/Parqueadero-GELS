import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:parqueadero_app/core/domain/tipo_vehiculo.dart';
import 'package:parqueadero_app/core/network/api_exception.dart';
import 'package:parqueadero_app/core/theme/app_breakpoints.dart';
import 'package:parqueadero_app/core/theme/app_typography.dart';
import 'package:parqueadero_app/core/utils/money.dart';
import 'package:parqueadero_app/core/widgets/error_banner.dart';
import 'package:parqueadero_app/core/widgets/loading_skeleton.dart';
import 'package:parqueadero_app/features/auth/data/auth_repository_impl.dart';
import 'package:parqueadero_app/features/auth/domain/auth_repository.dart';
import 'package:parqueadero_app/features/auth/domain/usuario.dart';
import 'package:parqueadero_app/features/celdas/presentation/widgets/celda_accion_rapida_sheet.dart';
import 'package:parqueadero_app/features/tickets/data/ticket_repository_impl.dart';
import 'package:parqueadero_app/features/tickets/domain/cobro_preview.dart';
import 'package:parqueadero_app/features/tickets/domain/desglose_item.dart';
import 'package:parqueadero_app/features/tickets/domain/pago.dart';
import 'package:parqueadero_app/features/tickets/domain/recibo.dart';
import 'package:parqueadero_app/features/tickets/domain/ticket.dart';
import 'package:parqueadero_app/features/tickets/domain/ticket_repository.dart';
import 'package:parqueadero_app/features/tickets/domain/vehiculo.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockTicketRepository extends Mock implements TicketRepository {}

void main() {
  late MockAuthRepository authRepository;
  late MockTicketRepository ticketRepository;

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
    id: 'v1',
    placa: 'ABC123',
    tipo: tipo,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  final establecimiento = Establecimiento(
    nombre: 'Parqueadero',
    nit: '123',
    direccion: 'Calle 1',
    telefono: '123',
    ciudad: 'Bogotá',
    regimenTributario: 'Régimen común',
    numeroResolucion: '1',
    textoResponsabilidad: 'Responsable',
    textoSeguro: 'Seguro',
    textoHorario: 'Horario',
    textoReclamos: 'Reclamos',
  );

  Recibo recibo() => Recibo(
    consecutivo: 1,
    fechaEmision: DateTime.utc(2026, 1, 1),
    establecimiento: establecimiento,
    placa: 'ABC123',
    tipoVehiculo: TipoVehiculo.carro,
    celda: 'A-01',
    horaEntrada: DateTime.utc(2026, 1, 1),
    horaSalida: DateTime.utc(2026, 1, 1, 1),
    tiempoTotal: '1h',
    desglose: const [],
    total: 5000,
    metodoPago: MetodoPago.efectivo,
    operador: 'Ana',
  );

  Ticket ticket({TipoVehiculo tipo = TipoVehiculo.carro, Recibo? recibo}) =>
      Ticket(
        id: 't1',
        codigo: 'T-1',
        vehiculoId: 'v1',
        celdaId: 'c1',
        horaEntrada: DateTime.now().toUtc().subtract(const Duration(hours: 1)),
        tarifaId: 'tarifa1',
        estado: EstadoTicket.abierto,
        operadorEntradaId: 'op1',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
        vehiculo: vehiculo(tipo: tipo),
        recibo: recibo,
      );

  setUpAll(() async {
    // formatMoney() usa NumberFormat con locale 'es_CO'; en main() lo hace
    // initializeDateFormatting, que los widget tests nunca ejecutan.
    await initializeDateFormatting('es_CO');
  });

  setUp(() {
    authRepository = MockAuthRepository();
    ticketRepository = MockTicketRepository();
    when(
      () => authRepository.restoreSession(),
    ).thenAnswer((_) async => operador);
  });

  void stubTicketAbierto(Ticket t) {
    when(
      () => ticketRepository.listar(
        celdaId: 'c1',
        estado: EstadoTicket.abierto,
        perPage: 1,
      ),
    ).thenAnswer(
      (_) async => TicketPageResult(data: [t], page: 1, perPage: 1, total: 1),
    );
    when(() => ticketRepository.obtenerPorId(t.id)).thenAnswer((_) async => t);
  }

  String? rutaVisitada;

  Future<void> pumpSheet(WidgetTester tester) async {
    rutaVisitada = null;
    final router = GoRouter(
      initialLocation: '/celdas',
      routes: [
        GoRoute(
          path: '/celdas',
          builder: (context, state) => Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showCeldaAccionRapida(context, 'c1'),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/tickets',
          builder: (context, state) {
            rutaVisitada = '/tickets';
            return const Scaffold(body: Text('HISTORIAL'));
          },
        ),
        GoRoute(
          path: '/tickets/:id/salida',
          builder: (context, state) {
            rutaVisitada = '/tickets/${state.pathParameters['id']}/salida';
            return const Scaffold(body: Text('SALIDA'));
          },
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepository),
          ticketRepositoryProvider.overrideWithValue(ticketRepository),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('buscando ticket: muestra el skeleton y no un CircularProgressIndicator principal', (tester) async {
    final completer = Completer<TicketPageResult>();
    when(
      () => ticketRepository.listar(
        celdaId: 'c1',
        estado: EstadoTicket.abierto,
        perPage: 1,
      ),
    ).thenAnswer((_) => completer.future);

    rutaVisitada = null;
    final router = GoRouter(
      initialLocation: '/celdas',
      routes: [
        GoRoute(
          path: '/celdas',
          builder: (context, state) => Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showCeldaAccionRapida(context, 'c1'),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepository),
          ticketRepositoryProvider.overrideWithValue(ticketRepository),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('abrir'));
    await tester.pump();

    expect(find.byType(LoadingSkeleton), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    completer.complete(const TicketPageResult(data: [], page: 1, perPage: 1, total: 0));
    await tester.pumpAndSettle();
  });

  testWidgets('sin ticket abierto: muestra el mensaje, no un panel vacío', (
    tester,
  ) async {
    when(
      () => ticketRepository.listar(
        celdaId: 'c1',
        estado: EstadoTicket.abierto,
        perPage: 1,
      ),
    ).thenAnswer(
      (_) async =>
          const TicketPageResult(data: [], page: 1, perPage: 1, total: 0),
    );

    await pumpSheet(tester);

    expect(
      find.text('No se encontró un ticket abierto para esta celda.'),
      findsOneWidget,
    );
  });

  // Regresión responsive: el viewport de test por defecto (800×600) ya cae
  // en la rama ancha, así que sin estos dos tests ningún test del archivo
  // ejercita realmente la rama angosta (bottom sheet).
  group('responsive según ancho de pantalla', () {
    setUp(() {
      when(
        () => ticketRepository.listar(
          celdaId: 'c1',
          estado: EstadoTicket.abierto,
          perPage: 1,
        ),
      ).thenAnswer(
        (_) async =>
            const TicketPageResult(data: [], page: 1, perPage: 1, total: 0),
      );
    });

    Future<void> conAncho(WidgetTester tester, double width) async {
      final view = tester.view;
      view.physicalSize = Size(width, 800);
      view.devicePixelRatio = 1.0;
      addTearDown(view.resetPhysicalSize);
      addTearDown(view.resetDevicePixelRatio);
      await pumpSheet(tester);
    }

    testWidgets(
      'angosta (<600, móvil): bottom sheet pegado abajo, con handle',
      (tester) async {
        await conAncho(tester, 375);

        expect(find.byType(BottomSheet), findsOneWidget);
        expect(find.byType(Dialog), findsNothing);
      },
    );

    testWidgets(
      'ancha (≥600, web/escritorio): diálogo centrado con ancho máximo, sin handle',
      (tester) async {
        await conAncho(tester, 1200);

        expect(find.byType(Dialog), findsOneWidget);
        expect(find.byType(BottomSheet), findsNothing);

        final constraintBox = tester.widget<ConstrainedBox>(
          find
              .ancestor(
                of: find.byType(CeldaAccionRapidaSheet),
                matching: find.byType(ConstrainedBox),
              )
              .first,
        );
        expect(
          constraintBox.constraints.maxWidth,
          AppBreakpoints.contentMaxWidth,
        );
        expect(
          constraintBox.constraints.maxHeight,
          tester.view.physicalSize.height * 0.9,
        );
      },
    );
  });

  testWidgets(
    'con ticket abierto: muestra placa, celda y el monto del preview',
    (tester) async {
      stubTicketAbierto(ticket());
      when(() => ticketRepository.previsualizarCobro('t1')).thenAnswer(
        (_) async => CobroPreview(
          valorTotal: 5000,
          desglose: const [],
          horaEntrada: DateTime.utc(2026, 1, 1),
          horaSalida: DateTime.utc(2026, 1, 1, 1),
        ),
      );

      await pumpSheet(tester);

      expect(find.text('ABC123'), findsOneWidget);
      expect(find.textContaining('Celda'), findsOneWidget);
      expect(find.text(formatMoney(5000)), findsNWidgets(2));
    },
  );

  testWidgets('con preview cargado: muestra el desglose sin pulsar nada', (
    tester,
  ) async {
    stubTicketAbierto(ticket());
    when(() => ticketRepository.previsualizarCobro('t1')).thenAnswer(
      (_) async => CobroPreview(
        valorTotal: 5000,
        desglose: [
          DesgloseBloque(
            dia: 1,
            bloqueNumero: 1,
            inicio: DateTime.utc(2026, 1, 1, 8),
            fin: DateTime.utc(2026, 1, 1, 9),
            minutos: 60,
            tipoCobro: TipoCobro.parcial,
            valor: 5000,
          ),
        ],
        horaEntrada: DateTime.utc(2026, 1, 1),
        horaSalida: DateTime.utc(2026, 1, 1, 1),
      ),
    );

    await pumpSheet(tester);

    expect(find.textContaining('bloque 1'), findsOneWidget);
    expect(find.text('Ver detalle de factura'), findsNothing);
  });

  testWidgets('el monto total usa AppTypography.montoDestacado', (tester) async {
    stubTicketAbierto(ticket());
    when(() => ticketRepository.previsualizarCobro('t1')).thenAnswer(
      (_) async => CobroPreview(
        valorTotal: 5000,
        desglose: const [],
        horaEntrada: DateTime.utc(2026, 1, 1),
        horaSalida: DateTime.utc(2026, 1, 1, 1),
      ),
    );

    await pumpSheet(tester);

    final monto = tester.widget<Text>(find.text(formatMoney(5000)).first);
    expect(monto.style?.fontSize, AppTypography.montoDestacado.fontSize);
    expect(monto.style?.fontWeight, AppTypography.montoDestacado.fontWeight);
  });

  testWidgets(
    'cobrar: llama a registrarSalida con el método elegido y cierra el panel',
    (tester) async {
      stubTicketAbierto(ticket());
      when(() => ticketRepository.previsualizarCobro('t1')).thenAnswer(
        (_) async => CobroPreview(
          valorTotal: 5000,
          desglose: const [],
          horaEntrada: DateTime.utc(2026, 1, 1),
          horaSalida: DateTime.utc(2026, 1, 1, 1),
        ),
      );
      when(
        () => ticketRepository.registrarSalida(
          't1',
          metodo: any(named: 'metodo'),
          valorManual: any(named: 'valorManual'),
        ),
      ).thenAnswer((_) async => ticket(recibo: recibo()));

      await pumpSheet(tester);
      await tester.tap(find.text('Efectivo'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '10000');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cobrar ${formatMoney(5000)}'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();

      verify(
        () => ticketRepository.registrarSalida(
          't1',
          metodo: MetodoPago.efectivo,
          valorManual: null,
        ),
      ).called(1);
      expect(find.byType(CeldaAccionRapidaSheet), findsNothing);
    },
  );

  testWidgets('cobrar: muestra confirmación y no cobra antes de confirmar', (
    tester,
  ) async {
    stubTicketAbierto(ticket());
    when(() => ticketRepository.previsualizarCobro('t1')).thenAnswer(
      (_) async => CobroPreview(
        valorTotal: 5000,
        desglose: const [],
        horaEntrada: DateTime.utc(2026, 1, 1),
        horaSalida: DateTime.utc(2026, 1, 1, 1),
      ),
    );

    await pumpSheet(tester);
    await tester.tap(find.text('Cobrar ${formatMoney(5000)}'));
    await tester.pumpAndSettle();

    expect(find.text('¿Confirmar salida?'), findsOneWidget);
    verifyNever(
      () => ticketRepository.registrarSalida(
        any(),
        metodo: any(named: 'metodo'),
        valorManual: any(named: 'valorManual'),
      ),
    );
  });

  testWidgets('cobrar: cancelar no cobra y mantiene el panel abierto', (
    tester,
  ) async {
    stubTicketAbierto(ticket());
    when(() => ticketRepository.previsualizarCobro('t1')).thenAnswer(
      (_) async => CobroPreview(
        valorTotal: 5000,
        desglose: const [],
        horaEntrada: DateTime.utc(2026, 1, 1),
        horaSalida: DateTime.utc(2026, 1, 1, 1),
      ),
    );

    await pumpSheet(tester);
    await tester.tap(find.text('Cobrar ${formatMoney(5000)}'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    verifyNever(
      () => ticketRepository.registrarSalida(
        any(),
        metodo: any(named: 'metodo'),
        valorManual: any(named: 'valorManual'),
      ),
    );
    expect(find.byType(CeldaAccionRapidaSheet), findsOneWidget);
  });

  testWidgets('cobrar: el botón muestra el monto del preview', (tester) async {
    stubTicketAbierto(ticket());
    when(() => ticketRepository.previsualizarCobro('t1')).thenAnswer(
      (_) async => CobroPreview(
        valorTotal: 5000,
        desglose: const [],
        horaEntrada: DateTime.utc(2026, 1, 1),
        horaSalida: DateTime.utc(2026, 1, 1, 1),
      ),
    );

    await pumpSheet(tester);

    expect(find.text('Cobrar ${formatMoney(5000)}'), findsOneWidget);
  });

  testWidgets(
    'tipo OTRO: el botón navega al formulario completo en vez de cobrar',
    (tester) async {
      stubTicketAbierto(ticket(tipo: TipoVehiculo.otro));
      when(() => ticketRepository.previsualizarCobro('t1')).thenAnswer(
        (_) async => CobroPreview(
          valorTotal: null,
          desglose: const [],
          horaEntrada: DateTime.utc(2026, 1, 1),
          horaSalida: DateTime.utc(2026, 1, 1, 1),
        ),
      );

      await pumpSheet(tester);

      expect(find.text('Ir a registrar salida'), findsOneWidget);
      await tester.tap(find.text('Ir a registrar salida'));
      await tester.pumpAndSettle();

      expect(rutaVisitada, '/tickets/t1/salida');
      verifyNever(
        () => ticketRepository.registrarSalida(
          any(),
          metodo: any(named: 'metodo'),
          valorManual: any(named: 'valorManual'),
        ),
      );
    },
  );

  testWidgets('error al cobrar: muestra el mensaje y no cierra el panel', (
    tester,
  ) async {
    stubTicketAbierto(ticket());
    when(() => ticketRepository.previsualizarCobro('t1')).thenAnswer(
      (_) async => CobroPreview(
        valorTotal: 5000,
        desglose: const [],
        horaEntrada: DateTime.utc(2026, 1, 1),
        horaSalida: DateTime.utc(2026, 1, 1, 1),
      ),
    );
    when(
      () => ticketRepository.registrarSalida(
        any(),
        metodo: any(named: 'metodo'),
        valorManual: any(named: 'valorManual'),
      ),
    ).thenThrow(
      const ApiException(
        code: 'OPERADOR_SIN_TURNO_ABIERTO',
        message: 'No tienes un turno abierto',
        statusCode: 409,
      ),
    );

    await pumpSheet(tester);
    await tester.tap(find.text('Cobrar ${formatMoney(5000)}'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();

    expect(find.text('No tienes un turno abierto'), findsOneWidget);
    expect(find.byType(CeldaAccionRapidaSheet), findsOneWidget);
  });

  testWidgets('cobrar exitoso: muestra el SnackBar con placa y monto', (
    tester,
  ) async {
    stubTicketAbierto(ticket());
    when(() => ticketRepository.previsualizarCobro('t1')).thenAnswer(
      (_) async => CobroPreview(
        valorTotal: 5000,
        desglose: const [],
        horaEntrada: DateTime.utc(2026, 1, 1),
        horaSalida: DateTime.utc(2026, 1, 1, 1),
      ),
    );
    when(
      () => ticketRepository.registrarSalida(
        't1',
        metodo: any(named: 'metodo'),
        valorManual: any(named: 'valorManual'),
      ),
    ).thenAnswer((_) async => ticket(recibo: recibo()));

    await pumpSheet(tester);
    await tester.tap(find.text('Cobrar ${formatMoney(5000)}'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();

    expect(
      find.text('Salida registrada · ABC123 · ${formatMoney(5000)} cobrados'),
      findsOneWidget,
    );
    expect(find.text('Ver recibo'), findsOneWidget);
  });

  testWidgets('error al cobrar: renderiza ErrorBanner', (tester) async {
    stubTicketAbierto(ticket());
    when(() => ticketRepository.previsualizarCobro('t1')).thenAnswer(
      (_) async => CobroPreview(
        valorTotal: 5000,
        desglose: const [],
        horaEntrada: DateTime.utc(2026, 1, 1),
        horaSalida: DateTime.utc(2026, 1, 1, 1),
      ),
    );
    when(
      () => ticketRepository.registrarSalida(
        any(),
        metodo: any(named: 'metodo'),
        valorManual: any(named: 'valorManual'),
      ),
    ).thenThrow(
      const ApiException(
        code: 'OPERADOR_SIN_TURNO_ABIERTO',
        message: 'No tienes un turno abierto',
        statusCode: 409,
      ),
    );

    await pumpSheet(tester);
    await tester.tap(find.text('Cobrar ${formatMoney(5000)}'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();

    expect(find.byType(ErrorBanner), findsOneWidget);
  });

  testWidgets(
    'el sheet se cierra durante el cobro: igual se muestra el snackbar con el recibo',
    (tester) async {
      stubTicketAbierto(ticket());
      when(() => ticketRepository.previsualizarCobro('t1')).thenAnswer(
        (_) async => CobroPreview(
          valorTotal: 5000,
          desglose: const [],
          horaEntrada: DateTime.utc(2026, 1, 1),
          horaSalida: DateTime.utc(2026, 1, 1, 1),
        ),
      );
      // La salida queda EN VUELO a propósito: es la ventana en la que el
      // operador puede cerrar (o arrastrar sin querer) el panel.
      final salidaEnVuelo = Completer<Ticket>();
      when(
        () => ticketRepository.registrarSalida(
          't1',
          metodo: any(named: 'metodo'),
          valorManual: any(named: 'valorManual'),
        ),
      ).thenAnswer((_) => salidaEnVuelo.future);

      await pumpSheet(tester);
      await tester.tap(find.text('Cobrar ${formatMoney(5000)}'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmar'));
      await tester.pump();

      // Con el POST todavía sin responder, el operador cierra el panel.
      final contextoDelSheet = tester.element(
        find.byType(CeldaAccionRapidaSheet),
      );
      Navigator.of(contextoDelSheet).pop();
      await tester.pumpAndSettle();
      expect(find.byType(CeldaAccionRapidaSheet), findsNothing);

      // Ahora responde el backend: el cobro ocurrió, el operador tiene que
      // verlo confirmado aunque el panel que lo lanzó ya no exista.
      salidaEnVuelo.complete(ticket(recibo: recibo()));
      await tester.pumpAndSettle();

      expect(
        find.text('Salida registrada · ABC123 · ${formatMoney(5000)} cobrados'),
        findsOneWidget,
      );
      expect(find.text('Ver recibo'), findsOneWidget);
    },
  );
}
