import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:parqueadero_app/features/auth/data/auth_repository_impl.dart';
import 'package:parqueadero_app/features/auth/domain/auth_repository.dart';
import 'package:parqueadero_app/features/auth/domain/usuario.dart';
import 'package:parqueadero_app/features/turnos/domain/turno.dart';
import 'package:parqueadero_app/features/turnos/presentation/widgets/turno_list_item.dart';
import 'package:parqueadero_app/features/usuarios/data/usuario_repository_impl.dart';
import 'package:parqueadero_app/features/usuarios/domain/usuario_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockUsuarioRepository extends Mock implements UsuarioRepository {}

void main() {
  late MockAuthRepository authRepository;
  late MockUsuarioRepository usuarioRepository;

  Usuario usuario({required String id, required String nombre, RolUsuario rol = RolUsuario.operador}) => Usuario(
    id: id,
    nombre: nombre,
    email: '$id@test.com',
    rol: rol,
    activo: true,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  Turno turno({
    String operadorId = 'op1',
    DateTime? cierre,
    EstadoTurno estado = EstadoTurno.abierto,
    int? diferencia,
  }) => Turno(
    id: 'tur1',
    operadorId: operadorId,
    apertura: DateTime.utc(2026, 1, 1, 6),
    cierre: cierre,
    baseInicial: 50000,
    diferencia: diferencia,
    estado: estado,
    createdAt: DateTime.utc(2026, 1, 1, 6),
    updatedAt: DateTime.utc(2026, 1, 1, 6),
  );

  setUpAll(() async {
    await initializeDateFormatting('es_CO');
  });

  setUp(() {
    authRepository = MockAuthRepository();
    usuarioRepository = MockUsuarioRepository();
  });

  Future<void> pumpItem(WidgetTester tester, Turno turno, {RolUsuario rol = RolUsuario.operador, String sesionId = 'op1'}) async {
    when(() => authRepository.restoreSession()).thenAnswer((_) async => usuario(id: sesionId, nombre: 'Sesión', rol: rol));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepository),
          usuarioRepositoryProvider.overrideWithValue(usuarioRepository),
        ],
        child: MaterialApp(home: Scaffold(body: TurnoListItem(turno: turno))),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('OPERADOR viendo su propio turno: título "Mi turno", nunca el UUID', (tester) async {
    await pumpItem(tester, turno(operadorId: 'op1'), rol: RolUsuario.operador, sesionId: 'op1');

    expect(find.text('Mi turno'), findsOneWidget);
    expect(find.textContaining('op1'), findsNothing);
  });

  testWidgets('ADMIN viendo un turno ajeno: título con el nombre resuelto vía operadoresProvider', (tester) async {
    when(
      () => usuarioRepository.listar(
        rol: any(named: 'rol'),
        activo: any(named: 'activo'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer(
      (_) async => UsuarioPageResult(
        data: [usuario(id: 'op2', nombre: 'Carlos')],
        page: 1,
        perPage: 100,
        total: 1,
      ),
    );

    await pumpItem(tester, turno(operadorId: 'op2'), rol: RolUsuario.admin, sesionId: 'admin1');

    expect(find.text('Carlos'), findsOneWidget);
    expect(find.textContaining('op2'), findsNothing);
  });

  testWidgets('turno abierto: muestra "En curso" en vez de una hora de cierre', (tester) async {
    await pumpItem(tester, turno(cierre: null, estado: EstadoTurno.abierto));

    expect(find.text('En curso'), findsOneWidget);
  });

  testWidgets('turno cerrado: muestra la hora de cierre formateada, no "En curso"', (tester) async {
    await pumpItem(
      tester,
      turno(cierre: DateTime.utc(2026, 1, 1, 14), estado: EstadoTurno.cerrado, diferencia: 0),
    );

    expect(find.text('En curso'), findsNothing);
    expect(find.textContaining('Cierre:'), findsOneWidget);
  });

  testWidgets('siempre muestra la base inicial', (tester) async {
    await pumpItem(tester, turno());

    expect(find.textContaining('Base inicial:'), findsOneWidget);
  });

  testWidgets('con diferencia no nula: usa el mismo texto que diferenciaTexto (signo + palabra)', (tester) async {
    await pumpItem(
      tester,
      turno(cierre: DateTime.utc(2026, 1, 1, 14), estado: EstadoTurno.cerrado, diferencia: 5000),
    );

    expect(find.textContaining('Sobrante'), findsOneWidget);
  });

  testWidgets('con diferencia null: no muestra ninguna línea de diferencia', (tester) async {
    await pumpItem(tester, turno(diferencia: null));

    expect(find.textContaining('Sobrante'), findsNothing);
    expect(find.textContaining('Faltante'), findsNothing);
    expect(find.textContaining('Cuadre exacto'), findsNothing);
  });
}
