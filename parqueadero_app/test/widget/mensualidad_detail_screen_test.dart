import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
import 'package:parqueadero_app/features/mensualidades/presentation/mensualidad_detail_screen.dart';

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

  Mensualidad mensualidad({EstadoPagoMensualidad estadoPago = EstadoPagoMensualidad.noPagada}) {
    final ahora = DateTime.now().toUtc();
    return Mensualidad(
      id: 'm1',
      vehiculoId: 'veh1234567',
      celdaId: null,
      fechaInicio: ahora.subtract(const Duration(days: 30)),
      fechaFin: ahora.add(const Duration(days: 60)),
      valorMensualidad: 150000,
      estadoPago: estadoPago,
      fechaPago: null,
      createdAt: ahora,
      updatedAt: ahora,
    );
  }

  setUpAll(() async {
    // formatBogota()/formatMoney() usan locale 'es_CO'; en main() lo hace
    // initializeDateFormatting, que los widget tests nunca ejecutan.
    await initializeDateFormatting('es_CO');
  });

  setUp(() {
    mensualidadRepository = MockMensualidadRepository();
    authRepository = MockAuthRepository();
  });

  Future<void> pumpDetailScreen(
    WidgetTester tester, {
    required RolUsuario rol,
    Mensualidad? mensualidadInicial,
  }) async {
    when(() => authRepository.restoreSession()).thenAnswer((_) async => usuario(rol));
    when(
      () => mensualidadRepository.listar(
        estadoPago: any(named: 'estadoPago'),
        placa: any(named: 'placa'),
        vigencia: any(named: 'vigencia'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer(
      (_) async =>
          MensualidadPageResult(data: [mensualidadInicial ?? mensualidad()], page: 1, perPage: 20, total: 1),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mensualidadRepositoryProvider.overrideWithValue(mensualidadRepository),
          authRepositoryProvider.overrideWithValue(authRepository),
        ],
        child: const MaterialApp(home: MensualidadDetailScreen(mensualidadId: 'm1')),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('OPERADOR: ve el mensaje de acceso restringido', (tester) async {
    await pumpDetailScreen(tester, rol: RolUsuario.operador);

    expect(find.byType(AccesoRestringido), findsOneWidget);
  });

  testWidgets('mensualidad no encontrada en la lista: muestra el mensaje correspondiente', (tester) async {
    when(() => authRepository.restoreSession()).thenAnswer((_) async => usuario(RolUsuario.admin));
    when(
      () => mensualidadRepository.listar(
        estadoPago: any(named: 'estadoPago'),
        placa: any(named: 'placa'),
        vigencia: any(named: 'vigencia'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer((_) async => const MensualidadPageResult(data: [], page: 1, perPage: 20, total: 0));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mensualidadRepositoryProvider.overrideWithValue(mensualidadRepository),
          authRepositoryProvider.overrideWithValue(authRepository),
        ],
        child: const MaterialApp(home: MensualidadDetailScreen(mensualidadId: 'm1')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(EmptyState), findsOneWidget);
  });

  testWidgets('listado con error: muestra ErrorState con el mensaje del backend, no "no encontrada"', (
    tester,
  ) async {
    when(() => authRepository.restoreSession()).thenAnswer((_) async => usuario(RolUsuario.admin));
    when(
      () => mensualidadRepository.listar(
        estadoPago: any(named: 'estadoPago'),
        placa: any(named: 'placa'),
        vigencia: any(named: 'vigencia'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenThrow(const ApiException(code: 'INTERNAL_ERROR', message: 'Error de red', statusCode: 500));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mensualidadRepositoryProvider.overrideWithValue(mensualidadRepository),
          authRepositoryProvider.overrideWithValue(authRepository),
        ],
        child: const MaterialApp(home: MensualidadDetailScreen(mensualidadId: 'm1')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ErrorState), findsOneWidget);
    expect(find.text('Error de red'), findsOneWidget);
    expect(find.text('Mensualidad no encontrada.'), findsNothing);
  });

  testWidgets('listado con error: tocar Reintentar vuelve a pedir el listado', (tester) async {
    when(() => authRepository.restoreSession()).thenAnswer((_) async => usuario(RolUsuario.admin));
    when(
      () => mensualidadRepository.listar(
        estadoPago: any(named: 'estadoPago'),
        placa: any(named: 'placa'),
        vigencia: any(named: 'vigencia'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenThrow(const ApiException(code: 'INTERNAL_ERROR', message: 'Error de red', statusCode: 500));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mensualidadRepositoryProvider.overrideWithValue(mensualidadRepository),
          authRepositoryProvider.overrideWithValue(authRepository),
        ],
        child: const MaterialApp(home: MensualidadDetailScreen(mensualidadId: 'm1')),
      ),
    );
    await tester.pumpAndSettle();

    when(
      () => mensualidadRepository.listar(
        estadoPago: any(named: 'estadoPago'),
        placa: any(named: 'placa'),
        vigencia: any(named: 'vigencia'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer((_) async => MensualidadPageResult(data: [mensualidad()], page: 1, perPage: 20, total: 1));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Reintentar'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ElevatedButton, 'Cancelar mensualidad'), findsOneWidget);
  });

  testWidgets('NO_PAGADA: muestra únicamente el botón de cancelar', (tester) async {
    await pumpDetailScreen(tester, rol: RolUsuario.admin);

    expect(find.widgetWithText(ElevatedButton, 'Cancelar mensualidad'), findsOneWidget);
  });

  testWidgets('los chips de estado llevan el mismo tag de Hero que el listado', (tester) async {
    await pumpDetailScreen(tester, rol: RolUsuario.admin);

    final tags = tester.widgetList<Hero>(find.byType(Hero)).map((h) => h.tag).toSet();
    expect(tags, {'mensualidad-pago-m1', 'mensualidad-vigencia-m1'});
  });

  testWidgets('CANCELADA: no muestra ningún botón de acción', (tester) async {
    await pumpDetailScreen(
      tester,
      rol: RolUsuario.admin,
      mensualidadInicial: mensualidad(estadoPago: EstadoPagoMensualidad.cancelada),
    );

    expect(find.widgetWithText(ElevatedButton, 'Cancelar mensualidad'), findsNothing);
  });

  testWidgets('cancelar: pide confirmación antes de llamar al repositorio', (tester) async {
    await pumpDetailScreen(tester, rol: RolUsuario.admin);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Cancelar mensualidad'));
    await tester.pumpAndSettle();

    expect(find.text('¿Cancelar mensualidad?'), findsOneWidget);
    verifyNever(() => mensualidadRepository.cancelar(any()));

    when(
      () => mensualidadRepository.cancelar('m1'),
    ).thenAnswer((_) async => mensualidad(estadoPago: EstadoPagoMensualidad.cancelada));
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();

    verify(() => mensualidadRepository.cancelar('m1')).called(1);
    expect(find.widgetWithText(ElevatedButton, 'Cancelar mensualidad'), findsNothing);
  });

  testWidgets('cancelar cancelado en el diálogo: no llama al repositorio', (tester) async {
    await pumpDetailScreen(tester, rol: RolUsuario.admin);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Cancelar mensualidad'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar').last);
    await tester.pumpAndSettle();

    verifyNever(() => mensualidadRepository.cancelar(any()));
    expect(find.widgetWithText(ElevatedButton, 'Cancelar mensualidad'), findsOneWidget);
  });
}
