import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:parqueadero_app/core/network/api_exception.dart';
import 'package:parqueadero_app/features/tickets/data/ticket_repository_impl.dart';
import 'package:parqueadero_app/features/tickets/domain/cobro_preview.dart';
import 'package:parqueadero_app/features/tickets/domain/desglose_item.dart';
import 'package:parqueadero_app/features/tickets/domain/ticket_repository.dart';
import 'package:parqueadero_app/features/tickets/presentation/cobro_preview_notifier.dart';

class MockTicketRepository extends Mock implements TicketRepository {}

void main() {
  late MockTicketRepository ticketRepository;
  late ProviderContainer container;

  CobroPreview previewBloques({int valorTotal = 9000}) => CobroPreview(
    valorTotal: valorTotal,
    desglose: [
      DesgloseBloque(
        dia: 1,
        bloqueNumero: 1,
        inicio: DateTime.utc(2026, 1, 1, 13),
        fin: DateTime.utc(2026, 1, 1, 14, 30),
        minutos: 90,
        tipoCobro: TipoCobro.parcial,
        valor: valorTotal,
      ),
    ],
    horaEntrada: DateTime.utc(2026, 1, 1, 13),
    horaSalida: DateTime.utc(2026, 1, 1, 14, 30),
  );

  CobroPreview previewMensualidad() => CobroPreview(
    valorTotal: 0,
    desglose: const [DesgloseMensualidad()],
    horaEntrada: DateTime.utc(2026, 1, 1, 13),
    horaSalida: DateTime.utc(2026, 1, 1, 14, 30),
  );

  CobroPreview previewManual() => CobroPreview(
    valorTotal: null,
    desglose: const [
      DesgloseManual(valor: null, motivo: 'El operador digita el valor al registrar la salida'),
    ],
    horaEntrada: DateTime.utc(2026, 1, 1, 13),
    horaSalida: DateTime.utc(2026, 1, 1, 14, 30),
  );

  setUp(() {
    ticketRepository = MockTicketRepository();
    container = ProviderContainer(
      overrides: [ticketRepositoryProvider.overrideWithValue(ticketRepository)],
    );
    addTearDown(container.dispose);
  });

  // autoDispose: hay que mantener un listener vivo, mismo motivo que en
  // celda_list_notifier_test.dart.
  void mantenerVivo() => container.listen(cobroPreviewNotifierProvider('t1'), (_, _) {});

  test('carga inicial exitosa con bloques', () async {
    when(() => ticketRepository.previsualizarCobro('t1')).thenAnswer((_) async => previewBloques());

    mantenerVivo();
    expect(container.read(cobroPreviewNotifierProvider('t1')).isLoading, isTrue);

    await Future<void>.delayed(Duration.zero);

    final state = container.read(cobroPreviewNotifierProvider('t1'));
    expect(state.isLoading, isFalse);
    expect(state.preview?.valorTotal, 9000);
    expect(state.esTerminal, isFalse);
  });

  test('carga inicial con mensualidad vigente: valorTotal 0', () async {
    when(() => ticketRepository.previsualizarCobro('t1')).thenAnswer((_) async => previewMensualidad());

    mantenerVivo();
    await Future<void>.delayed(Duration.zero);

    final state = container.read(cobroPreviewNotifierProvider('t1'));
    expect(state.preview?.valorTotal, 0);
    expect(state.preview?.desglose.single, const DesgloseMensualidad());
  });

  test('carga inicial con vehículo OTRO: valorTotal null con motivo', () async {
    when(() => ticketRepository.previsualizarCobro('t1')).thenAnswer((_) async => previewManual());

    mantenerVivo();
    await Future<void>.delayed(Duration.zero);

    final state = container.read(cobroPreviewNotifierProvider('t1'));
    expect(state.preview?.valorTotal, isNull);
    expect((state.preview?.desglose.single as DesgloseManual).motivo, isNotNull);
  });

  test('carga inicial con error: expone el mensaje del backend', () async {
    when(
      () => ticketRepository.previsualizarCobro('t1'),
    ).thenThrow(const ApiException(code: 'UNKNOWN', message: 'Ha ocurrido un error', statusCode: 500));

    mantenerVivo();
    await Future<void>.delayed(Duration.zero);

    final state = container.read(cobroPreviewNotifierProvider('t1'));
    expect(state.isLoading, isFalse);
    expect(state.error?.message, 'Ha ocurrido un error');
    expect(state.esTerminal, isFalse);
  });

  test('refrescar() con datos previos: un fallo de fondo no borra el preview ni muestra error', () async {
    when(() => ticketRepository.previsualizarCobro('t1')).thenAnswer((_) async => previewBloques());
    mantenerVivo();
    await Future<void>.delayed(Duration.zero);
    expect(container.read(cobroPreviewNotifierProvider('t1')).preview, isNotNull);

    when(
      () => ticketRepository.previsualizarCobro('t1'),
    ).thenThrow(const ApiException(code: 'UNKNOWN', message: 'falla de fondo', statusCode: 500));
    await container.read(cobroPreviewNotifierProvider('t1').notifier).refrescar();

    final state = container.read(cobroPreviewNotifierProvider('t1'));
    expect(state.preview, isNotNull);
    expect(state.error, isNull);
  });

  for (final codigo in ['TICKET_NO_ABIERTO', 'TICKET_NO_ENCONTRADO']) {
    test('$codigo es terminal: marca esTerminal y deja de reintentar', () {
      fakeAsync((async) {
        when(
          () => ticketRepository.previsualizarCobro('t1'),
        ).thenThrow(ApiException(code: codigo, message: 'ya no está abierto', statusCode: 409));

        mantenerVivo();
        async.flushMicrotasks();

        final state = container.read(cobroPreviewNotifierProvider('t1'));
        expect(state.esTerminal, isTrue);
        expect(state.error?.message, 'ya no está abierto');

        // Aunque pase el intervalo del timer, no debe reintentar: sigue
        // habiendo sido llamado una sola vez.
        async.elapse(const Duration(seconds: 31));
        async.flushMicrotasks();
        verify(() => ticketRepository.previsualizarCobro('t1')).called(1);
      });
    });
  }

  test('el timer de 30s dispara un refresco automático sin interacción del usuario', () {
    fakeAsync((async) {
      when(() => ticketRepository.previsualizarCobro('t1')).thenAnswer((_) async => previewBloques());

      mantenerVivo();
      async.flushMicrotasks();
      verify(() => ticketRepository.previsualizarCobro('t1')).called(1);

      async.elapse(const Duration(seconds: 31));
      async.flushMicrotasks();
      verify(() => ticketRepository.previsualizarCobro('t1')).called(1);
    });
  });
}
