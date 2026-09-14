import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_elevation.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/elapsed_time.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/utils/tipo_vehiculo_label.dart';
import '../../../auth/domain/usuario.dart';
import '../../../auth/presentation/session_notifier.dart';
import '../../domain/celda.dart';
import '../celda_accion_notifier.dart';
import '../celda_list_notifier.dart';
import '../reloj_notifier.dart';
import 'celda_accion_rapida_sheet.dart';
import 'celda_quick_actions_sheet.dart';

class CeldaCard extends ConsumerWidget {
  const CeldaCard({
    super.key,
    required this.celdaId,
    this.entryIndex = 0,
    this.entrada = kAlwaysCompleteAnimation,
  });

  final String celdaId;

  /// Posición dentro de su zona: solo escalona el delay de la animación de
  /// entrada (ver el cálculo de `beginFrac`/`endFrac` más abajo), no se usa
  /// para nada más.
  final int entryIndex;

  /// Controller ÚNICO compartido por toda la grilla (uno solo, en
  /// `CeldasScreen`) — reemplaza el `AnimationController` propio que antes
  /// creaba cada tarjeta, que instanciaba ~30 controllers/tickers de golpe
  /// en el primer build. Cada tarjeta deriva su propio tramo de entrada con
  /// `Interval`, calculado a partir de [entryIndex], sobre este mismo
  /// controller. Por defecto ya completo (`kAlwaysCompleteAnimation`): una
  /// `CeldaCard` construida suelta (tests, reutilización futura) se muestra
  /// de una sin exigir un controller real.
  final Animation<double> entrada;

  /// Tope del delay escalonado por índice: la tarjeta N-ésima de su zona
  /// empieza a entrar a los `(N * 25).clamp(0, maxDelayMs)` ms.
  static const maxDelayMs = 300;

  /// Duración que debe tener el controller compartido de `CeldasScreen` para
  /// que quepan el delay máximo más la animación de cada tarjeta.
  static final totalMs = maxDelayMs + AppMotion.fast.inMilliseconds;

