import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:parqueadero_app/core/network/api_exception.dart';
import 'package:parqueadero_app/core/utils/money.dart';
import 'package:parqueadero_app/core/widgets/detail_skeleton.dart';
import 'package:parqueadero_app/features/auth/data/auth_repository_impl.dart';
import 'package:parqueadero_app/features/auth/domain/auth_repository.dart';
import 'package:parqueadero_app/features/auth/domain/usuario.dart';
import 'package:parqueadero_app/features/turnos/data/turno_repository_impl.dart';
import 'package:parqueadero_app/features/turnos/domain/arqueo_turno.dart';
import 'package:parqueadero_app/features/turnos/domain/turno.dart';
import 'package:parqueadero_app/features/turnos/domain/turno_repository.dart';
import 'package:parqueadero_app/features/turnos/presentation/turno_cierre_screen.dart';

class MockTurnoRepository extends Mock implements TurnoRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockTurnoRepository turnoRepository;
  late MockAuthRepository authRepository;

  Usuario operador() => Usuario(
    id: 'op1',
    nombre: 'Ana',
    email: 'ana@test.com',
    rol: RolUsuario.operador,
    activo: true,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  ArqueoTurno arqueoEnVivo({int efectivoEsperado = 65000}) => ArqueoTurno(
    turnoId: 'tur1',
    operadorId: 'op1',
    estado: EstadoTurno.abierto,
    apertura: DateTime.utc(2026, 1, 1, 6),
    baseInicial: 50000,
    totalesPorMetodo: const TotalesPorMetodo(efectivo: 15000, tarjeta: 20000, transferencia: 0),
    totalRecaudado: 35000,
    ticketsCerrados: 4,
    efectivoEsperado: efectivoEsperado,
  );

  ArqueoTurno arqueoPendiente({int efectivoEsperado = 65000}) => ArqueoTurno(
    turnoId: 'tur1',
    operadorId: 'op1',
    estado: EstadoTurno.cerradoPendienteArqueo,
    apertura: DateTime.utc(2026, 1, 1, 6),
    cierre: DateTime.utc(2026, 1, 1, 14),
    baseInicial: 50000,
    totalesPorMetodo: const TotalesPorMetodo(efectivo: 15000, tarjeta: 20000, transferencia: 0),
    totalRecaudado: 35000,
    ticketsCerrados: 4,
    efectivoEsperado: efectivoEsperado,
  );

  ArqueoTurno arqueoFinal({required int efectivoContado, required int diferencia}) => ArqueoTurno(
    turnoId: 'tur1',
    operadorId: 'op1',
    estado: EstadoTurno.cerrado,
    apertura: DateTime.utc(2026, 1, 1, 6),
    cierre: DateTime.utc(2026, 1, 1, 14),
    baseInicial: 50000,
    totalesPorMetodo: const TotalesPorMetodo(efectivo: 15000, tarjeta: 20000, transferencia: 0),
    totalRecaudado: 35000,
    ticketsCerrados: 4,
    efectivoEsperado: 65000,
    efectivoContado: efectivoContado,
    diferencia: diferencia,
  );

  setUpAll(() async {
    await initializeDateFormatting('es_CO');
  });

  setUp(() {
    turnoRepository = MockTurnoRepository();
    authRepository = MockAuthRepository();
    when(() => authRepository.restoreSession()).thenAnswer((_) async => operador());
    when(
      () => turnoRepository.listar(
        operadorId: any(named: 'operadorId'),
        estado: any(named: 'estado'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer((_) async => const TurnoPageResult(data: [], page: 1, perPage: 1, total: 0));
  });

  Future<void> pumpCierre(WidgetTester tester) async {
    when(() => turnoRepository.obtenerArqueo('tur1')).thenAnswer((_) async => arqueoEnVivo());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          turnoRepositoryProvider.overrideWithValue(turnoRepository),
          authRepositoryProvider.overrideWithValue(authRepository),
        ],
        child: const MaterialApp(home: TurnoCierreScreen(turnoId: 'tur1')),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pumpCierrePendiente(WidgetTester tester) async {
    when(() => turnoRepository.obtenerArqueo('tur1')).thenAnswer((_) async => arqueoPendiente());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          turnoRepositoryProvider.overrideWithValue(turnoRepository),
          authRepositoryProvider.overrideWithValue(authRepository),
        ],
        child: const MaterialApp(home: TurnoCierreScreen(turnoId: 'tur1')),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('cargando: muestra el skeleton y no un CircularProgressIndicator', (tester) async {
    final completer = Completer<ArqueoTurno>();
    when(() => turnoRepository.obtenerArqueo('tur1')).thenAnswer((_) => completer.future);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          turnoRepositoryProvider.overrideWithValue(turnoRepository),
          authRepositoryProvider.overrideWithValue(authRepository),
        ],
        child: const MaterialApp(home: TurnoCierreScreen(turnoId: 'tur1')),
      ),
    );
    await tester.pump();

    expect(find.byType(DetailSkeleton), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    completer.complete(arqueoEnVivo());
    await tester.pumpAndSettle();
  });

  testWidgets('muestra el efectivo esperado del arqueo en vivo', (tester) async {
    await pumpCierre(tester);

    expect(find.textContaining(formatMoney(65000)), findsOneWidget);
  });

  testWidgets('sobrante: la diferencia se recalcula en vivo mientras se escribe', (tester) async {
    await pumpCierre(tester);

    await tester.enterText(find.widgetWithText(TextFormField, 'Efectivo contado'), '70000');
    await tester.pump();

    expect(find.textContaining('Sobrante: +'), findsOneWidget);
  });

  testWidgets('faltante: la diferencia se recalcula en vivo mientras se escribe', (tester) async {
    await pumpCierre(tester);

    await tester.enterText(find.widgetWithText(TextFormField, 'Efectivo contado'), '60000');
    await tester.pump();

    expect(find.textContaining('Faltante: -'), findsOneWidget);
  });

  testWidgets('cancelar el diálogo de confirmación no llama al repositorio', (tester) async {
    await pumpCierre(tester);

    await tester.enterText(find.widgetWithText(TextFormField, 'Efectivo contado'), '65000');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Cerrar turno'));
    await tester.pumpAndSettle();
    expect(find.text('¿Cerrar turno?'), findsOneWidget);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    verifyNever(() => turnoRepository.cerrar(any(), any()));
    expect(find.widgetWithText(ElevatedButton, 'Cerrar turno'), findsOneWidget);
  });

  testWidgets('confirmar: muestra el resumen final sin pedir otra llamada', (tester) async {
    when(
      () => turnoRepository.cerrar('tur1', 65000),
    ).thenAnswer((_) async => arqueoFinal(efectivoContado: 65000, diferencia: 0));

    await pumpCierre(tester);
    await tester.enterText(find.widgetWithText(TextFormField, 'Efectivo contado'), '65000');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Cerrar turno'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();

    expect(find.text('Turno cerrado'), findsOneWidget);
    expect(find.text('Arqueo final'), findsOneWidget);
    expect(find.textContaining('Cuadre exacto'), findsOneWidget);
    verify(() => turnoRepository.cerrar('tur1', 65000)).called(1);
    verify(() => turnoRepository.obtenerArqueo('tur1')).called(1);
  });

  testWidgets('409: vuelve al formulario con el error del backend', (tester) async {
    when(() => turnoRepository.cerrar('tur1', 65000)).thenThrow(
      const ApiException(code: 'CONFLICT', message: 'El turno ya está cerrado', statusCode: 409),
    );

    await pumpCierre(tester);
    await tester.enterText(find.widgetWithText(TextFormField, 'Efectivo contado'), '65000');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Cerrar turno'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();

    expect(find.text('El turno ya está cerrado'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Cerrar turno'), findsOneWidget);
  });

  group('turno pendiente de arqueo', () {
    testWidgets('muestra el título y el botón como "Completar arqueo"', (tester) async {
      await pumpCierrePendiente(tester);

      expect(find.text('Completar arqueo'), findsWidgets);
      expect(find.widgetWithText(ElevatedButton, 'Cerrar turno'), findsNothing);
    });

    testWidgets('el diálogo de confirmación pregunta por completar el arqueo', (tester) async {
      await pumpCierrePendiente(tester);

      await tester.enterText(find.widgetWithText(TextFormField, 'Efectivo contado'), '65000');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Completar arqueo'));
      await tester.pumpAndSettle();

      expect(find.text('¿Completar arqueo?'), findsOneWidget);
    });

    testWidgets('confirmar: llama a completarArqueo (no a cerrar) y muestra "Arqueo completado"', (tester) async {
      when(
        () => turnoRepository.completarArqueo('tur1', 65000),
      ).thenAnswer((_) async => arqueoFinal(efectivoContado: 65000, diferencia: 0));

      await pumpCierrePendiente(tester);
      await tester.enterText(find.widgetWithText(TextFormField, 'Efectivo contado'), '65000');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Completar arqueo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();

      expect(find.text('Arqueo completado'), findsOneWidget);
      verify(() => turnoRepository.completarArqueo('tur1', 65000)).called(1);
      verifyNever(() => turnoRepository.cerrar(any(), any()));
    });

    testWidgets('403: vuelve al formulario con el error del backend', (tester) async {
      when(() => turnoRepository.completarArqueo('tur1', 65000)).thenThrow(
        const ApiException(
          code: 'TURNO_ARQUEO_SOLO_ADMIN',
          message: 'Solo un administrador puede completar el arqueo',
          statusCode: 403,
        ),
      );

      await pumpCierrePendiente(tester);
      await tester.enterText(find.widgetWithText(TextFormField, 'Efectivo contado'), '65000');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Completar arqueo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();

      expect(find.text('Solo un administrador puede completar el arqueo'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Completar arqueo'), findsOneWidget);
    });
  });
}
