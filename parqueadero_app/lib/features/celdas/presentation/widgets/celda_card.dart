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
import 'celda_quick_actions_sheet.dart';

/// `ConsumerStatefulWidget` (no `ConsumerWidget`) a propósito: la animación
/// de entrada escalonada (ver [_CeldaCardState.initState]) solo debe correr
/// una vez por tarjeta genuinamente nueva, y eso requiere un `State` cuyo
/// `initState` Flutter reutiliza mientras la `Key` (`ValueKey(celda.id)`,
/// la pone `CeldasScreen`) siga en la misma posición del árbol — así el
/// poll de 30s o un cambio en otra celda no la vuelven a disparar.
class CeldaCard extends ConsumerStatefulWidget {
  const CeldaCard({super.key, required this.celdaId, this.entryIndex = 0});

  final String celdaId;

  /// Posición dentro de su zona: solo escalona el delay de la animación de
  /// entrada (§1.7 del plan), no se usa para nada más.
  final int entryIndex;

  @override
  ConsumerState<CeldaCard> createState() => _CeldaCardState();
}

class _CeldaCardState extends ConsumerState<CeldaCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrada;

  @override
  void initState() {
    super.initState();
    _entrada = AnimationController(vsync: this, duration: AppMotion.fast);
    final delay = Duration(
      milliseconds: (widget.entryIndex * 25).clamp(0, 300),
    );
    Future.delayed(delay, () {
      if (mounted) _entrada.forward();
    });
  }

  @override
  void dispose() {
    _entrada.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          if (c.id == widget.celdaId) return c;
        }
        return null;
      }),
    );
    if (celda == null) return const SizedBox.shrink();

    // Estado de una acción rápida (§1.4) en vuelo para ESTA celda — ya lo
    // expone `CeldaAccionNotifier`, no se agrega nada nuevo al notifier.
    final pendiente = ref
        .watch(celdaAccionNotifierProvider(widget.celdaId))
        .isLoading;

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

    // Borde de urgencia: intensidad (alpha + grosor) del mismo demarcación,
    // nunca un cambio de matiz — antes interpolaba hacia el naranja de
    // StatusTone.warning, lo que contradecía la skill directamente.
    final urgencia = transcurrido == null
        ? 0.0
        : (transcurrido.inMinutes / 180).clamp(0.0, 1.0);
    final borderColor = AppColors.demarcacion.withValues(
      alpha: 0.5 + urgencia * 0.5,
    );
    final borderWidth = 1.5 + urgencia * 1.5;

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
          // entrada" con la celda ya preseleccionada, en vez de pasar por el
          // detalle. Cualquier otro caso (ADMIN, u otro estado) mantiene el
          // comportamiento original.
          onTap: () {
            tapFeedback();
            esOperador && celda.estado == EstadoCelda.libre
                ? context.push('/tickets/entrada?celdaId=${celda.id}')
                : context.push('/celdas/${celda.id}');
          },
          onLongPress: () {
            tapFeedback();
            showCeldaQuickActions(context, widget.celdaId);
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
                      else
                        Text(
                          celda.codigo,
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(color: colorTexto),
                          textAlign: TextAlign.center,
                        ),
                      const SizedBox(height: AppSpacing.xs),
                      // Tipo permitido solo tiene sentido en una bahía
                      // disponible; en MANTENIMIENTO no aplica y, sobre el
                      // rayado, texto suelto (sin placa) no sería legible.
                      if (celda.estado == EstadoCelda.libre)
                        Text(
                          tipoVehiculoLabel(celda.tipoPermitido),
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: colorTexto),
                          textAlign: TextAlign.center,
                        ),
                      if (transcurrido != null)
                        Text(
                          formatElapsed(transcurrido),
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: colorTexto),
                        ),
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
                      showCeldaQuickActions(context, widget.celdaId);
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

    if (MediaQuery.of(context).disableAnimations) return tarjeta;

    return FadeTransition(
      opacity: _entrada,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: _entrada, curve: AppMotion.curve)),
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
