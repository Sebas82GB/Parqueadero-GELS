import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:parqueadero_app/core/network/api_exception.dart';
import 'package:parqueadero_app/core/widgets/acceso_restringido.dart';
import 'package:parqueadero_app/core/widgets/empty_state.dart';
import 'package:parqueadero_app/core/widgets/error_state.dart';
import 'package:parqueadero_app/features/auth/data/auth_repository_impl.dart';
import 'package:parqueadero_app/features/auth/domain/auth_repository.dart';
import 'package:parqueadero_app/features/auth/domain/usuario.dart';
import 'package:parqueadero_app/features/mensualidades/data/mensualidad_repository_impl.dart';
import 'package:parqueadero_app/features/mensualidades/domain/mensualidad.dart';
import 'package:parqueadero_app/features/mensualidades/domain/mensualidad_repository.dart';
import 'package:parqueadero_app/features/mensualidades/presentation/mensualidades_screen.dart';

class MockMensualidadRepository extends Mock implements MensualidadRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockMensualidadRepository mensualidadRepository;
  late MockAuthRepository authRepository;

  Usuario usuario(RolUsuario rol) => Usuario(
    id: 'u1',
    nombre: 'Ana',
    email: 'ana@test.com',
    rol: rol,
    activo: true,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  // Fechas relativas a "ahora" (no fijas) para que el semáforo mostrado no
  // dependa de la fecha real en la que corran los tests.
  Mensualidad mensualidad(
    String id, {
    EstadoPagoMensualidad estadoPago = EstadoPagoMensualidad.noPagada,
    DateTime? fechaFin,
  }) {
    final ahora = DateTime.now().toUtc();
    return Mensualidad(
      id: id,
      vehiculoId: 'veh1234567',
      celdaId: null,
      fechaInicio: ahora.subtract(const Duration(days: 30)),
      fechaFin: fechaFin ?? ahora.add(const Duration(days: 60)),
      valorMensualidad: 150000,
      estadoPago: estadoPago,
      fechaPago: null,
      createdAt: ahora,
      updatedAt: ahora,
    );
  }

  setUpAll(() async {
    await initializeDateFormatting('es_CO');
  });

  setUp(() {
    mensualidadRepository = MockMensualidadRepository();
    authRepository = MockAuthRepository();
  });

  void stubListar({List<Mensualidad> data = const [], int total = 0}) {
    when(
      () => mensualidadRepository.listar(
        estadoPago: any(named: 'estadoPago'),
        placa: any(named: 'placa'),
        vigencia: any(named: 'vigencia'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer(
      (invocation) async => MensualidadPageResult(
        data: data,
        page: invocation.namedArguments[#page] as int,
        perPage: 20,
        total: total,
      ),
    );
  }

  Future<GoRouter> pumpMensualidadesScreen(WidgetTester tester, {RolUsuario rol = RolUsuario.admin}) async {
    when(() => authRepository.restoreSession()).thenAnswer((_) async => usuario(rol));
    final router = GoRouter(
      initialLocation: '/mensualidades',
      routes: [
        GoRoute(path: '/mensualidades', builder: (context, state) => const MensualidadesScreen()),
        GoRoute(
          path: '/mensualidades/:id',
          builder: (context, state) => Scaffold(body: Text('DETALLE_${state.pathParameters['id']}')),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mensualidadRepositoryProvider.overrideWithValue(mensualidadRepository),
          authRepositoryProvider.overrideWithValue(authRepository),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('OPERADOR: ve el mensaje de acceso restringido', (tester) async {
    stubListar();
    await pumpMensualidadesScreen(tester, rol: RolUsuario.operador);

    expect(find.byType(AccesoRestringido), findsOneWidget);
  });

  testWidgets('ADMIN vacío: muestra el mensaje de vacío', (tester) async {
    stubListar();
    await pumpMensualidadesScreen(tester);

    expect(find.byType(EmptyState), findsOneWidget);
  });

  testWidgets('ADMIN error: muestra el mensaje del backend con reintentar', (tester) async {
    when(
      () => mensualidadRepository.listar(
        estadoPago: any(named: 'estadoPago'),
        placa: any(named: 'placa'),
        vigencia: any(named: 'vigencia'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenThrow(const ApiException(code: 'UNKNOWN', message: 'No hay conexión con el servidor.', statusCode: 0));

    await pumpMensualidadesScreen(tester);

    expect(find.byType(ErrorState), findsOneWidget);
  });

  testWidgets('con datos: tap en una mensualidad navega al detalle', (tester) async {
    stubListar(data: [mensualidad('m1')], total: 1);

    await pumpMensualidadesScreen(tester);
    await tester.tap(find.byType(ListTile));
    await tester.pumpAndSettle();

    expect(find.text('DETALLE_m1'), findsOneWidget);
  });

  testWidgets('con datos: muestra "Cargar más" cuando hayMas', (tester) async {
    stubListar(data: [mensualidad('m1')], total: 2);

    await pumpMensualidadesScreen(tester);

    expect(find.widgetWithText(ElevatedButton, 'Cargar más'), findsOneWidget);
  });

  testWidgets('mensualidad cancelada: no duplica el chip de vigencia', (tester) async {
    stubListar(
      data: [
        mensualidad(
          'm1',
          estadoPago: EstadoPagoMensualidad.cancelada,
          fechaFin: DateTime.now().toUtc().subtract(const Duration(days: 10)),
        ),
      ],
      total: 1,
    );

    await pumpMensualidadesScreen(tester);

    expect(find.text('Cancelada'), findsOneWidget);
  });

  testWidgets('mensualidad activa y vencida: muestra el chip de estado y el de vigencia', (tester) async {
    stubListar(
      data: [mensualidad('m1', fechaFin: DateTime.now().toUtc().subtract(const Duration(days: 10)))],
      total: 1,
    );

    await pumpMensualidadesScreen(tester);

    expect(find.text('No pagada'), findsOneWidget);
    expect(find.text('Vencida'), findsOneWidget);
  });

  testWidgets('cambiar el filtro de estado de pago vuelve a pedir la página 1', (tester) async {
    stubListar(data: [mensualidad('m1')], total: 1);

    await pumpMensualidadesScreen(tester);
    await tester.tap(find.text('Todos los estados'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pagada').last);
    await tester.pumpAndSettle();

    verify(
      () => mensualidadRepository.listar(
        estadoPago: EstadoPagoMensualidad.pagada,
        placa: any(named: 'placa'),
        vigencia: any(named: 'vigencia'),
        page: 1,
        perPage: any(named: 'perPage'),
      ),
    ).called(1);
  });
}
