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

/// Mide el efecto del `.select` que `registrar_salida_screen.dart` usa sobre
/// `cobroPreviewNotifierProvider`.
///
/// La pantalla observaba antes el estado completo y se reconstruía entera en
/// cada respuesta del timer de 30s, aunque el cobro no hubiera cambiado: cada
/// preview trae una `horaSalida` nueva y ni `CobroPreviewState` ni
/// `CobroPreview` implementan `==`, así que toda respuesta es un objeto
/// distinto y notifica. Ahora observa solo
/// `(esTerminal, valorTotal)`, un record — y los records sí tienen igualdad
/// estructural, así que una respuesta con el mismo cobro no notifica.
///
/// `_PreviewCobroSection` sigue observando el estado completo a propósito:
/// muestra `horaSalida` ("Actualizado a las ..."), que cambia siempre. Por eso
/// cada test cuenta DOS contadores en paralelo sobre el mismo provider: el del
/// `.select` (la pantalla) y el del estado completo (la tarjeta del cobro).
void main() {
  late MockTicketRepository ticketRepository;
  late ProviderContainer container;

  const ticketId = 't1';

  final horaEntrada = DateTime.utc(2026, 1, 1, 13);
  final horaSalidaPrimera = DateTime.utc(2026, 1, 1, 14, 30);
  // El segundo preview llega 30s después: misma estadía cobrada, otra hora de
  // cálculo. Es exactamente el caso que disparaba el repintado inútil.
  final horaSalidaSegunda = DateTime.utc(2026, 1, 1, 14, 30, 30);

  CobroPreview previewCon({required int? valorTotal, required DateTime horaSalida}) => CobroPreview(
    valorTotal: valorTotal,
    desglose: [
      DesgloseBloque(
        dia: 1,
        bloqueNumero: 1,
        inicio: horaEntrada,
        fin: horaSalida,
        minutos: 90,
        tipoCobro: TipoCobro.parcial,
        valor: valorTotal,
      ),
    ],
    horaEntrada: horaEntrada,
    horaSalida: horaSalida,
  );

  setUp(() {
    ticketRepository = MockTicketRepository();
    container = ProviderContainer(
      overrides: [ticketRepositoryProvider.overrideWithValue(ticketRepository)],
    );
    addTearDown(container.dispose);
  });

  /// Contadores de notificaciones. Se enganchan ANTES de que resuelva la carga
  /// inicial, así que también hacen de keep-alive del provider autoDispose
  /// (mismo motivo que `mantenerVivo()` en `cobro_preview_notifier_test.dart`).
  /// `fireImmediately: false`: no se cuenta el estado inicial, solo los
  /// cambios posteriores.
  ({int Function() select, int Function() completas}) engancharContadores() {
    var notificacionesSelect = 0;
    container.listen(
      cobroPreviewNotifierProvider(ticketId).select(
        (s) => (esTerminal: s.esTerminal, valorTotal: s.preview?.valorTotal),
      ),
      (_, _) => notificacionesSelect++,
      fireImmediately: false,
    );

    var notificacionesCompletas = 0;
    container.listen(
      cobroPreviewNotifierProvider(ticketId),
      (_, _) => notificacionesCompletas++,
      fireImmediately: false,
    );

    return (select: () => notificacionesSelect, completas: () => notificacionesCompletas);
  }

  test('segundo preview con igual valorTotal y distinta horaSalida: el select NO notifica', () async {
    when(
      () => ticketRepository.previsualizarCobro(ticketId),
    ).thenAnswer((_) async => previewCon(valorTotal: 9000, horaSalida: horaSalidaPrimera));

    final contadores = engancharContadores();
    await Future<void>.delayed(Duration.zero);

    final selectTrasCargaInicial = contadores.select();
    final completasTrasCargaInicial = contadores.completas();

    // Segundo refresco: mismo cobro (9000, no terminal), otra horaSalida.
    when(
      () => ticketRepository.previsualizarCobro(ticketId),
    ).thenAnswer((_) async => previewCon(valorTotal: 9000, horaSalida: horaSalidaSegunda));
    await container.read(cobroPreviewNotifierProvider(ticketId).notifier).refrescar();

    // El estado sí cambió de verdad: la tarjeta del cobro tiene qué repintar.
    expect(
      container.read(cobroPreviewNotifierProvider(ticketId)).preview?.horaSalida,
      horaSalidaSegunda,
      reason: 'el segundo preview debe haber entrado al estado; si no, el test no mide nada',
    );

    final selectDelSegundoRefresco = contadores.select() - selectTrasCargaInicial;
    final completasDelSegundoRefresco = contadores.completas() - completasTrasCargaInicial;

    expect(
      selectDelSegundoRefresco,
      0,
      reason:
          'MEDICIÓN: en el segundo refresco el select recibió '
          '$selectDelSegundoRefresco notificación(es) (0 esperadas: valorTotal y '
          'esTerminal no cambiaron) y el provider completo recibió '
          '$completasDelSegundoRefresco (1 esperada: horaSalida cambió). '
          'Totales desde el enganche: select=${contadores.select()} '
          '(solo la carga inicial), provider completo=${contadores.completas()}. '
          'Si este número deja de ser 0, la pantalla volvió a reconstruirse entera cada 30s.',
    );

    expect(
      completasDelSegundoRefresco,
      1,
      reason:
          'el provider completo debe seguir notificando ($completasDelSegundoRefresco '
          'recibidas): _PreviewCobroSection muestra horaSalida y necesita repintarse',
    );

    expect(
      selectTrasCargaInicial,
      1,
      reason:
          'control: el select sí notificó en la carga inicial ($selectTrasCargaInicial), '
          'así que su 0 en el segundo refresco es filtrado real, no un listener muerto',
    );
  });

  test('segundo preview con valorTotal distinto: el select SÍ notifica', () async {
    when(
      () => ticketRepository.previsualizarCobro(ticketId),
    ).thenAnswer((_) async => previewCon(valorTotal: 9000, horaSalida: horaSalidaPrimera));

    final contadores = engancharContadores();
    await Future<void>.delayed(Duration.zero);

    final selectTrasCargaInicial = contadores.select();

    when(
      () => ticketRepository.previsualizarCobro(ticketId),
    ).thenAnswer((_) async => previewCon(valorTotal: 12000, horaSalida: horaSalidaSegunda));
    await container.read(cobroPreviewNotifierProvider(ticketId).notifier).refrescar();

    expect(container.read(cobroPreviewNotifierProvider(ticketId)).preview?.valorTotal, 12000);

    final selectDelSegundoRefresco = contadores.select() - selectTrasCargaInicial;
    expect(
      selectDelSegundoRefresco,
      1,
      reason:
          'MEDICIÓN: valorTotal pasó de 9000 a 12000 y el select recibió '
          '$selectDelSegundoRefresco notificación(es) (1 esperada). Si fuera 0, la '
          'optimización habría roto la reactividad del cobro en pantalla.',
    );
  });

  test('esTerminal pasa a true: el select notifica', () async {
    when(
      () => ticketRepository.previsualizarCobro(ticketId),
    ).thenAnswer((_) async => previewCon(valorTotal: 9000, horaSalida: horaSalidaPrimera));

    final contadores = engancharContadores();
    await Future<void>.delayed(Duration.zero);

    final selectTrasCargaInicial = contadores.select();

    // Otro operador cerró o anuló el ticket mientras esta pantalla seguía abierta.
    when(() => ticketRepository.previsualizarCobro(ticketId)).thenThrow(
      const ApiException(code: 'TICKET_NO_ABIERTO', message: 'ya no está abierto', statusCode: 409),
    );
    await container.read(cobroPreviewNotifierProvider(ticketId).notifier).refrescar();

    expect(container.read(cobroPreviewNotifierProvider(ticketId)).esTerminal, isTrue);

    final selectDelSegundoRefresco = contadores.select() - selectTrasCargaInicial;
    expect(
      selectDelSegundoRefresco,
      1,
      reason:
          'MEDICIÓN: esTerminal pasó a true (valorTotal siguió en 9000) y el select '
          'recibió $selectDelSegundoRefresco notificación(es) (1 esperada). Si fuera 0, '
          'el botón "Registrar salida" nunca se deshabilitaría.',
    );
  });
}
