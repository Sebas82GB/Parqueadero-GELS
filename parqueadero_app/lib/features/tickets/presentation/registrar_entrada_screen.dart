import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/placa_tipo.dart';
import '../../../core/utils/tipo_vehiculo_label.dart';
import '../../../core/utils/upper_case_text_formatter.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/button_spinner.dart';
import '../../../core/widgets/detail_skeleton.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/error_state.dart';
import '../../celdas/domain/celda.dart';
import '../../celdas/presentation/celda_list_notifier.dart';
import '../../celdas/presentation/widgets/celda_estado_badge.dart';
import '../../turnos/presentation/widgets/turno_activo_indicator.dart';
import '../domain/ticket.dart';
import 'registrar_entrada_notifier.dart';

/// Dos puntos de entrada, distinguidos por [celdaId]:
/// - Con celda: se llega desde el tap en una celda LIBRE de la cuadrícula
///   (`celda_card.dart`) — el operador elige a mano el espacio físico
///   exacto. La celda ya debe estar cargada en [celdaListNotifierProvider].
/// - Sin celda (`celdaId == null`): se llega desde "Registrar entrada" en
///   el dashboard del operador — ruta rápida que no pasa por la cuadrícula.
///   Al confirmar, se asigna automáticamente la primera celda LIBRE cuyo
///   tipo coincida con el elegido (ver `CeldaListState.celdasLibresDeTipo`),
///   en vez de pedir que el operador la busque a mano. `estado: LIBRE` no
///   garantiza que el backend la acepte (reservada por una mensualidad
///   vigente de otro vehículo, ocupada un instante antes por otro
///   operador, etc. — ver `_codigosCeldaEspecifica` en [_submit]), así que
///   si la primera candidata falla por un motivo propio de ESA celda, se
///   reintenta en silencio con la siguiente antes de rendirse.
class RegistrarEntradaScreen extends ConsumerStatefulWidget {
  const RegistrarEntradaScreen({super.key, required this.celdaId});

  final String? celdaId;

  @override
  ConsumerState<RegistrarEntradaScreen> createState() => _RegistrarEntradaScreenState();
}

