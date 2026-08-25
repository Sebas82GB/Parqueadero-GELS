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
import 'package:parqueadero_app/features/tarifas/data/tarifa_repository_impl.dart';
import 'package:parqueadero_app/features/tarifas/domain/tarifa.dart';
import 'package:parqueadero_app/features/tarifas/domain/tarifa_repository.dart';
import 'package:parqueadero_app/features/tarifas/presentation/tarifas_screen.dart';

class MockTarifaRepository extends Mock implements TarifaRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockTarifaRepository tarifaRepository;
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

  Tarifa tarifa({String id = 'tar1', TipoVehiculo tipo = TipoVehiculo.carro, DateTime? vigenteHasta}) => Tarifa(
    id: id,
    tipoVehiculo: tipo,
    valorMinuto: 100,
    valorPlena: 8000,
    valorNocturna: 6000,
    valorMes: 150000,
    vigenteDesde: DateTime.utc(2026, 1, 1),
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
    tarifaRepository = MockTarifaRepository();
    authRepository = MockAuthRepository();
  });

  Future<void> pumpTarifasScreen(WidgetTester tester, {RolUsuario rol = RolUsuario.admin}) async {
    when(() => authRepository.restoreSession()).thenAnswer((_) async => usuario(rol));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tarifaRepositoryProvider.overrideWithValue(tarifaRepository),
          authRepositoryProvider.overrideWithValue(authRepository),
        ],
        child: const MaterialApp(home: TarifasScreen()),
      ),
    );
    await tester.pump();
  }

  testWidgets('OPERADOR: ve el mensaje de acceso restringido', (tester) async {
    await pumpTarifasScreen(tester, rol: RolUsuario.operador);
    await tester.pumpAndSettle();

    expect(find.byType(AccesoRestringido), findsOneWidget);
  });

  testWidgets('ADMIN cargando: muestra el spinner', (tester) async {
    final completer = Completer<List<Tarifa>>();
    when(() => tarifaRepository.listarTodas()).thenAnswer((_) => completer.future);

    await pumpTarifasScreen(tester);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete([]);
    await tester.pumpAndSettle();
  });

  testWidgets('ADMIN error: muestra el mensaje del backend con reintentar', (tester) async {
    when(() => tarifaRepository.listarTodas()).thenThrow(
      const ApiException(code: 'UNKNOWN', message: 'No hay conexión con el servidor.', statusCode: 0),
    );

    await pumpTarifasScreen(tester);
    await tester.pumpAndSettle();

    expect(find.byType(ErrorState), findsOneWidget);

    when(() => tarifaRepository.listarTodas()).thenAnswer((_) async => []);
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.byType(ErrorState), findsNothing);
  });

  testWidgets('ADMIN vacío: muestra el mensaje de vacío', (tester) async {
    when(() => tarifaRepository.listarTodas()).thenAnswer((_) async => []);

    await pumpTarifasScreen(tester);
    await tester.pumpAndSettle();

    expect(find.byType(EmptyState), findsOneWidget);
  });

  testWidgets('ADMIN con datos: muestra chip Vigente y botón Cerrar vigencia', (tester) async {
    when(() => tarifaRepository.listarTodas()).thenAnswer((_) async => [tarifa()]);

    await pumpTarifasScreen(tester);
    await tester.pumpAndSettle();

    expect(find.text('Vigente'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Cerrar vigencia'), findsOneWidget);
  });

  testWidgets('sin tarifa vigente: muestra la nota de aviso', (tester) async {
    when(
      () => tarifaRepository.listarTodas(),
    ).thenAnswer((_) async => [tarifa(vigenteHasta: DateTime.utc(2026, 1, 15))]);

    await pumpTarifasScreen(tester);
    await tester.pumpAndSettle();

    expect(find.textContaining('Sin tarifa vigente'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Cerrar vigencia'), findsNothing);
  });

  testWidgets('Cerrar vigencia: pide confirmación antes de llamar al repositorio', (tester) async {
    when(() => tarifaRepository.listarTodas()).thenAnswer((_) async => [tarifa()]);

    await pumpTarifasScreen(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Cerrar vigencia'));
    await tester.pumpAndSettle();

    expect(find.text('¿Cerrar vigencia?'), findsOneWidget);
    verifyNever(() => tarifaRepository.cerrar(any()));

    when(
      () => tarifaRepository.cerrar('tar1'),
    ).thenAnswer((_) async => tarifa(vigenteHasta: DateTime.utc(2026, 2, 1)));
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();

    verify(() => tarifaRepository.cerrar('tar1')).called(1);
  });

  testWidgets('filtro por tipo: solo muestra el grupo del tipo elegido', (tester) async {
    when(
      () => tarifaRepository.listarTodas(),
    ).thenAnswer((_) async => [tarifa(id: 't1'), tarifa(id: 't2', tipo: TipoVehiculo.moto)]);

    await pumpTarifasScreen(tester);
    await tester.pumpAndSettle();

    expect(find.text('Carro'), findsOneWidget);
    expect(find.text('Moto'), findsOneWidget);

    await tester.tap(find.text('Todos los tipos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Moto').last);
    await tester.pumpAndSettle();

    expect(find.text('Carro'), findsNothing);
  });
}
