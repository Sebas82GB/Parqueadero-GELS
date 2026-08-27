import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:parqueadero_app/core/network/api_exception.dart';
import 'package:parqueadero_app/features/celdas/data/celda_repository_impl.dart';
import 'package:parqueadero_app/features/celdas/domain/celda.dart';
import 'package:parqueadero_app/features/celdas/domain/celda_repository.dart';
import 'package:parqueadero_app/features/celdas/presentation/celda_accion_notifier.dart';
import 'package:parqueadero_app/features/celdas/presentation/celda_list_notifier.dart';
import 'package:parqueadero_app/features/tickets/data/ticket_repository_impl.dart';
import 'package:parqueadero_app/features/tickets/domain/ticket_repository.dart';

class MockCeldaRepository extends Mock implements CeldaRepository {}

class MockTicketRepository extends Mock implements TicketRepository {}

void main() {
  late MockCeldaRepository celdaRepository;
  late MockTicketRepository ticketRepository;
  late ProviderContainer container;

  Celda celda({EstadoCelda estado = EstadoCelda.libre}) => Celda(
    id: 'c1',
    codigo: 'A-01',
    zona: 'Zona A',
    tipoPermitido: TipoVehiculo.carro,
    estado: estado,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  setUp(() {
    celdaRepository = MockCeldaRepository();
    ticketRepository = MockTicketRepository();
    // celdaListNotifierProvider arranca su propia carga al construirse;
    // sin este stub, ese GET de fondo lanzaría MissingStubError.
    when(() => celdaRepository.listarTodas()).thenAnswer((_) async => [celda()]);
    when(
      () => ticketRepository.listar(estado: any(named: 'estado'), perPage: any(named: 'perPage')),
    ).thenAnswer((_) async => const TicketPageResult(data: [], page: 1, perPage: 100, total: 0));
    container = ProviderContainer(
      overrides: [
        celdaRepositoryProvider.overrideWithValue(celdaRepository),
        ticketRepositoryProvider.overrideWithValue(ticketRepository),
      ],
    );
    addTearDown(container.dispose);
    // Ambos providers son autoDispose: `container.listen` los mantiene vivos
    // durante el test, igual que el `ref.watch` de una pantalla real.
    container.listen(celdaListNotifierProvider, (_, _) {});
    container.listen(celdaAccionNotifierProvider('c1'), (_, _) {});
  });

  test('marcarMantenimiento exitoso: limpia el error y actualiza CeldaListNotifier', () async {
    when(() => celdaRepository.marcarMantenimiento('c1')).thenAnswer(
      (_) async => celda(estado: EstadoCelda.mantenimiento),
    );
    await Future<void>.delayed(Duration.zero);

    await container.read(celdaAccionNotifierProvider('c1').notifier).marcarMantenimiento();

    final accionState = container.read(celdaAccionNotifierProvider('c1'));
    expect(accionState.isLoading, isFalse);
    expect(accionState.errorMessage, isNull);

    final celdaActualizada = container
        .read(celdaListNotifierProvider)
        .celdas
        .firstWhere((c) => c.id == 'c1');
    expect(celdaActualizada.estado, EstadoCelda.mantenimiento);
  });

  test('marcarMantenimiento falla con 409 CELDA_OCUPADA: expone el mensaje del backend', () async {
    when(() => celdaRepository.marcarMantenimiento('c1')).thenThrow(
      const ApiException(code: 'CELDA_OCUPADA', message: 'La celda A-01 ya está ocupada', statusCode: 409),
    );

    await container.read(celdaAccionNotifierProvider('c1').notifier).marcarMantenimiento();

    final accionState = container.read(celdaAccionNotifierProvider('c1'));
    expect(accionState.isLoading, isFalse);
    expect(accionState.errorMessage, 'La celda A-01 ya está ocupada');
  });

  test('volverALibre exitoso: actualiza CeldaListNotifier', () async {
    when(() => celdaRepository.volverALibre('c1')).thenAnswer((_) async => celda(estado: EstadoCelda.libre));
    await Future<void>.delayed(Duration.zero);

    await container.read(celdaAccionNotifierProvider('c1').notifier).volverALibre();

    final accionState = container.read(celdaAccionNotifierProvider('c1'));
    expect(accionState.errorMessage, isNull);
  });

  test('volverALibre falla con 409 CELDA_ESTADO_INVALIDO: expone el mensaje del backend', () async {
    when(() => celdaRepository.volverALibre('c1')).thenThrow(
      const ApiException(code: 'CELDA_ESTADO_INVALIDO', message: 'La celda A-01 ya está libre', statusCode: 409),
    );

    await container.read(celdaAccionNotifierProvider('c1').notifier).volverALibre();

    final accionState = container.read(celdaAccionNotifierProvider('c1'));
    expect(accionState.errorMessage, 'La celda A-01 ya está libre');
  });

  test('404 CELDA_NO_ENCONTRADA: expone el mensaje del backend', () async {
    when(() => celdaRepository.marcarMantenimiento('c1')).thenThrow(
      const ApiException(code: 'CELDA_NO_ENCONTRADA', message: 'Celda no encontrada', statusCode: 404),
    );

    await container.read(celdaAccionNotifierProvider('c1').notifier).marcarMantenimiento();

    expect(container.read(celdaAccionNotifierProvider('c1')).errorMessage, 'Celda no encontrada');
  });
}