  /// Long-press y el ícono "⋮" comparten el mismo criterio: OPERADOR sobre
  /// OCUPADA va al panel de acción rápida nuevo (placa, monto, cobro);
  /// cualquier otro caso (ADMIN sobre libre/mantenimiento) sigue yendo al
  /// menú de acciones existente, sin cambios.
  void _abrirAccionRapida(BuildContext context, EstadoCelda estado, bool esOperador) {
    if (esOperador && estado == EstadoCelda.ocupada) {
      showCeldaAccionRapida(context, celdaId);
    } else {
      showCeldaQuickActions(context, celdaId);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Se observa sin condición, antes de cualquier early-return (mismo
    // criterio que `celda_detail_screen.dart`).
    final rol = ref.watch(sessionNotifierProvider).usuario?.rol;
    final esOperador = rol == RolUsuario.operador;
    final esAdmin = rol == RolUsuario.admin;

    // `.select`: solo esta tarjeta se reconstruye cuando SU celda cambia.
    // `reemplazarCelda()` arma una lista nueva pero conserva la misma
    // instancia de `Celda` (con `==` manual) para las que no cambiaron, así
    // que Riverpod no notifica a las tarjetas cuya celda sigue igual.
    final celda = ref.watch(
      celdaListNotifierProvider.select((s) {
        for (final c in s.celdas) {
          if (c.id == celdaId) return c;
        }
        return null;
      }),
    );
    if (celda == null) return const SizedBox.shrink();

    // Tipo real del vehículo parqueado, si se conoce (ver doc de
    // `CeldaListState.ticketInfoPorCeldaId`); `.select` sobre el mapa
    // completo, no sobre `celda`, así que solo esta tarjeta se reconstruye
    // si SU entrada del mapa cambia — un `record` compara por valor, así
    // que un refresco de 30s sin cambios reales no dispara nada.
    final ticketInfo = ref.watch(
      celdaListNotifierProvider.select((s) => s.ticketInfoPorCeldaId[celdaId]),
    );

    // Estado de una acción rápida (§1.4) en vuelo para ESTA celda — ya lo
    // expone `CeldaAccionNotifier`, no se agrega nada nuevo al notifier.
    final pendiente = ref.watch(celdaAccionNotifierProvider(celdaId)).isLoading;

    final duration = AppMotion.effective(context, AppMotion.fast);

    // Reloj compartido: solo las celdas OCUPADAS lo observan, así que el
    // tick de cada minuto no toca LIBRE/MANTENIMIENTO en absoluto.
    Duration? transcurrido;
    if (celda.estado == EstadoCelda.ocupada) {
      final ahora = ref.watch(relojNotifierProvider);
      transcurrido = ahora.toUtc().difference(celda.updatedAt);
    }

    // Mismas condiciones que `celda_quick_actions_sheet.dart` arma su lista
    // `acciones`: si ninguna aplica, el long-press no ofrece nada y no tiene
    // sentido mostrar el atajo. El long-press por sí solo no tiene ningún
    // indicio visual — un operador nuevo no lo descubre solo — así que este
    // ícono lo hace notorio Y sirve como alternativa de un toque.
    final tieneAccionRapida =
        (esOperador && celda.estado == EstadoCelda.ocupada) ||
        (esAdmin &&
            (celda.estado == EstadoCelda.libre ||
                celda.estado == EstadoCelda.mantenimiento));

    // Bahía pintada (skill diseno-parqueadero, "La cuadrícula: bahías
    // pintadas"): el estado se lee por relleno y contenido, nunca por
    // matiz. MANTENIMIENTO no tiene relleno plano — lo pinta _HatchPainter.
    final Color? fondo = switch (celda.estado) {
      EstadoCelda.libre => AppColors.concreto,
      EstadoCelda.ocupada => AppColors.asfalto,
      EstadoCelda.mantenimiento => null,
    };
    final colorTexto = celda.estado == EstadoCelda.ocupada
        ? AppColors.demarcacion
        : AppColors.tinta;

    // Borde de urgencia (solo OCUPADA): intensidad (alpha + grosor) del
    // mismo demarcación, nunca un cambio de matiz — antes interpolaba hacia
    // el naranja de StatusTone.warning, lo que contradecía la skill
    // directamente. LIBRE pasó a un borde neutro (`linea`, 1px): la bahía se
    // lee vacía por el relleno, no necesita el acento amarillo — eso se
    // reserva para lo que sí exige atención (una celda ocupada).
    final urgencia = transcurrido == null
        ? 0.0
        : (transcurrido.inMinutes / 180).clamp(0.0, 1.0);
    final borderColor = switch (celda.estado) {
      EstadoCelda.libre => AppColors.linea,
      EstadoCelda.ocupada => AppColors.demarcacion.withValues(alpha: 0.5 + urgencia * 0.5),
      EstadoCelda.mantenimiento => AppColors.demarcacion.withValues(alpha: 0.5),
    };
    final borderWidth = switch (celda.estado) {
      EstadoCelda.libre => 1.0,
      EstadoCelda.ocupada => 2.0 + urgencia * 1.0,
      EstadoCelda.mantenimiento => 1.5,
    };

    final tarjeta = RepaintBoundary(
      child: Card(
        margin: EdgeInsets.zero,
        color: Colors.transparent,
        elevation: AppElevation.flat,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          // Un OPERADOR sobre una celda LIBRE salta directo a "Registrar
          // entrada" con la celda ya preseleccionada; sobre una OCUPADA abre
          // el panel de acción rápida (bottom sheet, sin navegar a pantalla
          // completa). Cualquier otro caso (ADMIN, o MANTENIMIENTO) mantiene
          // el comportamiento original de ir al detalle.
          onTap: () {
            tapFeedback();
            if (esOperador && celda.estado == EstadoCelda.libre) {
              context.push('/tickets/entrada?celdaId=${celda.id}');
            } else if (esOperador && celda.estado == EstadoCelda.ocupada) {
              showCeldaAccionRapida(context, celdaId);
            } else {
              context.push('/celdas/${celda.id}');
            }
          },
          onLongPress: () {
            tapFeedback();
            _abrirAccionRapida(context, celda.estado, esOperador);
          },
          child: Stack(
            children: [
              // Capa de fondo del rayado, pintada antes que el borde/
              // contenido — el Card ya recorta todo el Stack a sus esquinas
              // redondeadas (`clipBehavior: Clip.antiAlias`), así que esto
              // sale con las esquinas correctas sin lógica de clip propia.
              if (celda.estado == EstadoCelda.mantenimiento)
                const Positioned.fill(
                  child: CustomPaint(painter: _HatchPainter()),
                ),
              // `Positioned.fill`: sin esto, el `AnimatedContainer` (sin
              // tamaño propio) se encoge a su contenido en vez de llenar la
              // celda cuadrada de la grilla — la bahía pintada quedaba más
              // chica que su celda y el ícono de "más opciones" (posicionado
              // relativo a todo el Stack) caía fuera de ella, sobre el fondo
              // de la pantalla en vez del relleno del estado.
              Positioned.fill(
                child: AnimatedContainer(
                  duration: duration,
                  curve: AppMotion.curve,
                  decoration: BoxDecoration(
                    color: fondo,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: borderColor, width: borderWidth),
                  ),
                  padding: const EdgeInsets.all(AppSpacing.gutter),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (celda.estado == EstadoCelda.mantenimiento)
                        // Placa sólida para que el código se lea encima del
                        // rayado — el estado ya lo dice el fondo, esto es
                        // solo legibilidad, no un refuerzo del estado.
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.concreto,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xs,
                              vertical: 2,
                            ),
                            child: Text(
                              celda.codigo,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(color: AppColors.tinta),
                            ),
                          ),
                        )
                      else if (celda.estado == EstadoCelda.libre) ...[
                        // Ícono de tipo permitido en vez del texto: la
                        // celda ya se lee vacía por el relleno, esto solo
                        // aclara qué puede entrar ahí.
                        Icon(
                          tipoVehiculoIcon(celda.tipoPermitido),
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          size: 22,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          celda.codigo,
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(color: colorTexto),
                          textAlign: TextAlign.center,
                        ),
                      ] else ...[
                        // OCUPADA: el código ya no se muestra acá (se ve en
                        // el panel de acción rápida al tocar la celda); el
                        // tipo viene del ticket real si ya se conoce
                        // (`ticketInfo`), y si no, cae de vuelta al tipo
                        // permitido de la celda.
                        Icon(
                          tipoVehiculoIcon(ticketInfo?.tipo ?? celda.tipoPermitido),
                          color: AppColors.demarcacion,
                          size: 22,
                        ),
                        // Placa del ticket abierto: mismo `ticketInfo` que ya
                        // trae el ícono, sin ningún GET nuevo. Ausente solo
                        // si la celda quedó fuera de la primera página de
                        // 100 tickets ABIERTOS (ver doc de `ticketInfo` en
                        // `celda_list_state.dart`) — ahí no se inventa nada,
                        // se omite la línea.
                        if (ticketInfo?.placa case final placa?) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            placa,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorTexto,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (transcurrido != null) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            formatElapsed(transcurrido),
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(color: colorTexto),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
              if (pendiente)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surface.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Center(
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                ),
              if (tieneAccionRapida)
                Positioned(
                  top: 2,
                  right: 2,
                  child: InkResponse(
                    radius: 18,
                    onTap: () {
                      tapFeedback();
                      _abrirAccionRapida(context, celda.estado, esOperador);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      child: celda.estado == EstadoCelda.mantenimiento
                          // Sobre el rayado un tono fijo no alcanza: la
                          // mitad de las franjas son asfalto oscuro (~2:1 de
                          // contraste con onSurfaceVariant, casi invisible
                          // ahí). Misma placa sólida que ya usa el código.
                          ? DecoratedBox(
                              decoration: BoxDecoration(
                                color: AppColors.concreto,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.sm,
                                ),
                              ),
                              child: const Icon(
                                Icons.more_vert,
                                size: 18,
                                color: AppColors.tinta,
                              ),
                            )
                          : Icon(
                              Icons.more_vert,
                              size: 18,
                              // Sobre OCUPADA (fondo asfalto) el tono oscuro
                              // por defecto quedaría invisible; demarcación
                              // pasa 10.6:1 de contraste ahí. Sobre LIBRE,
                              // sin cambios.
                              color: celda.estado == EstadoCelda.ocupada
                                  ? AppColors.demarcacion
                                  : Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                            ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    if (MediaQuery.disableAnimationsOf(context)) return tarjeta;

    // Tramo de esta tarjeta dentro del controller COMPARTIDO: antes de
    // `beginFrac` vale 0, después de `endFrac` vale 1 — mismo efecto que el
    // controller propio de antes (delay + 150ms), solo que derivado de un
    // único controller en vez de instanciar uno por tarjeta.
    final delayMs = (entryIndex * 25).clamp(0, maxDelayMs);
    final beginFrac = delayMs / totalMs;
    final endFrac = (delayMs + AppMotion.fast.inMilliseconds) / totalMs;
    // El fade original usaba el valor crudo (lineal) del controller; el
    // slide lo pasaba por AppMotion.curve. Se preserva esa asimetría acá con
    // dos Interval distintos sobre el mismo tramo.
    final fade = CurvedAnimation(parent: entrada, curve: Interval(beginFrac, endFrac));
    final deslizamiento = CurvedAnimation(
      parent: entrada,
      curve: Interval(beginFrac, endFrac, curve: AppMotion.curve),
    );

    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(deslizamiento),
        child: tarjeta,
      ),
    );
  }
}

/// Rayado diagonal de MANTENIMIENTO: alterna asfalto/demarcación, como el
/// achurado real de una vía cerrada. Patrón constante (no depende de props
/// que cambien), así que nunca necesita repintarse a sí mismo.
class _HatchPainter extends CustomPainter {
  const _HatchPainter();

  static const double _grosor = 8;
  static const double _paso = _grosor * 2;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.asfalto);

    final raya = Paint()
      ..color = AppColors.demarcacion
      ..style = PaintingStyle.stroke
      ..strokeWidth = _grosor;

    for (double x = -size.height; x < size.width + size.height; x += _paso) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), raya);
    }
  }

  @override
  bool shouldRepaint(covariant _HatchPainter oldDelegate) => false;
}
