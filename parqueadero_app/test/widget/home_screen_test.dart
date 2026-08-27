import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:parqueadero_app/features/auth/data/auth_repository_impl.dart';
import 'package:parqueadero_app/features/auth/domain/auth_repository.dart';
import 'package:parqueadero_app/features/auth/domain/usuario.dart';
import 'package:parqueadero_app/features/auth/presentation/home_screen.dart';
import 'package:parqueadero_app/features/celdas/data/celda_repository_impl.dart';
import 'package:parqueadero_app/features/celdas/domain/celda_repository.dart';
import 'package:parqueadero_app/features/tickets/data/ticket_repository_impl.dart';
import 'package:parqueadero_app/features/tickets/domain/ticket_repository.dart';
import 'package:parqueadero_app/features/turnos/data/turno_repository_impl.dart';
import 'package:parqueadero_app/features/turnos/domain/turno_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockTurnoRepository extends Mock implements TurnoRepository {}

class MockCeldaRepository extends Mock implements CeldaRepository {}

class MockTicketRepository extends Mock implements TicketRepository {}

void main() {
  late MockAuthRepository authRepository;
  late MockTurnoRepository turnoRepository;
  late MockCeldaRepository celdaRepository;
  late MockTicketRepository ticketRepository;

  Usuario usuario(RolUsuario rol) => Usuario(
    id: 'u1',
    nombre: 'Ana',
    email: 'ana@test.com',
    rol: rol,
    activo: true,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  setUp(() {
    authRepository = MockAuthRepository();
    turnoRepository = MockTurnoRepository();
    celdaRepository = MockCeldaRepository();
    ticketRepository = MockTicketRepository();
    when(
      () => turnoRepository.listar(
        operadorId: any(named: 'operadorId'),
        estado: any(named: 'estado'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer((_) async => const TurnoPageResult(data: [], page: 1, perPage: 1, total: 0));
    // Solo lo usa el dashboard de OPERADOR, pero se deja stubeado siempre:
    // ADMIN nunca lo lee, así que no afecta ese caso.
    when(() => celdaRepository.listarTodas()).thenAnswer((_) async => const []);
    when(
      () => ticketRepository.listar(estado: any(named: 'estado'), perPage: any(named: 'perPage')),
    ).thenAnswer((_) async => const TicketPageResult(data: [], page: 1, perPage: 100, total: 0));
  });

  Future<void> pumpHome(WidgetTester tester, RolUsuario rol) async {
    when(() => authRepository.restoreSession()).thenAnswer((_) async => usuario(rol));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepository),
          turnoRepositoryProvider.overrideWithValue(turnoRepository),
          celdaRepositoryProvider.overrideWithValue(celdaRepository),
          ticketRepositoryProvider.overrideWithValue(ticketRepository),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('OPERADOR: ve su dashboard, con "Buscar placa" en vez del botón plano de ADMIN', (tester) async {
    await pumpHome(tester, RolUsuario.operador);

    expect(find.text('Buscar placa'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Buscar por placa'), findsNothing);
  });

  testWidgets('ADMIN: también ve el botón Buscar por placa', (tester) async {
    await pumpHome(tester, RolUsuario.admin);

    expect(find.widgetWithText(ElevatedButton, 'Buscar por placa'), findsOneWidget);
  });
}