class _RegistrarEntradaScreenState extends ConsumerState<RegistrarEntradaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _placaController = TextEditingController();
  TipoVehiculo? _tipoVehiculo;
  bool _tipoInicializado = false;

  /// `true` en cuanto el operador toca el selector de tipo a mano. Mientras
  /// siga en `false`, la placa manda: cada tecla recalcula
  /// [tipoVehiculoDePlaca] y, si detecta un formato colombiano válido,
  /// actualiza [_tipoVehiculo] solo. En cuanto el operador elige un tipo a
  /// mano (p.ej. "Otro" para una bicicleta), esta bandera pasa a `true` y la
  /// autodetección deja de sobrescribir su elección para el resto del
  /// formulario.
  bool _tipoElegidoManualmente = false;

  /// Solo se usa en el flujo sin celda preseleccionada: "no hay ninguna
  /// libre de este tipo" se sabe recién al intentar enviar, así que no es
  /// un error que pueda venir de [RegistrarEntradaNotifier] (nunca llega a
  /// llamar la API).
  String? _errorSinCeldaDisponible;

  /// Cubre TODO el intento de envío, incluidos los reintentos con otra
  /// celda: `RegistrarEntradaNotifier.state.isLoading` por sí solo
  /// parpadearía a `false` entre un intento fallido y el siguiente (cada
  /// llamada a `registrar()` lo resetea), lo que reactivaría el botón a
  /// mitad del reintento silencioso.
  bool _enviando = false;

  /// Errores de `POST /tickets` que dependen de LA CELDA elegida, no de la
  /// placa/tarifa/horario: si la primera candidata falla con uno de estos,
  /// tiene sentido reintentar con la siguiente celda LIBRE del mismo tipo
  /// en vez de mostrarle el error al operador. `CELDA_RESERVADA_MENSUALIDAD`
  /// es el caso real que motivó esto — `estado: LIBRE` no sabe nada de
  /// mensualidades, así que la única forma de enterarse es que el backend
  /// la rechace.
  static const _codigosCeldaEspecifica = {
    'CELDA_NO_ENCONTRADA',
    'CELDA_OCUPADA',
    'CELDA_EN_MANTENIMIENTO',
    'CELDA_TIPO_INCOMPATIBLE',
    'CELDA_RESERVADA_MENSUALIDAD',
  };

  @override
  void dispose() {
    _placaController.dispose();
    super.dispose();
  }

  Future<void> _submit({required Celda? celdaPreseleccionada}) async {
    if (!_formKey.currentState!.validate() || _enviando) return;

    List<Celda> candidatas;
    if (celdaPreseleccionada != null) {
      candidatas = [celdaPreseleccionada];
    } else {
      candidatas = ref.read(celdaListNotifierProvider).celdasLibresDeTipo(_tipoVehiculo!);
      if (candidatas.isEmpty) {
        setState(
          () => _errorSinCeldaDisponible =
              'No hay celdas libres para ${tipoVehiculoLabel(_tipoVehiculo!).toLowerCase()} en este momento.',
        );
        return;
      }
    }
    setState(() {
      _errorSinCeldaDisponible = null;
      _enviando = true;
    });

    final placa = _placaController.text.trim().toUpperCase();
    Ticket? ticket;
    String celdaIdUsada = candidatas.first.id;
    try {
      for (final candidata in candidatas) {
        celdaIdUsada = candidata.id;
        ticket = await ref
            .read(registrarEntradaNotifierProvider.notifier)
            .registrar(placa: placa, tipoVehiculo: _tipoVehiculo!, celdaId: celdaIdUsada);
        if (ticket != null) break;
        if (!mounted) return;
        final codigo = ref.read(registrarEntradaNotifierProvider).errorCode;
        // Ni una celda distinta arreglaría esto (placa/tarifa/horario, o un
        // error sin `code` — sin respuesta del backend): se corta acá y se
        // deja el mensaje del último intento en pantalla.
        if (codigo == null || !_codigosCeldaEspecifica.contains(codigo)) break;
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
    if (ticket == null || !mounted) return;

    // Sin diálogo de "Aceptar": esta pantalla se repite decenas de veces por
    // turno y no es una acción irreversible que necesite doble confirmación
    // (a diferencia de registrar salida o cerrar turno). Vuelve a la
    // cuadrícula de inmediato y confirma con un snackbar que no exige toque
    // — mismo idioma que ya usa celda_quick_actions_sheet.dart (pop seguido
    // de ScaffoldMessenger.of(context), seguro acá porque la app tiene un
    // único ScaffoldMessenger raíz en MaterialApp.router).
    context.pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Entrada registrada · Ticket ${ticket.codigo} · Celda ${ticket.celda?.codigo ?? celdaIdUsada}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final celdaIdBuscado = widget.celdaId;
    Celda? celdaPreseleccionada;
    // Solo relevante en el flujo sin celda: mientras la lista siga sin datos
    // y sin terminar de cargar, `celdasLibresDeTipo` no puede decir todavía
    // si hay o no una disponible — el botón espera a que resuelva en vez de
    // reportar "no hay celdas libres" por una lista vacía a medias.
    var celdasListasParaAutoAsignar = true;

    if (celdaIdBuscado != null) {
      // `.select()` con un record compara por valor (Celda ya implementa
      // `==`), así que el poll de 30s de `CeldaListNotifier` deja de
      // reconstruir este formulario completo cuando ninguno de estos tres
      // campos cambió de verdad.
      final celdaState = ref.watch(
        celdaListNotifierProvider.select((s) {
          Celda? celda;
          for (final c in s.celdas) {
            if (c.id == celdaIdBuscado) {
              celda = c;
              break;
            }
          }
          return (celda: celda, isLoading: s.isLoading, errorMessage: s.errorMessage);
        }),
      );
      celdaPreseleccionada = celdaState.celda;

      if (celdaPreseleccionada == null) {
        Widget body;
        if (celdaState.isLoading) {
          body = const DetailSkeleton();
        } else if (celdaState.errorMessage != null) {
          body = ErrorState(
            message: celdaState.errorMessage!,
            onRetry: ref.read(celdaListNotifierProvider.notifier).refrescar,
          );
        } else {
          body = const EmptyState(
            icon: Icons.error_outline,
            message: 'No se encontró la celda seleccionada. Vuelve a la cuadrícula e inténtalo de nuevo.',
          );
        }
        return Scaffold(appBar: AppBar(title: const Text('Registrar entrada')), body: body);
      }
    } else {
      celdasListasParaAutoAsignar = !ref.watch(
        celdaListNotifierProvider.select((s) => s.celdas.isEmpty && s.isLoading),
      );
    }

    if (!_tipoInicializado) {
      // Sin celda todavía no hay un `tipoPermitido` del que partir: CARRO es
      // el tipo más común, el operador lo cambia si hace falta.
      _tipoVehiculo = celdaPreseleccionada?.tipoPermitido ?? TipoVehiculo.carro;
      _tipoInicializado = true;
    }

    final state = ref.watch(registrarEntradaNotifierProvider);
    final celdaSeleccionada = celdaPreseleccionada;

    return Scaffold(
      appBar: AppBar(
        title: Text(celdaSeleccionada != null ? 'Registrar entrada · ${celdaSeleccionada.codigo}' : 'Registrar entrada'),
      ),
      body: Column(
        children: [
          const TurnoActivoIndicator(),
          Expanded(
            child: SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (celdaSeleccionada != null) ...[
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const CeldaEstadoBadge(estado: EstadoCelda.libre, size: 32),
                                    const SizedBox(width: AppSpacing.sm),
                                    Text(
                                      'Celda ${celdaSeleccionada.codigo}',
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text('Zona ${celdaSeleccionada.zona}'),
                                Text('Tipo permitido: ${tipoVehiculoLabel(celdaSeleccionada.tipoPermitido)}'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                      TextFormField(
                        controller: _placaController,
                        enabled: !_enviando,
                        autofocus: true,
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: [
                          FilteringTextInputFormatter.deny(RegExp(r'\s')),
                          UpperCaseTextFormatter(),
                        ],
                        decoration: const InputDecoration(labelText: 'Placa'),
                        // Mientras el operador no haya elegido el tipo a
                        // mano, la placa debe coincidir con un formato
                        // colombiano reconocible (carro/moto): sin eso no
                        // hay tipo que autoasignar y el envío no tiene
                        // sentido. En cuanto elige a mano (p.ej. "Otro" para
                        // una bicicleta), basta con el validador de siempre.
                        validator: _tipoElegidoManualmente ? placaValidator : placaConTipoValidator,
                        // Autodetección en vivo: mientras el operador no haya
                        // tocado el selector, cada tecla recalcula el tipo
                        // según el formato de placa colombiano y actualiza
                        // el dropdown de abajo. Si la placa no coincide con
                        // ningún formato, se deja el último tipo conocido
                        // (el operador puede seguir escribiendo o elegir a
                        // mano).
                        onChanged: (value) {
                          if (_tipoElegidoManualmente) return;
                          setState(() {
                            final detectado = tipoVehiculoDePlaca(value.trim().toUpperCase());
                            if (detectado != null) _tipoVehiculo = detectado;
                          });
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _TipoVehiculoDropdown(
                        // Cambia de key cuando la autodetección actualiza
                        // `_tipoVehiculo` para que el dropdown (que guarda
                        // su valor en estado interno, ver comentario de la
                        // clase) se reconstruya con el nuevo `initialValue`
                        // en vez de ignorarlo. Una vez el operador elige a
                        // mano, `_tipoVehiculo` ya no cambia por la placa,
                        // así que la key deja de moverse.
                        key: ValueKey(_tipoVehiculo),
                        initialValue: _tipoVehiculo!,
                        enabled: !_enviando,
                        // La elección manual manda sobre la autodetección
                        // para el resto del formulario: `_TipoVehiculoDropdown`
                        // ya no se sobrescribe con lo que se siga escribiendo
                        // en la placa.
                        onChanged: (value) => setState(() {
                          _tipoVehiculo = value;
                          _tipoElegidoManualmente = true;
                        }),
                      ),
                      if (!_tipoElegidoManualmente &&
                          tipoVehiculoDePlaca(_placaController.text.trim().toUpperCase()) == _tipoVehiculo) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Detectado por la placa',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      // Botón (y error) fuera del scroll, siempre visible: con el teclado
      // abierto, el formulario podía empujar "Registrar entrada" fuera del
      // viewport y obligar a cerrar el teclado o hacer scroll de más para
      // confirmar — justo en la tarea que más se repite en el turno.
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_errorSinCeldaDisponible != null) ...[
                Text(
                  _errorSinCeldaDisponible!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: AppSpacing.md),
                // Mientras `_enviando` sigue en `true`, `state.error` puede
                // traer el fallo de un intento intermedio (una celda que ya
                // se está reintentando con otra) — no es el resultado final
                // todavía, así que no se muestra hasta que termine.
              ] else if (!_enviando && state.error != null) ...[
                ErrorBanner(error: state.error!),
                // El vehículo ya está adentro (probablemente de un intento
                // anterior que sí se registró): en vez de dejar al operador
                // sin salida, se ofrece ir directo a buscar esa placa y ver
                // su ticket abierto. Mismo patrón que
                // `OPERADOR_SIN_TURNO_ABIERTO` → "Abrir turno" en
                // `registrar_salida_screen.dart`.
                if (state.error case ApiException(code: 'VEHICULO_CON_TICKET_ABIERTO')) ...[
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton(
                    onPressed: () => context.push('/tickets/buscar'),
                    child: const Text('Buscar placa'),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
              ],
              ElevatedButton(
                onPressed: (_enviando || !celdasListasParaAutoAsignar)
                    ? null
                    : () => _submit(celdaPreseleccionada: celdaSeleccionada),
                child: _enviando ? const ButtonSpinner() : const Text('Registrar entrada'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Aislado del formulario para que elegir un tipo no reconstruya las ~150
/// líneas de `RegistrarEntradaScreen` — el valor elegido solo lo lee
/// `_submit()` más adelante (vía [onChanged]), ningún otro widget del
/// formulario depende de él en cada tecla/selección.
class _TipoVehiculoDropdown extends StatefulWidget {
  const _TipoVehiculoDropdown({super.key, required this.initialValue, required this.enabled, required this.onChanged});

  final TipoVehiculo initialValue;
  final bool enabled;
  final ValueChanged<TipoVehiculo> onChanged;

  @override
  State<_TipoVehiculoDropdown> createState() => _TipoVehiculoDropdownState();
}

class _TipoVehiculoDropdownState extends State<_TipoVehiculoDropdown> {
  late TipoVehiculo _value = widget.initialValue;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<TipoVehiculo>(
      initialValue: _value,
      decoration: const InputDecoration(labelText: 'Tipo de vehículo'),
      items: [
        for (final tipo in TipoVehiculo.values)
          DropdownMenuItem(value: tipo, child: Text(tipoVehiculoLabel(tipo))),
      ],
      onChanged: widget.enabled
          ? (value) {
              if (value == null) return;
              setState(() => _value = value);
              widget.onChanged(value);
            }
          : null,
    );
  }
}
