import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:parqueadero_app/core/network/api_exception.dart';
import 'package:parqueadero_app/core/theme/app_colors.dart';
import 'package:parqueadero_app/features/auth/data/auth_repository_impl.dart';
import 'package:parqueadero_app/features/auth/domain/auth_repository.dart';
import 'package:parqueadero_app/features/auth/domain/usuario.dart';
import 'package:parqueadero_app/features/turnos/data/turno_repository_impl.dart';
import 'package:parqueadero_app/features/turnos/domain/turno.dart';
import 'package:parqueadero_app/features/turnos/domain/turno_repository.dart';
import 'package:parqueadero_app/features/turnos/presentation/widgets/turno_activo_indicator.dart';

class MockTurnoRepository extends Mock implements TurnoRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockTurnoRepository turnoRepository;
  late MockAuthRepository authRepository;

  Usuario usuario({RolUsuario rol = RolUsuario.operador}) => Usuario(
    id: 'op1',
    nombre: 'Ana',
    email: 'ana@test.com',
    rol: rol,
    activo: true,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  Turno turno() => Turno(
    id: 'tur1',
    operadorId: 'op1',
    apertura: DateTime.utc(2026, 1, 1, 6),
    baseInicial: 50000,
    estado: EstadoTurno.abierto,
    createdAt: DateTime.utc(2026, 1, 1, 6),
    updatedAt: DateTime.utc(2026, 1, 1, 6),
  );

  setUpAll(() async {
    await initializeDateFormatting('es_CO');
  });

  setUp(() {
    turnoRepository = MockTurnoRepository();
    authRepository = MockAuthRepository();
  });

  Future<void> pumpIndicador(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          turnoRepositoryProvider.overrideWithValue(turnoRepository),
          authRepositoryProvider.overrideWithValue(authRepository),
        ],
        child: const MaterialApp(home: Scaffold(body: TurnoActivoIndicator())),
      ),
    );
  }

  testWidgets('ADMIN: no renderiza nada', (tester) async {
    when(() => authRepository.restoreSession()).thenAnswer((_) async => usuario(rol: RolUsuario.admin));

    await pumpIndicador(tester);
    await tester.pumpAndSettle();

    expect(find.byType(Container), findsNothing);
    verifyNever(
      () => turnoRepository.listar(
        operadorId: any(named: 'operadorId'),
        estado: any(named: 'estado'),
        perPage: any(named: 'perPage'),
      ),
    );
  });

  testWidgets('OPERADOR sin turno abierto: muestra el aviso y el botón de abrir', (tester) async {
    when(() => authRepository.restoreSession()).thenAnswer((_) async => usuario());
    when(
      () => turnoRepository.listar(operadorId: 'op1', estado: EstadoTurno.abierto, perPage: 1),
    ).thenAnswer((_) async => const TurnoPageResult(data: [], page: 1, perPage: 1, total: 0));

    await pumpIndicador(tester);
    await tester.pumpAndSettle();

    expect(find.text('Sin turno abierto'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Abrir turno'), findsOneWidget);
  });

  testWidgets('OPERADOR con turno abierto: muestra la hora de apertura y el botón de arqueo', (tester) async {
    when(() => authRepository.restoreSession()).thenAnswer((_) async => usuario());
    when(
      () => turnoRepository.listar(operadorId: 'op1', estado: EstadoTurno.abierto, perPage: 1),
    ).thenAnswer((_) async => TurnoPageResult(data: [turno()], page: 1, perPage: 1, total: 1));

    await pumpIndicador(tester);
    await tester.pumpAndSettle();

    expect(find.textContaining('Turno abierto desde'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Ver arqueo'), findsOneWidget);
  });

  // Regresión del hallazgo de la auditoría UX: el aviso usaba el azul de
  // StatusTone.info (0xFF2C6FBB, ajeno a AppColors) en vez de la identidad
  // de marca. Ahora es asfalto/demarcación, igual que la bahía pintada.
  testWidgets(
    'OPERADOR con turno abierto: fondo asfalto y texto/ícono/acción en demarcación, no el azul de StatusStyle',
    (tester) async {
      when(() => authRepository.restoreSession()).thenAnswer((_) async => usuario());
      when(
        () => turnoRepository.listar(operadorId: 'op1', estado: EstadoTurno.abierto, perPage: 1),
      ).thenAnswer((_) async => TurnoPageResult(data: [turno()], page: 1, perPage: 1, total: 1));

      await pumpIndicador(tester);
      await tester.pumpAndSettle();

      final banner = tester
          .widgetList<Container>(find.byType(Container))
          .firstWhere((c) => (c.decoration as BoxDecoration?)?.color == AppColors.asfalto);
      expect((banner.decoration! as BoxDecoration).color, AppColors.asfalto);

      final icono = tester.widget<Icon>(find.byIcon(Icons.schedule));
      expect(icono.color, AppColors.demarcacion);

      final texto = tester.widget<Text>(find.textContaining('Turno abierto desde'));
      expect(texto.style?.color, AppColors.demarcacion);

      final boton = tester.widget<TextButton>(find.widgetWithText(TextButton, 'Ver arqueo'));
      expect(boton.style?.foregroundColor?.resolve(<WidgetState>{}), AppColors.demarcacion);
    },
  );

  // Verifica el contraste real (no solo el hex) para que una regresión de
  // color en cualquiera de los dos tokens se detecte aquí, igual que
  // status_style_test.dart hace con los tonos de StatusStyle.
  test('demarcación sobre asfalto pasa AA (>= 4.5:1) como texto/ícono del banner de turno', () {
    double canal(double c) => c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
    double luminancia(Color color) => 0.2126 * canal(color.r) + 0.7152 * canal(color.g) + 0.0722 * canal(color.b);
    double contraste(Color a, Color b) {
      final la = luminancia(a);
      final lb = luminancia(b);
      final claro = la > lb ? la : lb;
      final oscuro = la > lb ? lb : la;
      return (claro + 0.05) / (oscuro + 0.05);
    }

    final ratio = contraste(AppColors.demarcacion, AppColors.asfalto);

    expect(ratio, greaterThanOrEqualTo(4.5), reason: 'contraste real: $ratio');
  });

  testWidgets('error de red: muestra el mensaje y permite reintentar', (tester) async {
    when(() => authRepository.restoreSession()).thenAnswer((_) async => usuario());
    when(
      () => turnoRepository.listar(operadorId: 'op1', estado: EstadoTurno.abierto, perPage: 1),
    ).thenThrow(const ApiException(code: 'UNKNOWN', message: 'No hay conexión con el servidor.', statusCode: 0));

    await pumpIndicador(tester);
    await tester.pumpAndSettle();

    expect(find.text('No hay conexión con el servidor.'), findsOneWidget);

    when(
      () => turnoRepository.listar(operadorId: 'op1', estado: EstadoTurno.abierto, perPage: 1),
    ).thenAnswer((_) async => const TurnoPageResult(data: [], page: 1, perPage: 1, total: 0));
    await tester.tap(find.widgetWithText(TextButton, 'Reintentar'));
    await tester.pumpAndSettle();

    expect(find.text('Sin turno abierto'), findsOneWidget);
  });
}
