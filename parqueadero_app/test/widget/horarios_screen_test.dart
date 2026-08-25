import 'dart:async';

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
import 'package:parqueadero_app/features/horarios/data/horario_repository_impl.dart';
import 'package:parqueadero_app/features/horarios/domain/horario.dart';
import 'package:parqueadero_app/features/horarios/domain/horario_repository.dart';
import 'package:parqueadero_app/features/horarios/presentation/horarios_screen.dart';

class MockHorarioRepository extends Mock implements HorarioRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockHorarioRepository horarioRepository;
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

  Horario horario({
    String id = 'hor1',
    String apertura = '08:00',
    String cierre = '21:00',
    DateTime? vigenteDesde,
    DateTime? vigenteHasta,
  }) => Horario(
    id: id,
    apertura: apertura,
    cierre: cierre,
    vigenteDesde: vigenteDesde ?? DateTime.utc(2026, 1, 1),
    vigenteHasta: vigenteHasta,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  setUpAll(() async {
    // formatBogota() usa DateFormat con locale 'es_CO'; en main() lo hace
    // initializeDateFormatting, que los widget tests nunca ejecutan.
    await initializeDateFormatting('es_CO');
  });

  setUp(() {
    horarioRepository = MockHorarioRepository();
    authRepository = MockAuthRepository();
  });

  Future<void> pumpHorariosScreen(WidgetTester tester, {RolUsuario rol = RolUsuario.admin}) async {
    when(() => authRepository.restoreSession()).thenAnswer((_) async => usuario(rol));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          horarioRepositoryProvider.overrideWithValue(horarioRepository),
          authRepositoryProvider.overrideWithValue(authRepository),
        ],
        child: const MaterialApp(home: HorariosScreen()),
      ),
    );
    await tester.pump();
  }

  testWidgets('OPERADOR: ve el mensaje de acceso restringido', (tester) async {
    await pumpHorariosScreen(tester, rol: RolUsuario.operador);
    await tester.pumpAndSettle();

    expect(find.byType(AccesoRestringido), findsOneWidget);
  });

  testWidgets('ADMIN cargando: muestra el spinner', (tester) async {
    final completer = Completer<List<Horario>>();
    when(() => horarioRepository.listarTodas()).thenAnswer((_) => completer.future);

    await pumpHorariosScreen(tester);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete([]);
    await tester.pumpAndSettle();
  });

  testWidgets('ADMIN error: muestra el mensaje del backend con reintentar', (tester) async {
    when(() => horarioRepository.listarTodas()).thenThrow(
      const ApiException(code: 'UNKNOWN', message: 'No hay conexión con el servidor.', statusCode: 0),
    );

    await pumpHorariosScreen(tester);
    await tester.pumpAndSettle();

    expect(find.byType(ErrorState), findsOneWidget);

    when(() => horarioRepository.listarTodas()).thenAnswer((_) async => []);
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.byType(ErrorState), findsNothing);
  });

  testWidgets('ADMIN vacío: muestra el mensaje de vacío con acción de crear', (tester) async {
    when(() => horarioRepository.listarTodas()).thenAnswer((_) async => []);

    await pumpHorariosScreen(tester);
    await tester.pumpAndSettle();

    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text('Crear horario'), findsOneWidget);
  });

  testWidgets('ADMIN con vigente: muestra chip Vigente y las horas', (tester) async {
    when(() => horarioRepository.listarTodas()).thenAnswer((_) async => [horario()]);

    await pumpHorariosScreen(tester);
    await tester.pumpAndSettle();

    expect(find.text('Vigente'), findsOneWidget);
    expect(find.text('08:00 – 21:00'), findsOneWidget);
  });

  testWidgets('sin horario vigente: muestra la nota de aviso', (tester) async {
    when(
      () => horarioRepository.listarTodas(),
    ).thenAnswer((_) async => [horario(vigenteHasta: DateTime.utc(2026, 1, 15))]);

    await pumpHorariosScreen(tester);
    await tester.pumpAndSettle();

    expect(find.textContaining('Sin horario vigente'), findsOneWidget);
  });

  testWidgets('histórico: se muestra debajo del vigente, sin incluirlo', (tester) async {
    when(() => horarioRepository.listarTodas()).thenAnswer(
      (_) async => [
        horario(
          id: 'viejo',
          apertura: '07:00',
          cierre: '20:00',
          vigenteDesde: DateTime.utc(2025, 1, 1),
          vigenteHasta: DateTime.utc(2026, 1, 1),
        ),
        horario(id: 'vigente', apertura: '08:00', cierre: '21:00', vigenteDesde: DateTime.utc(2026, 1, 1)),
      ],
    );

    await pumpHorariosScreen(tester);
    await tester.pumpAndSettle();

    expect(find.text('Histórico'), findsOneWidget);
    expect(find.text('07:00 – 20:00'), findsOneWidget);
    // El vigente aparece una sola vez (en la card superior), no repetido en
    // el histórico.
    expect(find.text('08:00 – 21:00'), findsOneWidget);
  });
}
