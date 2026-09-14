import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:parqueadero_app/features/celdas/data/celda_repository_impl.dart';
import 'package:parqueadero_app/features/celdas/domain/celda.dart';
import 'package:parqueadero_app/features/celdas/domain/celda_repository.dart';
import 'package:parqueadero_app/features/celdas/presentation/celda_list_notifier.dart';
import 'package:parqueadero_app/features/tickets/data/ticket_repository_impl.dart';
import 'package:parqueadero_app/features/tickets/domain/ticket_repository.dart';

class MockCeldaRepository extends Mock implements CeldaRepository {}

class MockTicketRepository extends Mock implements TicketRepository {}

/// Mide que el `.select` de `_ChipsFiltro` (celda_filtros_bar.dart) hace su
/// trabajo: el poll de 30s de `CeldaListNotifier` reemplaza el estado en cada
/// refresco y `CeldaListState` no implementa `==`, así que quien observa el
/// provider COMPLETO se entera siempre. El record de (estadoFiltro,
/// tipoFiltro) compara por valor y solo notifica cuando un filtro cambió de
/// verdad — que es lo único que los 6 ChoiceChip necesitan saber.
void main() {
  late MockCeldaRepository celdaRepository;
  late MockTicketRepository ticketRepository;
  late ProviderContainer container;

  Celda celda({String id = 'c1', String codigo = 'A-01'}) => Celda(
    id: id,
    codigo: codigo,
    zona: 'Zona A',
    tipoPermitido: TipoVehiculo.carro,
    estado: EstadoCelda.libre,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  setUp(() {
    celdaRepository = MockCeldaRepository();
    ticketRepository = MockTicketRepository();
    when(
      () => ticketRepository.listar(estado: any(named: 'estado'), perPage: any(named: 'perPage')),
    ).thenAnswer((_) async => const TicketPageResult(data: [], page: 1, perPage: 100, total: 0));
    when(() => celdaRepository.listarTodas()).thenAnswer((_) async => [celda()]);
    container = ProviderContainer(
      overrides: [
        celdaRepositoryProvider.overrideWithValue(celdaRepository),
        ticketRepositoryProvider.overrideWithValue(ticketRepository),
      ],
    );
    addTearDown(container.dispose);
  });

  /// Los dos contadores en paralelo sobre el MISMO provider: uno a través del
  /// `.select` de los chips, otro sobre el estado completo (lo que hacía el
  /// widget antes). `fireImmediately: false` para que solo cuenten cambios,
  /// no la suscripción inicial. Ambos listeners mantienen vivo al provider
  /// autoDispose durante todo el test.
  ({int Function() select, int Function() completo}) contadores() {
    var select = 0;
    var completo = 0;
    container.listen(
      celdaListNotifierProvider.select(
        (s) => (estadoFiltro: s.estadoFiltro, tipoFiltro: s.tipoFiltro),
      ),
      (_, _) => select++,
      fireImmediately: false,
    );
    container.listen(celdaListNotifierProvider, (_, _) => completo++, fireImmediately: false);
    return (select: () => select, completo: () => completo);
  }

  test('refresco del poll sin cambio de filtros: el select NO notifica', () async {
    final c = contadores();
    // Carga inicial (el microtask de `build()`), fuera de la medición.
    await Future<void>.delayed(Duration.zero);

    final selectTrasCarga = c.select();
    final completoTrasCarga = c.completo();

    // Tres refrescos idénticos: es exactamente lo que hace el Timer.periodic
    // de 30s, solo que sin esperarlos.
    for (var i = 0; i < 3; i++) {
      await container.read(celdaListNotifierProvider.notifier).refrescar();
    }

    final selectNuevas = c.select() - selectTrasCarga;
    final completoNuevas = c.completo() - completoTrasCarga;

    expect(
      selectNuevas,
      0,
      reason:
          'Tras 3 refrescos sin cambiar filtros: el select notificó $selectNuevas veces '
          'y el provider completo $completoNuevas. El select debe quedarse en 0 — '
          'cada notificación de más repinta los 6 ChoiceChip al pedo.',
    );
    expect(
      completoNuevas,
      greaterThan(0),
      reason:
          'control de la medición: el provider completo SÍ debe notificar '
          '(notificó $completoNuevas veces). Si esto fuera 0, el test no estaría '
          'provocando refrescos y el 0 del select no probaría nada.',
    );
  });

  test('cambiar el filtro de estado: el select SÍ notifica', () async {
    final c = contadores();
    await Future<void>.delayed(Duration.zero);
    final previas = c.select();

    container.read(celdaListNotifierProvider.notifier).setEstadoFiltro(EstadoCelda.ocupada);

    expect(c.select() - previas, 1);
    expect(
      container.read(celdaListNotifierProvider).estadoFiltro,
      EstadoCelda.ocupada,
    );
  });

  test('cambiar el filtro de tipo: el select SÍ notifica', () async {
    final c = contadores();
    await Future<void>.delayed(Duration.zero);
    final previas = c.select();

    container.read(celdaListNotifierProvider.notifier).setTipoFiltro(TipoVehiculo.moto);

    expect(c.select() - previas, 1);
    expect(container.read(celdaListNotifierProvider).tipoFiltro, TipoVehiculo.moto);
  });
}
