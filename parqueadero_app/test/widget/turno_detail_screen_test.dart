import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:parqueadero_app/core/network/api_exception.dart';
import 'package:parqueadero_app/core/widgets/error_state.dart';
import 'package:parqueadero_app/features/auth/data/auth_repository_impl.dart';
import 'package:parqueadero_app/features/auth/domain/auth_repository.dart';
import 'package:parqueadero_app/features/auth/domain/usuario.dart';
import 'package:parqueadero_app/features/turnos/data/turno_repository_impl.dart';
import 'package:parqueadero_app/features/turnos/domain/arqueo_turno.dart';
import 'package:parqueadero_app/features/turnos/domain/turno.dart';
import 'package:parqueadero_app/features/turnos/domain/turno_repository.dart';
import 'package:parqueadero_app/features/turnos/presentation/turno_detail_screen.dart';

class MockTurnoRepository extends Mock implements TurnoRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockTurnoRepository turnoRepository;
  late MockAuthRepository authRepository;

  Usuario usuario({required String id, RolUsuario rol = RolUsuario.operador}) => Usuario(
    id: id,
    nombre: 'Ana',
    email: 'ana@test.com',
    rol: rol,
    activo: true,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  ArqueoTurno arqueo({EstadoTurno estado = EstadoTurno.abierto, String operadorId = 'op1'}) => ArqueoTurno(
    turnoId: 'tur1',
    operadorId: operadorId,
    estado: estado,
    apertura: DateTime.utc(2026, 1, 1, 6),
    cierre: estado == EstadoTurno.cerrado ? DateTime.utc(2026, 1, 1, 14) : null,
    baseInicial: 50000,
    totalesPorMetodo: const TotalesPorMetodo(efectivo: 15000, tarjeta: 20000, transferencia: 0),
    totalRecaudado: 35000,
    ticketsCerrados: 4,
    efectivoEsperado: 65000,
    efectivoContado: estado == EstadoTurno.cerrado ? 65000 : null,
    diferencia: estado == EstadoTurno.cerrado ? 0 : null,
  );

  setUpAll(() async {
    await initializeDateFormatting('es_CO');
  });

  setUp(() {
    turnoRepository = MockTurnoRepository();
    authRepository = MockAuthRepository();
    when(() => authRepository.restoreSession()).thenAnswer((_) async => usuario(id: 'op1'));
  });

  Future<void> pumpDetalle(WidgetTester tester, {RolUsuario rol = RolUsuario.operador, String usuarioId = 'op1'}) async {
    when(() => authRepository.restoreSession()).thenAnswer((_) async => usuario(id: usuarioId, rol: rol));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          turnoRepositoryProvider.overrideWithValue(turnoRepository),
          authRepositoryProvider.overrideWithValue(authRepository),
        ],
        child: const MaterialApp(home: TurnoDetailScreen(turnoId: 'tur1')),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('cargando: muestra el spinner', (tester) async {
    when(() => turnoRepository.obtenerArqueo('tur1')).thenAnswer(
      (_) => Future.delayed(const Duration(milliseconds: 50), arqueo),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          turnoRepositoryProvider.overrideWithValue(turnoRepository),
          authRepositoryProvider.overrideWithValue(authRepository),
        ],
        child: const MaterialApp(home: TurnoDetailScreen(turnoId: 'tur1')),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('error: muestra ErrorState con botón de reintentar', (tester) async {
    when(() => turnoRepository.obtenerArqueo('tur1')).thenThrow(
      const ApiException(code: 'NOT_FOUND', message: 'Turno no encontrado', statusCode: 404),
    );

    await pumpDetalle(tester);

    expect(find.byType(ErrorState), findsOneWidget);
    expect(find.text('Turno no encontrado'), findsOneWidget);
  });

  testWidgets('turno abierto, dueño: muestra el arqueo en vivo y el botón de cerrar', (tester) async {
    when(() => turnoRepository.obtenerArqueo('tur1')).thenAnswer((_) async => arqueo());

    await pumpDetalle(tester);

    expect(find.text('Arqueo en vivo'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Cerrar turno'), findsOneWidget);
  });

  testWidgets('turno abierto, otro operador: no muestra el botón de cerrar', (tester) async {
    when(() => turnoRepository.obtenerArqueo('tur1')).thenAnswer((_) async => arqueo(operadorId: 'op1'));

    await pumpDetalle(tester, usuarioId: 'op2');

    expect(find.widgetWithText(ElevatedButton, 'Cerrar turno'), findsNothing);
  });

  testWidgets('turno abierto, ADMIN: sí muestra el botón de cerrar', (tester) async {
    when(() => turnoRepository.obtenerArqueo('tur1')).thenAnswer((_) async => arqueo(operadorId: 'op1'));

    await pumpDetalle(tester, rol: RolUsuario.admin, usuarioId: 'admin1');

    expect(find.widgetWithText(ElevatedButton, 'Cerrar turno'), findsOneWidget);
  });

  testWidgets('turno cerrado: muestra el arqueo final sin botón de cerrar', (tester) async {
    when(
      () => turnoRepository.obtenerArqueo('tur1'),
    ).thenAnswer((_) async => arqueo(estado: EstadoTurno.cerrado));

    await pumpDetalle(tester);

    expect(find.text('Arqueo final'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Cerrar turno'), findsNothing);
  });
}
