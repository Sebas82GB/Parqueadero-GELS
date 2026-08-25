import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:parqueadero_app/core/network/api_exception.dart';
import 'package:parqueadero_app/core/utils/money.dart';
import 'package:parqueadero_app/core/widgets/acceso_restringido.dart';
import 'package:parqueadero_app/features/auth/data/auth_repository_impl.dart';
import 'package:parqueadero_app/features/auth/domain/auth_repository.dart';
import 'package:parqueadero_app/features/auth/domain/usuario.dart';
import 'package:parqueadero_app/features/tarifas/data/tarifa_repository_impl.dart';
import 'package:parqueadero_app/features/tarifas/domain/tarifa.dart';
import 'package:parqueadero_app/features/tarifas/domain/tarifa_repository.dart';
import 'package:parqueadero_app/features/tarifas/presentation/nueva_tarifa_screen.dart';

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

  Tarifa tarifaCreada() => Tarifa(
    id: 'tar1',
    tipoVehiculo: TipoVehiculo.carro,
    valorMinuto: 100,
    valorPlena: 8000,
    valorNocturna: 6000,
    valorMes: 150000,
    vigenteDesde: DateTime.utc(2026, 1, 1),
    vigenteHasta: null,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  setUpAll(() async {
    registerFallbackValue(TipoVehiculo.carro);
    // formatMoney() usa NumberFormat con locale 'es_CO'; en main() lo hace
    // initializeDateFormatting, que los widget tests nunca ejecutan.
    await initializeDateFormatting('es_CO');
  });

  setUp(() {
    tarifaRepository = MockTarifaRepository();
    authRepository = MockAuthRepository();
    when(() => authRepository.restoreSession()).thenAnswer((_) async => usuario(RolUsuario.admin));
    when(() => tarifaRepository.listarTodas()).thenAnswer((_) async => []);
    // Default: la mayoría de los tests no verifica la vista previa, solo que
    // llenar el formulario no falle porque la llamada de fondo no está
    // estubada. Los tests que sí la verifican re-estuban esto.
    when(
      () => tarifaRepository.simular(
        tipoVehiculo: any(named: 'tipoVehiculo'),
        valorMinuto: any(named: 'valorMinuto'),
        valorPlena: any(named: 'valorPlena'),
        valorNocturna: any(named: 'valorNocturna'),
        duracionMinutos: any(named: 'duracionMinutos'),
      ),
    ).thenAnswer((_) async => 20000);
  });

  Future<GoRouter> pumpNuevaTarifaScreen(WidgetTester tester, {RolUsuario rol = RolUsuario.admin}) async {
    when(() => authRepository.restoreSession()).thenAnswer((_) async => usuario(rol));
    final router = GoRouter(
      initialLocation: '/tarifas',
      routes: [
        GoRoute(
          path: '/tarifas',
          builder: (context, state) => Scaffold(
            body: Center(
              child: TextButton(onPressed: () => context.push('/tarifas/nueva'), child: const Text('IR')),
            ),
          ),
        ),
        GoRoute(path: '/tarifas/nueva', builder: (context, state) => const NuevaTarifaScreen()),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tarifaRepositoryProvider.overrideWithValue(tarifaRepository),
          authRepositoryProvider.overrideWithValue(authRepository),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('IR'));
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('OPERADOR: ve el mensaje de acceso restringido', (tester) async {
    await pumpNuevaTarifaScreen(tester, rol: RolUsuario.operador);

    expect(find.byType(AccesoRestringido), findsOneWidget);
  });

  testWidgets('la advertencia de que crear cierra la vigencia anterior siempre está visible', (tester) async {
    await pumpNuevaTarifaScreen(tester);

    expect(
      find.text('Crear una tarifa nueva de este tipo cerrará automáticamente la vigencia actual.'),
      findsOneWidget,
    );
  });

  testWidgets('éxito: crea la tarifa, muestra el diálogo y vuelve atrás', (tester) async {
    when(
      () => tarifaRepository.crear(
        tipoVehiculo: any(named: 'tipoVehiculo'),
        valorMinuto: any(named: 'valorMinuto'),
        valorPlena: any(named: 'valorPlena'),
        valorNocturna: any(named: 'valorNocturna'),
        valorMes: any(named: 'valorMes'),
      ),
    ).thenAnswer((_) async => tarifaCreada());

    await pumpNuevaTarifaScreen(tester);

    await tester.tap(find.byType(DropdownButtonFormField<TipoVehiculo>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Carro').last);
    await tester.pumpAndSettle();

    final campos = find.byType(TextFormField);
    await tester.enterText(campos.at(0), '100');
    await tester.enterText(campos.at(1), '8000');
    await tester.enterText(campos.at(2), '6000');
    await tester.enterText(campos.at(3), '150000');

    await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Crear tarifa'));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Crear tarifa'));
    await tester.pumpAndSettle();

    expect(find.text('Tarifa creada'), findsOneWidget);

    await tester.tap(find.text('Aceptar'));
    await tester.pumpAndSettle();

    verify(
      () => tarifaRepository.crear(
        tipoVehiculo: TipoVehiculo.carro,
        valorMinuto: 100,
        valorPlena: 8000,
        valorNocturna: 6000,
        valorMes: 150000,
      ),
    ).called(1);
    expect(find.text('IR'), findsOneWidget);
  });

  testWidgets('400 validación: muestra el mensaje del backend sin navegar', (tester) async {
    when(
      () => tarifaRepository.crear(
        tipoVehiculo: any(named: 'tipoVehiculo'),
        valorMinuto: any(named: 'valorMinuto'),
        valorPlena: any(named: 'valorPlena'),
        valorNocturna: any(named: 'valorNocturna'),
        valorMes: any(named: 'valorMes'),
      ),
    ).thenThrow(
      const ApiException(code: 'VALIDATION_ERROR', message: 'valorMinuto debe ser un entero', statusCode: 400),
    );

    await pumpNuevaTarifaScreen(tester);

    await tester.tap(find.byType(DropdownButtonFormField<TipoVehiculo>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Carro').last);
    await tester.pumpAndSettle();

    final campos = find.byType(TextFormField);
    await tester.enterText(campos.at(0), '100');
    await tester.enterText(campos.at(1), '8000');
    await tester.enterText(campos.at(2), '6000');
    await tester.enterText(campos.at(3), '150000');

    await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Crear tarifa'));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Crear tarifa'));
    await tester.pumpAndSettle();

    expect(find.text('valorMinuto debe ser un entero'), findsOneWidget);
    expect(find.byType(NuevaTarifaScreen), findsOneWidget);
  });

  group('vista previa (POST /tarifas/simular)', () {
    Future<void> llenarFormulario(
      WidgetTester tester, {
      String tipo = 'Carro',
      String v1 = '100',
      String v2 = '8000',
      String v3 = '6000',
      String v4 = '150000',
    }) async {
      await tester.tap(find.byType(DropdownButtonFormField<TipoVehiculo>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(tipo).last);
      await tester.pumpAndSettle();

      final campos = find.byType(TextFormField);
      await tester.enterText(campos.at(0), v1);
      await tester.enterText(campos.at(1), v2);
      await tester.enterText(campos.at(2), v3);
      await tester.enterText(campos.at(3), v4);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
    }

    testWidgets('aparece tras completar los campos, calculada por el backend', (tester) async {
      when(
        () => tarifaRepository.simular(
          tipoVehiculo: TipoVehiculo.carro,
          valorMinuto: 100,
          valorPlena: 8000,
          valorNocturna: 6000,
          duracionMinutos: 120,
        ),
      ).thenAnswer((_) async => 16000);

      await pumpNuevaTarifaScreen(tester);
      await llenarFormulario(tester);

      expect(find.text('Un Carro de 2 horas pagaría ${formatMoney(16000)}.'), findsOneWidget);
    });

    testWidgets('tipo Otro: indica que el valor lo digita el operador, no un número', (tester) async {
      when(
        () => tarifaRepository.simular(
          tipoVehiculo: TipoVehiculo.otro,
          valorMinuto: 0,
          valorPlena: 0,
          valorNocturna: 0,
          duracionMinutos: 120,
        ),
      ).thenAnswer((_) async => null);

      await pumpNuevaTarifaScreen(tester);
      await llenarFormulario(tester, tipo: 'Otro', v1: '0', v2: '0', v3: '0', v4: '0');

      expect(
        find.text('Para vehículos tipo Otro, el valor lo digita el operador al registrar la salida.'),
        findsOneWidget,
      );
    });

    testWidgets('cambiar la duración dispara un nuevo cálculo', (tester) async {
      when(
        () => tarifaRepository.simular(
          tipoVehiculo: TipoVehiculo.carro,
          valorMinuto: 100,
          valorPlena: 8000,
          valorNocturna: 6000,
          duracionMinutos: 120,
        ),
      ).thenAnswer((_) async => 16000);
      when(
        () => tarifaRepository.simular(
          tipoVehiculo: TipoVehiculo.carro,
          valorMinuto: 100,
          valorPlena: 8000,
          valorNocturna: 6000,
          duracionMinutos: 360,
        ),
      ).thenAnswer((_) async => 40000);

      await pumpNuevaTarifaScreen(tester);
      await llenarFormulario(tester);
      expect(find.text('Un Carro de 2 horas pagaría ${formatMoney(16000)}.'), findsOneWidget);

      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('6 horas').last);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.text('Un Carro de 6 horas pagaría ${formatMoney(40000)}.'), findsOneWidget);
    });

    testWidgets('error de la simulación: leyenda discreta, no bloquea el formulario', (tester) async {
      when(
        () => tarifaRepository.simular(
          tipoVehiculo: any(named: 'tipoVehiculo'),
          valorMinuto: any(named: 'valorMinuto'),
          valorPlena: any(named: 'valorPlena'),
          valorNocturna: any(named: 'valorNocturna'),
          duracionMinutos: any(named: 'duracionMinutos'),
        ),
      ).thenThrow(const ApiException(code: 'UNKNOWN', message: 'error', statusCode: 500));

      await pumpNuevaTarifaScreen(tester);
      await llenarFormulario(tester);

      expect(find.text('No se pudo calcular la vista previa.'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Crear tarifa'), findsOneWidget);
    });
  });
}
