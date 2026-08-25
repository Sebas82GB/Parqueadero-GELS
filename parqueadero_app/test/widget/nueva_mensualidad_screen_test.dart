import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:parqueadero_app/core/widgets/acceso_restringido.dart';
import 'package:parqueadero_app/features/auth/data/auth_repository_impl.dart';
import 'package:parqueadero_app/features/auth/domain/auth_repository.dart';
import 'package:parqueadero_app/features/auth/domain/usuario.dart';
import 'package:parqueadero_app/features/celdas/data/celda_repository_impl.dart';
import 'package:parqueadero_app/features/celdas/domain/celda.dart';
import 'package:parqueadero_app/features/celdas/domain/celda_repository.dart';
import 'package:parqueadero_app/features/mensualidades/data/mensualidad_repository_impl.dart';
import 'package:parqueadero_app/features/mensualidades/domain/mensualidad_repository.dart';
import 'package:parqueadero_app/features/mensualidades/presentation/nueva_mensualidad_screen.dart';

class MockMensualidadRepository extends Mock implements MensualidadRepository {}

class MockCeldaRepository extends Mock implements CeldaRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockMensualidadRepository mensualidadRepository;
  late MockCeldaRepository celdaRepository;
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

  Celda celda(String id, String codigo) => Celda(
    id: id,
    codigo: codigo,
    zona: 'Zona A',
    tipoPermitido: TipoVehiculo.carro,
    estado: EstadoCelda.libre,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  setUpAll(() async {
    registerFallbackValue(TipoVehiculo.carro);
    registerFallbackValue(DateTime.utc(2026, 1, 1));
    // El botón de rango de fechas usa DateFormat con locale 'es_CO'; en
    // main() lo hace initializeDateFormatting, que los widget tests nunca
    // ejecutan.
    await initializeDateFormatting('es_CO');
  });

  setUp(() {
    mensualidadRepository = MockMensualidadRepository();
    celdaRepository = MockCeldaRepository();
    authRepository = MockAuthRepository();
    when(
      () => celdaRepository.listarTodas(),
    ).thenAnswer((_) async => [celda('c1', 'A-01'), celda('c2', 'A-02')]);
  });

  Future<void> pumpNuevaMensualidadScreen(WidgetTester tester, {RolUsuario rol = RolUsuario.admin}) async {
    when(() => authRepository.restoreSession()).thenAnswer((_) async => usuario(rol));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mensualidadRepositoryProvider.overrideWithValue(mensualidadRepository),
          celdaRepositoryProvider.overrideWithValue(celdaRepository),
          authRepositoryProvider.overrideWithValue(authRepository),
        ],
        child: const MaterialApp(home: NuevaMensualidadScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('OPERADOR: ve el mensaje de acceso restringido', (tester) async {
    await pumpNuevaMensualidadScreen(tester, rol: RolUsuario.operador);

    expect(find.byType(AccesoRestringido), findsOneWidget);
  });

  testWidgets('muestra el banner informativo sobre placas ya existentes', (tester) async {
    await pumpNuevaMensualidadScreen(tester);

    expect(
      find.textContaining('Si la placa ya existe, se reutilizará el vehículo registrado'),
      findsOneWidget,
    );
  });

  testWidgets('el dropdown de celda se puebla desde celdaListNotifierProvider', (tester) async {
    await pumpNuevaMensualidadScreen(tester);

    await tester.tap(find.text('Sin celda asignada'));
    await tester.pumpAndSettle();

    expect(find.text('A-01 · Zona A'), findsOneWidget);
    expect(find.text('A-02 · Zona A'), findsOneWidget);
  });

  testWidgets('sin un rango de fechas válido: bloquea el envío y no llama al repositorio', (tester) async {
    await pumpNuevaMensualidadScreen(tester);

    final campos = find.byType(TextFormField);
    await tester.enterText(campos.at(0), 'ABC123'); // placa

    await tester.tap(find.byType(DropdownButtonFormField<TipoVehiculo>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Carro').last);
    await tester.pumpAndSettle();

    await tester.enterText(campos.at(3), '150000'); // valor de la mensualidad

    await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Crear mensualidad'));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Crear mensualidad'));
    await tester.pumpAndSettle();

    expect(
      find.text('Selecciona un rango de fechas válido: la fecha final debe ser posterior a la inicial.'),
      findsOneWidget,
    );
    verifyNever(
      () => mensualidadRepository.crear(
        placa: any(named: 'placa'),
        tipoVehiculo: any(named: 'tipoVehiculo'),
        propietarioNombre: any(named: 'propietarioNombre'),
        propietarioTelefono: any(named: 'propietarioTelefono'),
        celdaId: any(named: 'celdaId'),
        fechaInicio: any(named: 'fechaInicio'),
        fechaFin: any(named: 'fechaFin'),
        valorMensualidad: any(named: 'valorMensualidad'),
      ),
    );
  });
}
